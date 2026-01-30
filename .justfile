set positional-arguments
mrconfig := justfile_directory() / ".mrconfig"
export GOBIN := justfile_directory() / "bin"

_default:
	just --list

# Patch setup. 𝟎 If you want to use the patch.
patch-setup:
	patch -p1 < mrconfig.patch

# Setup the repos. 𝟏 Run this first (unless you want the patch - run that first, then this)!
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

export CLAIR_CONF := "./etc/clair/config.json"

# Run `clairctl` with provided arguments, building if necesarry.
[no-exit-message]
clairctl *args="help":
	test -e bin/clairctl || just build
	./bin/clairctl "$@"

# Install systemd user units for Clair and a database.
[private]
systemd-install:
	#!/usr/bin/zsh
	set -euo pipefail
	test -e =podman
	test -e =systemctl
	: "${XDG_CONFIG_HOME:=${HOME}/.config}"
	c={{justfile_directory()}}/etc/containers
	ct=${XDG_CONFIG_HOME}/containers/systemd
	s={{justfile_directory()}}/etc/systemd
	mkdir -p ${XDG_CONFIG_HOME}/{clair,containers/systemd}
	print "WORKSPACE={{justfile_directory()}}" >"${XDG_CONFIG_HOME}/clair/env"
	for l in ${ct}/clair-postgresql.{volume,container}; [[ -h $l ]] && rm $l
	ln -s ${c}/clair-postgresql.{volume,container} ${ct}
	for u in ${s}/clair@.service ${s}/clair-postgresql-proxy.{socket,service}; systemctl --user link $u
	systemctl --user daemon-reload

# Uninstall systemd user units.
[private]
systemd-uninstall:
	#!/usr/bin/zsh
	set -euo pipefail
	test -e =podman
	test -e =systemctl
	: "${XDG_CONFIG_HOME:=${HOME}/.config}"
	ct=${XDG_CONFIG_HOME}/containers/systemd
	for l in ${ct}/clair-postgresql.{volume,container}; [[ -h $l ]] && rm $l
	systemctl --user stop 'clair@*.service' ||:
	for u in clair@.service clair-postgresql-proxy.{socket,service}; systemctl --user disable $u
	for u in clair-postgresql-proxy.{socket,service}; systemctl --user stop $u ||:
	systemctl --user stop clair-postgresql.service &>/dev/null ||:
	systemctl --user daemon-reload

# Install and start systemd user unit.
systemctl-start *$instance="combo": systemd-install gobuild
	systemctl --user enable --now clair-postgresql-proxy.socket
	systemctl --user start clair@${instance}.service

# Stop systemd user unit.
systemctl-stop *$instance="combo":
	systemctl --user stop clair@${instance}.service

# Do miscellaneous cleanup.
clean: systemd-uninstall
	rm -rf {{justfile_directory()}}/bin/*
