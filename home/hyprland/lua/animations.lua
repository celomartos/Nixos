hl.curve("winIn", {
	type = "bezier",
	points = {
		{ 0.16, 1.0 },
		{ 0.3, 1.0 },
	},
})

hl.curve("winOut", {
	type = "bezier",
	points = {
		{ 0.7, 0.0 },
		{ 0.84, 0.0 },
	},
})

hl.curve("smooth", {
	type = "bezier",
	points = {
		{ 0.22, 1.0 },
		{ 0.36, 1.0 },
	},
})

hl.curve("workspace", {
	type = "bezier",
	points = {
		{ 0.12, 0.8 },
		{ 0.2, 1.0 },
	},
})

hl.curve("layerIn", {
	type = "bezier",
	points = {
		{ 0.2, 1.0 },
		{ 0.35, 1.0 },
	},
})

hl.curve("layerOut", {
	type = "bezier",
	points = {
		{ 0.55, 0.0 },
		{ 0.8, 0.0 },
	},
})

--------------------
---- ANIMATIONS ----
--------------------

hl.animation({
	leaf = "windowsIn",
	enabled = true,
	speed = 4,
	bezier = "winIn",
	style = "popin 40%",
})

hl.animation({
	leaf = "windowsOut",
	enabled = true,
	speed = 3,
	bezier = "winOut",
	style = "popin 20%",
})

hl.animation({
	leaf = "windowsMove",
	enabled = true,
	speed = 4,
	bezier = "smooth",
	style = "slide",
})

hl.animation({
	leaf = "workspacesIn",
	enabled = true,
	speed = 4,
	bezier = "workspace",
	style = "slide",
})

hl.animation({
	leaf = "workspacesOut",
	enabled = true,
	speed = 4,
	bezier = "workspace",
	style = "slide",
})

hl.animation({
	leaf = "layersIn",
	enabled = true,
	speed = 5,
	bezier = "layerIn",
	style = "slide",
})

hl.animation({
	leaf = "layersOut",
	enabled = false,
	speed = 5,
	bezier = "workspace",
	style = "slide",
})
