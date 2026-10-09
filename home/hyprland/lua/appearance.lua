hl.config({
	general = {
		gaps_in = 8,
		gaps_out = 25,

		border_size = 1,

		col = {
			active_border = "rgba(8a8a8aff)",
			inactive_border = "rgba(11111111)",
		},

		resize_on_border = false,
		allow_tearing = true,

		layout = "dwindle",
	},

	decoration = {
		rounding = 12,

		active_opacity = 1.0,
		inactive_opacity = 1.0,

		shadow = {
			enabled = true,
			range = 18,
			render_power = 3,
			color = "rgba(00000066)",
		},

		blur = {
			enabled = true,
			size = 1,
			passes = 2,
			ignore_opacity = false,
			vibrancy = 0.15,
		},
	},
})

--------------------
---- DWINDLE ----
--------------------

hl.config({
	dwindle = {
		preserve_split = true,
		smart_split = true,
		smart_resizing = true,
		permanent_direction_override = false,
	},
})

-------------------
---- MASTER ----
-------------------

hl.config({
	master = {
		new_status = "master",
	},
})

----------------
---- MISC ----
----------------

hl.config({
	misc = {
		force_default_wallpaper = -1,
		disable_hyprland_logo = true,
		vrr = 0,
	},

	cursor = {
		hide_on_key_press = true,
		hide_on_touch = true,
	},

	render = {
		direct_scanout = true,
	},
})

----------------------
---- ANIMATIONS ----
----------------------

hl.config({
	animations = {
		enabled = true,
	},
})
