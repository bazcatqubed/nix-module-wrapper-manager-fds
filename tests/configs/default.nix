let
  sources = import ../../npins;
in
{
  pkgs ? import sources.nixos-unstable { },
}:

let
  wmLib = (import ../../. { }).lib;
  build = args: wmLib.build (args // { inherit pkgs; });
in
{
  fastfetch = build { modules = [ ./wrapper-fastfetch.nix ]; };
  neofetch = build {
    modules = [ ./wrapper-neofetch.nix ];
    specialArgs.yourMomName = "Yor mom";
  };
  xdg-desktop-entry = build { modules = [ ./xdg-desktop-entry.nix ]; };
  xdg-basedirs = build { modules = [ ./xdg-basedirs.nix ]; };
  single-basepackage = build { modules = [ ./single-basepackage.nix ]; };
  neofetch-with-additional-files = build { modules = [ ./neofetch-with-additional-files.nix ]; };
  systemd-units = build { modules = [ ./systemd-units.nix ]; };
  systemd-unit-data-format-files = build { modules = [ ./systemd-unit-data-format-files.nix ]; };
  systemd-unit-with-empty-value = build { modules = [ ./systemd-unit-with-empty-value.nix ]; };
  wrappers-with-systemd-units = build { modules = [ ./wrappers-with-systemd-enabled.nix ]; };
  wrappers-for-yt-dlp = build { modules = [ ./wrappers-for-yt-dlp.nix ]; };
  data-format-files = build { modules = [ ./data-format-files ]; };
  gnome-session-basic-example = build { modules = [ ./gnome-session-basic-example.nix ]; };

  # Testing out from the library set that needs the module environment.
  lib-modules-make-wraparound = build { modules = [ ./lib-modules-subset/make-wraparound.nix ]; };
  systemd-lib-module-test = build { modules = [ ./lib-modules-subset/systemd-lib-module-test.nix ]; };
}
