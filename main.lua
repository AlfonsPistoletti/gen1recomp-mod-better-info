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

    local makeHudHelpers = loadFactory("hud_helpers.lua")
    local makeMoveRow = loadFactory("move_row.lua")

    local hudHelpers = makeHudHelpers(mod)
    local moveRow = makeMoveRow(mod)

    if mod.options:get("new_summary_menu") then
        local makeSummaryMenu = loadFactory("summary_menu.lua")
        makeSummaryMenu(mod, hudHelpers, moveRow)
    end

    if mod.options:get("enable_move_relearner") then
        local makeNpc = loadFactory("npc_move_relearner.lua")
        makeNpc(mod, moveRow)
    end

    if mod.options:get("battle_moves") then
        local battleMoves = loadFactory("battle_moves.lua")
        battleMoves(mod, moveRow)
    end

    if mod.options:get("new_pokedex") then
        local pokedex = loadFactory("pokedex.lua")
        local dexEntry = loadFactory("dex_entry.lua")
        dexEntry(mod, moveRow)
        pokedex(mod)
    end
end
