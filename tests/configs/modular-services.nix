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
      in
      pkgs.runCommand "wrapper-manager-modular-services-actually-built" { } ''
        [ -x "${wrapper}/bin/${config.wrappers.ghostunnel-fds.executableName}" ] \
        && [ -x "${wrapper}/bin/${config.wrappers.ghostunnel-baz.executableName}" ] \
        && touch $out
      '';
  };
  # end::test[]
}
