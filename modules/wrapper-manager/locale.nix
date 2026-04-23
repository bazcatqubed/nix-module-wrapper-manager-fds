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
    mkIf
    mkOption
    types
  ;

  cfg = config.locale;

  localeModuleFactory =
    {
      isGlobal ? false,
    }:
    {
      enable = mkOption {
        type = types.bool;
        default = if isGlobal then true else cfg.enable;
        example = false;
        description =
          if isGlobal then
            ''
              Whether to enable explicit glibc locale support. This is recommended
              for Nix-built applications.
            ''
          else
            ''
              Whether to enable locale support for this wrapper. Recommended for
              Nix-built applications.
            '';
      };

      package = mkOption {
        type = types.package;
        default = if isGlobal then (pkgs.glibcLocales.override { allLocales = true; }) else cfg.package;
        description = ''
          The package containing glibc locales.
        '';
      };
    };
in
{
  options.locale = localeModuleFactory { isGlobal = true; };

  options.wrappers =
    let
      localeSubmodule =
        {
          config,
          lib,
          name,
          ...
        }:
        let
          submoduleCfg = config.locale;
        in
        {
          options.locale = localeModuleFactory { isGlobal = false; };

          config = mkIf submoduleCfg.enable {
            env.LOCALE_ARCHIVE.value = "${submoduleCfg.package}/lib/locale/locale-archive";
          };
        };
    in
    mkOption { type = with types; attrsOf (submodule localeSubmodule); };
}
