return function(mod, hudHelpers, moveRow)
    local Font = require("src.render.Font")
    local Theme = require("src.ui.Theme")
    local HudTiles = require("src.render.HudTiles")
    local Strings = require("src.core.Strings")
    local OriginalDexEntryMenu = require("src.ui.DexEntryMenu")
    local Sound = require("src.core.Sound")
    local Sprites = require("src.pokemon.Sprites")
    local PaletteFX = require("src.render.PaletteFX")
    local Colors = require("mods.better_info.Colors")
    local MapView = require("mods.better_info.map")
    local CrystalAnim = require("mods.better_info.crystal_anim")

    local DexEntryMenu = {}
    DexEntryMenu.__index = DexEntryMenu
    DexEntryMenu.isOpaque = true

    local ARROW_ICON = hudHelpers.loadIcon("assets/icons/arrow.png")
    local HINT_INFO = hudHelpers.loadIcon("assets/icons/hint_info.png")
    local HINT_STATS = hudHelpers.loadIcon("assets/icons/hint_stats.png")
    local HINT_MOVES = hudHelpers.loadIcon("assets/icons/hint_moves.png")
    local HINT_AREA = hudHelpers.loadIcon("assets/icons/hint_area.png")


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

    function DexEntryMenu:sgbPalettes(game)
        local P = PaletteFX
        local out = {}

        -- Der komplette Screen bekommt die normale Dex-Palette.
        local base = P.pal(game.data, "BROWNMON")
        if base then
            table.insert(out, P.whole(base))
        end

        -- Danach lokale Pokémon-Paletten.
        for _, z in ipairs(self.zones or {}) do
            if z.colors then
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

    local function drawSprite(self)
        local game = self.game
        local def = self.def
        local sprite = self.sprite

        if not sprite then
            return
        end

        local iw, ih = sprite:getDimensions()

        local areaX = 6
        local areaY = 2
        local areaW = 72
        local areaH = 64

        local x = areaX + math.floor((areaW - iw) / 2)
        local y = areaY + math.floor((areaH - ih) / 2)

        love.graphics.setColor(1, 1, 1, 1)

        -- Red++ true-color sprites müssen aus der Palette raus.
        if game.save.options.colors == "redpp" and self.spriteTrueColor then
            PaletteFX.markTrueColor(x, y, iw, ih)
        else
            local monColors = PaletteFX.monPal(game.data, def.id)

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

        love.graphics.draw(sprite, x, y)
    end

    local function drawBall(game, x, y)
        love.graphics.setColor(1, 1, 1, 1)
        OriginalDexEntryMenu.tile(game, 0x72, x / 8, y / 8)
        love.graphics.setColor(0, 0, 0, 1)
    end

    local function resolveArgs(speciesOrOpts)
        if type(speciesOrOpts) == "table" then
            return speciesOrOpts.id or speciesOrOpts.species or speciesOrOpts[1],
                speciesOrOpts.forceOwned and true or false
        end

        return speciesOrOpts, false
    end

    local function buildLevelUpMoves(game, def)
        local moves = {}

        local function addMove(level, moveId)
            local moveDef = game.data.moves[moveId]

            if not moveDef then
                print("Missing move:", moveId)
                return
            end

            moves[#moves + 1] = {
                level = level,
                move = moveId,
                name = moveDef.name,
                power = moveDef.power,
                accuracy = moveDef.accuracy,
                pp = moveDef.pp,
                effect = moveDef.effect
            }
        end

        for _, moveId in ipairs(def.level1Moves or {}) do
            addMove(1, moveId)
        end

        for _, entry in ipairs(def.learnset or {}) do
            addMove(entry.level, entry.move)
        end

        return moves
    end

    local function descLines(self)
        local game = self.game
        local def = self.def
        local e = def.dexEntry or {}

        local owned = self.forceOwned or self.owned[def.id]
        local text = owned and e.text and game.data.text[e.text] or nil

        if not text then
            return nil
        end

        local lines = {}

        text = text:gsub("\f", "\n")
        text = text:gsub("\v", "\n")

        for line in (text .. "\n"):gmatch("(.-)\n") do
            if line ~= "" then
                lines[#lines + 1] = line
            end
        end

        if #lines == 0 then
            return nil
        end

        -- Punkt an das Ende des gesamten Textes
        lines[#lines] = lines[#lines] .. "."

        return lines
    end

    local BASE_STAT_MAX = 255

    local STAT_COLORS = {
        HP = {
            paletteName = "GREENMON"
        },
        ATK = {
            paletteName = "YELLOWMON"
        },
        DEF = {
            paletteName = "BROWNMON"
        },
        SPD = {
            paletteName = "PURPLEMON"
        },
        SP = {
            paletteName = "CYANMON"
        }
    }
    local function drawBaseStatBar(stat, value, x, y, barW, owned, zoneSink)
        value = value or 0

        local statName = Colors.statName(stat)
        Font.draw(("%3s"):format(statName), x, y)

        local fraction = owned and math.min(1, value / BASE_STAT_MAX) or 0
        local fillW = math.floor((barW - 2) * fraction)

        local barX = x + 26

        -- Background
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill", barX, y + 1, barW, 4)

        -- Stat bar
        if fillW > 0 then
            love.graphics.setColor(170 / 255, 170 / 255, 170 / 255, 1)
            love.graphics.rectangle("fill", barX + 1, y + 2, fillW, 2)
        end

        -- palette
        local color = Colors.statPalette(stat)
        if color and color.paletteName and zoneSink then
            table.insert(zoneSink, {
                x = barX,
                y = y + 1,
                w = barW,
                h = 4,
                paletteName = color.paletteName
            })
        end

        love.graphics.setColor(1, 1, 1, 1)

        -- Number
        if owned then
            Font.draw(("%3d"):format(value), barX + barW + 4, y)
        else
            Font.draw("?", barX + barW + 4, y)
        end
    end

    local EVO_VIEW_Y = 102
    local EVO_VIEW_H = 30
    local EVO_STEP = 20

    local EVO_HOLD = 56
    local EVO_EVERY = 5

    local function evolutionScrollOffset(self, evolutions)
        local visibleH = EVO_VIEW_H
        local contentH = #evolutions * EVO_STEP

        if contentH <= visibleH then
            return 0
        end

        local travel = contentH - visibleH

        local scroll = travel * EVO_EVERY
        local loop = EVO_HOLD + scroll + EVO_HOLD + scroll

        local t = self.counter % loop

        if t < EVO_HOLD then
            return 0

        elseif t < EVO_HOLD + scroll then
            return math.floor((t - EVO_HOLD) / EVO_EVERY)

        elseif t < EVO_HOLD + scroll + EVO_HOLD then
            return travel

        else
            return travel - math.floor((t - EVO_HOLD - scroll - EVO_HOLD) / EVO_EVERY)
        end
    end

    local function drawEvolution(self, x, y, owned)
        local evolutions = self.def.evolutions

        love.graphics.setColor(0, 0, 0, 1)

        Font.draw("EVOLUTION", x, y)
        y = y + 12

        if not evolutions or #evolutions == 0 then
            Font.draw("---", x, y)
            return
        end

        if not owned then
            Font.draw("?", x, y)
            return
        end

        local scroll = evolutionScrollOffset(self, evolutions)

        -- Sichtbarer Bereich
        local viewY = y
        local viewH = EVO_VIEW_H

        love.graphics.setScissor(x, viewY, 148, viewH)

        local drawY = y - scroll

        for _, evo in ipairs(evolutions) do

            local seen = self.seen[evo.species]

            -- Bedingung
            if evo.method == "LEVEL" then
                HudTiles.statusTile(0x6E, x, drawY)
                Font.draw(("%02d"):format(evo.level or 0), x + 8, drawY)

            elseif evo.method == "ITEM" then
                Font.draw(evo.item or "?", x, drawY)

            else
                Font.draw(evo.method or "?", x, drawY)
            end

            drawY = drawY + 8

            -- Pfeil
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(ARROW_ICON, x + 8, drawY)

            -- Ziel-Spezies
            love.graphics.setColor(0, 0, 0, 1)
            Font.draw(seen and evo.species or "?", x + 24, drawY)

            drawY = drawY + 12
        end

        love.graphics.setScissor()
    end

    local PIC_DELAY = 16
    function DexEntryMenu.new(game, speciesOrOpts, onDone)
        local species, forceOwned = resolveArgs(speciesOrOpts)

        local self = setmetatable({
            game = game,
            forceOwned = forceOwned,
            onDone = onDone
        }, DexEntryMenu)
        self.def = game.data.pokemon[species]

        local pokedex = game.save.pokedex or {}

        self.seen = pokedex.seen or {}
        self.owned = pokedex.owned or {}

        -- build level-up moves if pokemon is owned
        local owned = self.owned[species] or forceOwned

        if owned then
            self.levelUpMoves = buildLevelUpMoves(game, self.def)
        else
            self.levelUpMoves = {}
        end

        self.moveScroll = 1

        local path, trueColor = require("src.pokemon.Sprites").path(game.data, species, "front", {
            kind = "dex"
        })
        -- pcall's second return has to survive the guard (#307)
        local ok, img = false, nil
        if path then
            ok, img = pcall(love.graphics.newImage, path)
        end
        self.sprite = ok and img or nil
        self.spriteTrueColor = self.sprite and trueColor or false
        self.spriteFrames = self.sprite
            and CrystalAnim.resolveFrames(path, self.sprite) or nil
        self.spriteAnimStart = (love.timer and love.timer.getTime
            and love.timer.getTime()) or 0

        self.blink = 0
        self.tab = 1

        self.species = self.def

        self.picDelay = PIC_DELAY

        self.areaMap = MapView.new(game, self.def.id)

        local art = ((game.data.field or {}).townMap or {}).upArrow

        local okArrow, arrow = pcall(love.graphics.newImage,
            (art and art.path) or "townmap/up_arrow.png")

        self.upArrow = okArrow and arrow or nil

        return self
    end

    local INFO_X = 80
    local INFO_Y = 2

    local DESC_X = 12
    local DESC_Y = 70
    local DESC_LINE = 11
    local function drawTab1(self)
        local game = self.game
        local def = self.def
        local sprite = self.sprite
        local trueColor = self.spriteTrueColor
        local species = self.species
        local e = def.dexEntry or {}

        local owned = self.forceOwned or self.owned[def.id]

        local metric = e.heightM ~= nil
        local numbers = owned and e.heightFt

        -- species sprite
        if sprite then
            drawSprite(self)
        end

        -- species info
        love.graphics.setColor(0, 0, 0, 1)

        -- number
        HudTiles.statusTile(0x74, INFO_X, INFO_Y)
        Font.drawCode(0xF2, INFO_X + 8, INFO_Y)
        Font.draw(("%03d"):format(species.dex or 0), INFO_X + 16, INFO_Y)

        -- caught indicator
        if owned then
            drawBall(self.game, INFO_X + 44, INFO_Y - 1)
        end

        -- name
        Font.draw(species.name, INFO_X, INFO_Y + 8)

        -- types
        for i, typeId in ipairs(species.types) do
            Colors.drawTypeBadge(self.game, typeId, INFO_X + (i - 1) * 32, INFO_Y + 16, self.zones or {})
        end

        -- kind
        Font.draw(owned and e.kind or "?", INFO_X, INFO_Y + 30)

        if not metric then
            Font.draw(Strings("HT"), INFO_X, INFO_Y + 44)
            Font.draw("′", INFO_X + 40, INFO_Y + 44)
            Font.draw("″", INFO_X + 64, INFO_Y + 44)
            Font.draw(Strings("WT"), INFO_X, INFO_Y + 52)
            Font.draw(Strings("lb"), INFO_X + 64, INFO_Y + 52)
            -- engine/menus/pokedex.asm:449-450, overwritten at :518-520
            if not numbers then
                Font.draw("?", INFO_X + 32, INFO_Y + 44)
                Font.draw("??", INFO_X + 48, INFO_Y + 44)
                Font.draw("???", INFO_X + 40, INFO_Y + 52)
            end
        end

        if numbers then
            if metric then
                Font.draw((Strings("GR. %.1fm", e.heightM):gsub("(%d)%.(%d)", "%1,%2")), INFO_X, INFO_Y + 44)
                Font.draw((Strings("GEW. %.1fkg", e.weightKg or 0):gsub("(%d)%.(%d)", "%1,%2")), INFO_X, INFO_Y + 52)
            else
                Font.draw(("%2d"):format(e.heightFt), INFO_X + 24, INFO_Y + 44)
                Font.draw(("%02d"):format(e.heightIn or 0), INFO_X + 48, INFO_Y + 44)
                Font.draw(("%6.1f"):format((e.weight or 0) / 10), INFO_X + 16, INFO_Y + 52)
            end
        end

        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill", 12, 66, 148, 1)
        love.graphics.setColor(1, 1, 1, 1)

        -- description. now one block
        local lines = descLines(self)

        if lines then
            for i, line in ipairs(lines) do
                Font.draw(line, DESC_X, DESC_Y + (i - 1) * DESC_LINE)
            end
        end
    end

    local function drawTab2(self)
        local stats = self.def.baseStats
        local growth = self.def.growthRate
        if not stats then
            return
        end

        local owned = self.forceOwned or self.owned[self.def.id]

        local x = 12
        local y = 4
        local gap = 10

        Font.draw("BASE STATS", x, y)
        y = y + gap
        drawBaseStatBar("hp", stats.hp, x, y, 90, owned, self.zones)
        y = y + gap
        drawBaseStatBar("attack", stats.attack, x, y, 90, owned, self.zones)
        y = y + gap
        drawBaseStatBar("defense", stats.defense, x, y, 90, owned, self.zones)
        y = y + gap
        drawBaseStatBar("speed", stats.speed, x, y, 90, owned, self.zones)
        y = y + gap
        drawBaseStatBar("special", stats.special, x, y, 90, owned, self.zones)

        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill", 12, 66, 148, 1)
        love.graphics.setColor(1, 1, 1, 1)

        if not growth then
            return
        end

        love.graphics.setColor(0, 0, 0, 1)
        Font.draw("GROW:", x, 72)
        Font.draw(owned and growth or "?", x + 48, 72)

        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill", 12, 84, 148, 1)
        love.graphics.setColor(1, 1, 1, 1)

        drawEvolution(self, x, 90, owned)
    end

    local MOVE_TOTAL_W = 122
    local MOVE_START_X = 36
    local MOVE_LIST_Y = 16
    local MOVE_VISIBLE_ROWS = 6
    local function drawTab3(self)

        Font.draw("LEARNED MOVES", 12, 4)

        -- check if owned
        local owned = self.forceOwned or self.owned[self.def.id]

        if not owned then
            Font.draw("???", 68, 64)
            return
        end

        local moves = self.levelUpMoves or {}
        local startIndex = self.moveScroll or 1

        local maxScroll = math.max(1, #moves - MOVE_VISIBLE_ROWS + 1)

        for visibleIndex = 1, MOVE_VISIBLE_ROWS do
            local moveIndex = startIndex + visibleIndex - 1
            local entry = moves[moveIndex]

            if not entry then
                break
            end

            local y = MOVE_LIST_Y + (visibleIndex - 1) * moveRow.ROW_H

            HudTiles.statusTile(0x6E, 8, y)
            Font.draw(("%02d"):format(entry.level or 0), 16, y)
            moveRow.drawMoveRow(self.game, entry, MOVE_START_X, y, self.zones, MOVE_TOTAL_W, true)

            -- Scroll arrow: up
            if startIndex > 1 then
                -- HudTiles.statusTile(0xXX, 8, 12)
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(self.upArrow, 152, 4)
            end

            -- Scroll arrow: down
            if startIndex < maxScroll then
                Font.drawCode(Theme.moreArrow, 152, 128)
            end
        end
    end

    local function drawTab4(self)
        self.areaMap:draw(4, -8, 1)
    end

    local TAB_INDICATORS = {
        [1] = 22,
        [2] = 54,
        [3] = 86,
        [4] = 118
    }
    local function drawTabs(self)
        -- divider
        love.graphics.setColor(1, 1, 1, 1)
        for ty = 0, 17 do
            OriginalDexEntryMenu.tile(self.game, DIVIDER[ty], 0, ty)
        end

        -- bottom
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill", 4, 136, 160, 8)
        love.graphics.setColor(1, 1, 1, 1)

        local tabX = 24
        local gap = 32
        love.graphics.draw(HINT_INFO, tabX, 136)
        tabX = tabX + gap
        love.graphics.draw(HINT_STATS, tabX, 136)
        tabX = tabX + gap
        love.graphics.draw(HINT_MOVES, tabX, 136)
        tabX = tabX + gap
        love.graphics.draw(HINT_AREA, tabX, 136)

        local indicatorX = TAB_INDICATORS[self.tab]

        love.graphics.rectangle("fill", indicatorX, 139, 2, 2)
    end

    local TAB_DRAW = {drawTab1, drawTab2, drawTab3, drawTab4}
    local TAB_COUNT = #TAB_DRAW

    function DexEntryMenu:update(dt)
        if self.spriteFrames then
            self.sprite = CrystalAnim.frameForTime(self.spriteFrames,
                self.spriteAnimStart, CrystalAnim.playOnce(self.game))
        end

        -- play cry after delay
        if (self.picDelay or 0) > 0 then
            self.picDelay = self.picDelay - 1

            if self.picDelay == 0 then
                self.crySrc = Sound.playCry(self.game.data, self.def.id)
            end

            return
        end

        self.blink = ((self.blink or 0) + 1) % 60
        self.counter = (self.counter or 0) + 1

        local input = self.game.input

        if input:wasPressed("left") then
            self.tab = self.tab - 1

            if self.tab < 1 then
                self.tab = TAB_COUNT
            end

        elseif input:wasPressed("right") then
            self.tab = self.tab + 1

            if self.tab > TAB_COUNT then
                self.tab = 1
            end

        elseif input:wasPressed("start") then
            local def = self.def
            if def then
                Sound.playCry(self.game.data, def.id)
            end

        elseif input:wasPressed("b") then
            self.game.stack:pop()

            if self.onDone then
                self.onDone()
            end
        end

        -- moves tab
        if self.tab == 3 then
            if input:wasPressed("up") then
                self.moveScroll = math.max(1, self.moveScroll - 1)
            elseif input:wasPressed("down") then
                local maxScroll = math.max(1, #self.levelUpMoves - MOVE_VISIBLE_ROWS + 1)

                self.moveScroll = math.min(maxScroll, self.moveScroll + 1)
            end
        end

        -- area tab
        if self.tab == 4 and self.areaMap then
            self.areaMap:update(dt)
        end
    end

    function DexEntryMenu:draw()
        local game = self.game
        local def = self.def

        if not def then
            return
        end
        local forceOwned = self.forceOwned

        self.zones = {}

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", 0, 0, 160, 144)

        -- current tab
        local drawTab = TAB_DRAW[self.tab]
        if drawTab then
            drawTab(self)
        end

        -- which tab is active
        drawTabs(self)
    end

    mod.content.screens:override("DexEntryMenu", DexEntryMenu)
end
