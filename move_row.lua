-- Draws the move rows with additional info
return function(mod, colors)
    local Font = require("src.render.Font")
    local PaletteFX = require("src.render.PaletteFX")

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

    local function loadIcon(relPath)
        local ok, img = pcall(love.graphics.newImage, mod.assets:path(relPath))
        return ok and img or nil
    end

    local POWER_ICON = loadIcon("assets/icons/power.png")
    local ACCURACY_ICON = loadIcon("assets/icons/accuracy.png")

    local function truncateName(name)
        if #name > NAME_MAX_CHARS then
            return name:sub(1, NAME_MAX_CHARS - 1) .. "."
        end
        return name
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

    local function drawMoveRow(game, entry, textX, y, zoneSink)
        local g = love.graphics

        if not entry then
            g.setColor(0, 0, 0, 1)
            Font.draw("ー", textX, y)
            g.setColor(1, 1, 1, 1)
            return
        end

        local powerIconW = POWER_ICON and POWER_ICON:getWidth() or ICON_W
        local accIconW = ACCURACY_ICON and ACCURACY_ICON:getWidth() or ICON_W
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
            local abbr = colors.typeAbbr(mdef.type)
            local boxW = TYPE_ABBR_LEN * 8 + TYPE_BOX_PAD_X * 2
            local boxY = y - 1

            -- "redpp" / advanced
            if game.save.options.colors == "redpp" then
                colors.setColorFromTable(colors.gbcColor(mdef.type))
                g.rectangle("fill", typeBoxX, boxY, boxW, TYPE_BOX_H)
                PaletteFX.markTrueColor(typeBoxX, boxY, boxW, TYPE_BOX_H)
            else -- SGB
                g.setColor(170 / 255, 170 / 255, 170 / 255, 1)
                g.rectangle("fill", typeBoxX, boxY, boxW, TYPE_BOX_H)
                if zoneSink then
                    local paletteName = colors.gbPaletteName(mdef.type)
                    if paletteName then
                        table.insert(zoneSink, {
                            x = typeBoxX,
                            y = boxY,
                            w = boxW,
                            h = TYPE_BOX_H,
                            paletteName = paletteName
                        })
                    end
                end
            end

            g.setColor(0, 0, 0, 1)
            Font.draw(abbr, typeBoxX + TYPE_BOX_PAD_X, y)
        end

        g.setColor(1, 1, 1, 1)
        if POWER_ICON then
            g.draw(POWER_ICON, col1, y + NAME_H)
            PaletteFX.markTrueColor(col1, y + NAME_H, ICON_W, ICON_W)
        end
        Font.draw(("%3s"):format(getMovePower(entry)), col2, y + NAME_H)

        if ACCURACY_ICON then
            g.draw(ACCURACY_ICON, col3, y + NAME_H)
            PaletteFX.markTrueColor(col3, y + NAME_H, ICON_W, ICON_W)
        end
        Font.draw(("%3d"):format(entry.accuracy), col4, y + NAME_H)

        Font.draw(("PP%2d"):format(entry.pp), col5, y + NAME_H)
    end

    local function drawMoveDetailCard(game, entry, x, y, gap)
        local g = love.graphics

        local typeBadgeOffset = 42

        local mdef = game.data.moves[entry.move]
        if mdef and mdef.type then
            local abbr = colors.typeAbbr(mdef.type)
            local boxW = TYPE_ABBR_LEN * 8 + TYPE_BOX_PAD_X * 2

            if game.save.options.colors == "redpp" then
                colors.setColorFromTable(colors.gbcColor(mdef.type))
                g.rectangle("fill", x + typeBadgeOffset, y, boxW, TYPE_BOX_H)
                PaletteFX.markTrueColor(x + typeBadgeOffset, y, boxW, TYPE_BOX_H)
            else
                g.setColor(170 / 255, 170 / 255, 170 / 255, 1)
                g.rectangle("fill", x + typeBadgeOffset, y, boxW, TYPE_BOX_H)
            end

            g.setColor(0, 0, 0, 1)
            Font.draw(abbr, x + TYPE_BOX_PAD_X + typeBadgeOffset, y + 1)
        end

        g.setColor(1, 1, 1, 1)
        if POWER_ICON then
            g.draw(POWER_ICON, x, y)
            PaletteFX.markTrueColor(x, y, ICON_W, ICON_W)
        end
        Font.draw(("%3s"):format(getMovePower(entry)), x + ICON_W + 2, y)

        y = y + NAME_H + gap

        if ACCURACY_ICON then
            g.draw(ACCURACY_ICON, x, y)
            PaletteFX.markTrueColor(x, y, ICON_W, ICON_W)
        end
        Font.draw(("%3d"):format(entry.accuracy), x + ICON_W + 2, y)

        y = y + NAME_H + gap

        Font.draw(("PP%2d/%2d"):format(entry.pp, entry.pp), x, y)
    end

    return {
        drawMoveRow = drawMoveRow,
        drawMoveDetailCard = drawMoveDetailCard,
        ROW_H = ROW_H,
        POWER_ICON = POWER_ICON,
        ACCURACY_ICON = ACCURACY_ICON
    }

end
