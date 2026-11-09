-- Механиты Echaris — runtime (docs: Планеты → Echaris).
--
-- Зоны и центры: при генерации карты Echaris скрипт ставит центры захвата и вокруг них
--   серверы контроля. Чем дальше от точки высадки, тем больше серверов и тем они тяжелее.
--   Рядом с точкой высадки — нейтральная зона без Механитов (хардкор убирает её).
--   Центр открывается, только когда рядом не осталось серверов.
-- Sentinel-09: при первом уроне вызывает подкрепления.
-- Overseer: при смерти — тревога, все Механиты рядом идут к месту его гибели.
-- Disruptor: ЭМИ — рядом с ним турели игрока отключаются, дроны разряжаются.
-- Хардкор «Волны по таймеру»: Механиты атакуют по расписанию.

local mechanites = {}

local function diary_add(force, key)
  if force and force.valid and remote.interfaces["sap-diary"] then remote.call("sap-diary", "add", force.name, key) end
end

mechanites.TICK_INTERVAL = 120
mechanites.WAVE_INTERVAL = 10 * 60 * 60

local SURFACE = "echaris"
local CENTER_CHANCE = 1 / 20
local NEUTRAL_RADIUS = 160
local NEUTRAL_RADIUS_HARDCORE = 32
local HEAVY_DISTANCE = 600
local CENTER_LOCK_RADIUS = 40
local SERVERS = { "sap-control-server", "sap-control-server-heavy" }
local CENTERS = {
  data = { "automation", "logistics", "production", "military", "energy", "robotics", "space" },
  suppression = { "military", "sap-military" },
  assembly = { "automation", "logistics", "production" },
  energy = { "energy", "sap-energy" },
}
local CENTER_TYPES = { "data", "suppression", "assembly", "energy" }
local REINFORCEMENTS = 3
local ALARM_RADIUS = 80
local EMP_RADIUS = 10
local EMP_TICKS = 5 * 60
local WAVE_SIZE = 10

local function state()
  storage.mechanites = storage.mechanites or {}
  local s = storage.mechanites
  s.called = s.called or {}
  s.disabled_turrets = s.disabled_turrets or {}
  return s
end

local function hardcore(name)
  return settings.startup[name].value
end

-- Генерация зон -----------------------------------------------------------------

local function card_quality(distance)
  local archive = game.forces.player.technologies["sap-archive-decipherer"]
  local bonus = archive and archive.researched and 0.2 or 0
  local roll = math.random() + math.min(distance / 3000, 0.6) + bonus
  return roll > 1.45 and "legendary" or roll > 1.3 and "epic" or roll > 1.1 and "rare"
    or roll > 0.85 and "uncommon" or "normal"
end

local function place(surface, name, near, radius, force)
  local position = surface.find_non_colliding_position(name, near, radius, 1)
  if not position then return nil end
  return surface.create_entity({ name = name, position = position, force = force })
end

