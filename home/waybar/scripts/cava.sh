#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

bars=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
config="$script_dir/cava-waybar.conf"

cava -p "$config" | while IFS= read -r frame; do
    IFS=';' read -r -a levels <<< "$frame"
    output=""

    for level in "${levels[@]}"; do
        [[ "$level" =~ ^[0-7]$ ]] || continue
        output+="${bars[$((10#$level))]}"
    done

    if [[ -n "$output" ]]; then
        printf '%s\n' "$output"
    fi
done
