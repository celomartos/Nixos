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
	match = {
		namespace = "quickshell-app-launcher",
	},
	animation = "popin 92%",
})

hl.layer_rule({
	match = { namespace = "rofi" },
	blur = true,
	ignore_alpha = 0.5,
})

-- 1. Regra da camada: aplica o zoom (popin) e o esmaecimento (fade) ao seu launcher
hl.layer_rule({
	match = {
		namespace = "quickshell-app-launcher",
	},
	-- Um popin com uma porcentagem menor (ex: 80%) cria um efeito de zoom mais perceptível
	animation = "popin 80%",
})

hl.layer_rule({
	match = {
		namespace = "quickshell-app-launcher",
	},
	blur = true,
	ignore_alpha = 0.5,
})

-- 2. (Opcional, mas recomendado) Regra separada para garantir o fade
hl.layer_rule({
	match = {
		namespace = "quickshell-app-launcher",
	},
	animation = "fade",
})

-- 3. Animação global para camadas, definindo uma curva de aceleração suave
-- A curva "easeOutQuint" é uma ótima opção para simular a desaceleração do macOS
hl.animation({
	leaf = "layersIn", -- Animação de abertura da camada
	enabled = true,
	speed = 3, -- Velocidade em decissegundos (3 = 300ms)
	bezier = "easeOutQuint", -- Curva de desaceleração suave
})

hl.animation({
	leaf = "layersOut", -- Animação de fechamento da camada
	enabled = true,
	speed = 3,
	bezier = "easeOutQuint", -- Ou uma curva de aceleração para o fechamento
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
	animation = "popin 80%",
})

hl.layer_rule({
	name = "linux-wallpaperengine-fade",
	match = {
		namespace = "^linux-wallpaperengine$",
	},
	animation = "fade",
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

--Allow Tearing in games
hl.window_rule({
	match = { class = "^steam_app_.*" },
	immediate = true,
})
