--------------------
---- BEZIER CURVES ----
--------------------

-- Abertura: rápida, com desaceleração suave
hl.curve("macEaseOut", {
	type = "bezier",
	points = {
		{ 0.18, 0.9 },
		{ 0.28, 1.0 },
	},
})

-- Fechamento: aceleração progressiva e suave
hl.curve("macEaseIn", {
	type = "bezier",
	points = {
		{ 0.7, 0.0 },
		{ 0.84, 0.0 },
	},
})

-- Transições equilibradas
hl.curve("macEaseInOut", {
	type = "bezier",
	points = {
		{ 0.45, 0.0 },
		{ 0.55, 1.0 },
	},
})

-- Spring mais responsivo, sem bounce
hl.curve("macSpring", {
	type = "spring",
	mass = 1,
	stiffness = 256,
	damping = 32,
})

--------------------
---- WINDOWS ----
--------------------

hl.animation({
	leaf = "windows",
	enabled = true,
	speed = 3.2,
	bezier = "macEaseOut",
})

hl.animation({
	leaf = "windowsIn",
	enabled = true,
	speed = 2.8,
	spring = "macSpring",
	style = "popin 92%",
})

hl.animation({
	leaf = "windowsOut",
	enabled = true,
	speed = 2.2,
	bezier = "macEaseIn",
	style = "popin 92%",
})

hl.animation({
	leaf = "windowsMove",
	enabled = true,
	speed = 3.0,
	spring = "macSpring",
	style = "slide",
})

--------------------
---- FADE ----
--------------------

hl.animation({
	leaf = "fade",
	enabled = true,
	speed = 2.7,
	bezier = "macEaseInOut",
})

hl.animation({
	leaf = "fadeIn",
	enabled = true,
	speed = 2.4,
	bezier = "macEaseOut",
})

hl.animation({
	leaf = "fadeOut",
	enabled = true,
	speed = 1.9,
	bezier = "macEaseIn",
})

--------------------
---- WORKSPACES ----
--------------------

hl.animation({
	leaf = "workspaces",
	enabled = true,
	speed = 2.8,
	spring = "macSpring",
	style = "slidefade 15%",
})

hl.animation({
	leaf = "workspacesIn",
	enabled = true,
	speed = 1.8,
	spring = "macSpring",
	style = "slidefade 15%",
})

hl.animation({
	leaf = "workspacesOut",
	enabled = true,
	speed = 1.8,
	spring = "macSpring",
	style = "slidefade 15%",
})

--------------------
---- LAYERS ----
--------------------

hl.animation({
	leaf = "layers",
	enabled = true,
	speed = 2.7,
	bezier = "macEaseOut",
	style = "popin",
})

hl.animation({
	leaf = "layersIn",
	enabled = true,
	speed = 2.5,
	spring = "macSpring",
	style = "popin",
})

hl.animation({
	leaf = "layersOut",
	enabled = true,
	speed = 2.0,
	bezier = "macEaseIn",
	style = "popin",
})

--------------------
---- FADE LAYERS ----
--------------------

hl.animation({
	leaf = "fadeLayers",
	enabled = true,
	speed = 2.7,
	bezier = "macEaseInOut",
})

hl.animation({
	leaf = "fadeLayersIn",
	enabled = true,
	speed = 2.2,
	bezier = "macEaseOut",
})

hl.animation({
	leaf = "fadeLayersOut",
	enabled = true,
	speed = 1.8,
	bezier = "macEaseIn",
})

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

-- Hyprshot: desativa animação da camada de congelamento
hl.layer_rule({
	name = "hyprshot-no-animation",
	match = {
		namespace = "^hyprpicker$",
	},
	no_anim = true,
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
