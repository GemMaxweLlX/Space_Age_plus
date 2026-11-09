-- space-age-plus-core: runtime-логика общих механик.
local oxygen = require("scripts.oxygen")
local diary = require("scripts.diary")
local exploration = require("scripts.exploration")
local techtree = require("scripts.techtree")
local quality_bonus = require("scripts.quality_bonus")

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

-- Дерево технологий
script.on_event(defines.events.on_gui_opened, techtree.on_gui_opened)
script.on_event(defines.events.on_gui_click, techtree.on_gui_click)
script.on_event(defines.events.on_chunk_generated, techtree.on_chunk_generated)

-- Бонусы технологий по качеству
local bonus_filter = {
  { filter = "type", type = "assembling-machine" }, { filter = "type", type = "furnace" },
  { filter = "type", type = "mining-drill" }, { filter = "type", type = "lab" },
}
for _, e in pairs({ defines.events.on_built_entity, defines.events.on_robot_built_entity,
                    defines.events.script_raised_built, defines.events.script_raised_revive }) do
  script.on_event(e, function(event)
    if event.entity and event.entity.valid and event.entity.name == "sap-telescope" then
      exploration.on_built(event)
    else
      quality_bonus.on_built(event)
    end
  end, { { filter = "name", name = "sap-telescope" }, table.unpack(bonus_filter) })
end
for _, e in pairs({ defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity,
                    defines.events.on_entity_died, defines.events.script_raised_destroy }) do
  script.on_event(e, quality_bonus.on_removed, bonus_filter)
end

-- Для автотестов.
remote.add_interface("sap-core", {
  unlock_tech = function(force_name, tech, quality) techtree.unlock(game.forces[force_name], tech, quality) end,
  researched_quality = function(force_name, tech) return quality_bonus.researched_quality(game.forces[force_name], tech) end,
})
