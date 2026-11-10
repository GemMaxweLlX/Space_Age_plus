-- space-age-plus-nivar: runtime-логика (Nivar — спутник Аквило).
local caves = require("scripts.caves")
local cryostorm = require("scripts.cryostorm")
local creatures = require("scripts.creatures")

script.on_init(function()
  caves.on_init()
  cryostorm.on_init()
  creatures.on_init()
end)
script.on_configuration_changed(function()
  cryostorm.rescan()
end)

script.on_nth_tick(cryostorm.TICK_INTERVAL, cryostorm.on_tick)
script.on_nth_tick(creatures.TICK_INTERVAL, creatures.on_tick)
script.on_nth_tick(caves.ARMOR_TICK_INTERVAL + 1, caves.on_armor_tick)
script.on_event(defines.events.on_chunk_generated, creatures.on_chunk_generated)
script.on_event(defines.events.on_surface_created, caves.on_surface_created)
script.on_event(defines.events.on_gui_opened, caves.on_gui_opened)
script.on_event(defines.events.on_gui_click, caves.on_gui_click)

-- Лифт и список машин для криобури: у мода один обработчик на событие, поэтому общий.
local filter = {
  { filter = "name", name = "sap-nivar-elevator" },
  { filter = "type", type = "assembling-machine" }, { filter = "type", type = "furnace" },
  { filter = "type", type = "mining-drill" }, { filter = "type", type = "lab" },
  { filter = "type", type = "inserter" },
}
for _, e in pairs({ defines.events.on_built_entity, defines.events.on_robot_built_entity,
                    defines.events.script_raised_built, defines.events.script_raised_revive }) do
  script.on_event(e, function(event)
    caves.on_built(event)
    cryostorm.track(event.entity)
  end, filter)
end
for _, e in pairs({ defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity,
                    defines.events.on_entity_died, defines.events.script_raised_destroy }) do
  script.on_event(e, function(event)
    caves.on_removed(event)
    cryostorm.untrack(event.entity)
  end, filter)
end

-- Для автотестов.
remote.add_interface("sap-nivar", {
  test_click = function(player_index, element)
    caves.on_gui_click({ element = element, player_index = player_index, name = defines.events.on_gui_click })
  end,
  set_cryostorm = function(active) cryostorm.set_active(active) end,
  cryostorm_tick = function() cryostorm.on_tick() end,
  wake_caves = function() return cryostorm.wake_caves() end,
  is_cryostorm = function() return storage.cryostorm ~= nil and storage.cryostorm.active == true end,
  partner_of = function(entity) return caves.partner_of(entity) end,
})
