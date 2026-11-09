-- Дневник инженера (docs: Дневник).
--
-- Окно по клавише J. При первом открытии — выбор предыстории (только тон дневника).
-- Записи общие для команды: каждая появляется один раз, когда случается её событие.
-- Тексты — locale [sap-diary-title] / [sap-diary-text], ключи — как в docs/design/05-diary.md.
-- Модули планет добавляют записи через remote.call("sap-diary", "add", force_name, key).

local diary = {}

diary.TICK_INTERVAL = 5 * 60 * 60

local GUI_NAME = "sap_diary_frame"
local BACKGROUNDS = { corporate = "bg-corporate", loner = "bg-loner", history = "bg-history" }
local COMPANIES = { "Ironveil Industries", "Kessel Corp", "Aether Dynamics", "Redstone Collective", "Novum Frontier",
                    "Cascade Systems" }
local JOURNALS = { "aether", "cascade", "ironveil", "kessel", "loner", "novum", "redstone" }
local AWAY_TICKS = 2 * 60 * 60 * 60

-- Убийства: имя существа → { ключ, порог } (несколько порогов — несколько записей).
local KILLS = {
  ["sap-scorch"] = { { "kill-scorch-1", 1 }, { "kill-scorch-10", 10 } },
  ["sap-magmar"] = { { "kill-magmar", 1 } },
  ["sap-molten"] = { { "kill-molten", 1 } },
  ["sap-sentinel"] = { { "kill-sentinel", 1 } },
  ["sap-ripple"] = { { "kill-ripple", 1 } },
  ["sap-surf"] = { { "kill-surf", 1 } },
  ["sap-abyss"] = { { "kill-abyss", 1 } },
  ["sap-blizzard"] = { { "kill-blizzard", 1 } },
  ["sap-ice-guardian"] = { { "kill-guardian", 1 } },
  ["sap-frost"] = { { "kill-frost", 1 } },
  ["sap-bottomless"] = { { "kill-bottomless", 1 } },
}
local BITER_KILLS = { { "kill-biter-1", 1 }, { "kill-biter-10", 10 }, { "kill-biter-50", 50 } }

local SCOUT_ENTRY = { solaris = "scout-solaris", echaris = "scout-echaris", aquara = "scout-aquara", nivar = "scout-nivar" }

local function state()
  storage.diary = storage.diary or {}
  local s = storage.diary
  s.forces = s.forces or {}
  s.players = s.players or {}
  return s
end

local function force_state(force)
  local s = state()
  s.forces[force.index] = s.forces[force.index] or { entries = {}, seen = {}, kills = {}, built = 0, flags = {} }
  return s.forces[force.index]
end

local function player_state(player)
  local s = state()
  s.players[player.index] = s.players[player.index] or {}
  return s.players[player.index]
end

local function is_open(player)
  return player.gui.screen[GUI_NAME] ~= nil
end

local refresh

--- Добавляет запись команде (один раз на ключ). params — подстановки для текста.
function diary.add(force, key, params)
  if not (force and force.valid) then return end
  local fs = force_state(force)
  if fs.seen[key] then return end
  fs.seen[key] = true
  table.insert(fs.entries, { key = key, tick = game.tick, params = params })
  for _, player in pairs(force.players) do
    player.print({ "sap-diary.new-entry", { "sap-diary-title." .. key } }, { color = { r = 0.8, g = 0.7, b = 1 } })
    if is_open(player) then refresh(player) end
  end
end

-- Окно ----------------------------------------------------------------------------

