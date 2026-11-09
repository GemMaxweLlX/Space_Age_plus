-- space-age-plus-echaris: runtime-логика (docs: Echaris; Вопросы реализации → I6).
local storm = require("scripts.storm")

script.on_init(storm.on_init)
script.on_configuration_changed(storm.on_configuration_changed)
script.on_nth_tick(storm.TICK_INTERVAL, storm.on_tick)
script.on_event(defines.events.on_surface_created, storm.on_surface_created)

local built_filter = { { filter = "name", name = "sap-storm-stabilizer" } }
for _, e in pairs({
  defines.events.on_built_entity,
  defines.events.on_robot_built_entity,
  defines.events.script_raised_built,
  defines.events.script_raised_revive,
}) do
  script.on_event(e, storm.on_stabilizer_built, built_filter)
end

-- Механиты
local mechanites = require("scripts.mechanites")
script.on_nth_tick(mechanites.TICK_INTERVAL + 1, mechanites.on_tick)
script.on_nth_tick(mechanites.WAVE_INTERVAL, mechanites.on_wave_tick)
script.on_event(defines.events.on_chunk_generated, mechanites.on_chunk_generated)
script.on_event(defines.events.on_gui_opened, mechanites.on_gui_opened)
script.on_event(defines.events.on_entity_damaged, mechanites.on_entity_damaged,
  { { filter = "name", name = "sap-sentinel" } })
script.on_event(defines.events.on_entity_died, mechanites.on_entity_died, {
  { filter = "name", name = "sap-sentinel" },
  { filter = "name", name = "sap-overseer" },
})

-- Силовой барьер, стелс, взлом
local specials = require("scripts.specials")
script.on_nth_tick(specials.TICK_INTERVAL, specials.on_tick)
script.on_event(defines.events.on_script_trigger_effect, specials.on_script_trigger_effect)

-- Для автотестов.
remote.add_interface("sap-echaris", {
  storm_tick = function() storm.on_tick() end,
  center_alarm = function(center, force_name) return mechanites.center_alarm(center, game.forces[force_name]) end,
})
