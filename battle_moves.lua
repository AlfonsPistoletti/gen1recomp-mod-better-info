return function(mod, moveRow)
    local Font = require("src.render.Font")
    local PaletteFX = require("src.render.PaletteFX")

    local function moveDef(game, move)
        local id = type(move) == "table" and move.id or move
        return game.data.moves[id]
    end

    local function moveToEntry(game, move)
        local mdef = moveDef(game, move)
        return {
            move = move.id,
            name = mdef and mdef.name or move.id,
            power = mdef and mdef.power or 0,
            accuracy = mdef and mdef.accuracy or 0,
            pp = move.pp,
            effect = mdef and mdef.effect or ""
        }
    end

    local NORMAL_X = 0
    local NORMAL_Y = 56

    local WIDE_X = 216
    local WIDE_Y = 96

    local BOX_W = 88
    local BOX_H = 40

    local function clearRegion(game, x, y, w, h)
        local r, g, b = PaletteFX.paperShade(game.data)
        love.graphics.setColor(r, g, b, 1)
        love.graphics.rectangle("fill", x, y, w, h)
    end

    local function renderMoveDetail(battle)

        local boxX, boxY

        if battle.phase ~= "moveSelect" then
            return
        end
        local game = battle.game
        local moves = battle.player and battle.player.curMoves
        if not moves then
            return
        end

        if battle.player.disabledSlot == battle.moveIndex then
            return
        end

        local selected = moves[battle.moveIndex]
        if not selected then
            return
        end
        local entry = moveToEntry(game, selected)

        if battle:isWideBattleLayout() then
            boxX, boxY = WIDE_X, WIDE_Y
        else
            boxX, boxY = NORMAL_X, NORMAL_Y
        end

        clearRegion(game, boxX, boxY, 88, 40)
        Font.drawBox(boxX / 8, boxY / 8, 11, 6)

        moveRow.drawMoveDetailCard(game, entry, boxX + 8, boxY + 8, 4)
    end

    mod.hooks:wrap("battle.overlay", function(next, battle)
        next(battle)
        local ok, err = pcall(renderMoveDetail, battle)
        if not ok then
            mod.log:error("battle move detail overlay failed: %s", tostring(err))
        end
    end, -100)
end
