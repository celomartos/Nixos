package.path = package.path .. ";" .. debug.getinfo(1, "S").source:sub(2):gsub("/[^/]+$", "") .. "/lua/?.lua"

require("init")
