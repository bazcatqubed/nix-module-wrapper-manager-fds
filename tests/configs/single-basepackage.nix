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
  };
  # end::test[]
}
