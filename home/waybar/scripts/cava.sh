#!/usr/bin/env bash

set -o pipefail

bars=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")
config="${BASH_SOURCE[0]%/*}/cava-waybar.conf"

cava -p "$config" | while IFS=';' read -r -a levels; do
    output=""

    for level in "${levels[@]}"; do
        [[ "$level" =~ ^[0-7]$ ]] || continue
        output+="${bars[level]}"
    done

    printf '%s\n' "$output"
done
