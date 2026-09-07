-- completely replaces the vanilla summary menu
-- with a 3-4 tab menu
return function(mod, hudHelpers, moveRow)
    local Sprites = require("src.pokemon.Sprites")
    local HudTiles = require("src.render.HudTiles")
    local Status = require("src.battle.Status")
    local TypeChart = require("src.battle.TypeChart")
    local Strings = require("src.core.Strings")
    local Growth = require("src.pokemon.Growth")
    local PaletteFX = require("src.render.PaletteFX")

    mod.content.screens:override("SummaryMenu", {
        new = function(game, mon)
            local Font = mod.ui.Font
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

            -- Sprite einmalig laden und cachen
            local path, trueColor = Sprites.path(game.data, mon.species, "front", {
                mon = mon,
                kind = "summary"
            })
            if path then
                local ok, img = pcall(love.graphics.newImage, path)
                self.sprite = ok and img or nil
            end
            self.spriteTrueColor = self.sprite and trueColor or false

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
                hudHelpers.printLevel(120, 2, mon.level)

                if self.sprite then
                    local pw, ph = self.sprite:getDimensions()
                    local py = math.max(0, 56 - ph)
                    love.graphics.draw(self.sprite, 4 + pw, 1 + py, 0, -1, 1)
                    if self.spriteTrueColor then
                        PaletteFX.markTrueColor(4, 1 + py, pw, ph)
                    end
                end

                hudHelpers.drawLineBox(19, 0, 5, 8)

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

            -- statExp = 65535 (sqrt(65535)/4 ~= 63.9998)
            local function statExpBonus(statExp)
                return math.sqrt(statExp or 0) / 4
            end

            local STAT_EXP_BONUS_MAX = 64
            local STAT_EXP_MAX = 65535

            local function drawStatExpBar(label, statExp, x, y, barW)
                Font.draw(("%3s"):format(label), x, y)

                local bonus = statExpBonus(statExp)
                local fraction = math.min(1, bonus / STAT_EXP_BONUS_MAX)
                -- am tatsächlichen Maximum explizit auf 100%, wegen Rundungsfehler
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

            -- Tab 1: Status, Types, Exp
            local function drawTabStatus(game, mon)
                local data = game.data
                local def = data.pokemon[mon.species]

                Font.drawBox(0, 8, 10, 10)

                local startX = 8
                local y = 72
                local lineH = 8
                local gap = 8

                Font.draw(Strings("STATUS/"), startX, y)
                y = y + lineH
                Font.draw(Status.hudLabelFor(data.statuses, mon.status) or "OK", startX, y)
                y = y + lineH + gap

                Font.draw(Strings("TYPE1/"), startX, y)
                y = y + lineH
                Font.draw(def.types[1] and TypeChart.displayName(def.types[1]) or "", startX, y)
                y = y + lineH + gap

                if def.types[2] then
                    Font.draw(Strings("TYPE2/"), startX, y)
                    y = y + lineH
                    Font.draw(TypeChart.displayName(def.types[2]), startX, y)
                    y = y + lineH + gap
                end

                startX = 88
                y = 72
                Font.draw(Strings("EXP PTS."), startX, y)
                y = y + lineH
                Font.draw(("%7d"):format(mon.exp), startX, y)
                y = y + lineH + gap
                Font.draw(Strings("LEVEL UP"), startX, y)
                y = y + lineH
                local nextExp = mon.level < 100 and (Growth.expForLevel(def.growthRate, mon.level + 1) - mon.exp) or 0
                Font.draw(("%7d"):format(math.max(0, nextExp)), startX, y)
                y = y + lineH + gap
                HudTiles.statusTile(0x70, startX, y) -- '<to>' at (14,6), was missing (#280)
                hudHelpers.printLevel(startX + 12, y, math.min(100, mon.level + 1))
            end

            -- Tab 2: Moves
            local function drawTabMoves(game, mon)
                self.typeZones = {}
                Font.drawBox(0, 7, 20, 11)

                local startY = 64
                for i = 1, 4 do
                    local mv = mon.moves[i]
                    local entry = mv and moveToEntry(game.data, mv)
                    local y = startY + (i - 1) * moveRow.ROW_H
                    moveRow.drawMoveRow(game, entry, 16, y, self.typeZones)
                end
            end

            -- Tab 3: Stats, OT, ID
            local function drawTabStats(game, mon)
                Font.drawBox(0, 8, 10, 10)

                local showDVs = mod.options:get("show_extended_tab")
                local valueX = showDVs and (48 - 24) or 48 -- move left if DVs are displayed

                local stats = {{"ATTACK", mon.stats.attack, mon.dvs.attack},
                               {"DEFENSE", mon.stats.defense, mon.dvs.defense},
                               {"SPEED", mon.stats.speed, mon.dvs.speed},
                               {"SPECIAL", mon.stats.special, mon.dvs.special}}

                for i, s in ipairs(stats) do
                    local y = 72 + (i - 1) * 16
                    Font.draw(Strings(s[1]), 8, y)

                    if showDVs then
                        local statText = ("%3d/"):format(s[2])
                        love.graphics.setColor(0, 0, 0, 1)
                        Font.draw(statText, valueX, y + 8)

                        local dvX = valueX + Font.width(statText)
                        love.graphics.setColor(0.5, 0.5, 0.5, 1)
                        Font.draw(("%2d"):format(s[3]), dvX, y + 8)
                        love.graphics.setColor(0, 0, 0, 1)
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

            -- Tab 4: Extended: Stat Exp
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
                local DOT_SIZE_ACTIVE = 4
                local ACTIVE_COLOR = 0
                local INACTIVE_COLOR = 85 / 255

                for i = 1, total do
                    local active = (i == activeTab)
                    local dotX = x + (i - 1) * gap
                    local shade = active and ACTIVE_COLOR or INACTIVE_COLOR
                    local size = active and DOT_SIZE_ACTIVE or DOT_SIZE
                    love.graphics.setColor(shade, shade, shade, 1)
                    if active then
                        love.graphics.rectangle("fill", dotX - 1, y - 1, size, size)
                    else
                        love.graphics.rectangle("fill", dotX, y, size, size)
                    end
                end

                PaletteFX.markTrueColor(x, y, (DOT_SIZE_ACTIVE + gap) * total, DOT_SIZE_ACTIVE)

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
                drawHeader(game, mon)
                drawTabDots(tab, #TAB_NAMES, 80, 50, 8)
                TAB_DRAW[tab](game, mon)
            end

            return self
        end
    })
end
