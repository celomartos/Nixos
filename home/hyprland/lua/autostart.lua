hl.on("hyprland.start", function()

    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    hl.exec_cmd("linux-wallpaperengine --screen-root HDMI-A-1 --bg 3024218050 --silent --layer background")
    hl.exec_cmd("cliphist wipe")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("waybar")
    hl.exec_cmd("mako")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("kbuildsycoca6")
    hl.exec_cmd("easyeffects --gapplication-service")

end)
