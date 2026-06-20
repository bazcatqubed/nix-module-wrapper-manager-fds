# SPDX-FileCopyrightText: 2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

{ config, lib, pkgs, ... }:

let
  cfg = config.xdg.portals;
  settingsFormat = pkgs.formats.ini {
    listToValue = builtins.concatStringsSep ";";
  };

  portalsConf = { name, ... }: {
    options.settings = lib.mkOption {
      type = settingsFormat.type;
      default = { };
      description = ''
        Portal settings of the XDG desktop session. For more information, see
        {manpage}`portals.conf(5)`.
      '';
      example = lib.literalExpression ''
        {
          preferred = {
            default = [ "gtk" ];
          };
        }
      '';
    };
  };
in
{
  options.xdg.portals = lib.mkOption {
    type = with lib.types; attrsOf (submodule portalsConf);
    description = ''
      Set of individual portals configurations to be placed on
      `$out/share/xdg-desktop-portal/$NAME-portals.conf`.
    '';
    default = { };
    example = lib.literalExpression ''
      {
        custom-wm.settings.preferred = {
          default = [ "gtk" ];
        };

        custom-mangowc.settings.preferred = {
          default = [
            "gtk"
          ];

          "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
          "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
          "org.freedesktop.impl.portal.ScreenShot" = [ "wlr" ];
          "org.freedesktop.impl.portal.Inhibit" = [ "gtk" ];
        };
      }
    '';
  };

  config = lib.mkIf (cfg != { }) {
    files =
      let
        mkPortalConf = n: v:
          lib.nameValuePair "share/xdg-desktop-portal/${n}-portals.conf" {
            source = settingsFormat.generate "xdg-portal-${n}-config" v.settings;
          };
      in
      lib.mapAttrs' mkPortalConf cfg;
  };
}
