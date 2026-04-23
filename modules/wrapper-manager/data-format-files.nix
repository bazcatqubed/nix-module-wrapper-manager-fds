# SPDX-FileCopyrightText: 2025-2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

{
  config,
  lib,
  pkgs,
  options,
  ...
}:

let
  inherit (lib)
    literalExpression
    mapAttrs'
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    nameValuePair
    types
  ;

  cfg = config.dataFormats;

  dataFileModule =
    {
      config,
      name,
      ...
    }:
    {
      options = {
        target = mkOption {
          type = types.str;
          description = ''
            Path relative to the derivation output path.
          '';
          example = literalExpression "/etc/xdg/app/config.json";
          default = name;
        };

        variant = mkOption {
          type = types.nonEmptyStr;
          description = ''
            Indicates what data format to generate for the data file from
            {option}`dataFormats.formats`.
          '';
          default = "json";
          example = "yaml";
        };

        mode = mkOption {
          type = types.strMatching "[0-7]{3,4}";
          default = "0444";
          example = "0600";
          description = ''
            Permissions to be given to the file. By default, it is given with a
            symlink.
          '';
        };

        content = mkOption {
          type = cfg.formats.${config.variant}.type // {
            description = "given from {option}`dataFormats.formats.<variant>.type`";
          };
          description = ''
            The data content structure in accordance to the variant's type.
          '';
          example = literalExpression ''
            {
              num_of_boundaries = 67;
              battle.skills = [
                "Bushido Flow"
                "Shy Supernova"
                "Mach 13 Elephant Explosion"
                "Steel Python"
                "Cashmere Cannonball"
              ];
            }
          '';
        };
      };
    };

  formatModule =
    { name, ... }:
    {
      freeformType = with types; attrsOf anything;

      options = {
        type = mkOption {
          type = types.optionType;
          description = ''
            The module option type for the value of the Nix-representable format.
          '';
        };

        generate = mkOption {
          type = with types; functionTo (functionTo package);
          description = ''
            The generator function for the Nix-representable format.
          '';
        };
      };
    };
in
{
  options.dataFormats = {
    formats = mkOption {
      type = with types; attrsOf (submodule formatModule);
      description = ''
        A set of [Nix-representable
        formats](https://nixos.org/manual/nixos/unstable/#sec-settings-nix-representable)
        to generate the files configured from
        {option}`dataFormats.files.<name>.content`.
      '';
      default = { };
      example = literalExpression ''
        {
          json = pkgs.formats.json { };
          ini = pkgs.formats.ini { };
        }
      '';
    };

    enableCommonFormats = mkEnableOption null // {
      description = ''
        Whether to initialize {option}`dataFormats.formats` with common formats.

        For future references, the formats exported are JSON, YAML, TOML, and
        INI. With the following code being equivalent to the module effect:

        ```nix
        {
          json = pkgs.formats.json { };
          yaml = pkgs.formats.yaml { };
          toml = pkgs.formats.toml { };
          ini = pkgs.formats.ini { };
        }
        ```
      '';
      default = true;
      example = false;
    };

    enableExtraFormats = mkEnableOption null // {
      description = ''
        Whether to initialize extra data formats from other modules.

        :::{.note}
        For third-party module authors, you can use this option as the basis
        for adding your own data formats.
        :::
      '';
    };

    files = mkOption {
      type = with types; attrsOf (submodule dataFileModule);
      default = { };
      description = ''
        A set of data files to be exported to the package.
      '';
      example = literalExpression ''
        {
          "share/lazygit/config.yml" = {
            variant = "yaml";
            content = mkMerge [
              {
                gui = {
                  expandFocusedSidePanel = true;
                  showBottomLine = false;
                  skipRewordInEditorWarning = true;
                  theme = {
                    selectedLineBgColor = [ "reverse" ];
                    selectedRangeBgColor = [ "reverse" ];
                  };
                };
                notARepository = "skip";
              }

              {
                gui.expandFocusedSidePanel = mkForce false;
              }
            ];
          };

          "/etc/hello/config.json" = {
            variant = "json";
            content = {
              locale = "FR";
              defaultName = "Gretchen";
              defaultFormat = "long";
            };
          };
        }
      '';
    };
  };

  config = mkMerge [
    (mkIf cfg.enableCommonFormats {
      dataFormats.formats = {
        json = pkgs.formats.json { };
        toml = pkgs.formats.toml { };
        yaml = pkgs.formats.yaml { };
        ini = pkgs.formats.ini { };
      };
    })

    (mkIf (cfg.files != { }) {
      files =
        let
          generateFile =
            n: v:
            nameValuePair n {
              inherit (v) mode;
              source =
                cfg.formats.${v.variant}.generate "wrapper-manager-data-file-${builtins.baseNameOf n}"
                  v.content;
            };
        in
        mapAttrs' generateFile cfg.files;
    })
  ];
}
