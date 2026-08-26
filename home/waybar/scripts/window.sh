#!/bin/sh

class=$(hyprctl activewindow -j | jq -r '.class')

case "$class" in
firefox)
  echo "󰈹 Firefox"
  ;;
kitty)
  echo "󰆍 Kitty"
  ;;
vesktop)
  echo "󰙯 Vesktop"
  ;;
mpv)
  echo "󰎆 mpv"
  ;;
*)
  echo "$class"
  ;;
esac
