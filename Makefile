.PHONY: docs-serve
docs-serve:
	inotifywait --monitor --event modify --recursive docs/website --exclude "node_modules" | while read -r path action file; do antora generate site.yml; done

.PHONY: docs-build
docs-build:
	antora generate site.yml

.PHONY: build
build:
	{ command -v nix >/dev/null && nix build -f docs/ website; } || { nix-build docs/ -A website; }

.PHONY: check
check:
	{ command -v nix > /dev/null && nix flake check; } || { nix-build tests -A configs -A lib; }

# Ideally, this should be done only in the remote CI environment with a certain
# update cadence/rhythm.
.PHONY: update
update:
	npins update

# Ideally this should be done before committing.
.PHONY: format
format:
	treefmt
