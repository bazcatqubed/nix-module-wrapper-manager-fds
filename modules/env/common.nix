# SPDX-FileCopyrightText: 2024-2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

{
  options,
  config,
  lib,
  pkgs,
  wrapperManagerLib,
  ...
}:

let
  cfg = config.wrapper-manager;

  wrapperManagerModule = lib.types.submoduleWith {
    description = "wrapper-manager configuration";
    class = "wrapperManager";
    specialArgs = cfg.extraSpecialArgs;
    modules = [
      ../wrapper-manager

      "${pkgs.path}/nixos/modules/misc/assertions.nix"
      "${pkgs.path}/nixos/modules/misc/meta.nix"

      (
        { name, lib, ... }:
        {
          config._module.args.pkgs = lib.mkDefault pkgs;
          config.build.drvName = lib.mkDefault "wrapper-manager-${name}";
        }
      )

      (
        { lib, ... }:
        {
          options.enableInstall = lib.mkOption {
            type = lib.types.bool;
            default = cfg.enableInstall;
            description = "Install the package to the wider-scoped environment.";
            example = false;
          };
        }
      )
    ]
    ++ cfg.sharedModules;
  };
in
{
  options.wrapper-manager = {
    enableInstall = lib.mkOption {
      type = lib.types.bool;
      description = ''
        Enable installing the package to the wider-scoped environment list
        of packages. This is to be set as the default value of
        {option}`enableInstall` in the wrapper-manager package environment.
      '';
      default = true;
      example = false;
    };

    sharedModules = lib.mkOption {
      type = with lib.types; listOf deferredModule;
      default = [ ];
      example = lib.literalExpression ''
        [
          {
            config.build = {
              variant = "shell";
            };
          }
        ]
      '';
      description = ''
        Extra modules to be added to all of the wrapper-manager configurations.
      '';
    };

    packages = lib.mkOption {
      type = lib.types.attrsOf wrapperManagerModule;
      description = ''
        A set of wrappers to be added into the environment configuration.
      '';
      default = { };
      visible = "shallow";
      example = lib.literalExpression ''
        {
          custom-ricing = { lib, pkgs, ... }: {
            wrappers.fastfetch = {
              arg0 = lib.getExe' pkgs.fastfetch "fastfetch";
              appendArgs = [
                "--config" ./config/fastfetch/config
                "--logo" "Guix"
              ];
              env.NO_COLOR.value = 1;
            };
          };

          music-setup = { lib, pkgs, ... }: {
            wrappers.yt-dlp-audio = {
              arg0 = lib.getExe' pkgs.yt-dlp "yt-dlp";
              prependArgs = [
                "--config-location" ./config/yt-dlp/audio.conf
              ];
            };

            wrappers.yt-dlp-video = {
              arg0 = lib.getExe' pkgs.yt-dlp "yt-dlp";
              prependArgs = [
                "--config-location" ./config/yt-dlp/video.conf
              ];
            };

            wrappers.beets-fds = {
              arg0 = lib.getExe' pkgs.beet "beet";
              prependArgs = [
                "--config" ./config/beets/config
              ];
            };
          };

          writing = { lib, pkgs, ... }: {
            wrappers.asciidoctor-fds = {
              arg = lib.getExe' pkgs.asciidoctor-with-extensions "asciidoctor";
              executableName = "asciidoctor";
              prependArgs =
                builtins.map (v: "-r ''${v}") [
                  "asciidoctor-diagram"
                  "asciidoctor-bibtex"
                ];
            };
          };
        }
      '';
    };

    extraSpecialArgs = lib.mkOption {
      type = with lib.types; attrsOf anything;
      default = { };
      description = ''
        Additional set of module arguments to be passed to `specialArgs` of
        the wrapper module evaluation.
      '';
      example = {
        yourMomName = "Joe Mama";
      };
    };

    # They're all disabled by default to let wrapper-manager not get out of the
    # way. wrapper-manager configurations are meant to be a part of other
    # environments and we're trying not to make a spotlight for wrapper-manager
    # in whatever form including exporting the documentation.
    documentation = {
      manpage.enable = lib.mkEnableOption "manpage output";
      html.enable = lib.mkEnableOption "HTML output";

      extraModules = lib.mkOption {
        type = with lib.types; listOf deferredModule;
        description = ''
          List of extra wrapper-manager modules to be included as part of the
          documentation.
        '';
        default = [ ];
        example = lib.literalExpression ''
          [
            ./modules/wrapper-manager
          ]
        '';
      };
    };
  };

  config = {
    # Bringing the library set from the wrapper-manager environment for
    # convenience. It would also allow its users for full control without using
    # the integration module itself.
    _module.args.wrapperManagerLib = import ../../lib { inherit pkgs; };

    # Since the wrapper packages are included as a native submodule instead of
    # evaluating it ourselves which imports the assertion module, the wrapper
    # configs' assertions and warnings should be properly imported into the
    # wider-scoped environment for a nicer traceback.
    warnings =
      let
        getWrapperWarnings =
          name: wrapperCfg:
          wrapperManagerLib.utils.getWarnings (options.wrapper-manager.packages.loc ++ [ name ]) wrapperCfg;
      in
      lib.concatLists (lib.mapAttrsToList getWrapperWarnings cfg.packages);

    assertions =
      let
        getWrapperAssertions =
          name: wrapperCfg:
          wrapperManagerLib.utils.getAssertions (options.wrapper-manager.packages.loc ++ [ name ]) wrapperCfg;
      in
      lib.concatLists (lib.mapAttrsToList getWrapperAssertions cfg.packages);
  };
}
