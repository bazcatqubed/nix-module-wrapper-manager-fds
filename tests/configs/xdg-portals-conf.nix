# SPDX-FileCopyrightText: 2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

{
  config,
  lib,
  pkgs,
  ...
}:

{
  xdg.portals."com.example.WindowWaweger".settings.preferred = {
    default = [ "gnome" "gtk" ];
    "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
  };

  xdg.portals.custom-wm-thingy.settings.preferred = {
    default = [ "wlr" ];
    "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
  };

  # tag::test[]
  build.extraPassthru.wrapperManagerTests = {
    actuallyBuilt =
      let
        wrapper = config.build.toplevel;
      in
      pkgs.runCommand "wrapper-manager-xdg-desktop-entry-actually-built" { } ''
        [ -e "${wrapper}/share/xdg-desktop-portal/com.example.WindowWaweger-portals.conf" ] \
        && [ -e "${wrapper}/share/xdg-desktop-portal/custom-wm-thingy-portals.conf" ] \
        && touch $out
      '';
  };
  # end::test[]
}
