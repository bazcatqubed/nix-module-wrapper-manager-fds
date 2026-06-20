# SPDX-FileCopyrightText: 2024-2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

{ pkgs, ... }:

{
  imports = [
    ./base.nix
    ./files.nix
    ./data-format-files.nix
    ./locale.nix
    ./build.nix
    ./lib.nix
    ./xdg/base-dirs.nix
    ./xdg/desktop-entries.nix

    ./programs/systemd
    ./programs/gnome-session
  ];
}
