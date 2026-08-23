local M = {}

function M.register(mod)
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
end

return M
