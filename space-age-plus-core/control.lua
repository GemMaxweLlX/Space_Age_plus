-- space-age-plus-core: runtime-логика общих механик.
local oxygen = require("scripts.oxygen")
local diary = require("scripts.diary")
local exploration = require("scripts.exploration")
local techtree = require("scripts.techtree")
local quality_bonus = require("scripts.quality_bonus")
local capture = require("scripts.capture")
local condensing = require("scripts.condensing")
local no_delivery = require("scripts.no_delivery")
local dungeon = require("scripts.dungeon")
local story = require("scripts.story")
dungeon.on_core_taken = story.on_core_taken

script.on_init(function()
  oxygen.on_init()
  exploration.on_init()
  techtree.on_init()
  quality_bonus.on_init()
  dungeon.on_init()
end)

script.on_configuration_changed(function()
  oxygen.on_configuration_changed()
  exploration.on_configuration_changed()
  techtree.on_configuration_changed()
  dungeon.on_init()
  dungeon.add_missing_entrances()
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
script.on_event(defines.events.on_gui_opened, function(event)
  techtree.on_gui_opened(event)
  dungeon.on_gui_opened(event)
  story.on_gui_opened(event)
end)
script.on_event(defines.events.on_gui_click, function(event)
  techtree.on_gui_click(event)
  diary.on_gui_click(event)
  dungeon.on_gui_click(event)
  story.on_gui_click(event)
end)
script.on_event(defines.events.on_chunk_generated, function(event)
  techtree.on_chunk_generated(event)
  dungeon.on_chunk_generated(event)
end)

-- Постройка: телескоп, бонусы качества, дневник (все постройки игрока).
for _, e in pairs({ defines.events.on_built_entity, defines.events.on_robot_built_entity,
                    defines.events.script_raised_built, defines.events.script_raised_revive }) do
  script.on_event(e, function(event)
    local entity = event.entity
    if not (entity and entity.valid) then return end
    if entity.name == "sap-telescope" then exploration.on_built(event) end
    quality_bonus.on_built(event)
    diary.on_built(event)
    story.on_built(entity)
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
script.on_nth_tick(120 + 7, techtree.on_tick)
script.on_event(defines.events.on_cargo_pod_finished_descending, diary.on_cargo_pod_finished_descending)
remote.add_interface("sap-diary", {
  add = function(force_name, key)
    local force = game.forces[force_name]
    if force then diary.add(force, key) end
  end,
  check_base = function(force_name) diary.check_base_now(game.forces[force_name]) end,
  entries = function(force_name)
    local result = {}
    local s = storage.diary and storage.diary.forces[game.forces[force_name].index]
    for _, e in pairs(s and s.entries or {}) do result[#result + 1] = e.key end
    return result
  end,
})

-- Для автотестов.
local sap_settings = require("sap_settings")
remote.add_interface("sap-core", {
  get_setting = function(name) return sap_settings.get(name) end,
  -- Тесты с игроком: «нажатие» на элемент окна и на клавишу дневника (те же обработчики).
  test_click = function(player_index, element)
    local event = { element = element, player_index = player_index, name = defines.events.on_gui_click }
    techtree.on_gui_click(event)
    diary.on_gui_click(event)
    dungeon.on_gui_click(event)
    story.on_gui_click(event)
  end,
  test_toggle_diary = function(player_index) diary.toggle({ player_index = player_index }) end,
  test_set_llk_chance = function(value) settings.global["sap-llk-chance"] = { value = value } end, -- luacheck: ignore 122
  decipher = function(force_name, entity, choice, llk_roll)
    local names, message = techtree.test_run(game.forces[force_name], entity, choice, llk_roll)
    return { names = names, message = message }
  end,
  oxygen_step = function(character, initial_air) return oxygen.test_step(character, initial_air) end,
  no_delivery_override = function(surface_name, value) no_delivery.set_override(surface_name, value) end,
  check_pod = function(pod) return no_delivery.check_pod(pod, nil) end,
  unlock_tech = function(force_name, tech, quality) techtree.unlock(game.forces[force_name], tech, quality) end,
  dungeon_generate = function(planet) return dungeon.generate(planet) end,
  dungeon_place_entrance = function(surface_name, position)
    return dungeon.place_entrance(game.get_surface(surface_name), position)
  end,
  dungeon_enter = function(player_index, entrance) dungeon.enter(game.get_player(player_index), entrance) end,
  dungeon_leave = function(player_index) dungeon.leave(game.get_player(player_index)) end,
  dungeon_doors = function(planet)
    local n = 0
    for _, d in pairs(storage.dungeons and storage.dungeons.doors or {}) do
      if d.planet == planet and d.door.valid then n = n + 1 end
    end
    return n
  end,
  dungeon_door_locks = function(planet)
    local result = {}
    for _, d in pairs(storage.dungeons and storage.dungeons.doors or {}) do
      if d.planet == planet then result[#result + 1] = { door = d.door, lock = d.lock, kind = d.kind } end
    end
    return result
  end,
  story_choose = function(force_name, ending) return story.choose(game.forces[force_name], ending) end,
  story_ending = function(force_name) return story.ending_of(game.forces[force_name]) end,
  test_set_story_victory = function(value) settings.global["sap-story-victory"] = { value = value } end, -- luacheck: ignore 122
  researched_quality = function(force_name, tech) return quality_bonus.researched_quality(game.forces[force_name], tech) end,
})

-- Захват ульев SA+
script.on_event(defines.events.on_script_trigger_effect, capture.on_script_trigger_effect)

-- Конденсация пара (паровая турбина Mk2, мега-турбина)
script.on_nth_tick(condensing.TICK_INTERVAL + 2, condensing.on_tick)

-- Хардкор «Без доставки с платформы»
script.on_event(defines.events.on_cargo_pod_finished_ascending, no_delivery.on_cargo_pod_finished_ascending)

-- Подземелья древней расы: двери открываются по замкам.
script.on_nth_tick(dungeon.TICK_INTERVAL + 3, dungeon.on_tick)
