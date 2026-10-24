#!/usr/bin/env bash

set -o pipefail

bars=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")
config="$(dirname -- "${BASH_SOURCE[0]}")/cava-waybar.conf"

cava -p "$config" | while IFS= read -r line; do
    output=""
    IFS=';' read -r -a levels <<< "$line"

    for level in "${levels[@]}"; do
        if [[ "$level" =~ ^[0-7]$ ]]; then
            output+="${bars[$level]}"
        fi
    done

    printf '%s\n' "$output"
done
