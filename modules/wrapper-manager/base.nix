# SPDX-FileCopyrightText: 2024-2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

{
  config,
  lib,
  options,
  ...
}:

let
  inherit (lib)
    concatStringsSep
    elem
    escapeShellArg
    lists
    literalExpression
    mapAttrsToList
    mkIf
    mkMerge
    mkOption
    optionals
    types
  ;
  envConfig = config;

  toStringType =
    (
      with types;
      coercedTo (oneOf [
        str
        path
        int
        float
        bool
      ]) (x: "${x}") str
    )
    // {
      description = "string and select types (numbers, boolean, and path) convertible to it";
    };
  envSubmodule =
    {
      config,
      lib,
      name,
      ...
    }:
    {
      options = {
        action = mkOption {
          type = types.enum [
            "unset"
            "set"
            "set-default"
            "prefix"
            "suffix"
          ];
          description = ''
            Sets the appropriate action for the environment variable.

            * `unset`... unsets the given variable.

            * `set-default` only sets the variable with the given value if
            not already set.

            * `set` forcibly sets the variable with given value.

            * `prefix` and `suffix` prepends and appends the environment
            variable containing a given separator-delimited list of values
            respectively. It requires the `value` to be a list of string and a
            `separator` value.
          '';
          default = "set";
          example = "unset";
        };

        value = mkOption {
          type = with types; either toStringType (listOf toStringType);
          description = ''
            The value of the variable that is holding.

            ::: {.note}
            It accepts a list of values only for `prefix` and `suffix` action.
            :::
          '';
          example = "HELLO THERE";
        };

        separator = mkOption {
          type = types.str;
          description = ''
            Separator used to create a character-delimited list of the
            environment variable holding a list of values.

            ::: {.note}
            Only used for `prefix` and `suffix` action.
            :::
          '';
          default = ":";
          example = ";";
        };
      };
    };

  wrapperType =
    {
      name,
      lib,
      config,
      pkgs,
      ...
    }:
    let
      flagType = with types; listOf toStringType;
    in
    {
      options = {
        prependArgs = mkOption {
          type = flagType;
          description = ''
            A list of arguments to be prepended to the user-given argument for the
            wrapper script.
          '';
          default = [ ];
          example = literalExpression ''
            [
              "--config" ./config.conf
            ]
          '';
        };

        appendArgs = mkOption {
          type = flagType;
          description = ''
            A list of arguments to be appended to the user-given argument for the
            wrapper script.
          '';
          default = [ ];
          example = literalExpression ''
            [
              "--name" "doggo"
              "--location" "Your mom's home"
            ]
          '';
        };

        arg0 = mkOption {
          type = types.str;
          description = ''
            The first argument of the wrapper script.
          '';
          example = literalExpression "getExe' pkgs.fastfetch \"fastfetch\"";
        };

        executableName = mkOption {
          type = types.nonEmptyStr;
          description = "The name of the executable.";
          default = name;
          example = "custom-name";
        };

        env = options.environment.variables;
        pathAdd = options.environment.pathAdd;

        preScript = mkOption {
          type = types.lines;
          description = ''
            Script fragments to run before the main executable.

            ::: {.note}
            This option is only used when {option}`build.variant` is set to
            `shell`.
            :::
          '';
          default = "";
          example = literalExpression ''
            echo "HELLO WORLD!"
          '';
        };

        # makeWrapperArgs are unescaped, a third-party module author can take
        # advantage of that with runtime expansion values (if using the shell
        # wrapper).
        makeWrapperArgs = mkOption {
          type = with types; listOf str;
          description = ''
            A list of extra arguments to be passed as part of `makeWrapper`
            build step.
          '';
          example = [ "--inherit-argv0" ];
        };
      };

      config = mkMerge [
        {
          env = envConfig.environment.variables;
          pathAdd = envConfig.environment.pathAdd;

          makeWrapperArgs =
            mapAttrsToList (
              n: v:
              if v.action == "unset" then
                "--${v.action} ${escapeShellArg n}"
              else if
                elem v.action [
                  "prefix"
                  "suffix"
                ]
              then
                "--${v.action} ${escapeShellArg n} ${escapeShellArg v.separator} ${escapeShellArg (concatStringsSep v.separator v.value)}"
              else
                "--${v.action} ${escapeShellArg n} ${escapeShellArg v.value}"
            ) config.env
            ++ (builtins.map (v: "--add-flags ${escapeShellArg v}") config.prependArgs)
            ++ (builtins.map (v: "--append-flags ${escapeShellArg v}") config.appendArgs)
            ++ (optionals (envConfig.build.variant == "shell" && config.preScript != "") (
              let
                preScript =
                  pkgs.runCommand "wrapper-script-prescript-${config.executableName}" { }
                    config.preScript;
              in
              [
                "--run"
                preScript
              ]
            ));
        }

        (mkIf (config.pathAdd != [ ]) {
          env.PATH.value = lists.map builtins.toString config.pathAdd;
          env.PATH.action = "prefix";
        })
      ];
    };
in
{
  options = {
    wrappers = mkOption {
      type = with types; attrsOf (submodule wrapperType);
      description = ''
        A set of wrappers to be included in the resulting derivation from
        wrapper-manager evaluation.
      '';
      default = { };
      example = literalExpression ''
        {
          yt-dlp-audio = {
            arg0 = getExe' pkgs.yt-dlp "yt-dlp";
            prependArgs = [
              "--config-location" ./config/yt-dlp/audio.conf
            ];
          };
        }
      '';
    };

    basePackages = mkOption {
      type = with types; either package (listOf package);
      description = ''
        Packages to be included in the wrapper package. However, there are
        differences in behavior when given certain values.

        * When the value is a bare package, the build process will use
        `$PACKAGE.overrideAttrs` to create the package. This makes it suitable
        to be used as part of `programs.<name>.package` typically found on
        other environments (e.g., NixOS). Take note this means a rebuild of the
        package.

        * When the value is a list of packages, the build process will use
        `symlinkJoin` as the builder to create the derivation.
      '';
      default = [ ];
      example = literalExpression ''
        with pkgs; [
          yt-dlp
        ]
      '';
    };

    environment.variables = mkOption {
      type = with types; attrsOf (submodule envSubmodule);
      description = ''
        A global set of environment variables and their actions to be applied
        per-wrapper.
      '';
      default = { };
      example = literalExpression ''
        {
          "FOO_TYPE".value = "custom";
          "FOO_LOG_STYLE" = {
            action = "set-default";
            value = "systemd";
          };
          "USELESS_VAR".action = "unset";
        }
      '';
    };

    environment.pathAdd = mkOption {
      type = with types; listOf path;
      description = ''
        A global list of paths to be added per-wrapper as part of the `PATH`
        environment variable.
      '';
      default = [ ];
      example = literalExpression ''
        wrapperManagerLib.getBin (with pkgs; [
          yt-dlp
          gallery-dl
        ])
      '';
    };
  };
}
