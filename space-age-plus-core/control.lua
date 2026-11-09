-- space-age-plus-core: runtime-логика общих механик.
local oxygen = require("scripts.oxygen")
local diary = require("scripts.diary")
local exploration = require("scripts.exploration")

script.on_init(function()
  oxygen.on_init()
  exploration.on_init()
end)

script.on_configuration_changed(function()
  oxygen.on_configuration_changed()
  exploration.on_configuration_changed()
end)

-- Кислород
script.on_nth_tick(oxygen.TICK_INTERVAL, oxygen.on_tick)
script.on_event(defines.events.on_player_created, oxygen.on_player_created)
script.on_event(defines.events.on_player_respawned, oxygen.on_player_respawned)
script.on_event(defines.events.on_player_removed, oxygen.on_player_removed)
script.on_event(defines.events.on_runtime_mod_setting_changed, oxygen.on_settings_changed)

-- Дневник
script.on_event("sap-toggle-diary", diary.toggle)

-- Исследование планет
local telescope_filter = { { filter = "name", name = "sap-telescope" } }
for _, e in pairs({
  defines.events.on_built_entity,
  defines.events.on_robot_built_entity,
  defines.events.script_raised_built,
  defines.events.script_raised_revive,
}) do
  script.on_event(e, exploration.on_built, telescope_filter)
end
script.on_event(defines.events.on_rocket_launch_ordered, exploration.on_rocket_launch_ordered)
script.on_event(defines.events.on_force_created, exploration.on_force_created)
script.on_event(defines.events.on_research_finished, exploration.on_research_finished)
