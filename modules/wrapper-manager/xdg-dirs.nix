# SPDX-FileCopyrightText: 2024-2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

{ config, lib, ... }:

let
  inherit (lib)
    lists
    literalExpression
    mkMerge
    mkOption
    types
  ;

  cfg = config.xdg;

  xdgDirsOption = {
    configDirs = mkOption {
      type = with types; listOf str;
      description = ''
        A list of paths to be appended as part of the `XDG_CONFIG_DIRS`
        environment to be applied per-wrapper.
      '';
      default = [ ];
      example = literalExpression ''
        wrapperManagerLib.getXdgConfigDirs (with pkgs; [
          yt-dlp
          fastfetch
        ])
      '';
    };

    dataDirs = mkOption {
      type = with types; listOf str;
      description = ''
        A list of paths to be appended as part of the `XDG_DATA_DIRS`
        environment to be applied per-wrapper.
      '';
      default = [ ];
      example = literalExpression ''
        wrapperManagerLib.getXdgDataDirs (with pkgs; [
          yt-dlp
          fastfetch
        ])
      '';
    };
  };
in
{
  options.xdg = xdgDirsOption;

  options.wrappers = mkOption {
    type =
      let
        xdgDirsType =
          {
            name,
            lib,
            config,
            ...
          }:
          {
            options.xdg = xdgDirsOption;

            config = mkMerge [
              {
                # When set this way, we could allow the user to override everything.
                xdg.configDirs = cfg.configDirs;
                xdg.dataDirs = cfg.dataDirs;
              }

              (lib.mkIf (config.xdg.configDirs != [ ]) {
                env.XDG_CONFIG_DIRS.value = lists.map builtins.toString config.xdg.configDirs;
                env.XDG_CONFIG_DIRS.action = "prefix";
              })

              (lib.mkIf (config.xdg.dataDirs != [ ]) {
                env.XDG_DATA_DIRS.value = lists.map builtins.toString config.xdg.dataDirs;
                env.XDG_DATA_DIRS.action = "prefix";
              })
            ];
          };
      in
      with types;
      attrsOf (submodule xdgDirsType);
  };
}
