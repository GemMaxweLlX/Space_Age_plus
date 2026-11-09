-- space-age-plus-core: runtime-логика общих механик.
local oxygen = require("scripts.oxygen")

script.on_init(function()
  oxygen.on_init()
end)

script.on_configuration_changed(function()
  oxygen.on_configuration_changed()
end)

script.on_nth_tick(oxygen.TICK_INTERVAL, oxygen.on_tick)
script.on_event(defines.events.on_player_created, oxygen.on_player_reset)
script.on_event(defines.events.on_player_respawned, oxygen.on_player_reset)
script.on_event(defines.events.on_player_removed, oxygen.on_player_removed)
script.on_event(defines.events.on_runtime_mod_setting_changed, oxygen.on_settings_changed)
