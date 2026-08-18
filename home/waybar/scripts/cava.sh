#!/usr/bin/env bash

bars=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")

cava | while read -r line; do
    output=""

    for ((i=0; i<${#line}; i++)); do
        char="${line:i:1}"

        if [[ "$char" =~ [0-7] ]]; then
            output+=${bars[$char]}
        fi
    done

    echo "$output"
done
