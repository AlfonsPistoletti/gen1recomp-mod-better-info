-- Places the Move Relearn NPC Into Celadon City
-- Holds the Move Relearn Menu logic

return function(mod, moveRow)
    local Screens = require("src.ui.Screens")
    local MoveLearnMenu = require("src.ui.MoveLearnMenu")
    local TextBox = require("src.render.TextBox")
    local Font = require("src.render.Font")
    local NAME_MAX_CHARS = 12
    local ROW_H = 19

    local function truncateName(name)
        if #name > NAME_MAX_CHARS then
            return name:sub(1, NAME_MAX_CHARS - 1) .. "."
        end
        return name
    end

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
                    local entry = list[i]
                    local row = i - scroll
                    local y = startY + (row - 1) * ROW_H
                    moveRow.drawMoveRow(game, entry, 16, y, self.typeZones)
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
    -- Celadon Mansion 2f x3 y5
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
end
