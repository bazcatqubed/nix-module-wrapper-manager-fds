# SPDX-FileCopyrightText: 2025-2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

/*
  A fork of the NixOS systemd library from nixpkgs suited for wrapper-manager's
  needs. The major reason it is forked instead of using it directly is because
  a lot of the functions is centered around NixOS' need (unsurprisingly) and it
  would require a LOT of adjusting otherwise so why not just fork it directly.

  Unlike NixOS' version, wrapper-manager only cares about generating them unit
  files so it won't have additional options such as `restartTriggers` and the
  like. Thus, we have dropped several module options such as
  `systemd.units.<name>.enable` and `systemd.units.<name>.overrideStrategy`.
  Furthermore, we have added support for generating drop-in unit files by
  "$UNITNAME/$OVERRIDE_NAME" where it should map to
  `$out/etc/systemd/$TYPEDIR/$UNITNAME.$UNITTYPE.d/$OVERRIDE_NAME.conf`.

  It is meant to be composed alongside other packages of other environments
  (e.g., `systemd.packages` from NixOS) after all and several environment
  implementation are already taking care of installing them properly such as
  NixOS and home-manager.
*/
{
  pkgs,
  lib,
  self,
}:

let
  inherit (lib)
    all
    concatLists
    concatMap
    concatMapStringsSep
    concatStrings
    concatStringsSep
    const
    elem
    filterAttrs
    getExe
    hasPrefix
    head
    isDerivation
    isFloat
    isInt
    isList
    isPath
    isString
    last
    length
    mapAttrs
    mapAttrsToList
    match
    optional
    optionalString
    range
    removePrefix
    removeSuffix
    replaceStrings
    reverseList
    splitString
    stringToCharacters
    strings
    tail
    toIntBase10
    trace
    types
  ;
