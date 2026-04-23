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
    escapeShellArg
    filesystem
    foldlAttrs
    literalExpression
    mkBefore
    mkIf
    mkOption
    modules
    replaceStrings
    strings
    types
  ;

  cfg = config.files;

  filesModule =
    {
      name,
      lib,
      config,
      options,
      ...
    }:
    {
      options = {
        target = mkOption {
          type = types.nonEmptyStr;
          description = ''
            Path of the file relative to the derivation output path.
          '';
          default = name;
          example = "share/applications/org.example.App1.desktop";
        };

        source = mkOption {
          type = types.path;
          description = "Path of the file to be linked.";
        };

        text = mkOption {
          type = with types; nullOr lines;
          description = ''
            Text content of the given filesystem path.
          '';
          default = null;
          example = ''
            key=value
            hello=world
          '';
        };

        mode = mkOption {
          type = types.strMatching "[0-7]{0,4}";
          default = "0644";
          example = "0600";
          description = ''
            Permissions to be given to the file. By default, it is given with a
            symlink.
          '';
        };
      };

      config = {
        source = mkIf (config.text != null) (
          let
            name' = "wrapper-manager-filesystem-${replaceStrings [ "/" ] [ "-" ] name}";
          in
          modules.mkDerivedConfig options.text (pkgs.writeText name')
        );
      };
    };
in
{
  options.files = mkOption {
    type = with types; attrsOf (submodule filesModule);
    description = ''
      Extra set of files to be exported within the derivation.

      ::: {.caution}
      Be careful when placing executables in `$out/bin` as it is handled by
      wrapper-manager build step. Any files in `$out/bin` that have a
      configured wrapper will be overwritten since building the wrapper comes
      after installing the files.
      :::
    '';
    default = { };
    example = literalExpression ''
      {
        "share/example-app/docs".source = ./docs;
        "etc/xdg".source = ./config;

        "share/example-app/example-config".text = ''''
          hello=world
          location=INSIDE OF YOUR WALLS
        '''';
      }
    '';
  };

  config = mkIf (cfg != { }) {
    build.extraSetup =
      let
        installFiles =
          acc: n: v:
          let
            source = escapeShellArg v.source;
            target = escapeShellArg v.target;
            target' = strings.normalizePath "$out/${target}";
            installFile =
              let
                type = filesystem.pathType v.source;
              in
              if type == "directory" then
                ''
                  mkdir -p ${target'} && cp --recursive ${source}/* ${target'}
                ''
              else if type == "symlink" then
                ''
                  ln --symbolic --force ${source} ${target'}
                ''
              else
                ''
                  install -D --mode=${v.mode} ${source} ${target'}
                '';
          in
          ''
            ${acc}
            ${installFile}
          '';
      in
      mkBefore ''
        ${foldlAttrs installFiles "" cfg}
      '';
  };
}
