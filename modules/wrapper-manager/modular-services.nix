# SPDX-FileCopyrightText: 2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
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
    concatLists
    head
    literalExpression
    mapAttrs
    mapAttrsToList
    mkOption
    tail
    types
  ;

  cfg = config.environment.services;

  portable-lib = import "${pkgs.path}/lib/services/lib.nix" { inherit lib; };

  moduleServiceConfiguration = portable-lib.configure {
    serviceManagerPkgs = pkgs;
    extraRootModules = config.environment.sharedServiceModules;
  };
in
{
  options.environment.services = mkOption {
    description = ''
      Set of [modular
      services](https://nixos.org/manual/nixos/stable/#modular-services) to be
      integrated within the module environment.
    '';
    type = types.attrsOf moduleServiceConfiguration.serviceSubmodule;
    default = { };
    visible = "shallow";
  };

  options.environment.sharedServiceModules = mkOption {
    description = ''
      Additional modules to be imported through all of the modular service
      configurations.
    '';
    type = with types; listOf deferredModule;
    default = [ ];
    example = literalExpression ''
      [
        "''${pkgs.path}/nixos/modules/system/service/systemd/system.nix"
        "''${pkgs.path}/nixos/modules/system/service/systemd/config-data.nix"
      ]
    '';
  };

  config =
    let
      mkSubmoduleWarnings =
        fn: name: cfg:
        fn (options.environment.services.loc ++ [ name ]) cfg;
    in
    {
      assertions = concatLists (
        mapAttrsToList (mkSubmoduleWarnings portable-lib.getAssertions) cfg
      );

      warnings = concatLists (lib.mapAttrsToList (mkSubmoduleWarnings portable-lib.getWarnings) cfg);

      wrappers = mapAttrs (name: value: {
        arg0 = head value.process.argv;
        appendArgs = tail value.process.argv;
      }) cfg;
    };
}
