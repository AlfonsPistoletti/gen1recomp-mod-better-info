-- src/hud_helpers.lua
-- Kleine UI-Bausteine, 1:1 aus src/ui/SummaryMenu.lua übernommen (dort als
-- lokale, nicht exportierte Funktionen deklariert -- daher hier eine eigene
-- Kopie statt eines requires).
return function(mod)
    local Font = require("src.render.Font")
    local HudTiles = require("src.render.HudTiles")

    -- home/pokemon.asm:335-345 PrintLevel: das "<LV>"-Tile, dann das Level
    -- linksbündig direkt daneben.
    local function printLevel(tx, ty, level)
        HudTiles.statusTile(0x6E, tx, ty)
        tx = tx + 8
        Font.draw(tostring(level), tx, ty)
    end

    -- DrawLineBox (status_screen.asm): senkrechte Kante rechts, Ecke,
    -- waagerechter Ausleger nach links, Halbpfeil-Ende.
    local function drawLineBox(tx, ty, b, c)
        for i = 0, b - 1 do
            HudTiles.statusTile(0x78, tx * 8, (ty + i) * 8)
        end
        HudTiles.statusTile(0x77, tx * 8, (ty + b) * 8)
        for i = 1, c do
            HudTiles.statusTile(0x76, (tx - i) * 8, (ty + b) * 8)
        end
        HudTiles.statusTile(0x6F, (tx - c - 1) * 8, (ty + b) * 8)
    end

    return { printLevel = printLevel, drawLineBox = drawLineBox }
end