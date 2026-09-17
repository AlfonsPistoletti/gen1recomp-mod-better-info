return function(mod)
    local Strings = require("src.core.Strings")
    local Theme = require("src.ui.Theme")
    local Font = require("src.render.Font")
    local Sprites = require("src.pokemon.Sprites")
    local PaletteFX = require("src.render.PaletteFX")
    local PartyMenu = require("src.ui.PartyMenu")
    local DexEntryMenu = require("src.ui.DexEntryMenu")
    local HudTiles = require("src.render.HudTiles")
    local Sound = require("src.core.Sound")
    local MenuRepeat = require("src.ui.MenuRepeat")
    local Marquee = require("mods.better_info.marquee")
    local Colors = require("mods.better_info.Colors")

    local PokedexMenu = {}
    PokedexMenu.__index = PokedexMenu
    PokedexMenu.isOpaque = true

    local SHOW_INFO_BAR = true

    local COLS_MIN = 3
    local COLS_MAX = 6
    local CELL_W_MIN = 24
    local CELL_W_MAX = 24
    local CELL_H_MIN = 18
    local CELL_H_MAX = 18

    local GRID_X = 2
    local GRID_Y = 0

    local function loadIcon(relPath)
        local ok, img = pcall(love.graphics.newImage, mod.assets:path(relPath))
        return ok and img or nil
    end

    local SEEN_ICON = loadIcon("assets/icons/seen.png")
    local BALL_ICON = loadIcon("assets/icons/ball.png")
    local START_ICON = loadIcon("assets/icons/hint_start.png")
    local SELECT_ICON = loadIcon("assets/icons/hint_select.png")

    local function dividerCodes()
        local codes = {
            [0] = 0x71
        }
        for _, top in ipairs({1, 9}) do
            local code = 0x71
            for i = 0, 8 do
                codes[top + i] = code
                code = code == 0x71 and 0x70 or 0x71
            end
        end
        return codes
    end
    local DIVIDER = dividerCodes()

    local function drawBall(game, x, y)
        love.graphics.setColor(1, 1, 1, 1)
        DexEntryMenu.tile(game, 0x72, x / 8, y / 8)
        love.graphics.setColor(0, 0, 0, 1)
    end

    local function beep(self)
        if not (self.game and self.game.data) then
            return
        end
        require("src.core.Sound").play(self.game.data, "Press_AB")
    end

    local function buildSpeciesList(game, dex, dexSize)
        local byDex = {}
        for _, def in pairs(game.data.pokemon) do
            if def.dex then
                byDex[def.dex] = def
            end
        end

        -- highest seen or caught number
        local maxSeen = 0
        for n = 1, dexSize do
            local def = byDex[n]
            if def and (dex.owned[def.id] or dex.seen[def.id]) then
                maxSeen = n
            end
        end

        local species = {}
        for n = 1, maxSeen do
            local def = byDex[n]
            if def then
                species[#species + 1] = {
                    id = def.id,
                    dex = def.dex,
                    name = def.name,
                    dexEntry = def.dexEntry,
                    types = def.types
                }
            end
        end
        return species
    end

    function PokedexMenu:cols()
        return SHOW_INFO_BAR and COLS_MIN or COLS_MAX
    end

    function PokedexMenu:visibleRows()
        return math.floor(144 / CELL_H_MIN)
    end

    function PokedexMenu:cellXY(index)
        local zero = index - 1
        local cols = self:cols()
        local col = zero % cols
        local row = math.floor(zero / cols)

        local cellW = SHOW_INFO_BAR and CELL_W_MIN or CELL_W_MAX
        local cellH = CELL_H_MIN
        return GRID_X + col * cellW, GRID_Y + (row - self.scrollRow) * cellH
    end

    function PokedexMenu:syncScroll()
        local cols = self:cols()
        local rows = self:visibleRows()
        local totalRows = math.ceil(#self.items / cols)
        local curRow = math.floor((self.index - 1) / cols)

        if curRow - self.scrollRow >= rows then
            self.scrollRow = curRow - rows + 1
        end
        if curRow - self.scrollRow < 0 then
            self.scrollRow = curRow
        end
        self.scrollRow = math.max(0, math.min(self.scrollRow, math.max(0, totalRows - rows)))
    end

    function PokedexMenu:drawDexCount()
        local x = 92
        local y = 0

        -- Owned
        love.graphics.setColor(0, 0, 0, 1)
        Font.draw(Strings("OWN"), x, y)
        Font.draw(("%3s"):format(self.ownedCount), x + 36, y)

        -- Seen
        love.graphics.setColor(0, 0, 0, 1)
        Font.draw(Strings("SEEN"), x, y + 8)
        Font.draw(("%3s"):format(self.seenCount), x + 36, y + 8)
    end

    function PokedexMenu:isSeen(speciesId)
        return self.dex.seen[speciesId] == true
    end

    function PokedexMenu:isOwned(speciesId)
        return self.dex.owned[speciesId] == true
    end

    function PokedexMenu:drawSelectedSprite(species, seen)
        if not species or not seen then
            return
        end
        local mon = {
            species = species.id
        }
        local path, trueColor = Sprites.path(self.game.data, species.id, "front", {
            mon = mon,
            kind = "summary"
        })
        if not path then
            return
        end

        local image = love.graphics.newImage(path)
        local iw, ih = image:getDimensions()

        local areaX = 92
        local areaY = 20
        local areaW = 72
        local areaH = 56

        local x = areaX + math.floor((areaW - iw) / 2)
        local y = areaY + math.floor((areaH - ih) / 2)

        -- palette 
        if trueColor then
            PaletteFX.markTrueColor(x, y, iw, ih)
        else
            local monColors = PaletteFX.monPal(self.game.data, species.id)
            if monColors then
                table.insert(self.zones, {
                    colors = monColors,
                    x = x,
                    y = y,
                    w = iw,
                    h = ih
                })
            end
        end

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(image, x, y)
    end

    function PokedexMenu:sgbPalettes(game)
        local P = PaletteFX
        local out = {}

        -- base shade
        local base = P.pal(game.data, "BROWNMON")
        if base then
            table.insert(out, P.whole(base))
        end

        for _, z in ipairs(self.zones or {}) do
            if z.colors then
                -- species palette
                table.insert(out, z)
            elseif z.paletteName then
                local c = P.pal(game.data, z.paletteName)
                if c then
                    table.insert(out, {
                        colors = c,
                        x = z.x,
                        y = z.y,
                        w = z.w,
                        h = z.h
                    })
                end
            end
        end

        return out
    end

    function PokedexMenu:drawSpeciesName(species, seen)
        if not species then
            return
        end

        local speciesName = seen and species.name or "NO DATA"

        local key = seen and "name:" .. species.id or "pokedex_unknown"

        speciesName = Marquee.scroll(speciesName, 8, key)

        Font.draw(speciesName, 92, 88)
    end

    -- check if icon is trueColor
    local function iconIsTrueColor(game, species)
        local icons = game.data.icons or {}
        local def = game.data.pokemon[species]
        local entry = (icons.bySpecies and icons.bySpecies[species]) or (def and def.icon)
        if type(entry) == "table" then
            local path = tostring(entry.image or ""):lower()
            local paletteAware = path:find("icons_original", 1, true) ~= nil or path:find("icon_original", 1, true) ~=
                                     nil
            return not paletteAware
        end
        return false
    end

    function PokedexMenu:drawCell(species, index, x, y)
        love.graphics.setColor(1, 1, 1, 1)

        if self:isSeen(species.id) then
            local mon = {
                species = species.id,
                hp = 1,
                stats = {
                    hp = 1
                }
            }
            PartyMenu.drawIcon(self.game, mon, x + 8, y, index == self.index, self.counter)

            if iconIsTrueColor(self.game, species.id) then
                PaletteFX.markTrueColor(x, y, 24, 18)
            else
                local monColors = PaletteFX.monPal(self.game.data, species.id)
                if monColors then
                    table.insert(self.zones, {
                        colors = monColors,
                        x = x,
                        y = y,
                        w = 24,
                        h = 18
                    })
                end
            end
        else
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.rectangle("fill", x + 16, y + 8, 1, 1)
        end

        if self:isOwned(species.id) then
            love.graphics.draw(BALL_ICON, x + 1, y)
        end

        if index == self.index then
            Font.drawCode(Theme.cursor, x + 1, y + 6)
        end
    end

    local KIND_CHARS = 8
    local function drawKind(self, kind, x, y)
        if kind == "?" then
            Font.draw(kind, x, y)
            return
        end

        local first, second = kind:match("^(%S+)%s+(%S+)$")

        if first and second then
            Font.draw(first, x, y)
            Font.draw(second, x, y + 8)
            return
        end

        local species = self.items[self.index]
        local key = species and "kind:" .. species.id or "pokedex_kind"

        local text = Marquee.scroll(kind, KIND_CHARS, key)

        Font.draw(text, x, y)
    end

    function PokedexMenu:drawInfoBar()
        local species = self.items[self.index]
        if not species then
            return
        end

        local seen = self:isSeen(species.id)
        local owned = self:isOwned(species.id)

        self:drawDexCount()

        -- draw front sprite of selected mon
        love.graphics.setColor(1, 1, 1, 1)
        self:drawSelectedSprite(species, seen)

        -- name and number
        love.graphics.setColor(0, 0, 0, 1)
        self:drawSpeciesName(species, seen)
        HudTiles.statusTile(0x74, 92, 78)
        Font.drawCode(0xF2, 100, 78)
        Font.draw(("%03d"):format(species.dex or 0), 108, 78)

        -- caught indicator
        if owned then
            drawBall(self.game, 136, 77)
        end

        love.graphics.rectangle("fill", 92, 98, 80, 1)

        -- kind. line break if it exceeds 8 chars. prioritize full word breaks
        local e = species.dexEntry or {}
        local kind = owned and e.kind or "?"
        drawKind(self, kind, 92, 102)

        -- types
        if seen then
            for i, typeId in ipairs(species.types) do
                Colors.drawTypeBadge(self.game, typeId, 92 + (i - 1) * 32, 120, self.zones)
            end
        end

        -- bottom hints
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill", 84, 136, 80, 8)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(START_ICON, 88, 136)
        love.graphics.draw(SELECT_ICON, 128, 136)
    end

    function PokedexMenu.new(game, opts)
        opts = opts or {}
        local self = setmetatable({}, PokedexMenu)
        self.game = game
        self.onCancel = opts.onCancel -- B returns to the start menu when opened from it
        self.index = 1
        self.scrollRow = 0
        self.hold = MenuRepeat.new(MenuRepeat.GEN1_DELAY, MenuRepeat.GEN1_RATE)

        self.dex = game.save.pokedex or {
            seen = {},
            owned = {}
        }
        self.dexSize = game.data.constants.dexSize or 151
        self.items = buildSpeciesList(game, self.dex, self.dexSize)

        self.ownedCount = 0
        self.seenCount = 0

        for _, def in pairs(game.data.pokemon) do
            if def.dex then
                if self.dex.owned[def.id] then
                    self.ownedCount = self.ownedCount + 1
                    self.seenCount = self.seenCount + 1
                elseif self.dex.seen[def.id] then
                    self.seenCount = self.seenCount + 1
                end
            end
        end

        -- for animation
        self.counter = 0

        -- Sprite-Cache
        self.spriteCache = {}

        return self
    end

    local function chooseEntry(item, dexList)
        local game = dexList.game
        local Screens = require("src.ui.Screens")

        Screens.push(game, "DexEntryMenu", item)
    end
    PokedexMenu.onChoose = chooseEntry

    function PokedexMenu:update(dt)
        self.counter = self.counter + 1
        local cols = self:cols()
        local input = self.game.input

        local dir = MenuRepeat.direction(self.hold, input)

        if dir == "left" then
            self.index = math.max(1, self.index - 1)

        elseif dir == "right" then
            self.index = math.min(#self.items, self.index + 1)

        elseif dir == "up" then
            self.index = math.max(1, self.index - cols)

        elseif dir == "down" then
            self.index = math.min(#self.items, self.index + cols)

        elseif input:wasPressed("start") then
            local species = self.items[self.index]
            if species and self:isSeen(species.id) then
                Sound.playCry(self.game.data, species.id)
            end

        elseif input:wasPressed("select") then
            beep(self)
            SHOW_INFO_BAR = not SHOW_INFO_BAR

        elseif input:wasPressed("b") then
            beep(self)
            self.game.stack:pop()
            if self.onCancel then
                self.onCancel()
            end
            return

        elseif input:wasPressed("a") then
            local species = self.items[self.index]

            if species and self:isSeen(species.id) then
                beep(self)
                self.onChoose(self.items[self.index], self)
                return
            end
        end

        self:syncScroll()
    end

    function PokedexMenu:draw()
        self.zones = {}
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", 0, 0, 160, 144)

        local rows = self:visibleRows()
        local cols = self:cols()

        for i, species in ipairs(self.items) do
            local row = math.floor((i - 1) / cols)
            -- draw visible rows only
            if row >= self.scrollRow and row < self.scrollRow + rows then
                local x, y = self:cellXY(i)
                self:drawCell(species, i, x, y)
            end
        end

        -- divider
        love.graphics.setColor(1, 1, 1, 1)
        local divX = SHOW_INFO_BAR and 10 or 19
        for ty = 0, 17 do
            DexEntryMenu.tile(self.game, DIVIDER[ty], divX, ty)
        end

        if SHOW_INFO_BAR then
            self:drawInfoBar()
        end
    end

    mod.content.screens:override("PokedexMenu", PokedexMenu)
end
