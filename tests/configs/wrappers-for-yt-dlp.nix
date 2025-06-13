{ config, lib, pkgs, ... }:

{
  wrappers.yt-dlp-audio = {
    arg0 = lib.getExe' pkgs.yt-dlp "yt-dlp";
    prependArgs = [
      "--no-overwrite"
      "--extract-audio"
      "--format" "bestaudio"
      "--audio-format" "opus"
      "--output" "'%(album_artists.0,artists.0)s/%(album,playlist)s/%(track_number,playlist_index)d-%(track,title)s.%(ext)s'"
      "--download-archive" "archive"
      "--embed-thumbnail"
      "--add-metadata"
    ];
  };

  # You could also lessen the code above by passing `--config-location` to
  # yt-dlp and move them into a separate file. This is what wrapper-manager is
  # made for, after all.
  wrappers.yt-dlp-video = {
    arg0 = lib.getExe' pkgs.yt-dlp "yt-dlp";
    prependArgs = [
      "--config-location" (builtins.toString pkgs.emptyFile)
    ];
  };

  # tag::test[]
  build.extraPassthru.wrapperManagerTests = {
    actuallyBuilt = let
      wrapper = config.build.toplevel;
    in
      pkgs.runCommand "wrapper-manager-test-wrappers-for-yt-dlp-actually-built" { } ''
        [ -x "${wrapper}/bin/yt-dlp-audio" ] \
        && [ -x "${wrapper}/bin/yt-dlp-video" ] \
        && [ ! -x "${wrapper}/bin/yt-dlp" ] \
        && [ ! -d "${wrapper}/share" ] \
        && touch $out
      '';
  };
  # end::test[]
}
