local M = {}

local DEFAULT_TYPE_COLOR = {170, 170, 170, 1}

-- GBC Colors
local TYPE_COLORS_GBC = {
    NORMAL = {144, 152, 162},
    FIGHTING = {206, 63, 107},
    FLYING = {143, 168, 222},
    POISON = {171, 106, 200},
    GROUND = {217, 119, 70},
    ROCK = {201, 182, 139},
    BUG = {144, 192, 44},
    GHOST = {82, 105, 173},
    FIRE = {254, 156, 85},
    WATER = {77, 144, 214},
    GRASS = {101, 188, 94},
    ELECTRIC = {244, 210, 59},
    PSYCHIC_TYPE = {249, 113, 119},
    ICE = {115, 206, 191},
    DRAGON = {9, 109, 195},
    DARK = {91, 82, 101},
    FAIRY = {236, 144, 231},
    STEEL = {91, 142, 161}
}

-- SGB Colors
local TYPE_COLORS_GB = {
    NORMAL = "GRAYMON",
    FIGHTING = "BROWNMON",
    FLYING = "GRAYMON",
    POISON = "PURPLEMON",
    GROUND = "BROWNMON",
    ROCK = "BROWNMON",
    BUG = "GREENMON",
    GHOST = "PURPLEMON",
    FIRE = "REDMON",
    WATER = "BLUEMON",
    GRASS = "GREENMON",
    ELECTRIC = "YELLOWMON",
    PSYCHIC_TYPE = "PURPLEMON",
    ICE = "CYANMON",
    DRAGON = "CYANMON",
    DARK = "PURPLEMON",
    FAIRY = "PINKMON",
    STEEL = "GRAYMON"
}

function M.colorForType(game, typeId)
    if game.save.options.colors == "redpp" then
        return TYPE_COLORS_GBC[typeId] or DEFAULT_TYPE_COLOR
    end
    return TYPE_COLORS_GB[typeId] or DEFAULT_TYPE_COLOR
end

function M.setColorFromTable(c)
    love.graphics.setColor(c[1] / 255, c[2] / 255, c[3] / 255, c[4] or 1)
end

return M
