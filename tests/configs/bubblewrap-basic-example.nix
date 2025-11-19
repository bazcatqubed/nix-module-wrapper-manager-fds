{ config, lib, pkgs, ... }:

{
  wrappers.tmux = {
    wraparound.variant = "bubblewrap";

    wraparound.bubblewrap = {
      subwrapper.arg0 = lib.getExe' pkgs.tmux "tmux";
    };
  };

  # tag::test[]
  build.extraPassthru.wrapperManagerTests = {
    actuallyBuilt = let
      wrapper = config.build.toplevel;
    in
      pkgs.runCommand "wrapper-manager-test-gnome-session-empty-actually-built-with-nothing" { } ''
        [ -x "${wrapper}/bin/tmux" ] \
        && touch $out
      '';
  };
  # end::test[]
}
