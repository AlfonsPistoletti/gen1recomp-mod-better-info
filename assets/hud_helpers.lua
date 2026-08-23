local Font = require("src.render.Font")
local HudTiles = require("src.render.HudTiles")

local M = {}

function M.printLevel(tx, ty, level)
    HudTiles.statusTile(0x6E, tx, ty)
    tx = tx + 8
    Font.draw(tostring(level), tx, ty)
end

function M.drawLineBox(tx, ty, b, c)
    for i = 0, b - 1 do
        HudTiles.statusTile(0x78, tx * 8, (ty + i) * 8)
    end
    HudTiles.statusTile(0x77, tx * 8, (ty + b) * 8)
    for i = 1, c do
        HudTiles.statusTile(0x76, (tx - i) * 8, (ty + b) * 8)
    end
    HudTiles.statusTile(0x6F, (tx - c - 1) * 8, (ty + b) * 8)
end

return M