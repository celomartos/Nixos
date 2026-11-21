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
	stiffness = 300,
	damping = 35,
})

--------------------
---- WINDOWS ----
--------------------

hl.animation({
	leaf = "windows",
	enabled = true,
	speed = 2.5,
	bezier = "macEaseOut",
})

hl.animation({
	leaf = "windowsIn",
	enabled = true,
	speed = 1.0,
	spring = "macSpring",
	style = "popin 92%",
})

hl.animation({
	leaf = "windowsOut",
	enabled = true,
	speed = 1.5,
	bezier = "macEaseIn",
	style = "popin 94%",
})

hl.animation({
	leaf = "windowsMove",
	enabled = true,
	speed = 1.5,
	spring = "macSpring",
	style = "slide",
})

--------------------
---- FADE ----
--------------------

hl.animation({
	leaf = "fade",
	enabled = true,
	speed = 2.4,
	bezier = "macEaseInOut",
})

hl.animation({
	leaf = "fadeIn",
	enabled = true,
	speed = 2.1,
	bezier = "macEaseOut",
})

hl.animation({
	leaf = "fadeOut",
	enabled = true,
	speed = 1.7,
	bezier = "macEaseIn",
})

--------------------
---- WORKSPACES ----
--------------------

hl.animation({
	leaf = "workspaces",
	enabled = true,
	speed = 2.5,
	spring = "macSpring",
	style = "slidefade 10%",
})

hl.animation({
	leaf = "workspacesIn",
	enabled = true,
	speed = 1.6,
	spring = "macSpring",
	style = "slidefade 10%",
})

hl.animation({
	leaf = "workspacesOut",
	enabled = true,
	speed = 1.6,
	spring = "macSpring",
	style = "slidefade 10%",
})

--------------------
---- LAYERS ----
--------------------

hl.animation({
	leaf = "layers",
	enabled = true,
	speed = 2.2,
	bezier = "macEaseOut",
	style = "popin 96%",
})

hl.animation({
	leaf = "layersIn",
	enabled = true,
	speed = 1.8,
	spring = "macSpring",
	style = "popin 96%",
})

hl.animation({
	leaf = "layersOut",
	enabled = true,
	speed = 1.7,
	bezier = "macEaseIn",
	style = "popin 96%",
})

--------------------
---- FADE LAYERS ----
--------------------

hl.animation({
	leaf = "fadeLayers",
	enabled = true,
	speed = 2.2,
	bezier = "macEaseInOut",
})

hl.animation({
	leaf = "fadeLayersIn",
	enabled = true,
	speed = 2.0,
	bezier = "macEaseOut",
})

hl.animation({
	leaf = "fadeLayersOut",
	enabled = true,
	speed = 1.6,
	bezier = "macEaseIn",
})
