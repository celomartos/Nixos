#!/usr/bin/env bash

set -e

sudo nixos-rebuild switch \
  --flake . \
  --impure \
  --option substituters "https://cache.nixos.org/ https://attic.xuyh0120.win/lantian" \
  --option trusted-public-keys "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
