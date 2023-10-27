mrconfig := justfile_directory() / ".mrconfig"
export GOBIN := justfile_directory() / "bin"

setup:
	grep -q '{{mrconfig}}' ~/.mrtrust || echo '{{mrconfig}}' >> ~/.mrtrust
	mr checkout
	mr fetch

build *REFS: && (_gobuild "github.com/quay/clair/v4/cmd/clair" "github.com/quay/clair/v4/cmd/clairctl")
	#!/bin/sh
	set -e
	for arg in {{REFS}}; do
		repo="${arg%%:*}"
		ref="${arg#*:}"
		git -C "${repo}" fetch --quiet --all
		printf '%s: ' "${repo}"
		git -C "${repo}" reset --hard "${ref}"
	done

_gobuild +pkg:
	go work sync
	go build -trimpath -o {{GOBIN}} {{pkg}}
