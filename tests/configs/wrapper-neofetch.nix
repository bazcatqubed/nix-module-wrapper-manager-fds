{
  config,
  lib,
  pkgs,
  yourMomName,
  ...
}:

{
  build.drvName = "simple-womp-womp";

  wrappers.neofetch = {
    arg0 = lib.getExe' pkgs.neofetch "neofetch";
    executableName = yourMomName;
    appendArgs = [
      "--ascii_distro"
      "guix"
      "--title_fqdn"
      "off"
      "--os_arch"
      "off"
    ];
  };

  # tag::test[]
  build.extraPassthru.wrapperManagerTests = {
    actuallyBuilt =
      let
        wrapper = config.build.toplevel;
      in
      pkgs.runCommand "wrapper-manager-neofetch-actually-built" { } ''
        [ -x "${wrapper}/bin/${config.wrappers.neofetch.executableName}" ] && touch $out
      '';

    checkMetadata =
      let
        wrapper = config.build.toplevel;
      in
        lib.optionalAttrs (
          wrapper.name == config.build.drvName
        ) pkgs.emptyFile;
  };
  # end::test[]
}
