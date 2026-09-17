return function(mod)

    mod.options:define({{
        key = "new_pokedex",
        type = "toggle",
        label = "NEW POKEDEX",
        default = true
    }, {
        key = "new_summary_menu",
        type = "toggle",
        label = "NEW SUMMARY MENU",
        default = true
    }, {
        key = "show_extended_tab",
        type = "toggle",
        label = "ADDIT. INFO",
        default = true
    }, {
        key = "battle_moves",
        type = "toggle",
        label = "BATTLE MOVE INFO",
        default = true
    }, {
        key = "enable_move_relearner",
        type = "toggle",
        label = "MOVE RELEARNER",
        default = true
    }, {
        key = "party_icon_colors",
        type = "toggle",
        label = "PARTY ICON COLORS",
        default = true
    }})

    local function loadFactory(filename)
        local source, readErr = mod:read(filename)
        if not source then
            mod.log:error("%s is missing (%s)", filename, tostring(readErr))
            return nil
        end

        local chunk, compileErr = load(source, "@" .. mod.path .. "/" .. filename)
        if not chunk then
            mod.log:error("%s did not compile: %s", filename, tostring(compileErr))
            return nil
        end

        local ok, factory = pcall(chunk)
        if not ok or type(factory) ~= "function" then
            mod.log:error("%s must return a factory function: %s", filename, tostring(factory))
            return nil
        end
        return factory
    end

    -- A broken sub-file must only cost that one feature, matching
    -- loadFactory's own isolation design: a missing/uncompilable file is
    -- already handled by loadFactory returning nil, and this also guards
    -- the factory CALL itself (a runtime error while it installs its
    -- hooks/screens) so neither failure mode can crash the rest of the mod.
    local function runModule(filename, ...)
        local factory = loadFactory(filename)
        if not factory then return nil end
        local ok, result = pcall(factory, ...)
        if not ok then
            mod.log:error("%s failed to load: %s", filename, tostring(result))
            return nil
        end
        return result
    end

    local hudHelpers = runModule("hud_helpers.lua", mod)
    local moveRow = runModule("move_row.lua", mod, hudHelpers)

    if mod.options:get("new_summary_menu") then
        runModule("summary_menu.lua", mod, hudHelpers, moveRow)
    end

    if mod.options:get("enable_move_relearner") then
        runModule("npc_move_relearner.lua", mod, moveRow)
    end

    if mod.options:get("battle_moves") then
        runModule("battle_moves.lua", mod, moveRow)
    end

    if mod.options:get("new_pokedex") then
        runModule("dex_entry.lua", mod, hudHelpers, moveRow)
        runModule("pokedex.lua", mod, hudHelpers)
    end

    if mod.options:get("party_icon_colors") then
        runModule("party_icons.lua", mod)
    end
end
