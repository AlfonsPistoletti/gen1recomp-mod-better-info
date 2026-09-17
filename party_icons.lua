-- Party-list icons get their own species palette, matching the Pokedex's
-- DexEntryMenu:drawSprite (mods/better_info/dex_entry.lua): PaletteFX.monPal
-- per mon instead of the vanilla single MEWMON zone shared by the whole
-- icon column (src/ui/PartyMenu.lua PartyMenu:sgbPalettes).
--
-- Wraps the core PartyMenu module directly (not mod.content.screens:override):
-- unlike the pokedex/summary screens this mod replaces wholesale, the party
-- list stays the vanilla implementation -- input handling, HP bars, swap
-- animation and all -- and only the icon coloring changes, so there is
-- nothing here worth reimplementing and everything worth keeping.
--
-- sgbPalettes() draws the finished frame once per zone (PaletteFX.lua's own
-- doc comment), so a zone added AFTER the vanilla icon-block zone simply
-- overrides it for its own rect on the next draw pass -- the vanilla MEWMON
-- zone stays as the fallback wherever a mon's own palette can't be
-- resolved (headless data, an unmapped species), rather than leaving that
-- icon uncolored. A trueColor icon needs no help here: PartyMenu.drawIcon
-- already reports its own unshaded rect via PaletteFX.markTrueColor, and
-- that per-frame rect always draws after every static zone.
return function(mod)
    local PartyMenu = require("src.ui.PartyMenu")
    local PaletteFX = require("src.render.PaletteFX")

    -- Guards hot reload: re-running this factory must not stack a second
    -- wrap onto an already-patched sgbPalettes.
    if PartyMenu.__betterInfoIconColorsHook then return end
    PartyMenu.__betterInfoIconColorsHook = true

    local innerSgbPalettes = PartyMenu.sgbPalettes
    function PartyMenu:sgbPalettes(game)
        local zones = innerSgbPalettes(self, game)
        if not zones then return zones end

        local party = self.party or (game.save and game.save.party) or {}
        for i, mon in ipairs(party) do
            -- a slot mid swap-animation draws no icon this frame (see
            -- PartyMenu:draw's swapAnim.blank check), so it has nothing to
            -- color either
            if not (self.swapAnim and self.swapAnim.blank[i]) then
                local colors = mon.species and PaletteFX.monPal(game.data, mon.species)
                if colors then
                    -- PartyMenu.entryY: 16px (2 tile rows) per slot, icon
                    -- column at tile columns 1-2 (PartyMenu:sgbPalettes'
                    -- own icon-block zone above)
                    local top = (i - 1) * 2
                    zones[#zones + 1] = PaletteFX.zone(colors, 1, top, 2, top + 1)
                end
            end
        end

        return zones
    end
end
