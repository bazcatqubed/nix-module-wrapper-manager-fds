# SPDX-FileCopyrightText: 2024-2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

let
  sources = import ./npins;
in
{
  pkgs ? import sources.nixos-unstable { },
}:

let
  docs = import ./docs { inherit pkgs; };
  docsDevshell = import ./docs/website/shell.nix { inherit pkgs; };
in
pkgs.mkShell {
  inputsFrom = [ docs.website ];

  npmDeps = pkgs.importNpmLock.buildNodeModules {
    npmRoot = ./docs/website;
    inherit (pkgs) nodejs;
  };

  packages = with pkgs; [
    importNpmLock.hooks.linkNodeModulesHook
    nodejs
    prettier
    vscode-langservers-extracted
    (vale.withStyles (
      p: with p; [
        proselint
        readability
      ]
    ))
    vale-ls
    asciidoctor-with-extensions
    reuse

    npins
    treefmt
    nixfmt
    nixdoc

    # For easy validation of the test suite.
    yajsv
    jq
  ];
}
