# SPDX-FileCopyrightText: 2024-2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    attrValues
    concatMapStrings
    concatStringsSep
    isList
    literalExpression
    mkOption
    optionals
    recursiveUpdate
    types
  ;
in
{
  options.build = {
    drvName = mkOption {
      type = types.nonEmptyStr;
      description = ''
        The name of the final derivation output.
      '';
      default =
        if isList config.basePackages then
          "wrapper-manager-fds-wrapped-package"
        else
          let
            package = config.basePackages;
          in
          "${package.pname}-${package.version}-wm-wrapped";
      defaultText = ''
        if `config.basePackages` is a list then
          `"wrapper-manager-fds-wrapped-package"`
        else
          `"''$PACKAGE_PNAME-$PACKAGE_VERSION-wm-wrapped"`
      '';
      example = "my-custom-package-name";
    };

    variant = mkOption {
      type = types.enum [
        "binary"
        "shell"
      ];
      description = ''
        Indicates the type of wrapper to be made. By default, wrapper-manager
        sets this to `binary`.
      '';
      default = "binary";
      example = "shell";
    };

    extraSetup = mkOption {
      type = types.lines;
      description = ''
        Additional script for setting up the wrapper script derivation.
      '';
      default = "";
    };

    extraPassthru = mkOption {
      type = with types; attrsOf anything;
      description = ''
        Set of data to be passed through `passthru` of the resulting
        derivation.
      '';
      default = { };
    };

    extraMeta = mkOption {
      type = with types; attrsOf anything;
      description = ''
        Additional attributes to be passed as part of `meta` in the resulting
        derivation.
      '';
      default = { };
      example = literalExpression ''
        {
          mainProgram = config.wrappers.hello.executableName;
        }
      '';
    };

    toplevel = mkOption {
      type = types.package;
      readOnly = true;
      internal = true;
      description = "A derivation containing the wrapper script.";
    };
  };

  config = {
    build = {
      toplevel =
        let
          inherit (config.build) variant;
          makeWrapperArg0 =
            if variant == "binary" then
              "makeBinaryWrapper"
            else if variant == "shell" then
              "makeShellWrapper"
            else
              "makeWrapper";

          mkWrapBuild =
            wrappers:
            concatMapStrings (v: ''
              ${makeWrapperArg0} "${v.arg0}" "${builtins.placeholder "out"}/bin/${v.executableName}" ${concatStringsSep " " v.makeWrapperArgs}
            '') wrappers;

          mkDesktopEntries = desktopEntries: builtins.map (entry: pkgs.makeDesktopItem entry) desktopEntries;

          desktopEntries = mkDesktopEntries (attrValues config.xdg.desktopEntries);
        in
        if isList config.basePackages then
          pkgs.buildEnv {
            passthru = config.build.extraPassthru;
            meta = config.build.extraMeta;
            name = config.build.drvName;
            paths = desktopEntries ++ config.basePackages;
            nativeBuildInputs =
              if variant == "binary" then
                [ pkgs.makeBinaryWrapper ]
              else if variant == "shell" then
                [ pkgs.makeShellWrapper ]
              else
                [ ];
            postBuild = ''
              ${config.build.extraSetup}
              ${mkWrapBuild (attrValues config.wrappers)}
            '';
          }
        else
          config.basePackages.overrideAttrs (
            final: prev: {
              name = config.build.drvName;
              nativeBuildInputs =
                (prev.nativeBuildInputs or [ ])
                ++ (
                  if variant == "binary" then
                    [ pkgs.makeBinaryWrapper ]
                  else if variant == "shell" then
                    [ pkgs.makeShellWrapper ]
                  else
                    [ ]
                )
                ++ optionals (config.xdg.desktopEntries != { }) [ pkgs.copyDesktopItems ];
              desktopItems = (prev.desktopItems or [ ]) ++ desktopEntries;
              postFixup = ''
                ${prev.postFixup or ""}
                ${mkWrapBuild (attrValues config.wrappers)}
              '';
              passthru = recursiveUpdate (prev.passthru or { }) (
                config.build.extraPassthru
                // {
                  unwrapped = config.basePackages;
                }
              );
              meta = recursiveUpdate (prev.meta or { }) config.build.extraMeta;
            }
          );
    };
  };
}
