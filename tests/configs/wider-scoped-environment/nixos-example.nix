{ lib, config, ... }:

{
  wrapper-manager.packages.writing.imports = [
    ./other-wrapper-manager-modules
  ];

  wrapper-manager.packages.music-setup = {
    wrappers.beets = {
      arg0 = lib.getExe' pkgs.beets "beet";
      prependArgs = [ "--config" ./config/beets/config.yml ];
    };
  };

  wrapper-manager.packages.archive-setup = { lib, pkgs, ... }: {
    wrappers.gallery-dl = {
      arg0 = lib.getExe' pkgs.gallery-dl "gallery-dl";
      prependArgs = [ ];
    };

    wrappers.yt-dlp-audio = {
      arg0 = lib.getExe' pkgs.yt-dlp "yt-dlp";
      prependArgs = [
        "--config-location" ./configs/yt-dlp/audio.conf
      ];
    };
  };
}
