{ config, lib, pkgs, ... }:

{
  environment.services = {
    ghostunnel-fds = {
      imports = [ pkgs.ghostunnel.services.default ];

      ghostunnel = {
        listen = "0.0.0.0:5743";
        target = "0.0.0.0:5321";
        allowAll = true;
        cacert = null;
      };
    };

    ghostunnel-baz = {
      imports = [ pkgs.ghostunnel.services.default ];

      ghostunnel = {
        listen = "0.0.0.0:6033";
        target = "0.0.0.0:5839";
        cacert = null;
      };
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
          [ -x "${wrapper}/bin/ghostunnel-baz" ] \
          && [ -x "${wrapper}/bin/ghostunnel-fds" ] \
          && [ -f "${systemdDir}/system/ghostunnel-baz.service" ] \
          && [ -f "${systemdDir}/system/ghostunnel-fds.service" ] \
          && touch $out
        '';

    checkMetadata =
      let
        inherit (config.programs) systemd;
      in
        lib.optionalAttrs (
          systemd.system.services."ghostunnel-baz".name == "ghostunnel-baz.service"
          && systemd.system.services."ghostunnel-fds".name == "ghostunnel-fds.service"
        ) pkgs.emptyFile;
  };
  # end::test[]
}
