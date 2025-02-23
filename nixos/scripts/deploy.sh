#!/usr/bin/env bash

read REQUEST

SERVICE_NAME="$(echo "$REQUEST" | grep -E -o ' /[a-zA-Z0-9_]+ ' | tr -d '/ ')"
SERVICE_CONTENT="$(
	while read HEADER; do [ -z "$(echo "$HEADER" | tr -d '\r\n')" ] && break; done;
	head -n 1 | tr -d '\n'
)"

export PATH=$PATH:/run/current-system/sw/bin
export NIXPKGS_CONFIG=/etc/nix/nixpkgs-config.nix
export NIX_PATH=/root/.nix-defexpr/channels:nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos:nixos-config=/etc/nixos/configuration.nix:/nix/var/nix/profiles/per-user/root/channels
export NIX_PROFILES='/run/current-system/sw /nix/var/nix/profiles/default /etc/profiles/per-user/root /root/.local/state/nix/profile /nix/profile /root/.nix-profile'

if (echo -n "$SERVICE_CONTENT" >"./${SERVICE_NAME}.txt" && /run/current-system/sw/bin/nixos-rebuild switch 1>&2); then
	echo 'HTTP/1.1 200 OK'
	echo 'Connection: close'
	echo
	echo "Deployed '$SERVICE_CONTENT' to '$SERVICE_NAME' successfully"
else
	EXIT_CODE=$?
	echo 'HTTP/1.1 500 Internal Server Error'
	echo 'Connection: close'
	echo
	echo "Failed to deploy '$SERVICE_CONTENT' to '$SERVICE_NAME': exit code $EXIT_CODE"
fi
