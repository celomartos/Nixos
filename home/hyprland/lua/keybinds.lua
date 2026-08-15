local terminal          = "kitty"
local menu              = "rofi -show drun"
local screenshot        = "hyprshot -m region -m active --clipboard-only"
local waybar            = "killall waybar cava|| waybar"
local cliphist          = "cliphist list | rofi -dmenu -display-columns 2 | cliphist decode | wl-copy"
local filemanager       = "thunar"
local navegador         = "firefox"
local navegador_anonimo = "firefox --private-window"
local discord            = "vesktop"
local ide                = "zeditor"




local mainMod = "SUPER"

------------------------
---- WINDOW CONTROL ----
------------------------

hl.bind(mainMod .. " + Q",     hl.dsp.window.close())
hl.bind(mainMod .. " + SPACE", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + H",     hl.dsp.window.float({ action = "toggle" }))

------------------------
---- WORKSPACES ----
------------------------

hl.bind("ALT + 1", hl.dsp.focus({ workspace = 1 }))
hl.bind("ALT + 2", hl.dsp.focus({ workspace = 2 }))
hl.bind("ALT + 3", hl.dsp.focus({ workspace = 3 }))
hl.bind("ALT + 4", hl.dsp.focus({ workspace = 4 }))
hl.bind("ALT + 5", hl.dsp.focus({ workspace = 5 }))

hl.bind(mainMod .. " + 1", hl.dsp.window.move({ workspace = 1 }))
hl.bind(mainMod .. " + 2", hl.dsp.window.move({ workspace = 2 }))
hl.bind(mainMod .. " + 3", hl.dsp.window.move({ workspace = 3 }))
hl.bind(mainMod .. " + 4", hl.dsp.window.move({ workspace = 4 }))
hl.bind(mainMod .. " + 5", hl.dsp.window.move({ workspace = 5 }))

------------------------
---- EXECUTABLES ----
------------------------

hl.bind("ALT + ESCAPE",           hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + F",        hl.dsp.exec_cmd(screenshot))
hl.bind(mainMod .. " + K",        hl.dsp.exec_cmd(waybar))
hl.bind(mainMod .. " + T",        hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + V",        hl.dsp.exec_cmd(cliphist))
hl.bind(mainMod .. " + E",        hl.dsp.exec_cmd(filemanager))
hl.bind(mainMod .. " + N",        hl.dsp.exec_cmd(navegador))
hl.bind(mainMod .. " + D",        hl.dsp.exec_cmd(discord))
hl.bind(mainMod .. " + Z",        hl.dsp.exec_cmd(ide))
hl.bind(mainMod .. " + P",        hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind("CTRL + SHIFT + N",       hl.dsp.exec_cmd(navegador_anonimo))



------------------------
---- MOUSE ----
------------------------

hl.bind(
    mainMod .. " + mouse:272",
    hl.dsp.window.drag(),
    { mouse = true }
)

hl.bind(
    mainMod .. " + mouse:273",
    hl.dsp.window.resize(),
    { mouse = true }
)

------------------------
---- MULTIMEDIA ----
------------------------

hl.bind(
    "XF86AudioNext",
    hl.dsp.exec_cmd("playerctl next"),
    { locked = true }
)

hl.bind(
    "XF86AudioPause",
    hl.dsp.exec_cmd("playerctl play-pause"),
    { locked = true }
)

hl.bind(
    "XF86AudioPlay",
    hl.dsp.exec_cmd("playerctl play-pause"),
    { locked = true }
)

hl.bind(
    "XF86AudioPrev",
    hl.dsp.exec_cmd("playerctl previous"),
    { locked = true }
)

hl.bind(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
    {
        locked = true,
        repeating = true,
    }
)

hl.bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    {
        locked = true,
        repeating = true,
    }


)
