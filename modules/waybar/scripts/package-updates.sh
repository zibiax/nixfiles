#!/bin/sh
# NixOS: show how many days old the nixpkgs input in the flake lock is.
lock="$HOME/nixfiles/flake.lock"
[ -f "$lock" ] || { echo "-"; exit 0; }
modified=$(jq -r '.nodes.nixpkgs.locked.lastModified' "$lock")
days=$(( ($(date +%s) - modified) / 86400 ))
if [ "$days" -gt 0 ]; then
	echo "${days}d"
else
	echo "Up to date."
fi
