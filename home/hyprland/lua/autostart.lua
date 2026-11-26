hl.on("hyprland.start", function()
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

	hl.exec_cmd("cliphist wipe")
	hl.exec_cmd("systemctl --user start hyprpolkitagent")
	hl.exec_cmd("quickshell")
	-- hl.exec_cmd("waybar") -- Fallback Waybar
	hl.exec_cmd("mako")
	hl.exec_cmd(
		"wl-paste --type text --watch sh -c 'cliphist store && (qs ipc call clipboard refresh >/dev/null 2>&1 || true)'"
	)
	hl.exec_cmd(
		"wl-paste --type image --watch sh -c 'cliphist store && (qs ipc call clipboard refresh >/dev/null 2>&1 || true)'"
	)
	hl.exec_cmd("kbuildsycoca6")
	hl.exec_cmd("easyeffects --gapplication-service")
	--hl.exec_cmd("waypaper --restore")
	hl.exec_cmd(
		"linux-wallpaperengine --screen-root HDMI-A-1 --bg 3207947548 --scaling fill --layer background --fullscreen-pause-only-active --silent  --fps 30"
	)
end)
