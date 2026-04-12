# SPDX-FileCopyrightText: 2024-2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

{
  config,
  lib,
  pkgs,
  ...
}:

{
  wrappers.fastfetch = {
    arg0 = lib.getExe' pkgs.fastfetch "fastfetch";
    appendArgs = [
      "--logo"
      "guix"
    ];
  };

  # Testing out a simple file.
  files."share/nix/hello".text = ''
    WHOA THERE!
  '';

  # A file target with an "absolute" path.
  files."/absolute/path".text = ''
    WHAAAAAAAT!
  '';

  # Testing out source.
  files."share/nix/aloha".source = config.files."share/nix/hello".source;

  # Testing out an executable file.
  files."share/nix/example" = {
    text = "WHOA";
    mode = "0755";
  };

  # Testing out a directory.
  files."share/whoa".source = pkgs.writeTextDir "/what/is/this.txt" ''
    WHAT
  '';

  # tag::test[]
  build.extraPassthru.wrapperManagerTests = {
    actuallyBuilt =
      let
        wrapper = config.build.toplevel;
      in
      pkgs.runCommand "wrapper-manager-fastfetch-with-additional-files-actually-built" { } ''
        [ -x "${wrapper}/bin/${config.wrappers.fastfetch.executableName}" ] \
        && [ -f "${wrapper}/share/nix/hello" ] \
        && [ -f "${wrapper}/share/nix/aloha" ] \
        && [ -x "${wrapper}/share/nix/example" ] \
        && [ -d "${wrapper}/share/whoa" ] \
        && [ -f "${wrapper}/absolute/path" ] \
        && touch $out
      '';
  };
  # end::test[]
}
