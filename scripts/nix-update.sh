#!/usr/bin/env bash
set -euo pipefail

cd "$HOME/nix-config"

nix flake lock --update-input nixpkgs
sudo nixos-rebuild switch --flake .#nixos-adol
