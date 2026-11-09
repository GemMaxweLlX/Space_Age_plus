-- space-age-plus-solaris: runtime-логика (Solaris — планета у Солнца).
local overheat = require("scripts.overheat")
local creatures = require("scripts.creatures")
local power = require("scripts.power")

script.on_init(creatures.on_init)
script.on_configuration_changed(creatures.on_init)
script.on_nth_tick(overheat.TICK_INTERVAL, overheat.on_tick)
script.on_nth_tick(creatures.TICK_INTERVAL, creatures.on_tick)
script.on_nth_tick(creatures.ATTACK_INTERVAL, creatures.on_attack_tick)
script.on_event(defines.events.on_chunk_generated, creatures.on_chunk_generated)
script.on_event(defines.events.on_surface_created, creatures.on_surface_created)
script.on_nth_tick(power.TICK_INTERVAL + 3, power.on_tick)

-- Для автотестов.
remote.add_interface("sap-solaris", {
  charge_catcher = function(catcher, energy) power.charge(catcher, energy) end,
})
