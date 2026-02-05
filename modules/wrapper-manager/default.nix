# SPDX-FileCopyrightText: 2024-2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

{
  imports = [
    ./base.nix
    ./files.nix
    ./data-format-files.nix
    ./xdg-desktop-entries.nix
    ./xdg-dirs.nix
    ./locale.nix
    ./build.nix
    ./extra-args.nix

    ./programs/systemd
    ./programs/gnome-session
  ];
}