-- Во время генерации участка соседние ещё не готовы и места часто не хватает,
-- поэтому участки копятся в очереди, а центры ставятся на следующих проверках.
function mechanites.on_chunk_generated(event)
  local surface = event.surface
  if not (surface and surface.valid and surface.name == SURFACE) then return end
  local area = event.area
  local center_pos = { x = (area.left_top.x + area.right_bottom.x) / 2, y = (area.left_top.y + area.right_bottom.y) / 2 }
  local distance = math.sqrt(center_pos.x ^ 2 + center_pos.y ^ 2)
  local neutral = hardcore("sap-hardcore-echaris-no-neutral-zone") and NEUTRAL_RADIUS_HARDCORE or NEUTRAL_RADIUS
  if distance < neutral or math.random() >= CENTER_CHANCE then return end
  local s = state()
  s.queue = s.queue or {}
  s.queue[#s.queue + 1] = { position = center_pos, distance = distance }
end

local function build_zone(surface, center_pos, distance)
  local center_type = CENTER_TYPES[math.random(1, #CENTER_TYPES)]
  local center = place(surface, "sap-center-" .. center_type, center_pos, 32, "neutral")
  if not center then return end
  local inventory = center.get_inventory(defines.inventory.chest)
  local categories = CENTERS[center_type]
  for _ = 1, math.random(2, 3) do
    local category = categories[math.random(1, #categories)]
    if prototypes.item["sap-data-card-" .. category] then
      inventory.insert({ name = "sap-data-card-" .. category, count = 1, quality = card_quality(distance) })
    end
  end

  local count = 1 + math.floor(distance / 500)
  for _ = 1, math.min(count, 6) do
    local server = distance > HEAVY_DISTANCE and math.random() < 0.5 and SERVERS[2] or SERVERS[1]
    local offset = { x = center.position.x + math.random(-14, 14), y = center.position.y + math.random(-14, 14) }
    place(surface, server, offset, 16, "enemy")
  end
end

local function process_queue(surface)
  local s = state()
  if not s.queue or #s.queue == 0 then return end
  local queue = s.queue
  s.queue = {}
  for _, item in pairs(queue) do
    build_zone(surface, item.position, item.distance)
  end
end

function mechanites.on_gui_opened(event)
  local entity = event.entity
  if not (entity and entity.valid and string.sub(entity.name, 1, 11) == "sap-center-") then return end
  local servers = entity.surface.count_entities_filtered({
    name = SERVERS, position = entity.position, radius = CENTER_LOCK_RADIUS, limit = 1,
  })
  if servers == 0 and entity.name == "sap-center-suppression" then
    local player = game.get_player(event.player_index)
    if player then diary_add(player.force, "find-echaris-military") end
  end
  if servers > 0 then
    local player = game.get_player(event.player_index)
    if player then
      player.opened = nil
      player.print({ "sap-mechanites.center-locked" })
    end
  end
end

-- Поведение ---------------------------------------------------------------------

local function attack(unit, position)
  local commandable = unit.commandable
  if commandable then
    commandable.set_command({
      type = defines.command.attack_area, destination = position, radius = 16,
      distraction = defines.distraction.by_enemy,
    })
  end
end

function mechanites.on_entity_damaged(event)
  local entity = event.entity
  if not (entity and entity.valid and entity.name == "sap-sentinel") then return end
  local s = state()
  if s.called[entity.unit_number] then return end
  s.called[entity.unit_number] = true
  if event.cause and event.cause.valid then diary_add(event.cause.force, "reinforcements") end
  local target = event.cause and event.cause.valid and event.cause.position or entity.position
  for _ = 1, REINFORCEMENTS do
    local unit = place(entity.surface, "sap-stormbringer", entity.position, 8, entity.force)
    if unit then attack(unit, target) end
  end
end

function mechanites.on_entity_died(event)
  local entity = event.entity
  if not (entity and entity.valid) then return end
  if entity.name == "sap-sentinel" then
    state().called[entity.unit_number] = nil
  elseif entity.name == "sap-overseer" then
    local units = entity.surface.find_entities_filtered({
      type = "unit", force = entity.force, position = entity.position, radius = ALARM_RADIUS,
    })
    for _, unit in pairs(units) do
      if unit.valid then attack(unit, entity.position) end
    end
    if event.cause and event.cause.valid and event.cause.force then
      event.cause.force.print({ "sap-mechanites.alarm", #units })
    end
  end
end

local function emp(surface)
  local s = state()
  for _, disruptor in pairs(surface.find_entities_filtered({ name = "sap-disruptor" })) do
    local targets = surface.find_entities_filtered({
      type = { "ammo-turret", "electric-turret", "fluid-turret" },
      position = disruptor.position, radius = EMP_RADIUS,
    })
    for _, turret in pairs(targets) do
      if turret.force ~= disruptor.force then
        diary_add(turret.force, "emp-disruptor")
        turret.disabled_by_script = true
        s.disabled_turrets[turret.unit_number] = { entity = turret, until_tick = game.tick + EMP_TICKS }
      end
    end
    for _, robot in pairs(surface.find_entities_filtered({
      type = { "construction-robot", "logistic-robot" }, position = disruptor.position, radius = EMP_RADIUS,
    })) do
      robot.energy = 0
    end
  end
  for id, info in pairs(s.disabled_turrets) do
    if not info.entity.valid then
      s.disabled_turrets[id] = nil
    elseif game.tick >= info.until_tick then
      info.entity.disabled_by_script = false
      s.disabled_turrets[id] = nil
    end
  end
end

function mechanites.on_tick()
  local surface = game.get_surface(SURFACE)
  if surface then
    process_queue(surface)
    emp(surface)
  end
end

function mechanites.on_wave_tick()
  if not hardcore("sap-hardcore-echaris-timed-waves") then return end
  local surface = game.get_surface(SURFACE)
  if not surface then return end
  local servers = surface.find_entities_filtered({ name = SERVERS })
  if #servers == 0 then return end
  local targets = surface.find_entities_filtered({ force = "player", type = { "assembling-machine", "furnace",
    "mining-drill", "roboport", "electric-pole", "container" }, limit = 200 })
  if #targets == 0 then return end
  local server = servers[math.random(1, #servers)]
  local target = targets[math.random(1, #targets)].position
  for _ = 1, WAVE_SIZE do
    local unit = place(surface, "sap-sentinel", server.position, 12, server.force)
    if unit then attack(unit, target) end
  end
  game.forces.player.print({ "sap-mechanites.wave",
    string.format("[gps=%d,%d,%s]", target.x, target.y, SURFACE) })
end

return mechanites
