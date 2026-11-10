-- space-age-plus-debris: runtime-логика (docs: Глобальные механики → Мусор).
local debris = require("scripts.debris")

script.on_init(debris.on_init)
script.on_configuration_changed(debris.on_configuration_changed)
script.on_nth_tick(debris.TICK_INTERVAL, debris.on_tick)
script.on_nth_tick(debris.FALL_INTERVAL, debris.on_fall_tick)
script.on_event(defines.events.on_rocket_launched, debris.on_rocket_launched)
