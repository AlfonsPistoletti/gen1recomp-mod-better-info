-- move_relearner: a content-profile mod (api 2).
-- The 10-minute loop: edit, save, F5 in a POKEPORT_DEV=1 game, repeat.
return function(mod)
  -- patch, not override: every field you do not name keeps its base value
  -- (learnset, sprites, evolutions all survive this speed change)
  mod.content.pokemon:patch("MEW", { baseStats = { speed = 110 } })

  -- mod.events:on("pokemon.caught", function(e)
  --   mod.log:info("caught %s at L%d", e.species, e.level)
  -- end)
end
