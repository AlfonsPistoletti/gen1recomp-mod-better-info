-- Draws the move rows with additional info
return function(mod)
    local Font = require("src.render.Font")
    local PaletteFX = require("src.render.PaletteFX")
    local Colors = require("mods.better_info.Colors")

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

    local DEX_GAP = 8
    local SUMMARY_GAP = 16
    local function drawMoveRow(game, entry, textX, y, zoneSink, totalW, dex)
        local g = love.graphics

        if not entry then
            g.setColor(0, 0, 0, 1)
            Font.draw("ー", textX, y)
            g.setColor(1, 1, 1, 1)
            return
        end

        local powerIconW = POWER_ICON and POWER_ICON:getWidth() or ICON_W
        local accIconW = ACCURACY_ICON and ACCURACY_ICON:getWidth() or ICON_W

        -- type box always right
        local typeBoxW = Colors.TYPE_BADGE_W
        local typeBoxX = textX + totalW - typeBoxW

        -- name left
        local nameColW = totalW - typeBoxW - NAME_TYPE_GAP
        local maxNameChars = math.max(1, math.floor(nameColW / 8))

        local function truncateRowName(name)
            if #name > maxNameChars then
                if maxNameChars <= 1 then
                    return name:sub(1, maxNameChars)
                end
                return name:sub(1, maxNameChars - 1) .. "."
            end
            return name
        end

        Font.draw(truncateRowName(entry.name), textX, y)

        -- Type Badge
        local mdef = game.data.moves[entry.move]
        if mdef and mdef.type then
            Colors.drawTypeBadge(game, mdef.type, typeBoxX, y - 2, zoneSink)
        end

        -- bottom row
        local valueY = y + NAME_H

        local DEX_GAP = 8
        local SUMMARY_GAP = 9

        local powerIconW = POWER_ICON and POWER_ICON:getWidth() or ICON_W
        local accIconW = ACCURACY_ICON and ACCURACY_ICON:getWidth() or ICON_W

        local col1, col2, col3, col4, col5

        -- different column sizes in dex
        if dex then
            col1 = textX
            col2 = col1 + powerIconW + 2 + DEX_GAP
            col3 = col2 + VALUE_W + DEX_GAP
            col4 = col3 + accIconW + 2
            col5 = col4 + VALUE_W + DEX_GAP
        else
            col1 = textX
            col2 = col1 + powerIconW + 2
            col3 = col2 + VALUE_W + SUMMARY_GAP
            col4 = col3 + accIconW + 2
            col5 = col4 + VALUE_W + SUMMARY_GAP
        end

        -- Power
        if POWER_ICON then
            g.setColor(1, 1, 1, 1)
            g.draw(POWER_ICON, col1, valueY)
            PaletteFX.markTrueColor(col1, valueY, ICON_W, ICON_W)
        end

        g.setColor(0, 0, 0, 1)
        Font.draw(("%3s"):format(getMovePower(entry)), col2, valueY)

        -- Accuracy
        if ACCURACY_ICON then
            g.setColor(1, 1, 1, 1)
            g.draw(ACCURACY_ICON, col3, valueY)
            PaletteFX.markTrueColor(col3, valueY, ICON_W, ICON_W)
        end

        g.setColor(0, 0, 0, 1)
        Font.draw(("%3d"):format(entry.accuracy), col4, valueY)

        -- PP
        local ppText
        if dex then
            ppText = ("PP%2d"):format(entry.pp or 0)
        else
            ppText = ("PP%2d/%2d"):format(entry.currentPP or 0, entry.pp or 0)
        end
        Font.draw(ppText, col5, valueY)

        g.setColor(1, 1, 1, 1)
    end

    local function drawMoveDetailCard(game, entry, x, y, gap)
        local g = love.graphics

        local typeBadgeOffset = 42

        local mdef = game.data.moves[entry.move]
        if mdef and mdef.type then
            local abbr = Colors.typeAbbr(mdef.type)
            local boxW = TYPE_ABBR_LEN * 8 + TYPE_BOX_PAD_X * 2

            if game.save.options.colors == "redpp" then
                Colors.setColorFromTable(Colors.gbcColor(mdef.type))
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

        Font.draw(("PP%2d/%2d"):format(entry.currentPP or 0, entry.pp or 0), x, y)
    end

    return {
        drawMoveRow = drawMoveRow,
        drawMoveDetailCard = drawMoveDetailCard,
        ROW_H = ROW_H,
        POWER_ICON = POWER_ICON,
        ACCURACY_ICON = ACCURACY_ICON
    }

end
