# SPDX-FileCopyrightText: 2024-2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

{ config, pkgs, lib, ... }:

{
  options.wrapperManagerLibExtra = lib.mkOption {
    type = with lib.types; attrsOf anything;
    description = ''
      Set of items to be included within `wrapperManagerLib.extra` namespace.

      ::: {.note}
      It can only have an attribute set one level deep due to the chosen type
      (i.e., `attrsOf anything`). Otherwise, they could create a dedicated
      library set and put it under `_module.args.CUSTOMLIBNAME` for that
      purpose.
      :::
    '';
    default = { };
    example = lib.literalExpression ''
      {
        numBits = 943;

        mkCommonChromiumFlags = name: [
          "--data-dir"
          "''${config.xdg.configHome}/chromium-''${name}"
        ];
      }
    '';
  };

  config = {
    _module.args = {
      wrapperManagerLib =
        (import ../../lib { inherit pkgs; }) // {
          extra = config.wrapperManagerLibExtra;
        };
    };
  };
}
