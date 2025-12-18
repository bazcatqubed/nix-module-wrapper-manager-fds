{ config, lib, pkgs, ... }:

{
  programs.systemd.system.automounts = {
    "media-archives" = {
      where = "/media/archives";
      automountConfig.TimeoutIdleSec = 2;
    };
  };

  programs.systemd.system.mounts = {
    gnu = {
      documentation = [ "man:guix(1)" ];
      what = "/dev/sda3";
      where = "/gnu";

      enableStatelessInstallation = true;
      wantedBy = [ "guix-daemon.service" ];
    };

    home = {
      what = "/dev/sda1";
      where = "/home";
    };

    nix = {
      what = "/dev/sda2";
      where = "/nix";

      preStop = ''
        echo hello
      '';
      postStop = ''
        echo hehehehe
      '';
    };
  };

  # tag::test[]
  build.extraPassthru.wrapperManagerTests = {
    actuallyBuilt =
      let
        wrapper = config.build.toplevel;
        systemdDir = "${wrapper}/etc/systemd";
      in
        pkgs.runCommand "wrapper-manager-systemd-automount-and-mount-units-actually-built" { } ''
        [ -f "${systemdDir}/system/gnu.mount" ] \
        && [ -f "${systemdDir}/system/home.mount" ] \
        && [ -f "${systemdDir}/system/nix.mount" ] \
        && [ -f "${systemdDir}/system/media-archives.automount" ] \
        && [ -L "${systemdDir}/system/guix-daemon.service.wants" ] \
        && touch $out
        '';

    checkMetadata =
      let
        inherit (config.programs) systemd;
      in
        lib.optionalAttrs (
          systemd.system.mounts."gnu".name == "gnu.mount"
          && systemd.system.mounts."nix".name == "nix.mount"
          && systemd.system.mounts."home".name == "home.mount"
          && systemd.system.automounts."media-archives".name == "media-archives.automount"
        ) pkgs.emptyFile;
  };
  # end::test[]
}
