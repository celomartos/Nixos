--------------------
---- LAYER RULES ----
--------------------

-- Rofi: zoom discreto + fade
hl.layer_rule({
	match = {
		namespace = "^rofi$",
	},
	animation = "popin 92%",
})

hl.layer_rule({
	match = { namespace = "rofi" },
	blur = true,
	ignore_alpha = 0.5,
})

-- Hyprshot: desativa animação da camada de congelamento
hl.layer_rule({
	name = "hyprshot-no-animation",
	match = {
		namespace = "^hyprpicker$",
	},
	no_anim = true,
})

hl.layer_rule({
	match = { namespace = "notifications" },
	no_anim = true,
})

hl.layer_rule({
	name = "linux-wallpaperengine-fade",
	match = {
		namespace = "^linux-wallpaperengine$",
	},
	animation = "popin 92%",
})

--------------------
---- WINDOW RULES ----
--------------------

hl.window_rule({
	match = {
		class = ".*",
	},
	no_xdg_drags = true,
})

-- Satty
hl.window_rule({
	name = "satty",
	match = {
		class = "^com\\.gabm\\.satty$",
	},
	float = true,
	pin = true,
	center = true,
	no_anim = true,
})

hl.window_rule({
	name = "thunar-rename-dialog",

	match = {
		class = "^thunar$",
		initial_title = "^Rename.*$",
	},

	float = true,
	size = { 500, 180 },
})

hl.window_rule({
	name = "steam-settings-dialog",

	match = {
		class = "^steam$",
		initial_title = "^Steam Settings$",
	},

	float = true,
	center = true,
	no_blur = true,
})

hl.window_rule({
	name = "steam-game-properties",

	match = {
		class = "^steam$",
		initial_title = "negative:^(Steam|Steam Settings)$",
	},

	float = true,
	size = { 800, 650 },
	center = true,
	no_blur = true,
})

hl.window_rule({
	name = "gtk-save-dialog",

	match = {
		class = "^xdg-desktop-portal-gtk$",
		initial_title = ".* wants to save$",
	},

	float = true,
	size = { 800, 700 },
	center = true,
})

hl.window_rule({
	name = "ark-extract-dialog",

	match = {
		class = "^org[.]kde[.]ark$",
		initial_title = "^Extract — Ark$",
	},

	float = true,
	size = { 550, 550 },
	center = true,
})
