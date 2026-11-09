-- space-age-plus-aquara: runtime-логика (Aquara — спутник Глебы).
local storm = require("scripts.storm")
local creatures = require("scripts.creatures")

script.on_init(function()
  storm.on_init()
  creatures.on_init()
end)
script.on_nth_tick(storm.TICK_INTERVAL, storm.on_tick)
script.on_nth_tick(creatures.TICK_INTERVAL, creatures.on_tick)
script.on_nth_tick(creatures.ATTACK_INTERVAL, creatures.on_attack_tick)
script.on_event(defines.events.on_chunk_generated, creatures.on_chunk_generated)

-- Для автотестов: создать торнадо в точке.
remote.add_interface("sap-aquara", {
  spawn_tornado = function(position, target, strength) storm.spawn_at(position, target, strength) end,
})
