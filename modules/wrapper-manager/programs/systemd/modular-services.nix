# systemd-slash-wrapper-manager-fds integration for modular services.
{ config, lib, pkgs, ... }:

let
  cfg = config.environment.services;

  dashen = a: b:
    if b == "" then a
    else if a == "" then b
    else "${a}-${b}";

  makeUnits = unitType: prefix: topLevelServiceCfg:
  lib.concatMapAttrs (unitName: unitModule: {
    "${prefix}" = { ... }: {
      imports = unitModule;
    };
  }) topLevelServiceCfg.systemd.${unitType}
  // lib.concatMapAttrs (subunitName: subservice:
    makeUnits unitType (dashen prefix subunitName) subservice
  ) topLevelServiceCfg.services;
in
{
  environment.sharedServiceModules = [
    "${pkgs.path}/nixos/modules/system/service/systemd/service.nix"
  ];

  programs.systemd.system.services = lib.concatMapAttrs (
    unitName: topLevelServiceCfg: makeUnits "service" unitName topLevelServiceCfg
  ) cfg;

  programs.systemd.system.sockets = lib.concatMapAttrs (
    unitName: topLevelServiceCfg: makeUnits "sockets" unitName topLevelServiceCfg
  ) cfg;
}
