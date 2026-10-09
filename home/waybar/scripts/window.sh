#!/usr/bin/env bash

get_window() {
  class=$(hyprctl activewindow -j | jq -r '.class')

  case "$class" in
  firefox)
    echo "󰈹 Firefox"
    ;;
  kitty)
    echo " Kitty"
    ;;
  discord)
    echo "󰙯 Discord"
    ;;

  thunar)
    echo " Thunar"
    ;;

  com.github.th-ch.youtube-music)
    echo " Youtube"
    ;;

  Minecraft*)
    echo "󰍳 Minecraft"
    ;;

  brave-origin)
    echo "󰖟 Brave"
    ;;

  mpv)
    echo "󰎆 mpv"
    ;;
  "")
    echo ""
    ;;
  *)
    echo "$class"
    ;;
  esac
}

get_window

socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" |
  while read -r event; do
    case "$event" in
    activewindow\>\>*)
      get_window
      ;;
    esac
  done
