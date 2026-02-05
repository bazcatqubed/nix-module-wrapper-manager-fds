# SPDX-FileCopyrightText: 2024-2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

{ pkgs, ... }:

{
  _module.args = {
    wrapperManagerLib = import ../../lib { inherit pkgs; };
  };
}
