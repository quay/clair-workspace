mrconfig := justfile_directory() / ".mrconfig"
export GOBIN := justfile_directory() / "bin"
cmds := "github.com/quay/clair/v4/cmd/clair github.com/quay/clair/v4/cmd/clairctl"

setup: && fetch
	grep -q '{{mrconfig}}' ~/.mrtrust || echo '{{mrconfig}}' >> ~/.mrtrust
	mr checkout
	mkdir -p {{GOBIN}}

fetch:
	mr -q fetch

update:
	mr -q run git reset --hard origin/main

build *REFS: fetch update && _gobuild
	#!/bin/sh
	set -e
	for arg in {{REFS}}; do
		just _checkout "$arg"
	done

_checkout $ARG:
	#!/bin/sh
	set -e
	: "${ARG:?Missing argument}"
	repo="${ARG%%:*}"
	ref="${ARG#*:}"
	git -C "${repo}" fetch --quiet --all
	printf '%s: ' "${repo}"
	git -C "${repo}" reset --hard "${ref}"

_gobuild +pkg=cmds:
	go work sync
	go build -trimpath -o {{GOBIN}} {{pkg}}

test *REFS: fetch update && _gotest
	#!/bin/sh
	set -e
	for arg in {{REFS}}; do
		just _checkout "$arg"
	done

_gotest *$pkgs:
	go test ${pkgs:-$(go list -m | sed 's,$,/...,')}
