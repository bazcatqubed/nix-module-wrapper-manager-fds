# SPDX-FileCopyrightText: 2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

{ config, lib, pkgs, wrapperManagerLib, ... }:

let
  PI = 3.141592;
in
{
  wrapperManagerLibExtra = {
    numBits = 20496;

    math = {
      inherit PI;
      abs = number: if number < 0 then -(number) else number;
    };
  };

  files."share/pi-pi".text = builtins.toString wrapperManagerLib.extra.math.PI;

  files."absolute".text = builtins.toString (wrapperManagerLib.extra.math.abs (-50054));

  # tag::test[]
  build.extraPassthru.wrapperManagerTests = {
    actuallyBuilt =
      let
        wrapper = config.build.toplevel;
      in
        pkgs.runCommand "wrapper-manager-lib-extra-actually-built" { } ''
          [ -f "${wrapper}/share/pi-pi" ] \
          && [ "$(cat "${wrapper}/share/pi-pi")" = "${builtins.toString PI}" ] \
          && [ -f "${wrapper}/absolute" ] \
          && [ "$(cat "${wrapper}/absolute")" = "50054" ] \
          && touch $out
        '';

    # This shows that it can be used modularly.
    checkUsage =
      lib.optionalAttrs (
        wrapperManagerLib.extra.math.abs (-50) == 50
        && wrapperManagerLib.extra.numBits == 20496
      ) pkgs.emptyFile;
  };
  # end::test[]
}
