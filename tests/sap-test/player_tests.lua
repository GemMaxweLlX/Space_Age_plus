-- Тесты с настоящим игроком (MODE=player: factorio --test-save ... --test-arg player).
-- Проверяют окна и всё, что требует LuaPlayer: индикатор и расход кислорода, дневник,
-- дешифратор, ЛЛК, лифт. Нажатия на кнопки идут через тестовые remote-вызовы модов, которые
-- запускают те же обработчики, что и настоящий клик.

local player_tests = {}

local function find(element, predicate)
  if predicate(element) then return element end
  for _, child in pairs(element.children) do
    local found = find(child, predicate)
    if found then return found end
  end
  return nil
end

local function find_all(element, predicate, out)
  out = out or {}
  if predicate(element) then out[#out + 1] = element end
  for _, child in pairs(element.children) do find_all(child, predicate, out) end
  return out
end

local function by_action(action)
  return function(e) return e.tags and e.tags.sap_action == action end
end

function player_tests.register(steps, check, finish)
  local function player() return game.get_player(1) end

  steps[5] = function()
    -- Во freeplay игра начинается с заставки, и персонажа ещё нет.
    local p = player()
    if p and p.controller_type == defines.controllers.cutscene then p.exit_cutscene() end
    if p and not p.character then p.create_character() end
  end

  steps[10] = function()
    local p = player()
    check("player: test player exists", p ~= nil and p.character ~= nil)
  end

  -- Кислород ----------------------------------------------------------------------
  steps[20] = function()
    local p = player()
    local vulcanus = game.planets["vulcanus"].create_surface()
    vulcanus.request_to_generate_chunks({ 0, 0 }, 3)
    vulcanus.force_generate_chunk_requests()
    storage.pt_spot = vulcanus.find_non_colliding_position("character", { 0, 0 }, 60, 1, true)
    p.get_inventory(defines.inventory.character_armor).clear()
    p.teleport(storage.pt_spot, vulcanus)
    storage.pt_health = p.character.health
  end

  steps[260] = function()
    local p = player()
    check("player oxygen: indicator shown on Vulcanus", p.gui.top["sap_oxygen_frame"] ~= nil)
    check("player oxygen: suffocating without armor", p.character and p.character.health < storage.pt_health,
          p.character and p.character.health)
    -- Броня с баллоном; на Наувисе баллон заполняется.
    local armor = p.get_inventory(defines.inventory.character_armor)
    armor.insert({ name = "modular-armor", count = 1 })
    armor[1].grid.put({ name = "sap-oxygen-tank-equipment" })
    p.teleport({ 0, 0 }, game.surfaces.nauvis)
  end

  steps[330] = function()
    local p = player()
    check("player oxygen: indicator hidden on Nauvis", p.gui.top["sap_oxygen_frame"] == nil)
    p.character.health = p.character.max_health
    p.teleport(storage.pt_spot, game.surfaces["vulcanus"])
  end

  steps[620] = function()
    local p = player()
    check("player oxygen: tank keeps you alive", p.character and p.character.health == p.character.max_health,
          p.character and p.character.health)
    local frame = p.gui.top["sap_oxygen_frame"]
    check("player oxygen: bar shows remaining air", frame ~= nil and frame.bar.value > 0 and frame.bar.value < 1,
          frame and frame.bar.value)
    p.teleport({ 0, 0 }, game.surfaces.nauvis)
  end

  -- Дневник -----------------------------------------------------------------------
  steps[700] = function()
    local p = player()
    remote.call("sap-core", "test_toggle_diary", p.index)
    local frame = p.gui.screen["sap_diary_frame"]
    check("player diary: window opens", frame ~= nil)
    if not frame then return end
    local buttons = find_all(frame, by_action("diary-background"))
    check("player diary: three backgrounds offered", #buttons == 3, #buttons)
    if buttons[1] then remote.call("sap-core", "test_click", p.index, buttons[1]) end
    frame = p.gui.screen["sap_diary_frame"]
    local list = frame and find(frame, function(e) return e.type == "scroll-pane" end)
    check("player diary: entries shown after choosing", list ~= nil and #list.children >= 1,
          list and #list.children)
    remote.call("sap-core", "test_toggle_diary", p.index)
    check("player diary: window closes", p.gui.screen["sap_diary_frame"] == nil)
  end

  -- Дешифратор ---------------------------------------------------------------------
  local function machine(name, near, packs)
    local p = player()
    local surface = p.surface
    local e = surface.create_entity({ name = name, position = surface.find_non_colliding_position(name, near, 30, 1),
                                      force = p.force })
    if packs then
      local inv = e.get_inventory(defines.inventory.chest)
      inv.insert({ name = "automation-science-pack", count = 10 })
      inv.insert({ name = "logistic-science-pack", count = 10 })
    end
    return e
  end

  local function enabled_count(force)
    local n = 0
    for name in pairs(prototypes.mod_data["sap-tech-catalog"].data) do
      if force.technologies[name] and force.technologies[name].enabled then n = n + 1 end
    end
    return n
  end

  steps[800] = function()
    local p = player()
    local dec = machine("sap-decipherer", { 6, 6 }, true)
    dec.get_inventory(defines.inventory.chest).insert({ name = "sap-data-card-logistics", count = 1, quality = "epic" })
    p.opened = dec
    local panel = p.gui.relative["sap_techtree_relative"]
    check("player decipherer: side panel on opening", panel ~= nil)
    if not panel then return end
    remote.call("sap-core", "test_click", p.index, panel.run)
    local choice = p.gui.screen["sap_techtree_choice"]
    local options = choice and find_all(choice, by_action("choose")) or {}
    check("player decipherer: choice window with three options", #options == 3, #options)
    check("player decipherer: refresh offered for a card", choice and find(choice, by_action("refresh")) ~= nil)
    local before = enabled_count(p.force)
    if options[1] then remote.call("sap-core", "test_click", p.index, options[1]) end
    check("player decipherer: choosing unlocks a technology", enabled_count(p.force) == before + 1,
          before .. " -> " .. enabled_count(p.force))
    check("player decipherer: choice window closed", p.gui.screen["sap_techtree_choice"] == nil)
    p.opened = nil
  end

  -- ЛЛК -----------------------------------------------------------------------------
  steps[900] = function()
    local p = player()
    remote.call("sap-core", "test_set_llk_chance", 20)
    local llk = machine("sap-logic-lab", { -6, 6 }, false)
    p.opened = llk
    local panel = p.gui.relative["sap_techtree_relative"]
    check("player llk: side panel on opening", panel ~= nil)
    if not panel then return end
    local choice
    local tries = 0
    for _ = 1, 60 do
      tries = tries + 1
      local inv = llk.get_inventory(defines.inventory.chest)
      inv.insert({ name = "automation-science-pack", count = 10 })
      inv.insert({ name = "logistic-science-pack", count = 10 })
      remote.call("sap-core", "test_click", p.index, panel.run)
      choice = p.gui.screen["sap_techtree_choice"]
      if choice then break end
    end
    local options = choice and find_all(choice, by_action("choose")) or {}
    check("player llk: success after some tries", choice ~= nil, tries .. " tries")
    check("player llk: at most two options, no refresh", #options >= 1 and #options <= 2
          and find(choice, by_action("refresh")) == nil, #options)
    if options[1] then remote.call("sap-core", "test_click", p.index, options[1]) end
    p.opened = nil
  end

  -- Лифт Nivar ----------------------------------------------------------------------
  steps[1000] = function()
    local p = player()
    local nivar = game.planets["nivar"].create_surface()
    nivar.request_to_generate_chunks({ 0, 0 }, 2)
    nivar.force_generate_chunk_requests()
    local pos = nivar.find_non_colliding_position("sap-nivar-elevator", { 0, 0 }, 40, 1)
    local elevator = nivar.create_entity({ name = "sap-nivar-elevator", position = pos, force = p.force, raise_built = true })
    p.teleport(nivar.find_non_colliding_position("character", { pos.x + 3, pos.y }, 10, 1), nivar)
    p.opened = elevator
    local frame = p.gui.relative["sap_nivar_elevator"]
    check("player elevator: travel button on opening", frame ~= nil and frame.go ~= nil)
    if frame then remote.call("sap-nivar", "test_click", p.index, frame.go) end
    check("player elevator: went down to the caves", p.surface.name == "nivar-caves", p.surface.name)
    storage.pt_cave_elevator = remote.call("sap-nivar", "partner_of", elevator)
  end

  steps[1060] = function()
    local p = player()
    local partner = storage.pt_cave_elevator
    if partner and partner.valid then
      p.opened = partner
      local frame = p.gui.relative["sap_nivar_elevator"]
      if frame then remote.call("sap-nivar", "test_click", p.index, frame.go) end
    end
    check("player elevator: came back up", p.surface.name == "nivar", p.surface.name)
  end

  -- Подземелье ----------------------------------------------------------------------
  steps[1100] = function()
    local p = player()
    local nauvis = game.surfaces.nauvis
    p.teleport(nauvis.find_non_colliding_position("character", { 30, 30 }, 30, 1) or { 30, 30 }, nauvis)
    local entrance = remote.call("sap-core", "dungeon_place_entrance", "nauvis", { p.position.x + 4, p.position.y })
    storage.pt_entrance = entrance
    p.opened = entrance
    local frame = p.gui.relative["sap_dungeon_frame"]
    check("player dungeon: entrance window", frame ~= nil)
    if frame then remote.call("sap-core", "test_click", p.index, frame.go) end
    check("player dungeon: went down", p.surface.name == "sap-dungeon-nauvis", p.surface.name)
  end

  steps[1120] = function()
    local p = player()
    local trap = p.surface.find_entities_filtered({ name = "sap-ancient-trap", limit = 1 })[1]
    check("player dungeon: trap found", trap ~= nil)
    if trap then
      storage.pt_back = p.position
      p.teleport(trap.position)
      storage.pt_trap_health = p.character.health
    end
  end

  steps[1145] = function()
    local p = player()
    check("player dungeon: stepping on a trap hurts", p.character and p.character.health < storage.pt_trap_health,
          p.character and p.character.health)
    if storage.pt_back then p.teleport(storage.pt_back) end
    local entries = {}
    for _, k in pairs(remote.call("sap-diary", "entries", p.force.name)) do entries[k] = true end
    check("player diary: trap entry", entries["dungeon-trap"] == true)
  end

  steps[1160] = function()
    local p = player()
    local exit = p.surface.find_entities_filtered({ name = "sap-dungeon-exit", limit = 1 })[1]
    check("player dungeon: exit near start", exit ~= nil)
    if exit then
      p.opened = exit
      local frame = p.gui.relative["sap_dungeon_frame"]
      if frame then remote.call("sap-core", "test_click", p.index, frame.go) end
    end
    check("player dungeon: came back up", p.surface.name == "nauvis", p.surface.name)
    local e = storage.pt_entrance
    check("player dungeon: returned near the entrance", e and e.valid
          and math.abs(p.position.x - e.position.x) + math.abs(p.position.y - e.position.y) < 20)
  end

  -- Древний узел: окно выбора концовки -------------------------------------------------
  steps[1200] = function()
    local p = player()
    remote.call("sap-core", "test_set_story_victory", false)
    local surface = p.surface
    local nexus = surface.create_entity({
      name = "sap-ancient-nexus", force = p.force,
      position = surface.find_non_colliding_position("sap-ancient-nexus", { p.position.x + 8, p.position.y }, 30, 1),
    })
    p.opened = nexus
    local frame = p.gui.relative["sap_story_frame"]
    check("player story: empty nexus asks for the cores", frame ~= nil and frame.restore ~= nil
          and not frame.restore.enabled and type(frame.label.caption) == "table"
          and frame.label.caption[1] == "sap-story.need-cores")
    for _, entry in pairs(prototypes.mod_data["sap-ancient-cores"].data) do nexus.insert({ name = entry.item, count = 1 }) end
    p.opened = nil
    p.opened = nexus
    frame = p.gui.relative["sap_story_frame"]
    check("player story: nexus window with three endings", frame ~= nil and frame.restore ~= nil
          and frame.inherit ~= nil and frame.seal ~= nil)
    if frame then remote.call("sap-core", "test_click", p.index, frame.restore) end
    check("player story: ending chosen from the window", remote.call("sap-core", "story_ending", p.force.name) == "restore")
    frame = p.gui.relative["sap_story_frame"]
    check("player story: go home / stay buttons", frame ~= nil and frame["return"] ~= nil and frame.stay ~= nil)
    if frame then remote.call("sap-core", "test_click", p.index, frame.stay) end
    check("player story: stayed", remote.call("sap-core", "story_stage", p.force.name) == "recharge")
    remote.call("sap-core", "test_story_recharge", p.force.name)
    p.opened = nil
    p.opened = nexus
    frame = p.gui.relative["sap_story_frame"]
    check("player story: chosen ending disabled, others enabled", frame ~= nil and not frame.restore.enabled
          and frame.seal.enabled and frame.unity == nil)
  end

  local function achieved(name) return remote.call("sap-core", "achievement_unlocked", player().index, name) end

  -- Достижения подземелья: вход, Смотритель без урона.
  steps[1220] = function()
    local p = player()
    check("player achievement: first dungeon", achieved("sap-first-dungeon"))
    check("player achievement: ending (awakening)", achieved("sap-ending-restore"))
    p.character.health = p.character.max_health
    remote.call("sap-core", "dungeon_enter", p.index, storage.pt_entrance)
    local rec = remote.call("sap-core", "dungeon_record", "nauvis")
    if rec.boss and rec.boss.valid then rec.boss.die() end
  end

  steps[1295] = function()
    check("player achievement: Warden slayer", achieved("sap-warden-slayer"))
    check("player achievement: flawless", achieved("sap-flawless"))
  end

  -- Смерть в подземелье (последней: дальше персонажа нет).
  steps[1300] = function()
    local p = player()
    local entrance = storage.pt_entrance
    if entrance and entrance.valid then remote.call("sap-core", "dungeon_enter", p.index, entrance) end
    if p.character then p.character.die() end
  end

  steps[1320] = function()
    local p = player()
    local entries = {}
    for _, k in pairs(remote.call("sap-diary", "entries", p.force.name)) do entries[k] = true end
    check("player diary: death in a dungeon", entries["dungeon-death"] == true)
  end

  -- Все ядра и все концовки (после смерти персонаж не нужен).
  steps[1330] = function()
    local p = player()
    for planet in pairs(prototypes.mod_data["sap-ancient-cores"].data) do
      remote.call("sap-core", "test_core_taken", p.force.name, planet)
    end
    check("player achievement: all cores", achieved("sap-all-cores"))
    local force = p.force.name
    -- Пробуждение уже выбрано и «остаться»; дальше Наследие, Печать, Единство.
    for _, ending in pairs({ "inherit", "seal", "unity" }) do
      remote.call("sap-core", "test_story_recharge", force)
      remote.call("sap-core", "story_choose", force, ending)
      if ending ~= "unity" then remote.call("sap-core", "story_decide", force, "stay") end
    end
    check("player achievement: unity", achieved("sap-ending-unity"))
    check("player achievement: all endings", achieved("sap-all-endings"))
  end

  steps[1360] = function() finish() end
end

return player_tests
