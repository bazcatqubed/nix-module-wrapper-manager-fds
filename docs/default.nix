let
  sources = import ../npins;
in
{
  pkgs ? import sources.nixos-unstable { },
  extraModules ? [ ],
}:

let
  inherit (pkgs) nixosOptionsDoc lib;

  src = builtins.toString ../.;

  # Pretty much inspired from home-manager's documentation build process.
  evalDoc =
    args@{
      modules,
      includeModuleSystemOptions ? false,
      ...
    }:
    let
      options =
        (pkgs.lib.evalModules {
          modules = modules ++ [
            {
              _module.check = false;
              _module.args.pkgs = pkgs;
            }
          ];
          class = "wrapperManager";
        }).options;

      # Based from nixpkgs' and home-manager's code.
      gitHubDeclaration = user: repo: subpath: {
        url = "https://github.com/${user}/${repo}/blob/master/${subpath}";
        name = "<${repo}/${subpath}>";
      };
    in
    nixosOptionsDoc (
      {
        options =
          if includeModuleSystemOptions then options else builtins.removeAttrs options [ "_module" ];
        transformOptions =
          opt:
          opt
          // {
            declarations = map (
              decl:
              if lib.hasPrefix src (toString decl) then
                gitHubDeclaration "bazcatqubed" "nix-module-wrapper-manager-fds" (
                  lib.removePrefix "/" (lib.removePrefix src (toString decl))
                )
              else if decl == "lib/modules.nix" then
                gitHubDeclaration "NixOS" "nixpkgs" decl
              else
                decl
            ) opt.declarations;
          };
      }
      // builtins.removeAttrs args [
        "modules"
        "includeModuleSystemOptions"
      ]
    );
  releaseConfig = lib.importJSON ../release.json;

  wrapperManagerLib = (import ../. { }).lib;
  wmOptionsDoc = evalDoc {
    modules = [ ../modules/wrapper-manager ] ++ extraModules;
    includeModuleSystemOptions = true;
  };
  wmNixosDoc = evalDoc { modules = [ ../modules/env/nixos ]; };
  wmHmDoc = evalDoc { modules = [ ../modules/env/home-manager ]; };
  wmLibNixdocs =
    pkgs.runCommand "wrapper-manager-lib-nixdoc"
      {
        buildInputs = with pkgs; [ nixdoc ];
      }
      ''
        mkdir -p $out
        for nixfile in $(find ${../lib} -maxdepth 2 -name '*.nix'); do
          name=$(realpath --relative-to=${../lib} "$nixfile" | sed -E -e 's|\.nix||')
          [[ "$name" = "default" || "$(basename "$nixfile")" =~ ^[_]+ ]] && continue

          [ "$(basename $name)" = "default" ] && {
            name=$(dirname $name)
          }
          name=$(echo $name | tr '/' '.')

          filename="''${out}/''${name}.md"
          title="wrapperManagerLib.''${name}"

          nixdoc --file "$nixfile" --description "$title" --category "$name" --prefix "wrapperManagerLib" >> "$filename"
        done
      '';
in
{
  website =
    let
      buildAntoraSite = pkgs.callPackage ./build-antora-site.nix { };
      docsRootDir = "docs/website";
      docsRootModule = "${docsRootDir}/modules/ROOT";
    in
      buildAntoraSite (finalAttrs: {
        pname = "wrapper-manager-docs";
        version = "2025-05-31";
        modHash = "sha256-mhq2RmUQKMkXm+ATD3FOz/Y8IlS6ntBQiPQR63ZAg6I=";
        modRoot = "${finalAttrs.src}/docs/website";

        src = lib.cleanSourceWith {
          src = ../.;
          filter = name: type:
            let
              baseName = baseNameOf (toString name);
            in
            !(
              # Filter out editor backup / swap files.
              lib.hasSuffix "~" baseName
              || builtins.match "^\\.sw[a-z]$" baseName != null
              || builtins.match "^\\..*\\.sw[a-z]$" baseName != null

              # Filter all of the development-related thingies.
              || baseName == "node_modules"
              || baseName == ".direnv"
              || baseName == ".envrc"
              || baseName == ".github"
              ||

              # Filter out generates files.
              lib.hasSuffix ".o" baseName
              || lib.hasSuffix ".so" baseName
              ||
              # Filter out nix-build result symlinks
              (type == "symlink" && lib.hasPrefix "result" baseName)
              ||
              # Filter out sockets and other types of files we can't have in the store.
              (type == "unknown")
            );
        };
        playbookFile = "site.yml";

        nativeBuildInputs = with pkgs; [ kramdown-asciidoc ];

        preBuild = ''
          cat ${wmOptionsDoc.optionsAsciiDoc} | tee -a "${docsRootModule}/pages/wm-options.adoc" >/dev/null
          cat ${wmNixosDoc.optionsAsciiDoc} | tee -a "${docsRootModule}/pages/wm-nixos-options.adoc" >/dev/null
          cat ${wmHmDoc.optionsAsciiDoc} | tee -a "${docsRootModule}/pages/wm-hm-options.adoc" >/dev/null

          {
            echo '* Library set' | tee -a "${docsRootModule}/nav.adoc" >/dev/null
            mkdir -p "${docsRootModule}/pages/wm-lib"
            for i in ${wmLibNixdocs}/*.md; do
              name=$(basename --suffix=".md" "$i")
              kramdoc "$i" -o "${docsRootModule}/pages/wm-lib/$name.adoc" --attribute=page-toclevels=1 --auto-ids --lazy-ids && {
                echo "** xref:wm-lib/$name.adoc[]" | tee -a "${docsRootModule}/nav.adoc" >/dev/null
              }
            done

            # Make the ID attribute more explicitly defined since it is
            # interpreted as something else.
            sed -i -E 's|^\[#|[id=|' ${docsRootModule}/pages/wm-lib/*.adoc
          }
        '';

        uiBundle = pkgs.fetchurl {
          url = "https://gitlab.com/antora/antora-ui-default/-/jobs/artifacts/HEAD/raw/build/ui-bundle.zip?job=bundle-stable";
          hash = "sha256-Aw8WS8lO5ij9lzdxV8V5EHBgfSIM0j8boO9x6Dii3kw=";
        };
      });

  inherit wmOptionsDoc wmHmDoc wmNixosDoc wmLibNixdocs;

  inherit releaseConfig;
  outputs = {
    manpage =
      pkgs.runCommand "wrapper-manager-reference-manpage"
        {
          nativeBuildInputs = with pkgs; [
            nixos-render-docs
            asciidoctor-with-extensions
          ];
        }
        ''
          mkdir -p $out/share/man/man5
          asciidoctor --attribute is-wider-scoped --backend manpage \
            ${./manpages/header.adoc} --out-file header.5
          nixos-render-docs options manpage --revision ${releaseConfig.version} \
            --header ./header.5 --footer ${./manpages/footer.5} \
            ${wmOptionsDoc.optionsJSON}/share/doc/nixos/options.json \
            $out/share/man/man5/wrapper-manager-configuration.nix.5
        '';

    html =
      pkgs.runCommand "wrapper-manager-reference-html"
        {
          nativeBuildInputs = with pkgs; [
            asciidoctor-with-extensions
          ];
        }
        ''
          mkdir -p $out/share/wrapper-manager
          asciidoctor --backend html ${wmOptionsDoc.optionsAsciiDoc} --attribute toc --out-file $out/share/wrapper-manager/options-reference.html
        '';
  };
}
