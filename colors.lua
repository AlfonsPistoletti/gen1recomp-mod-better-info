-- Colors and Abbreviations Lookup
local Font = require("src.render.Font")
local PaletteFX = require("src.render.PaletteFX")
local paletteData = require("data.generated.palettes")

local g = love.graphics

local TYPE_ABBR_LEN = 3
local TYPE_BOX_PAD_X = 2
local TYPE_BOX_H = 8

local typeAbbreviations = {
    NORMAL = "NRM",
    FIRE = "FIR",
    WATER = "WTR",
    ELECTRIC = "ELC",
    GRASS = "GRS",
    ICE = "ICE",
    FIGHTING = "FGT",
    POISON = "PSN",
    GROUND = "GRD",
    FLYING = "FLY",
    PSYCHIC_TYPE = "PSY",
    BUG = "BUG",
    ROCK = "RCK",
    GHOST = "GHO",
    DRAGON = "DRA",
    DARK = "DRK",
    STEEL = "STL",
    FAIRY = "FAI"
 }

local moveColors_gbc = {
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
    STEEL = {91, 142, 161},
    FAIRY = {236, 144, 231}
}
local moveColors_gb = {
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

local DEFAULT_TYPE_COLOR = {170, 170, 170, 1}

local function typeAbbr(typeId)
    return typeAbbreviations[typeId]
end

-- trueColor
local function gbcColor(typeId)
    return moveColors_gbc[typeId] or DEFAULT_TYPE_COLOR
end

-- palette Colors
local function gbPaletteName(typeId)
    return moveColors_gb[typeId]
end

local function setColorFromTable(c)
    love.graphics.setColor(c[1] / 255, c[2] / 255, c[3] / 255, c[4] or 1)
end

local function pokemonPaletteName(speciesId)
    return paletteData.pokemon[speciesId]
end

local STAT_COLORS = {
    hp = {
        paletteName = "GREENMON"
    },
    attack = {
        paletteName = "YELLOWMON"
    },
    defense = {
        paletteName = "BROWNMON"
    },
    speed = {
        paletteName = "PURPLEMON"
    },
    special = {
        paletteName = "CYANMON"
    }
}

local function statPalette(stat)
    return STAT_COLORS[stat]
end

local STAT_NAMES = {
    hp = "HP",
    attack = "ATK",
    defense = "DEF",
    speed = "SPD",
    special = "SPC"
}

local function statName(stat)
    return STAT_NAMES[stat] or stat
end

local TYPE_BADGE_W, TYPE_BADGE_H, TYPE_BADGE_PAD_X, TYPE_BADGE_PAD_Y = 28, 9, 2, 1
local function drawTypeBadge(game, typeId, x, y, zoneSink)
    local abbr = typeAbbr(typeId)
    local g = love.graphics

    if game.save.options.colors == "redpp" then
        setColorFromTable(gbcColor(typeId))
        g.rectangle("fill", x, y, TYPE_BADGE_W, TYPE_BADGE_H)
        PaletteFX.markTrueColor(x, y, TYPE_BADGE_W, TYPE_BADGE_H)
    else
        g.setColor(170 / 255, 170 / 255, 170 / 255, 1)
        g.rectangle("fill", x, y, TYPE_BADGE_W, TYPE_BADGE_H)
        if zoneSink then
            local paletteName = gbPaletteName(typeId)
            if paletteName then
                table.insert(zoneSink, {
                    x = x,
                    y = y,
                    w = TYPE_BADGE_W,
                    h = TYPE_BADGE_H,
                    paletteName = paletteName
                })
            end
        end
    end

    g.setColor(0, 0, 0, 1)
    Font.draw(abbr, x + TYPE_BADGE_PAD_X, y + TYPE_BADGE_PAD_Y)
end

return {
    typeAbbr = typeAbbr,
    gbcColor = gbcColor,
    gbPaletteName = gbPaletteName,
    pokemonPaletteName = pokemonPaletteName,
    setColorFromTable = setColorFromTable,
    statPalette = statPalette,
    statName = statName,
    drawTypeBadge = drawTypeBadge,
    DEFAULT_TYPE_COLOR = DEFAULT_TYPE_COLOR,
    TYPE_BADGE_W = TYPE_BADGE_W,
    TYPE_BADGE_H = TYPE_BADGE_H
}
