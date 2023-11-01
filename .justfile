set positional-arguments
mrconfig := justfile_directory() / ".mrconfig"
export GOBIN := justfile_directory() / "bin"

_default:
	just --list

# Setup the repos. 𝟏 Run this first!
setup: && fetch
	grep -q '{{mrconfig}}' ~/.mrtrust || echo '{{mrconfig}}' >> ~/.mrtrust
	mr checkout
	mkdir -p {{GOBIN}}

# Fetch all repos' remotes.
fetch:
	mr -q fetch

# Update all repos to origin/main.
update:
	mr -q run git reset --hard origin/main

# Build the commands in ./clair/cmd/ with any specified REFS. 𝟐 Then, build the commands.
build *REFS: fetch update && gobuild
	#!/bin/sh
	set -e
	for arg in {{REFS}}; do
		just checkout "$arg"
	done

[private]
checkout $ARG:
	#!/bin/sh
	set -e
	: "${ARG:?Missing argument}"
	repo="${ARG%%:*}"
	ref="${ARG#*:}"
	git -C "${repo}" fetch --all
	printf '%s: ' "${repo}"
	git -C "${repo}" reset --hard "${ref}"

[private]
gobuild +pkg="github.com/quay/clair/v4/cmd/...":
	go work sync
	go install -trimpath {{pkg}}

# Test all modules with any specified REFS. 𝟑 Then, run all the tests.
test *REFS: fetch update && gotest
	#!/bin/sh
	set -e
	for arg in "$@"; do
		just _checkout "$arg"
	done

[private]
gotest *$pkgs:
	go test ${pkgs:-$(go list -m | sed 's,$,/...,')}

# Add a remote at URL to REPO, with the name NAME if supplied.
add-remote REPO URL *$NAME: && fetch
	@echo git -C './{{REPO}}' remote add "${NAME:-$(basename $(dirname '{{URL}}'))}" '{{URL}}'

export CLAIR_CONF := "./etc/clair/config.yaml"

# Run `clairctl` with provided arguments, building if necesarry.
[no-exit-message]
clairctl *args="help":
	test -e bin/clairctl || just build
	./bin/clairctl "$@"