local function add_entry(list, key, params, tick)
  local frame = list.add({ type = "frame", direction = "vertical", style = "inside_shallow_frame_with_padding" })
  frame.style.horizontally_stretchable = true
  local title = frame.add({ type = "label", caption = { "sap-diary-title." .. key } })
  title.style.font = "default-bold"
  if tick then
    title.caption = { "", { "sap-diary-title." .. key }, string.format("  [%d:%02d]", math.floor(tick / 216000), math.floor(tick / 3600) % 60) }
  end
  local text_key = { "sap-diary-text." .. key }
  for _, p in pairs(params or {}) do text_key[#text_key + 1] = p end
  local text = frame.add({ type = "label", caption = text_key })
  text.style.single_line = false
  text.style.maximal_width = 520
end

refresh = function(player)
  local frame = player.gui.screen[GUI_NAME]
  if not frame then return end
  frame.clear()
  local ps = player_state(player)
  if not ps.background then
    frame.add({ type = "label", caption = { "sap-diary.choose-background" } })
    local row = frame.add({ type = "flow", direction = "horizontal" })
    for id in pairs(BACKGROUNDS) do
      row.add({ type = "button", caption = { "sap-diary.background-" .. id }, tags = { sap_action = "diary-background", id = id } })
    end
    return
  end
  local scroll = frame.add({ type = "scroll-pane", direction = "vertical" })
  scroll.style.maximal_height = 600
  scroll.style.minimal_width = 560
  local entries = force_state(player.force).entries
  for i = #entries, 1, -1 do
    local e = entries[i]
    add_entry(scroll, e.key, e.params, e.tick)
  end
  add_entry(scroll, BACKGROUNDS[ps.background])
end

function diary.toggle(event)
  local player = game.get_player(event.player_index)
  if not player then return end
  local frame = player.gui.screen[GUI_NAME]
  if frame then
    frame.destroy()
    return
  end
  frame = player.gui.screen.add({ type = "frame", name = GUI_NAME, direction = "vertical", caption = { "sap-diary.title" } })
  frame.auto_center = true
  refresh(player)
end

function diary.on_gui_click(event)
  local element = event.element
  if not (element and element.valid and element.tags and element.tags.sap_action == "diary-background") then return end
  local player = game.get_player(event.player_index)
  if not player then return end
  player_state(player).background = element.tags.id
  refresh(player)
end

-- События --------------------------------------------------------------------------

function diary.on_entity_died(event)
  local entity, cause = event.entity, event.cause
  local force = event.force or (cause and cause.valid and cause.force)
  if not (entity and entity.valid and force and force.valid) or force.name == "enemy" or force.name == "neutral" then return end
  local name = entity.name
  if string.sub(name, 1, 12) == "sap-captive-" or name == "captive-biter-spawner" then
    diary.add(entity.force, "capture-starved")
    return
  end
  if entity.surface.platform and event.cause and event.cause.valid and event.cause.type == "asteroid" then
    diary.add(entity.force, "asteroid-hit")
    return
  end
  if entity.force.name ~= "enemy" or (entity.type ~= "unit" and entity.type ~= "spider-unit") then return end
  local rules = KILLS[name]
  local counter = name
  if not rules and (string.find(name, "biter") or string.find(name, "spitter")) then
    rules, counter = BITER_KILLS, "biter"
  end
  if not rules then return end
  local fs = force_state(force)
  fs.kills[counter] = (fs.kills[counter] or 0) + 1
  for _, rule in pairs(rules) do
    if fs.kills[counter] >= rule[2] then diary.add(force, rule[1]) end
  end
end

function diary.on_built(event)
  local entity = event.entity
  if not (entity and entity.valid) then return end
  local force, surface, name = entity.force, entity.surface.name, entity.name
  local fs = force_state(force)
  fs.built = fs.built + 1
  if fs.built >= 1000 then diary.add(force, "buildings-1000") end
  if name == "pumpjack" or name == "sap-pumpjack-mk2" then
    local resource = entity.surface.find_entities_filtered({ type = "resource", position = entity.position, radius = 1, limit = 1 })[1]
    if resource and resource.name == "sulfuric-acid-geyser" then
      diary.add(force, "res-acid")
      diary.add(force, "build-acid-pumpjack")
    elseif resource then
      diary.add(force, "res-oil")
      diary.add(force, "build-pumpjack")
    end
    if name == "sap-pumpjack-mk2" then diary.add(force, "build-pumpjack-mk2") end
  elseif name == "offshore-pump" and surface == "vulcanus" then
    diary.add(force, "res-lava")
  elseif name == "offshore-pump" and surface == "solaris" then
    diary.add(force, "build-solaris-offshore")
  elseif name == "sap-heavy-duty-pump" and surface == "solaris" then
    diary.add(force, "res-solaris-lava")
    diary.add(force, "build-heavy-pump")
  elseif name == "sap-deep-drill" or name == "sap-deep-drill-mk2" then
    diary.add(force, "build-deep-drill")
  elseif name == "sap-underwater-drill" then
    diary.add(force, "build-underwater-drill")
  elseif entity.type == "locomotive" then
    diary.add(force, "first-train")
  elseif entity.type == "reactor" then
    diary.add(force, "first-reactor")
  end
end

function diary.on_player_crafted_item(event)
  local player = game.get_player(event.player_index)
  if player and event.item_stack.valid_for_read and event.item_stack.name == "construction-robot" then
    diary.add(player.force, "first-robot")
  end
end

function diary.on_player_mined_item(event)
  local player = game.get_player(event.player_index)
  local name = event.item_stack and event.item_stack.name
  if not player then return end
  if name == "sap-cryolite" then diary.add(player.force, "res-cryolite") end
  if name == "sap-nivalite" then diary.add(player.force, "res-nivalite") end
end

function diary.on_rocket_launched(event)
  if event.rocket_silo and event.rocket_silo.valid then diary.add(event.rocket_silo.force, "first-rocket") end
end

function diary.on_player_changed_surface(event)
  local player = game.get_player(event.player_index)
  if not player then return end
  local surface = player.surface
  if surface.platform then
    diary.add(player.force, "first-platform")
  elseif surface.planet and surface.name ~= "nauvis" and surface.name ~= "nivar-caves" then
    diary.add(player.force, "first-visit")
  end
  if surface.name == "nauvis" then player_state(player).last_nauvis = game.tick end
end

function diary.on_player_died(event)
  local player = game.get_player(event.player_index)
  if not player then return end
  local surface = player.surface.name
  if surface == "solaris" then
    diary.add(player.force, "death-solaris")
  elseif surface == "nivar" or surface == "nivar-caves" then
    diary.add(player.force, "death-nivar")
  elseif event.cause and event.cause.valid and event.cause.type == "unit" then
    diary.add(player.force, "death-biters")
  end
end

function diary.on_entity_damaged(event)
  local entity = event.entity
  if not (entity and entity.valid and entity.type == "character") then return end
  if event.final_health > 0 and event.final_health < entity.max_health * 0.1 then
    diary.add(entity.force, "survived")
  end
end

--- Обломок с картами открыт игроком.
function diary.on_wreck_opened(player, wreck)
  local surface = wreck.surface.name
  local inventory = wreck.get_inventory(defines.inventory.chest)
  if surface == "nauvis" and inventory and inventory.get_item_count("sap-data-card-cryotech") > 0 then
    diary.add(player.force, "find-cold-blueprints")
  elseif surface == "solaris" then
    diary.add(player.force, "find-solaris-wreck")
  elseif surface == "echaris" and wreck.name == "sap-center-suppression" then
    diary.add(player.force, "find-echaris-military")
  end
  local fs = force_state(player.force)
  fs.flags.wrecks = (fs.flags.wrecks or 0) + 1
  -- Бортовые журналы других экспедиций.
  local journal = JOURNALS[(fs.flags.wrecks - 1) % #JOURNALS + 1]
  diary.add(player.force, "journal-" .. journal)
  if fs.flags.wrecks == 5 then diary.add(player.force, "journal-own") end
  if fs.flags.wrecks == 9 then diary.add(player.force, "journal-last") end
end

--- Дешифратор открыл технологию.
function diary.on_tech_unlocked(force, tech_name, quality, category, was_unlocked)
  if was_unlocked then diary.add(force, "tech-duplicate") end
  if quality ~= "normal" then diary.add(force, "quality-" .. quality) end
  if string.find(tech_name, "%-2$") or string.find(tech_name, "mk2") then
    diary.add(force, "tech-mk2", { COMPANIES[math.random(1, #COMPANIES)] })
  end
  if tech_name == "construction-robotics" or tech_name == "logistic-robotics" then diary.add(force, "tech-roboport") end
  if category == "military" or category == "sap-military" then diary.add(force, "tech-military") end
  if category == "cryotech" then diary.add(force, "tech-other-planet") end
  if category == "alien" then diary.add(force, "tech-alien") end
end

--- Запуски спутников (scripts/exploration.lua).
function diary.on_satellite(force, kind, planet, launches)
  if kind == "mk1" then
    diary.add(force, "sat-first")
    if launches >= 5 then diary.add(force, "sat-five-lost") end
  elseif kind == "mk1-found" then
    diary.add(force, "sat-weak-signal")
  elseif kind == "mk1-nothing" then
    diary.add(force, "sat-nothing")
  elseif kind == "mk2-ready" then
    diary.add(force, "sat-mk2-ready")
  elseif kind == "scouted" and SCOUT_ENTRY[planet] then
    diary.add(force, SCOUT_ENTRY[planet])
  end
end

--- Первая межпланетная доставка: капсула с грузом с платформы села на планету.
function diary.on_cargo_pod_finished_descending(event)
  local pod = event.cargo_pod
  if event.player_index or not (pod and pod.valid) then return end
  local origin = pod.cargo_pod_origin
  if origin and origin.valid and origin.surface.platform and pod.surface.planet then
    diary.add(origin.force, "first-delivery")
  end
end

local AUTONOMOUS_MACHINES = 30
local DEADLOCK_MACHINES = 10
local DEADLOCK_SHARE = 0.8

--- Раз в 5 минут: база на автомате, дедлок производства, первый пойманный улей Наувиса.
local function check_base(force)
  local working, starving, total = 0, 0, 0
  for _, surface in pairs(game.surfaces) do
    if not surface.platform then
      for _, machine in pairs(surface.find_entities_filtered({ type = "assembling-machine", force = force, limit = 500 })) do
        total = total + 1
        local status = machine.status
        if status == defines.entity_status.working then
          working = working + 1
        elseif status == defines.entity_status.item_ingredient_shortage or status == defines.entity_status.no_ingredients then
          starving = starving + 1
        end
      end
      if force_state(force).seen["capture-nauvis"] == nil and surface.name == "nauvis"
          and surface.count_entities_filtered({ name = "captive-biter-spawner", force = force, limit = 1 }) > 0 then
        diary.add(force, "capture-nauvis")
      end
    end
  end
  if working >= AUTONOMOUS_MACHINES then diary.add(force, "base-autonomous") end
  if total >= DEADLOCK_MACHINES and starving >= total * DEADLOCK_SHARE then diary.add(force, "deadlock") end
end

--- Для тестов: проверить базу команды сразу.
function diary.check_base_now(force)
  check_base(force)
end

function diary.on_tick()
  for _, force in pairs(game.forces) do
    if force.name ~= "enemy" and force.name ~= "neutral" and #force.players > 0 then check_base(force) end
  end
  for _, player in pairs(game.connected_players) do
    local ps = player_state(player)
    if player.surface.name == "nauvis" then
      ps.last_nauvis = game.tick
    elseif ps.last_nauvis and game.tick - ps.last_nauvis > AWAY_TICKS then
      diary.add(player.force, "away-from-home")
    end
  end
end

return diary
