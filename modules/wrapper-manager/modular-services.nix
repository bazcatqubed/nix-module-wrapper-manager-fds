{ config, lib, pkgs, options, ... }:

let
  cfg = config.environment.services;

  portable-lib = import "${pkgs.path}/nixos/modules/system/service/portable/lib.nix" { inherit lib; };

  moduleServiceConfiguration = portable-lib.configure {
    serviceManagerPkgs = pkgs;
    extraRootModules = config.environment.sharedServiceModules;
  };
in
{
  options.environment.services = lib.mkOption {
    description = ''
      Set of [modular
      services](https://nixos.org/manual/nixos/stable/#modular-services) to be
      integrated within the module environment.
    '';
    type = lib.types.attrsOf moduleServiceConfiguration.serviceSubmodule;
    default = { };
    visible = "shallow";
  };

  options.environment.sharedServiceModules = lib.mkOption {
    description = ''
      Additional modules to be imported through all of the modular service
      configurations.
    '';
    type = with lib.types; listOf deferredModule;
    default = [ ];
    example = lib.literalExpression ''
      [
        "''${pkgs.path}/nixos/modules/system/service/systemd/system.nix"
        "''${pkgs.path}/nixos/modules/system/service/systemd/config-data.nix"
      ]
    '';
  };

  config = let
    mkSubmoduleWarnings = fn: name: cfg:
      fn (options.environment.services.loc ++ [ name ]) cfg;
  in {
    assertions = lib.concatLists (
      lib.mapAttrsToList (mkSubmoduleWarnings portable-lib.getAssertions) cfg
    );

    warnings = lib.concatLists (
      lib.mapAttrsToList (mkSubmoduleWarnings portable-lib.getWarnings) cfg
    );

    wrappers =
      lib.mapAttrs (name: value: {
        arg0 = lib.head value.process.argv;
        appendArgs = lib.tail value.process.argv;
      }) cfg;
  };
}
