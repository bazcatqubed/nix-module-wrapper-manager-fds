# SPDX-FileCopyrightText: 2024-2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

{
  config,
  lib,
  pkgs,
  ...
}@moduleArgs:

let
  inherit (lib)
    filterAttrs
    mapAttrsToList
    mkDefault
    mkIf
    mkMerge
    optionals
  ;

  cfg = config.wrapper-manager;
  wmDocs = import ../../../docs {
    inherit pkgs;
    inherit (cfg.documentation) extraModules;
  };
in
{
  imports = [ ../common.nix ];

  config = mkMerge [
    {
      home.packages =
        optionals cfg.documentation.manpage.enable [
          wmDocs.outputs.manpage
          wmDocs.outputs.manpageCommonEnv.home-manager
        ]
        ++ optionals cfg.documentation.html.enable [ wmDocs.outputs.html ];

      wrapper-manager.extraSpecialArgs.hmConfig = config;
    }

    (mkIf (moduleArgs ? nixosConfig) {
      wrapper-manager.sharedModules = [
        (
          { lib, ... }:
          {
            # NixOS already has the option to set the locale so we don't need to
            # have this.
            config.locale.enable = mkDefault false;
          }
        )
      ];
    })

    (mkIf (cfg.packages != { }) {
      home.packages =
        let
          validPackages = filterAttrs (_: wrapper: wrapper.enableInstall) cfg.packages;
        in
        mapAttrsToList (_: wrapper: wrapper.build.toplevel) validPackages;
    })
  ];
}
