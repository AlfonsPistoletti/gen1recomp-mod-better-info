local Font = require("src.render.Font")
local PaletteFX = require("src.render.PaletteFX")
local Colors = require("colors")

local M = {}


local typeAbbreviations = loadDataFile("assets/type_abbreviations.lua")
local DEFAULT_TYPE_COLOR = {170, 170, 170, 1}

local NAME_MAX_CHARS = 12
local TYPE_ABBR_LEN = 3
local NAME_TYPE_GAP = 6
local TYPE_BOX_PAD_X = 2
local TYPE_BOX_H = 9
local ICON_W = 8
local VALUE_W = 3 * 8
local COL_GAP = 16
local ROW_H = 19
local NAME_H = 8

local function truncateName(name)
    if #name > NAME_MAX_CHARS then
        return name:sub(1, NAME_MAX_CHARS - 1) .. "."
    end
    return name
end

local function typeAbbr(typeId)
    return typeAbbreviations[typeId]
end

local function getMovePower(move)
    if move.power == 0 then
        return " ー "
    end
    if move.effect == "OHKO_EFFECT" then
        return "KO"
    end
    if move.effect == "SPECIAL_DAMAGE_EFFECT" then
        return "?"
    end
    return move.power
end

function M.drawMoveRow(game, entry, textX, y, powerIcon, accuracyIcon, zoneSink)
    local g = love.graphics
    local powerIconW = powerIcon and powerIcon:getWidth() or ICON_W
    local accIconW = accuracyIcon and accuracyIcon:getWidth() or ICON_W
    local col1 = textX
    local col2 = col1 + powerIconW + 2
    local col3 = col2 + VALUE_W + COL_GAP
    local col4 = col3 + accIconW + 2
    local col5 = col4 + VALUE_W + COL_GAP
    local nameColW = NAME_MAX_CHARS * 8
    local typeBoxX = textX + nameColW + NAME_TYPE_GAP

    Font.draw(truncateName(entry.name), textX, y)

    local mdef = game.data.moves[entry.move]
    if mdef and mdef.type then
        local abbr = typeAbbr(mdef.type)
        local boxW = TYPE_ABBR_LEN * 8 + TYPE_BOX_PAD_X * 2
        local boxY = y - 1

        if game.save.options.colors == "redpp" then
            Colors.setColorFromTable(Colors.colorForType(game, mdef.type))
            g.rectangle("fill", typeBoxX, boxY, boxW, TYPE_BOX_H)
            PaletteFX.markTrueColor(typeBoxX, boxY, boxW, TYPE_BOX_H)
        else
            g.setColor(0.33, 0.33, 0.33, 1)
            g.rectangle("fill", typeBoxX, boxY, boxW, TYPE_BOX_H)
            if zoneSink then
                table.insert(zoneSink, {
                    x = typeBoxX,
                    y = boxY,
                    w = boxW,
                    h = TYPE_BOX_H,
                    paletteName = Colors.colorForType(game, mdef.type)
                })
            end
        end

        g.setColor(0, 0, 0, 1)
        Font.draw(abbr, typeBoxX + TYPE_BOX_PAD_X, y)
    end

    g.setColor(1, 1, 1, 1)
    if powerIcon then
        g.draw(powerIcon, col1, y + NAME_H)
        PaletteFX.markTrueColor(col1, y + NAME_H, ICON_W, ICON_W)
    end
    Font.draw(("%3s"):format(getMovePower(entry)), col2, y + NAME_H)

    if accuracyIcon then
        g.draw(accuracyIcon, col3, y + NAME_H)
        PaletteFX.markTrueColor(col3, y + NAME_H, ICON_W, ICON_W)
    end
    Font.draw(("%3d"):format(entry.accuracy), col4, y + NAME_H)
    Font.draw(("PP%2d"):format(entry.pp), col5, y + NAME_H)
end

return M
