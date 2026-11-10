-- space-age-plus-solaris: runtime-логика (Solaris — планета у Солнца).
local overheat = require("scripts.overheat")
local creatures = require("scripts.creatures")
local power = require("scripts.power")

script.on_init(function()
  creatures.on_init()
  overheat.rescan()
end)
script.on_configuration_changed(function()
  creatures.on_init()
  overheat.rescan()
end)

-- Перегрев: список машин ведётся по событиям.
local machine_filter = {
  { filter = "type", type = "assembling-machine" }, { filter = "type", type = "furnace" },
  { filter = "type", type = "mining-drill" }, { filter = "type", type = "lab" },
}
for _, e in pairs({ defines.events.on_built_entity, defines.events.on_robot_built_entity,
                    defines.events.script_raised_built, defines.events.script_raised_revive }) do
  script.on_event(e, function(event) overheat.track(event.entity) end, machine_filter)
end
for _, e in pairs({ defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity,
                    defines.events.on_entity_died, defines.events.script_raised_destroy }) do
  script.on_event(e, function(event) overheat.untrack(event.entity) end, machine_filter)
end
script.on_nth_tick(overheat.TICK_INTERVAL, overheat.on_tick)
script.on_nth_tick(creatures.TICK_INTERVAL, creatures.on_tick)
script.on_nth_tick(creatures.ATTACK_INTERVAL, creatures.on_attack_tick)
script.on_event(defines.events.on_chunk_generated, creatures.on_chunk_generated)
script.on_event(defines.events.on_surface_created, creatures.on_surface_created)
script.on_nth_tick(power.TICK_INTERVAL + 3, power.on_tick)

-- Для автотестов.
remote.add_interface("sap-solaris", {
  charge_catcher = function(catcher, energy) power.charge(catcher, energy) end,
  overheat_tick = function() overheat.on_tick() end,
})
