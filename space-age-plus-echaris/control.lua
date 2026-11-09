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
