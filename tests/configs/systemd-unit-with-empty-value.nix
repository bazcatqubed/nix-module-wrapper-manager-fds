# The (reduced) basic systemd unit test but some of the units are disabled and
# should be absent in the final output. Though, disabled units should still
# have their metadata.
{ config, lib, pkgs, ... }:

{
  programs.systemd.user.targets.activitywatch = {
    enable = false;
    wantedBy = [ "default.target" ];
    description = "ActivityWatch server";
    requires = [ "default.target" ];
  };

  # This module only naively generates them unit.
  programs.systemd.user.services.activitywatch = {
    enable = true;
    bindsTo = [ "activitywatch.target" ];
    description = "ActivityWatch time tracker";
    documentation = [ "https://docs.activitywatch.net" ];

    serviceConfig = {
      LockPersonality = true;
      Restart = "on-failure";
      RestrictNamespaces = true;
    };
  };

  programs.systemd.system.services.hello.enable = false;
  programs.systemd.system.timers.hello.enable = false;

  programs.systemd.user.services."gnome-session-manager@".enable = false;
  programs.systemd.user.services."gnome-session-manager@one.foodogsquared.HorizontalHunger/10-gnome-session-wrapper-manager-override".enable = false;

  programs.systemd.system.targets.there = {
    enableStatelessInstallation = true;
    aliases = [ "whut-whut.service" ];
    wantedBy = [ "graphical.target" ];
    requiredBy = [ "multi-user.target" ];
    upheldBy = [ "default.target" "basic.target" ];
    description = "EEEEEEEEeeeeeeehhh.....";
  };

  programs.systemd.system.targets.whomp = {
    enable = false;
    enableStatelessInstallation = false;
    aliases = [ "whut-whut.service" ];
    wantedBy = [ "graphical.target" ];
    requiredBy = [ "multi-user.target" ];
    upheldBy = [ "default.target" "basic.target" ];
    description = "EEEEEEEEeeeeeeehhh.....";
  };

  # tag::test[]
  build.extraPassthru.wrapperManagerTests = {
    actuallyBuilt =
      let
        wrapper = config.build.toplevel;
        systemdDir = "${wrapper}/etc/systemd";
      in
        pkgs.runCommand "wrapper-manager-systemd-units-with-empty-value-actually-built" { } ''
        [ ! -f "${systemdDir}/system/hello.service" ] \
        && [ ! -f "${systemdDir}/system/hello.timer" ] \
        && [ ! -f "${systemdDir}/system/hello.socket" ] \
        && [ ! -f "${systemdDir}/user/activitywatch.target" ] \
        && [ -f "${systemdDir}/user/activitywatch.service" ] \
        && [ ! -f "${systemdDir}/user/gnome-session-manager@.service" ] \
        && [ ! -f "${systemdDir}/user/gnome-session-manager@one.foodogsquared.HorizontalHunger.service.d/10-gnome-session-wrapper-manager-override.conf" ] \
        && [ -d "${systemdDir}/system/graphical.target.wants" ] \
        && [ -d "${systemdDir}/system/multi-user.target.requires" ] \
        && [ -d "${systemdDir}/system/default.target.upholds" ] \
        && [ -d "${systemdDir}/system/basic.target.upholds" ] \
        && [ -L "${systemdDir}/system/basic.target.upholds/there.target" ] \
        && [ ! -L "${systemdDir}/system/basic.target.upholds/whomp.target" ] \
        && touch $out
        '';

    checkMetadata =
      let
        inherit (config.programs) systemd;
      in
        lib.optionalAttrs (
          # We're still checking for the disabled systemd units here.
          systemd.system.services."hello".name == "hello.service"
          && systemd.system.targets."whomp".name == "whomp.target"
          && systemd.user.services."gnome-session-manager@".name == "gnome-session-manager@.service"
          && systemd.user.services."gnome-session-manager@one.foodogsquared.HorizontalHunger/10-gnome-session-wrapper-manager-override".name == "gnome-session-manager@one.foodogsquared.HorizontalHunger.service"
        ) pkgs.emptyFile;
  };
  # end::test[]
}
