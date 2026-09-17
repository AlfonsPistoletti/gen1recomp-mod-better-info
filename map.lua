local GameVersion = require("src.core.GameVersion")
local Font = require("src.render.Font")
local Strings = require("src.core.Strings")
local MapView = {}

local function entryCoords(e)
    if type(e) ~= "table" then
        return nil
    end

    local c = e.coords or e
    local x = tonumber(c.x or c.col)
    local y = tonumber(c.y or c.row)

    return x, y
end

local function buildLocations(game)
    local townMap = (game.data.field or {}).townMap

    if type(townMap) ~= "table" then
        return {}, {}
    end

    if type(townMap.locations) == "table" then
        townMap = townMap.locations
    end

    local locations = {}
    local byMap = {}

    for mapId, entry in pairs(townMap) do
        local x, y = entryCoords(entry)

        if x and y then
            local loc = {
                x = x,
                y = y,
                name = entry.name or entry.label or mapId
            }

            locations[#locations + 1] = loc
            byMap[mapId] = loc
        end
    end

    return locations, byMap
end

local function loadBackground(game)
    local townMap = (game.data.field or {}).townMap or {}
    local bg = townMap.background

    if not (bg and bg.map and bg.tiles) then
        return nil
    end

    local ok, img = pcall(love.graphics.newImage, bg.tiles.path)

    if not ok then
        return nil
    end

    local quads = {}
    local iw, ih = img:getDimensions()
    local per = iw / 8

    for i = 0, per * (ih / 8) - 1 do
        quads[i] = love.graphics.newQuad((i % per) * 8, math.floor(i / per) * 8, 8, 8, iw, ih)
    end

    return {
        img = img,
        quads = quads,
        map = bg.map
    }
end

function MapView.new(game, speciesId)
    local self = setmetatable({}, {
        __index = MapView
    })

    self.game = game
    self.speciesId = speciesId

    self.bg = loadBackground(game)
    self.locations, self.byMap = buildLocations(game)

    self.nests = {}

    local nest = ((game.data.field or {}).townMap or {}).nest

    local ok, img = pcall(love.graphics.newImage, (nest and nest.path) or "townmap/nest.png")

    self.nestIcon = ok and img or nil

    -- get nest locations
    for mapId, enc in pairs(game.data.encounters or {}) do
        local found = false

        for _, group in pairs(enc) do
            for _, slot in ipairs(group.slots or {}) do
                if slot.species == speciesId then
                    found = true
                    break
                end
            end

            if found then
                break
            end
        end

        local loc = found and self.byMap[mapId]

        if loc then
            self.nests[#self.nests + 1] = loc
        end
    end

    self.blink = 0

    return self
end

function MapView:update(dt)
    self.blink = (self.blink + 1) % 50
end

function MapView:draw(x, y, scale)
    if not self.bg then
        return
    end

    scale = scale or 1

    love.graphics.push()

    love.graphics.translate(x, y)
    love.graphics.scale(scale, scale)

    for i, tile in ipairs(self.bg.map) do
        local col = (i - 1) % 20
        local row = math.floor((i - 1) / 20)

        love.graphics.draw(self.bg.img, self.bg.quads[tile], col * 8, row * 8)
    end

    -- No nests
    if #self.nests == 0 then
        Font.drawBox(1, 7, 17, 4)
        love.graphics.setColor(0, 0, 0, 1)
        Font.draw(" " .. Strings("AREA UNKNOWN"), 16, 72)
        love.graphics.setColor(1, 1, 1, 1)
    else
        -- blinking nest markers if found
        local showNest

        if GameVersion.generation() == 1 then
            showNest = self.blink < 25
        else
            showNest = self.blink % 16 < 10
        end

        if showNest then
            for _, loc in ipairs(self.nests) do
                local px = loc.x * 8 + 16
                local py = loc.y * 8 + 8

                if self.nestIcon then
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.draw(self.nestIcon, px, py)
                end
            end
        end
    end

    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.pop()
end

return MapView
