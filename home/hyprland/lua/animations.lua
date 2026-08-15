hl.curve("winIn", {
    type = "bezier",
    points = {
        {0.1, 1.0},
        {0.1, 1.0},
    },
})

hl.curve("winOut", {
    type = "bezier",
    points = {
        {0.1, 1.0},
        {0.1, 1.0},
    },
})

hl.curve("smoothOut", {
    type = "bezier",
    points = {
        {0.5, 0},
        {0.99, 0.99},
    },
})

hl.curve("layerOut", {
    type = "bezier",
    points = {
        {0.23, 1},
        {0.32, 1},
    },
})

--------------------
---- ANIMATIONS ----
--------------------

hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 5,
    bezier = "winIn",
    style = "slide",
})

hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 5,
    bezier = "smoothOut",
    style = "slide",
})

hl.animation({
    leaf = "windowsMove",
    enabled = true,
    speed = 5,
    bezier = "winIn",
    style = "slide",
})

hl.animation({
    leaf = "workspacesIn",
    enabled = true,
    speed = 5,
    bezier = "winIn",
    style = "slide",
})

hl.animation({
    leaf = "workspacesOut",
    enabled = true,
    speed = 5,
    bezier = "winOut",
    style = "slide",
})

hl.animation({
    leaf = "layersIn",
    enabled = true,
    speed = 5,
    bezier = "winIn",
    style = "slide",
})

hl.animation({
    leaf = "layersOut",
    enabled = false,
    speed = 0,
    bezier = "layerOut",
    style = "popin 50%",
})
