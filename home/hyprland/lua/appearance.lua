
hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 25,

        border_size = 2,

        col = {
            active_border = "rgba(ffffffff)",
            inactive_border = "rgba(11111111)",
        },

        resize_on_border = false,
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding = 14,

        active_opacity = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled = true,
            range = 22,
            render_power = 3,
            color = "rgba(00000055)",
        },

        blur = {
            enabled = true,
            size = 1,
            passes = 2,
            ignore_opacity = false,
            vibrancy = 0.17,
        },
    },
})

--------------------
---- DWINDLE ----
--------------------

hl.config({
    dwindle = {
        preserve_split = true,
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
