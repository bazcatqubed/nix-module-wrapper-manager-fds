# SPDX-FileCopyrightText: 2024-2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

let
  sources = import ../npins;
in
{
  pkgs ? import sources.nixos-unstable { },
}:

let
  inherit (pkgs) lib;
  wrapperManagerLibTests = import ./lib { inherit pkgs; };
  configs = import ./configs { inherit pkgs; };

in
{
  data = {
    inherit configs;
    lib = wrapperManagerLibTests;
  };

  results = {
    configs =
      let
        updateTestName =
          configName: package:
          lib.mapAttrs' (
            n: v: lib.nameValuePair "${configName}-${n}" v
          ) package.config.build.toplevel.wrapperManagerTests;
      in
      lib.concatMapAttrs updateTestName configs;

    lib =
      pkgs.runCommand "wrapper-manager-fds-lib-test"
        {
          testData = builtins.toJSON wrapperManagerLibTests;
          passAsFile = [ "testData" ];
          nativeBuildInputs = with pkgs; [
            yajsv
            jq
          ];
        }
        ''
          yajsv -s "${./lib/tests.schema.json}" "$testDataPath" && touch $out || jq . "$testDataPath"
        '';
  };
}
