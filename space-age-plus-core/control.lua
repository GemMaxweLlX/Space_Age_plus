-- space-age-plus-core: runtime-логика общих механик.
local oxygen = require("scripts.oxygen")
local diary = require("scripts.diary")
local exploration = require("scripts.exploration")
local techtree = require("scripts.techtree")
local quality_bonus = require("scripts.quality_bonus")
local capture = require("scripts.capture")
local condensing = require("scripts.condensing")

script.on_init(function()
  oxygen.on_init()
  exploration.on_init()
  techtree.on_init()
  quality_bonus.on_init()
end)

script.on_configuration_changed(function()
  oxygen.on_configuration_changed()
  exploration.on_configuration_changed()
  techtree.on_configuration_changed()
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
-- (постройка телескопа обрабатывается ниже, вместе с бонусами качества)
script.on_event(defines.events.on_rocket_launch_ordered, exploration.on_rocket_launch_ordered)
script.on_event(defines.events.on_force_created, function(event)
  exploration.on_force_created(event)
  techtree.on_force_created(event)
end)
script.on_event(defines.events.on_research_finished, function(event)
  exploration.on_research_finished(event)
  quality_bonus.on_research_finished(event)
end)

-- Дерево технологий и дневник: у мода один обработчик на событие, поэтому общие.
script.on_event(defines.events.on_gui_opened, techtree.on_gui_opened)
script.on_event(defines.events.on_gui_click, function(event)
  techtree.on_gui_click(event)
  diary.on_gui_click(event)
end)
script.on_event(defines.events.on_chunk_generated, techtree.on_chunk_generated)

-- Постройка: телескоп, бонусы качества, дневник (все постройки игрока).
for _, e in pairs({ defines.events.on_built_entity, defines.events.on_robot_built_entity,
                    defines.events.script_raised_built, defines.events.script_raised_revive }) do
  script.on_event(e, function(event)
    local entity = event.entity
    if not (entity and entity.valid) then return end
    if entity.name == "sap-telescope" then exploration.on_built(event) end
    quality_bonus.on_built(event)
    diary.on_built(event)
  end)
end
for _, e in pairs({ defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity,
                    defines.events.script_raised_destroy }) do
  script.on_event(e, quality_bonus.on_removed)
end
script.on_event(defines.events.on_entity_died, function(event)
  quality_bonus.on_removed(event)
  diary.on_entity_died(event)
end)

-- Дневник: остальные события
script.on_event(defines.events.on_entity_damaged, diary.on_entity_damaged, { { filter = "type", type = "character" } })
script.on_event(defines.events.on_player_crafted_item, diary.on_player_crafted_item)
script.on_event(defines.events.on_player_mined_item, diary.on_player_mined_item)
script.on_event(defines.events.on_rocket_launched, diary.on_rocket_launched)
script.on_event(defines.events.on_player_changed_surface, diary.on_player_changed_surface)
script.on_event(defines.events.on_player_died, diary.on_player_died)
script.on_nth_tick(diary.TICK_INTERVAL, diary.on_tick)
remote.add_interface("sap-diary", {
  add = function(force_name, key)
    local force = game.forces[force_name]
    if force then diary.add(force, key) end
  end,
  entries = function(force_name)
    local result = {}
    local s = storage.diary and storage.diary.forces[game.forces[force_name].index]
    for _, e in pairs(s and s.entries or {}) do result[#result + 1] = e.key end
    return result
  end,
})

-- Для автотестов.
remote.add_interface("sap-core", {
  unlock_tech = function(force_name, tech, quality) techtree.unlock(game.forces[force_name], tech, quality) end,
  researched_quality = function(force_name, tech) return quality_bonus.researched_quality(game.forces[force_name], tech) end,
})

-- Захват ульев SA+
script.on_event(defines.events.on_script_trigger_effect, capture.on_script_trigger_effect)

-- Конденсация пара (паровая турбина Mk2, мега-турбина)
script.on_nth_tick(condensing.TICK_INTERVAL + 2, condensing.on_tick)
