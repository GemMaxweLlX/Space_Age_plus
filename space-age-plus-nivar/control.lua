-- space-age-plus-nivar: runtime-логика (Nivar — спутник Аквило).
local caves = require("scripts.caves")
local cryostorm = require("scripts.cryostorm")
local creatures = require("scripts.creatures")

script.on_init(function()
  caves.on_init()
  cryostorm.on_init()
  creatures.on_init()
end)

script.on_nth_tick(cryostorm.TICK_INTERVAL, cryostorm.on_tick)
script.on_nth_tick(creatures.TICK_INTERVAL, creatures.on_tick)
script.on_event(defines.events.on_chunk_generated, creatures.on_chunk_generated)
script.on_event(defines.events.on_surface_created, caves.on_surface_created)
script.on_event(defines.events.on_gui_opened, caves.on_gui_opened)
script.on_event(defines.events.on_gui_click, caves.on_gui_click)

local elevator_filter = { { filter = "name", name = "sap-nivar-elevator" } }
for _, e in pairs({ defines.events.on_built_entity, defines.events.on_robot_built_entity,
                    defines.events.script_raised_built, defines.events.script_raised_revive,
                    defines.events.on_space_platform_built_entity }) do
  script.on_event(e, caves.on_built, elevator_filter)
end
for _, e in pairs({ defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity,
                    defines.events.on_entity_died, defines.events.script_raised_destroy }) do
  script.on_event(e, caves.on_removed, elevator_filter)
end

-- Для автотестов.
remote.add_interface("sap-nivar", {
  set_cryostorm = function(active) cryostorm.set_active(active) end,
  is_cryostorm = function() return storage.cryostorm ~= nil and storage.cryostorm.active == true end,
  partner_of = function(entity) return caves.partner_of(entity) end,
})
