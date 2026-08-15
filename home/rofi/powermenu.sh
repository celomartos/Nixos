#!/bin/bash

shutdown="⏻"
reboot=""

choice=$(printf "%s\n%s\n" "$shutdown" "$reboot" | rofi -dmenu \
    -format i \
    -p "Powermenu" \
    -theme-str 'window { width: 130px; }' \
    -theme-str 'listview { columns: 1; lines: 2; }' \
    -theme-str 'element-text { font: "JetBrainsMono Nerd Font 16"; }' \
    -theme-str 'window { font: "JetBrainsMono Nerd Font 16"; }' \
    -theme ~/.config/rofi/powermenu.rasi
)

[[ -z "$choice" ]] && exit 0

confirm() {
    printf "󰗼\n󰜺\n" | rofi -dmenu \
        -format i \
        -p "Tem certeza?" \
        -theme-str 'window { width: 130px; }' \
        -theme-str 'window { font: "JetBrainsMono Nerd Font 12"; }' \
        -theme-str 'listview { columns: 1; lines: 2; }' \
        -theme-str 'element-text { horizontal-align: 0.5; }' \
        -theme ~/.config/rofi/powermenu.rasi
}

case "$choice" in
    0)
        [[ "$(confirm)" == "0" ]] && systemctl poweroff
        ;;
    1)
        [[ "$(confirm)" == "0" ]] && systemctl reboot
        ;;
esac
