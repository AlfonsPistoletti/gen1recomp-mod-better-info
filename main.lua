-- mods/move_relearner/main.lua
return function(mod)

    mod.options:define({{
        key = "show_extended_tab",
        type = "toggle",
        label = "ADDIT. INFO",
        default = false
    }})

    local Screens = require("src.ui.Screens")
    local Font = require("src.render.Font")
    local MoveLearnMenu = require("src.ui.MoveLearnMenu")
    local TextBox = require("src.render.TextBox")
    local PaletteFX = require("src.render.PaletteFX")
    local Stats = require("src.pokemon.Stats")
    local Status = require("src.battle.Status")
    local Sprites = require("src.pokemon.Sprites")
    local TypeChart = require("src.battle.TypeChart")
    local Strings = require("src.core.Strings")

    -- LOAD ICONS
    local function loadIcon(relPath)
        local ok, img = pcall(love.graphics.newImage, mod.assets:path(relPath))
        return ok and img or nil
    end

    local POWER_ICON = loadIcon("assets/icons/power.png")
    local ACCURACY_ICON = loadIcon("assets/icons/accuracy.png")

    -- Move UI
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

    local function loadDataFile(relPath)
        local text = mod:read(relPath)
        local chunk = assert(load(text, "@" .. relPath))
        return chunk()
    end

    local typeAbbreviations = loadDataFile("assets/type_abbreviations.lua")
    local moveColors_gbc = loadDataFile("legacy/move_colors_gbc.lua")
    local moveColors_gb = loadDataFile("legacy/move_colors_gb.lua")
    local DEFAULT_TYPE_COLOR = {170, 170, 170, 1}

    local function typeAbbr(typeId)
        return typeAbbreviations[typeId]
    end

    local function colorForType(game, typeId)
        if game.save.options.colors == "redpp" then
            return moveColors_gbc[typeId] or DEFAULT_TYPE_COLOR
        end

        local function colorForType(game, typeId)
            if game.save.options.colors == "redpp" then
                return moveColors_gbc[typeId] or DEFAULT_TYPE_COLOR
            end
            return moveColors_gb[typeId] or DEFAULT_TYPE_COLOR
        end

        return DEFAULT_TYPE_COLOR
    end

    local function setColorFromTable(c)
        love.graphics.setColor(c[1] / 255, c[2] / 255, c[3] / 255, c[4] or 1)
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

    -- Modul-Ebene, ergänzt um einen optionalen zoneSink-Parameter
    local function drawMoveRow(game, entry, textX, y, powerIcon, accuracyIcon, zoneSink)
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
                -- redpp: fertige RGB-Werte, Shader komplett umgehen
                setColorFromTable(moveColors_gbc[mdef.type] or DEFAULT_TYPE_COLOR)
                g.rectangle("fill", typeBoxX, boxY, boxW, TYPE_BOX_H)
                PaletteFX.markTrueColor(typeBoxX, boxY, boxW, TYPE_BOX_H)
            else
                -- SGB/OG/etc.: neutrales Grau zeichnen, das zuverlässig in
                -- colors[3] (den kräftigen Ton) gebucketed wird; die eigentliche
                -- Farbe kommt später aus der Zone in sgbPalettes
                g.setColor(0.33, 0.33, 0.33, 1)
                g.rectangle("fill", typeBoxX, boxY, boxW, TYPE_BOX_H)
                if zoneSink then
                    local paletteName = moveColors_gb[mdef.type]
                    table.insert(zoneSink, {
                        x = typeBoxX,
                        y = boxY,
                        w = boxW,
                        h = TYPE_BOX_H,
                        paletteName = paletteName
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

    -- Lernset bis zum aktuellen Level, level1Moves inklusive, TM/HM-Liste
    -- wird bewusst NICHT angefasst, bereits gelernte Moves werden ausgeschlossen
    local function buildRelearnable(data, mon)
        local def = data.pokemon[mon.species]
        if not def then
            return {}
        end

        local known = {}
        for _, mv in ipairs(mon.moves) do
            known[mv.id] = true
        end

        local out = {}
        local function add(moveId)
            if known[moveId] then
                return
            end
            known[moveId] = true
            local mdef = data.moves[moveId]
            table.insert(out, {
                move = moveId,
                name = mdef and mdef.name or moveId,
                power = mdef and mdef.power or 0,
                accuracy = mdef and mdef.accuracy or 0,
                pp = mdef and mdef.pp or 0,
                effect = mdef and mdef.effect or ""
            })
        end

        for _, id in ipairs(def.level1Moves or {}) do
            add(id)
        end
        for _, entry in ipairs(def.learnset or {}) do
            if entry.level <= mon.level then
                add(entry.move)
            end
        end

        return out
    end

    local function printLevel(tx, ty, level)
        local HudTiles = require("src.render.HudTiles")
        HudTiles.statusTile(0x6E, tx, ty)
        tx = tx + 8
        Font.draw(tostring(level), tx, ty)
    end

    local function drawLineBox(tx, ty, b, c)
        local HudTiles = require("src.render.HudTiles")
        -- Under the status screen's overlay the vertical is $78 -- DrawLineBox
        -- writes `ld [hl], $78` (status_screen.asm:222), and :90-93 is what puts
        -- hud_2's single bar tile there.  $73 is the <ID> glyph on this screen,
        -- not a line, so the whole box has to come off statusTile (#280).  The
        -- drawn shapes are unchanged: hud_2 tile 0 is the same bar the battle
        -- layout parks at $73.
        for i = 0, b - 1 do
            HudTiles.statusTile(0x78, tx * 8, (ty + i) * 8)
        end
        HudTiles.statusTile(0x77, tx * 8, (ty + b) * 8)
        for i = 1, c do
            HudTiles.statusTile(0x76, (tx - i) * 8, (ty + b) * 8)
        end
        HudTiles.statusTile(0x6F, (tx - c - 1) * 8, (ty + b) * 8)
    end

    mod.content.screens:register("MoveRelearn", {
        new = function(game, mon)
            local self = {
                game = game,
                isOpaque = true
            }
            local list = buildRelearnable(game.data, mon)
            local index = 1
            local scroll = 0
            local CURSOR = 0xED

            -- LOAD ICONS
            if not self.powerIcon then
                local ok, img = pcall(love.graphics.newImage, mod.assets:path("assets/icons/power.png"))
                self.powerIcon = ok and img or nil
            end
            if not self.accuracyIcon then
                local ok, img = pcall(love.graphics.newImage, mod.assets:path("assets/icons/accuracy.png"))
                self.accuracyIcon = ok and img or nil
            end

            -- LAYOUT
            local ROWS = 5
            local startY = 8
            local textX = 16

            function self:update(dt)
                local input = game.input
                local n = #list + 1

                if #list == 0 then
                    if input:wasPressed("a") or input:wasPressed("b") then
                        game.stack:pop()
                    end
                    return
                end

                if input:wasPressed("up") then
                    index = index > 1 and index - 1 or n
                elseif input:wasPressed("down") then
                    index = index < n and index + 1 or 1
                elseif input:wasPressed("b") then
                    game.stack:pop()
                elseif input:wasPressed("a") then
                    if index > #list then
                        game.stack:pop()
                        return
                    end

                    local entry = list[index]
                    game.stack:pop()

                    if #mon.moves < 4 then
                        local mdef = game.data.moves[entry.move]
                        table.insert(mon.moves, {
                            id = entry.move,
                            pp = mdef and mdef.pp or 0
                        })
                        game.stack:push(TextBox.new(game, (mon.nickname or game.data.pokemon[mon.species].name) ..
                            " learned\n" .. entry.name .. "!"))
                    else
                        game.stack:push(MoveLearnMenu.new(game, mon, entry.move))
                    end
                    return
                end

                if index <= #list then
                    if index < scroll + 1 then
                        scroll = index - 1
                    end
                    if index > scroll + ROWS then
                        scroll = index - ROWS
                    end
                else
                    if #list > ROWS then
                        scroll = #list - ROWS
                    end
                end
            end

            function self:draw()
                self.typeZones = {}
                local g = love.graphics

                Font.drawBox(0, 14, 20, 4)
                Font.draw("RELEARN A MOVE", 8, 124)

                local last = math.min(#list, scroll + ROWS)
                for i = scroll + 1, last do
                    local e = list[i]
                    local row = i - scroll
                    local y = startY + (row - 1) * ROW_H
                    drawMoveRow(game, e, textX, y, POWER_ICON, ACCURACY_ICON, self.typeZones)
                end

                local visibleCount = last - scroll
                local cancelY = startY + visibleCount * ROW_H
                Font.draw("CANCEL", textX, cancelY)

                local cursorY
                if index > #list then
                    cursorY = cancelY
                else
                    cursorY = startY + (index - scroll - 1) * ROW_H
                end
                Font.drawCode(CURSOR, textX - 8, cursorY)

                if #list > ROWS and scroll + ROWS < #list then
                    Font.draw("v", 176, startY + ROWS * ROW_H - 4)
                end
            end

            return self
        end
    })

    mod.content.map_scripts:register("CELADON_MANSION_2F", {
        talk = {
            TEXT_MOVE_RELEARNER_GIVER = {{"show_text", "Did your <PK><MN>\nforget a move?"},
                                         {"show_text", "I can help them\nremember!"}, {"push_screen", "PartyMenu", {
                pickOnly = true,
                onSwitch = function(mon, partyMenuState)
                    local game = partyMenuState.game
                    local relearnable = buildRelearnable(game.data, mon)

                    if #relearnable == 0 then
                        local TextBox = require("src.render.TextBox")
                        local name = mon.nickname or game.data.pokemon[mon.species].name
                        game.stack:push(TextBox.new(game, "Your " .. name .. "\ndoesn't have moves\nto relearn."))
                    else
                        Screens.push(game, "MoveRelearn", mon)
                    end
                end
            }}}
        }
    })
    -- Celadon Mansion 1f x3 y5
    mod.content.maps:patch("CELADON_MANSION_2F", {
        objects = {
            __append = {{
                index = 210,
                x = 3,
                y = 5,
                sprite = "SPRITE_SCIENTIST",
                movement = "WALK",
                range = "ANY_DIR",
                text = "TEXT_MOVE_RELEARNER_GIVER"
            }}
        }
    })

    -- SUMMARY MENU
    mod.content.screens:override("SummaryMenu", {
        new = function(game, mon)
            local Font = mod.ui.Font
            local Sprites = require("src.pokemon.Sprites")
            local HudTiles = require("src.render.HudTiles")
            local self = {
                game = game,
                mon = mon,
                isOpaque = true
            }

            function self:sgbPalettes(game)
                local P = require("src.render.PaletteFX")
                local mon = self.mon
                if not mon then
                    return P.wholeNamed(game.data, "MEWMON")
                end
                local bar = P.pal(game.data, P.barPalName(mon.hp, mon.stats.hp))
                if not bar then
                    return nil
                end
                local zones = {P.whole(bar), P.zone(P.monPal(game.data, mon.species), 0, 0, 7, 7)}
                for _, z in ipairs(self.typeZones or {}) do
                    local colors = P.pal(game.data, z.paletteName)
                    if colors then
                        table.insert(zones, {
                            colors = colors,
                            x = z.x,
                            y = z.y,
                            w = z.w,
                            h = z.h
                        })
                    end
                end
                return zones
            end

            -- Load Sprite once
            local path, trueColor = Sprites.path(game.data, mon.species, "front", {
                mon = mon,
                kind = "summary"
            })
            if path then
                local ok, img = pcall(love.graphics.newImage, path)
                self.sprite = ok and img or nil
            end
            self.spriteTrueColor = self.sprite and trueColor or false

            -- CRY
            require("src.core.Sound").playCry(game.data, mon.species)

            local function getPokemonName(game, mon)
                local species = game.data.pokemon[mon.species]
                return mon.nickname or species.name
            end

            local function drawHeader(game, mon)
                local species = game.data.pokemon[mon.species]
                Font.draw(getPokemonName(game, mon), 72, 12)

                HudTiles.statusTile(0x74, 72, 2)
                Font.drawCode(0xF2, 80, 2) -- <DOT> (charmap.asm:182)
                Font.draw(("%03d"):format(species.dex or 0), 88, 2)
                printLevel(120, 2, mon.level)

                -- Draw Sprite from Cache
                if self.sprite then
                    local pw, ph = self.sprite:getDimensions()
                    local py = math.max(0, 56 - ph)
                    love.graphics.draw(self.sprite, 4 + pw, 1 + py, 0, -1, 1)
                    if self.spriteTrueColor then
                        require("src.render.PaletteFX").markTrueColor(4, 1 + py, pw, ph)
                    end
                end

                drawLineBox(19, 0, 5, 8)

                local PaletteFX = require("src.render.PaletteFX")
                local barZoned = PaletteFX.shader() ~= nil and PaletteFX.pal(game.data, "GREENBAR") ~= nil
                HudTiles.drawHPBar(game.data, 11, 3, mon, 1, barZoned) -- wHPBarType 1
                Font.draw(("%3d/%3d"):format(mon.hp, mon.stats.hp), 96, 32)
            end

            local function moveToEntry(data, mv)
                local mdef = data.moves[mv.id]
                return {
                    move = mv.id,
                    name = mdef and mdef.name or mv.id,
                    power = mdef and mdef.power or 0,
                    accuracy = mdef and mdef.accuracy or 0,
                    pp = mv.pp,
                    effect = mdef and mdef.effect or ""
                }
            end

            -- Der tatsächliche spielmechanische Bonus aus Stat-Exp (EVs), konvergiert
            -- gegen 64 bei statExp = 65535 (√65535/4 ≈ 63.9998)
            local function statExpBonus(statExp)
                return math.sqrt(statExp or 0) / 4
            end

            local STAT_EXP_BONUS_MAX = 64
            local STAT_EXP_MAX = 65535

            local function drawStatExpBar(label, statExp, x, y, barW)
                Font.draw(("%3s"):format(label), x, y)

                local bonus = statExpBonus(statExp)
                local fraction = math.min(1, bonus / STAT_EXP_BONUS_MAX)
                -- set to 1 because of rounding
                if (statExp or 0) >= STAT_EXP_MAX then
                    fraction = 1
                end

                local barX = x + 26
                love.graphics.setColor(0, 0, 0, 1)
                love.graphics.rectangle("fill", barX, y + 1, barW, 4)
                love.graphics.setColor(0.8, 0.5, 1, 1)
                love.graphics.rectangle("fill", barX + 1, y + 2, math.floor((barW - 2) * fraction), 2)
                love.graphics.setColor(1, 1, 1, 1)

                Font.draw(tostring(statExp or 0), barX + barW + 4, y)
            end

            -- Tab 1: STATUS, TYPES, OT, EXP
            local function drawTabStatus(game, mon)
                local data = game.data
                local def = data.pokemon[mon.species]

                -- LEFT
                Font.drawBox(0, 8, 10, 10)

                local startX = 8
                local y = 72
                local lineH = 8
                local gap = 8

                -- Block 1: STATUS
                Font.draw(Strings("STATUS/"), startX, y)
                y = y + lineH
                Font.draw(Status.hudLabelFor(data.statuses, mon.status) or "OK", startX, y)
                y = y + lineH + gap

                -- Block 2: TYPE1
                Font.draw(Strings("TYPE1/"), startX, y)
                y = y + lineH
                Font.draw(def.types[1] and TypeChart.displayName(def.types[1]) or "", startX, y)
                y = y + lineH + gap

                -- Block 3: TYPE2
                if def.types[2] then
                    Font.draw(Strings("TYPE2/"), startX, y)
                    y = y + lineH
                    Font.draw(TypeChart.displayName(def.types[2]), startX, y)
                    y = y + lineH + gap
                end

                -- RIGHT
                startX = 88
                y = 72
                Font.draw(Strings("EXP PTS."), startX, y)
                y = y + lineH
                Font.draw(("%7d"):format(mon.exp), startX, y)
                y = y + lineH + gap
                Font.draw(Strings("LEVEL UP"), startX, y)
                y = y + lineH
                local Growth = require("src.pokemon.Growth")
                local nextExp = mon.level < 100 and (Growth.expForLevel(def.growthRate, mon.level + 1) - mon.exp) or 0
                Font.draw(("%7d"):format(math.max(0, nextExp)), startX, y)
                y = y + lineH + gap
                HudTiles.statusTile(0x70, startX, y) -- '<to>' at (14,6), was missing (#280)
                printLevel(startX + 12, y, math.min(100, mon.level + 1))
            end

            -- Tab 2: MOVES
            local function drawTabMoves(game, mon)
                self.typeZones = {}
                Font.drawBox(0, 7, 20, 11)

                local startY = 64
                for i, mv in ipairs(mon.moves) do
                    local entry = moveToEntry(game.data, mv)
                    local y = startY + (i - 1) * ROW_H
                    drawMoveRow(game, entry, 16, y, POWER_ICON, ACCURACY_ICON, self.typeZones)
                end
            end

            -- Tab 3: STATS 
            local function drawTabStats(game, mon)
                -- vanilla stats box
                Font.drawBox(0, 8, 10, 10)

                local showDVs = mod.options:get("show_extended_tab")
                local valueX = showDVs and (48 - 24) or 48 -- move left if DVs are shown

                local stats = {{"ATTACK", mon.stats.attack, mon.dvs.attack},
                               {"DEFENSE", mon.stats.defense, mon.dvs.defense},
                               {"SPEED", mon.stats.speed, mon.dvs.speed},
                               {"SPECIAL", mon.stats.special, mon.dvs.special}}

                for i, s in ipairs(stats) do
                    local y = 72 + (i - 1) * 16
                    Font.draw(Strings(s[1]), 8, y)

                    if showDVs then
                        local statText = ("%3d/"):format(s[2])
                        love.graphics.setColor(0, 0, 0, 1) -- normal, für Stat-Wert + "/"
                        Font.draw(statText, valueX, y + 8)

                        local dvX = valueX + Font.width(statText)
                        love.graphics.setColor(0.5, 0.5, 0.5, 1) -- hellere Farbe für den DV
                        Font.draw(("%2d"):format(s[3]), dvX, y + 8)
                        love.graphics.setColor(0, 0, 0, 1) -- zurücksetzen
                    else
                        Font.draw(("%3d"):format(s[2]), valueX, y + 8)
                    end
                end

                local startX = 80
                local y = 72
                local lineH = 8
                local gap = 8

                HudTiles.statusTile(0x73, startX, y) -- <ID>
                HudTiles.statusTile(0x74, startX + 8, y) -- №
                Font.draw("/", startX + 16, y)
                y = y + lineH
                Font.draw(("%05d"):format(mon.otId or game.save.player.id or 0), startX + 16, y)
                y = y + lineH + gap
                Font.draw(Strings("OT/"), startX, y)
                y = y + lineH
                Font.draw(mon.ot or game.save.player.name or "RED", startX + 8, y)
            end

            local function drawTabExtended(game, mon)

                Font.drawBox(0, 8, 20, 10)

                local x = 12
                local y = 76
                local gap = 10

                Font.draw("STAT EXP", x, y)
                y = y + gap
                drawStatExpBar("HP", mon.statExp.hp, x, y, 64);
                y = y + gap
                drawStatExpBar("ATK", mon.statExp.attack, x, y, 64);
                y = y + gap
                drawStatExpBar("DEF", mon.statExp.defense, x, y, 64);
                y = y + gap
                drawStatExpBar("SPE", mon.statExp.speed, x, y, 64);
                y = y + gap
                drawStatExpBar("SPC", mon.statExp.special, x, y, 64);
                y = y + gap
            end

            local tab = 1
            local TAB_NAMES = {"STATUS", "MOVES", "TRAINER"}
            local TAB_DRAW = {drawTabStatus, drawTabMoves, drawTabStats}
            if mod.options:get("show_extended_tab") then
                table.insert(TAB_NAMES, "EXTENDED")
                table.insert(TAB_DRAW, drawTabExtended)
            end

            local function drawTabDots(activeTab, total, x, y, gap)
                local DOT_SIZE = 2
                local ACTIVE_COLOR = 0 / 255
                local INACTIVE_COLOR = 170 / 255

                for i = 1, total do
                    local dotX = x + (i - 1) * gap
                    local shade = (i == activeTab) and ACTIVE_COLOR or INACTIVE_COLOR
                    love.graphics.setColor(shade, shade, shade, 1)
                    love.graphics.rectangle("fill", dotX, y, DOT_SIZE, DOT_SIZE)
                end

                love.graphics.setColor(1, 1, 1, 1)
            end

            function self:update(dt)

                if game.input:wasPressed("left") then
                    tab = tab > 1 and tab - 1 or #TAB_NAMES
                elseif game.input:wasPressed("right") then
                    tab = tab < #TAB_NAMES and tab + 1 or 1
                end

                if game.input:wasPressed("b") then
                    game.stack:pop()
                end
            end

            function self:draw()
                -- Font.drawBox(0, 0, 20, 18)

                drawHeader(game, mon)
                drawTabDots(tab, #TAB_NAMES, 80, 50, 8)
                TAB_DRAW[tab](game, mon)
                -- Font.draw(TAB_NAMES[tab], 72, 132)
            end

            return self
        end
    })
end
