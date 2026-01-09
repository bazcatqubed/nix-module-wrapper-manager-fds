let
  sources = import ../../npins;
in
{
  pkgs ? import sources.nixos-unstable { },
}:

let
  wmLib = (import ../../. { }).lib;
  build = args: wmLib.build (args // {
    inherit pkgs;
    modules = args.modules or [ ] ++ [
      ../../modules/wrapper-manager/modular-services.nix
    ];
  });

  buildConfig = file: build { modules = [ file ]; };
in
{
  fastfetch = buildConfig ./wrapper-fastfetch.nix;
  neofetch = build {
    modules = [ ./wrapper-neofetch.nix ];
    specialArgs.yourMomName = "Yor mom";
  };
  xdg-desktop-entry = buildConfig ./xdg-desktop-entry.nix;
  xdg-basedirs = buildConfig ./xdg-basedirs.nix;
  single-basepackage = buildConfig ./single-basepackage.nix;
  modular-services = buildConfig ./modular-services.nix;
  neofetch-with-additional-files = buildConfig ./neofetch-with-additional-files.nix;
  systemd-units = buildConfig ./systemd-units.nix;
  systemd-unit-data-format-files = buildConfig ./systemd-unit-data-format-files.nix;
  systemd-unit-with-empty-value = buildConfig ./systemd-unit-with-empty-value.nix;
  systemd-automount-and-mount-units = buildConfig ./systemd-automount-and-mount-units.nix;
  systemd-modular-service-integration = build {
    modules = [
      ./systemd-modular-service-integration.nix
      ../../modules/wrapper-manager/programs/systemd/modular-services.nix
    ];
  };
  wrappers-with-systemd-units = buildConfig ./wrappers-with-systemd-enabled.nix;
  wrappers-for-yt-dlp = buildConfig ./wrappers-for-yt-dlp.nix;
  data-format-files = buildConfig ./data-format-files;
  gnome-session-basic-example = buildConfig ./gnome-session-basic-example.nix;
  gnome-session-basic-example-empty = buildConfig ./gnome-session-basic-example-empty.nix;

  # Testing out from the library set that needs the module environment.
  lib-modules-make-wraparound = buildConfig ./lib-modules-subset/make-wraparound.nix;
  systemd-lib-module-test = buildConfig ./lib-modules-subset/systemd-lib-module-test.nix;
}
