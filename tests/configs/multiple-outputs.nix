{ config, lib, pkgs, ... }: {

  files."share/hello-there".text = ''
    This is just a text that should be in the typical output path.
  '';

  build.extraSetup = ''
    echo "This is just a text in configs output path." >> "$configs/hello-there"
  '';

  build.overrideAttrs = _: _: {
    outputs = [ "out" "configs" ];
  };

  # tag::test[]
  build.extraPassthru.wrapperManagerTests = {
    actuallyBuilt =
      let
        wrapper = config.build.toplevel;
      in
      pkgs.runCommand "wrapper-manager-multiple-output-actually-built" { } ''
        [ -f "${wrapper}/share/hello-there" ] && \
        [ -f "${wrapper.configs}/hello-there" ] && \
        && touch $out
      '';
  };
  # end::test[]
}
