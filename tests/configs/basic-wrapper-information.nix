{ config, lib, pkgs, ... }:

{
  wrappers.hello = {
    arg0 = lib.getExe' pkgs.hello "hello";
    prependArgs = [
      "--traditional"
    ];
  };


  # tag::test[]
  build.extraPassthru.wrapperManagerTests = {
    actuallyBuilt =
      let
        wrapper = config.build.toplevel;
        systemdDir = "${wrapper}/etc/systemd";
      in
      pkgs.runCommand "wrapper-manager-systemd-units-actually-built" { } ''
        [ -x "${wrapper}/bin/hello" ] && touch $out
      '';

    checkMetadata =
        let
          wrapper = config.wrappers.hello;
        in
        lib.optionalAttrs (
          wrapper.argv == [ (lib.getExe' pkgs.hello "hello") "--traditional" ]
        ) pkgs.emptyFile;
  };
  # end::test[]
}
