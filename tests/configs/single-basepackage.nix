{
  config,
  lib,
  pkgs,
  ...
}:

{
  basePackages = pkgs.fastfetch;

  wrappers.fastfetch-guix = {
    arg0 = lib.getExe' pkgs.fastfetch "fastfetch";
    appendArgs = [
      "--logo"
      "Guix"
    ];
    env.NO_COLOR.value = "1";
    xdg.desktopEntry.enable = true;
  };

  # tag::test[]
  build.extraPassthru.wrapperManagerTests = {
    singleBasePackage =
      let
        wrapper = config.build.toplevel;
      in
      pkgs.runCommand "wrapper-manager-single-basepackage-actually-built" { } ''
        [ -e "${wrapper}/share/applications/fastfetch-guix.desktop" ] && [ -x "${wrapper}/bin/${config.wrappers.fastfetch-guix.executableName}" ] && touch $out
      '';

    checkMetadata =
      let
        inherit (pkgs) fastfetch;
        wrapper = config.build.toplevel;
        expectedDefaultDrvName = "${fastfetch.pname}-${fastfetch.version}-wm-wrapped";
      in
        lib.optionalAttrs (
          # We're checking the default value
          config.build.drvName == expectedDefaultDrvName
          && wrapper.name == expectedDefaultDrvName
        ) pkgs.emptyFile;
  };
  # end::test[]
}
