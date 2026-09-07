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
            effect = mdef and mdef.effect or "",
        }
    end

    local BOX_X, BOX_Y, BOX_W, BOX_H = 0, 64, 88, 40

    local function clearRegion(game)
        local r, g, b = PaletteFX.paperShade(game.data)
        love.graphics.setColor(r, g, b, 1)
        love.graphics.rectangle("fill", BOX_X, BOX_Y, BOX_W, BOX_H)
    end

    local function renderMoveDetail(battle)
        if battle.phase ~= "moveSelect" or battle:isWideBattleLayout() then return end
        local game = battle.game
        local moves = battle.player and battle.player.curMoves
        if not moves then return end

        if battle.player.disabledSlot == battle.moveIndex then return end

        local selected = moves[battle.moveIndex]
        if not selected then return end
        local entry = moveToEntry(game, selected)

        clearRegion(game)
        Font.drawBox(0, 7, 11, 6)

        moveRow.drawMoveDetailCard(game, entry, BOX_X + 8, BOX_Y, 4)
    end

    mod.hooks:wrap("battle.overlay", function(next, battle)
        next(battle)
        local ok, err = pcall(renderMoveDetail, battle)
        if not ok then
            mod.log:error("battle move detail overlay failed: %s", tostring(err))
        end
    end, -100)
end