in
rec {
  /**
    Convert the given non-generic unit options into the generic units version.
    For example, it converts `programs.systemd.system.services.hello` suitable
    for `programs.systemd.system.units.hello` where it will be included in the
    derivation.

    For third-party module authors, it is recommended to set
    `programs.systemd.{system,user}.units` with this function.

    # Arguments

    It's an attrset that is expected to have shared module options with
    `programs.systemd.system.units`.

    # Type

    ```
    intoUnit :: attr -> attr
    ```
  */
  intoUnit = def: {
    inherit (def)
      enable
      name
      enableStatelessInstallation
      filename
      settings
      wantedBy
      requiredBy
      upheldBy
      aliases
      ;
  };

  /**
    Builder function for generating a set of systemd units expected to be from
    `programs.systemd.$VARIANT.units`.

    # Arguments

    It's a sole attrset with the following expected attributes:

    units
    : A set of units associated with a systemd installation. Typically, this is
    used from `programs.systemd.user.units` and `programs.systemd.system.units`
    respectively to build the systemd installation directory.

    # Type

    ```
    generateUnits :: Attr -> Derivation
    ```

    # Example

    For the following example, assume it is invoked inside of a wrapper-manager
    configuration.

    ```nix
    { config, lib, pkgs, wrapperManagerLib, ... }:

    {
      files."lib/my-custom-apps/examples/systemd".source =
        wrapperManagerLib.systemd.generateUnits { inherit (config.programs.systemd.system) units; };
    }
    ```
  */
  generateUnits =
    {
      units ? { },
    }@args:
    pkgs.buildEnv {
      ignoreCollisions = false;
      name = "wrapper-manager-systemd-generated-units";
      paths = mapAttrsToList (_: v: v.unit) (filterAttrs (_: v: v.enable) units);
    };

  options = import ./_options.nix { inherit pkgs lib self; };
  submodules = import ./submodules.nix { inherit pkgs lib self; };

  /**
    Given a Nix string, return a shell string value.

    # Arguments

    s
    : The Nix string value.

    # Type

    ```
    shellEscape :: String -> String
    ```

    # Examples

    ```nix
    shellEscape "\\$"
    => "\\\\$"
    ```
  */
  shellEscape = s: (replaceStrings [ "\\" ] [ "\\\\" ] s);

  /**
    Given a Nix string, return a path-safe name typically used as part of a
    filename itself.

    # Arguments

    s
    : The string value.

    # Type

    ```
    mkPathSafeName :: String -> String
    ```

    # Examples

    ```nix
    mkPathSafeName "foo@sample.service"
    => "foo-sample.service"
    ```
  */
  mkPathSafeName = replaceStrings [ "@" ":" "\\" "[" "]" ] [ "-" "-" "-" "" "" ];

  /**
    Module type for matching with the systemd unit filenames.
  */
  unitNameType = types.strMatching "[a-zA-Z0-9@%:_.\\-]+[.](service|socket|device|mount|automount|swap|target|path|timer|scope|slice)";

  /**
    Given a string, split the unit name into the unit name and its drop-in, if
    there's one.

    # Arguments

    s
    : The string value.

    # Type

    ```
    splitUnitFilename :: str -> str
    ```

    # Example

    ```nix
    splitUnitFilename "hello-there.service"
    => [ "hello-there.service" ]

    splitUnitFilename "hello-there.service.d/10-overrides.conf"
    => [ "hello-there.service.d" "10-overrides.conf" ]
    ```
  */
  splitUnitFilename = s: self.utils.splitStringOnce "/" s;

  /**
    Naively get the unit name of the given string.

    # Arguments

    Same as
    [`wrapperManagerLib.systemd.splitUnitFilename`](#function-library-wrapperManagerLib.systemd.splitUnitFilename).

    # Type

    ```
    getUnitName :: str -> str
    ```

    # Examples

    ```nix
    getUnitName "hello.service.d/10-override.conf"
    => hello.service.d
    ```
  */
  getUnitName = s: head (splitUnitFilename s);

  /**
    Given a name and an extension, create the unit filename. Typically used for
    properly setting the `filename` option from `programs.systemd.units` and the
    like.

    # Arguments

    unitType
    : The unit type associated (e.g., `service`, `slice`).

    s
    : String value.

    # Type

    ```
    mkUnitFileName :: str -> str -> str
    ```

    # Example

    ```nix
    mkUnitFileName "service" "hello-there"1
    => "hello-there.service"

    mkUnitFileName "service" "hello-there/10-override"
    => "hello-there.service.d/10-override.conf"
    ```
  */
  mkUnitFileName =
    suffix: s:
    let
      unitName' = splitUnitFilename s;
      unitName = head unitName';
      overrideName = last unitName';
    in
    if unitName == overrideName then
      "${unitName}.${suffix}"
    else
      "${unitName}.${suffix}.d/${overrideName}.conf";

  # Internal implementation for creating a unit within wrapper-manager.
  makeUnit =
    name: unit:
    pkgs.runCommand "unit-${mkPathSafeName name}"
      {
        preferLocalBuild = true;
        allowSubstitutes = false;
        # unit.text can be null. But variables that are null listed in
        # passAsFile are ignored by nix, resulting in no file being created,
        # making the mv operation fail.
        text = unit.text;
        passAsFile = [ "text" ];
      }
      (
        ''
          name=${shellEscape unit.filename}
          mkdir -p "$out/$(dirname -- "$name")"
          mv "$textPath" "$out/$name"
        ''
        + optionalString unit.enableStatelessInstallation (
          let
            makeSymlinkScript =
              suffix: _item:
              let
                folderName = shellEscape "${_item}.${suffix}";
              in
              ''
                folderName=${folderName}
                mkdir -p "$out/$folderName" && ln -sfn ../$name "$out/$folderName/$name"
              '';
          in
          ''
            ${concatStrings (
              builtins.map (alias: ''
                ln -sfn $name "$out/${shellEscape alias}"
              '') unit.aliases
            )}

            ${concatStrings (builtins.map (makeSymlinkScript "wants") unit.wantedBy)}
            ${concatStrings (builtins.map (makeSymlinkScript "requires") unit.requiredBy)}
            ${concatStrings (builtins.map (makeSymlinkScript "upholds") unit.upheldBy)}
          ''
        )
      );

  boolValues = [
    true
    false
    "yes"
    "no"
  ];

  digits = map toString (range 0 9);

  isByteFormat =
    s:
    let
      l = reverseList (stringToCharacters s);
      suffix = head l;
      nums = tail l;
    in
    builtins.isInt s
    || (
      elem suffix (
        [
          "K"
          "M"
          "G"
          "T"
        ]
        ++ digits
      )
      && all (num: elem num digits) nums
    );

  assertByteFormat =
    name: group: attr:
    optional (
      attr ? ${name} && !isByteFormat attr.${name}
    ) "Systemd ${group} field `${name}' must be in byte format [0-9]+[KMGT].";

  toIntBaseDetected =
    value:
    assert (match "[0-9]+|0x[0-9a-fA-F]+" value) != null;
    (builtins.fromTOML "v=${value}").v;

  hexChars = stringToCharacters "0123456789abcdefABCDEF";

  isNumberOrRangeOf =
    check: v:
    if isInt v then
      check v
    else
      let
        parts = splitString "-" v;
        lower = toIntBase10 (head parts);
        upper = if tail parts != [ ] then toIntBase10 (head (tail parts)) else lower;
      in
      length parts <= 2 && lower <= upper && check lower && check upper;
  isPort = i: i >= 0 && i <= 65535;
  isPortOrPortRange = isNumberOrRangeOf isPort;

  assertValueOneOf =
    name: values: group: attr:
    optional (
      attr ? ${name} && !elem attr.${name} values
    ) "Systemd ${group} field `${name}' cannot have value `${toString attr.${name}}'.";

  assertValuesSomeOfOr =
    name: values: default: group: attr:
    optional (
      attr ? ${name}
      && !(all (x: elem x values) (splitString " " attr.${name}) || attr.${name} == default)
    ) "Systemd ${group} field `${name}' cannot have value `${toString attr.${name}}'.";

  assertHasField =
    name: group: attr:
    optional (!(attr ? ${name})) "Systemd ${group} field `${name}' must exist.";

  assertMinimum =
    name: min: group: attr:
    optional (
      attr ? ${name} && attr.${name} < min
    ) "Systemd ${group} field `${name}' must be greater than or equal to ${toString min}";

  checkUnitConfig =
    group: checks: attrs:
    let
      # We're applied at the top-level type (attrsOf unitOption), so the actual
      # unit options might contain attributes from mkOverride and mkIf that we need to
      # convert into single values before checking them.
      defs = mapAttrs (const (
        v:
        if v._type or "" == "override" then
          v.content
        else if v._type or "" == "if" then
          v.content
        else
          v
      )) attrs;
      errors = concatMap (c: c group defs) checks;
    in
    if errors == [ ] then true else trace (concatStringsSep "\n" errors) false;

  toOption =
    x:
    if x == true then
      "true"
    else if x == false then
      "false"
    else
      toString x;

  attrsToSection =
    as:
    concatStrings (
      concatLists (
        mapAttrsToList (
          name: value:
          map (x: ''
            ${name}=${toOption x}
          '') (if isList value then value else [ value ])
        ) as
      )
    );

  makeJobScript =
    {
      name,
      text,
      enableStrictShellChecks,
    }:
    let
      scriptName = replaceStrings [ "\\" "@" ] [ "-" "_" ] (shellEscape name);
      out =
        (
          if !enableStrictShellChecks then
            pkgs.writeShellScriptBin scriptName ''
              set -e

              ${text}
            ''
          else
            pkgs.writeShellApplication {
              name = scriptName;
              inherit text;
            }
        ).overrideAttrs
          (_: {
            # The derivation name is different from the script file name
            # to keep the script file name short to avoid cluttering logs.
            name = "unit-script-${scriptName}";
          });
    in
    getExe out;

  # Create a directory that contains systemd definition files from an attrset
  # that contains the file names as keys and the content as values. The values
  # in that attrset are determined by the supplied format.
  definitions =
    directoryName: format: definitionAttrs:
    let
      listOfDefinitions = mapAttrsToList (name: format.generate "${name}.conf") definitionAttrs;
    in
    pkgs.runCommand directoryName { } ''
      mkdir -p $out
      ${(concatStringsSep "\n" (map (pkg: "cp ${pkg} $out/${pkg.name}") listOfDefinitions))}
    '';

  # Escape a path according to the systemd rules. FIXME: slow
  # The rules are described in systemd.unit(5) as follows:
  # The escaping algorithm operates as follows: given a string, any "/" character is replaced by "-", and all other characters which are not ASCII alphanumerics, ":", "_" or "." are replaced by C-style "\x2d" escapes. In addition, "." is replaced with such a C-style escape when it would appear as the first character in the escaped string.
  # When the input qualifies as absolute file system path, this algorithm is extended slightly: the path to the root directory "/" is encoded as single dash "-". In addition, any leading, trailing or duplicate "/" characters are removed from the string before transformation. Example: /foo//bar/baz/ becomes "foo-bar-baz".
  escapeSystemdPath =
    s:
    let
      replacePrefix =
        p: r: s:
        (if (hasPrefix p s) then r + (removePrefix p s) else s);
      trim = s: removeSuffix "/" (removePrefix "/" s);
      normalizedPath = strings.normalizePath s;
    in
    replaceStrings [ "/" ] [ "-" ] (
      replacePrefix "." (strings.escapeC [ "." ] ".") (
        strings.escapeC (stringToCharacters " !\"#$%&'()*+,;<=>=@[\\]^`{|}~-") (
          if normalizedPath == "/" then normalizedPath else trim normalizedPath
        )
      )
    );

  # Quotes an argument for use in Exec* service lines.
  # systemd accepts "-quoted strings with escape sequences, toJSON produces
  # a subset of these.
  # Additionally we escape % to disallow expansion of % specifiers. Any lone ;
  # in the input will be turned it ";" and thus lose its special meaning.
  # Every $ is escaped to $$, this makes it unnecessary to disable environment
  # substitution for the directive.
  escapeSystemdExecArg =
    arg:
    let
      s =
        if isPath arg then
          "${arg}"
        else if isString arg then
          arg
        else if isInt arg || isFloat arg || isDerivation arg then
          toString arg
        else
          throw "escapeSystemdExecArg only allows strings, paths, numbers and derivations";
    in
    replaceStrings [ "%" "$" ] [ "%%" "$$" ] (strings.toJSON s);

  # Quotes a list of arguments into a single string for use in a Exec*
  # line.
  escapeSystemdExecArgs = concatMapStringsSep " " escapeSystemdExecArg;
}
