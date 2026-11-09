-- Бури и торнадо Aquara (docs: Планеты → Aquara → Бури и торнадо; A2, A3).
--
-- Сила бури: 0 (штиль), 1 слабая, 2 средняя, 3 сильная; меняется каждые 3-8 минут.
-- Буря снижает производительность машин (surface.global_effect). Хардкор «постоянная буря»
-- убирает штиль.
-- Торнадо появляются во время бури рядом с постройками и медленно ползут к ним. Постройки
-- рядом с торнадо получают урон, если не стоят под работающим штормовым щитом. Штормовой
-- якорь притягивает торнадо: дойдя до якоря, торнадо рассеивается и заряжает его.

local storm = {}

storm.TICK_INTERVAL = 60

local SURFACE = "aquara"
local SHIELD = "sap-storm-shield"
local ANCHORS = { "sap-storm-anchor", "sap-storm-anchor-mk2" }
local FORECAST_TICKS = 60 * 60
local SHIELD_RADIUS = 20
local ANCHOR_PULL_RADIUS = 48
local LEVEL_MIN_TICKS, LEVEL_MAX_TICKS = 3 * 60 * 60, 8 * 60 * 60
local SPEED_PENALTY = { 0.1, 0.2, 0.3 }
local SPAWN_EVERY = 10 -- проверок (секунд)
local SPAWN_CHANCE = { 0.15, 0.3, 0.5 }
local SPAWN_DISTANCE = 60
local STEP = 2
local LIFETIME = 120 -- проверок
local DAMAGE_RADIUS = 4
local DAMAGE = { 20, 40, 70 }
local ANCHOR_ENERGY = 40000000 -- Дж за пойманное торнадо, умножается на силу

local function state()
  storage.aquara_storm = storage.aquara_storm or { level = 0, next_change = 0, tornadoes = {}, counter = 0 }
  return storage.aquara_storm
end

local function permanent()
  return settings.startup["sap-hardcore-aquara-permanent-storm"].value
end

local function apply_level(surface, level)
  surface.global_effect = level > 0 and { speed = -SPEED_PENALTY[level] } or nil
end

local function forecast(s)
  if s.forecasted or game.tick < s.next_change - FORECAST_TICKS then return end
  s.forecasted = true
  for _, force in pairs(game.forces) do
    local tech = force.technologies["sap-storm-forecaster"]
    if tech and tech.researched then force.print({ "sap-aquara.forecast" }) end
  end
end

local function update_level(surface, s)
  forecast(s)
  if game.tick < s.next_change then return end
  s.forecasted = false
  local min = permanent() and 1 or 0
  s.level = math.random(min, 3)
  s.next_change = game.tick + math.random(LEVEL_MIN_TICKS, LEVEL_MAX_TICKS)
  apply_level(surface, s.level)
  if s.level > 0 then
    game.forces.player.print({ "sap-aquara.storm-" .. s.level })
  end
end

local function shielded(surface, position)
  for _, shield in pairs(surface.find_entities_filtered({ name = SHIELD, position = position, radius = SHIELD_RADIUS })) do
    if shield.is_connected_to_electric_network() then return true end
  end
  return false
end

local function spawn_tornado(surface, s)
  local targets = surface.find_entities_filtered({ force = "player", type = { "assembling-machine", "furnace",
    "mining-drill", "electric-pole", "container", "accumulator", "radar" }, limit = 200 })
  if #targets == 0 then return end
  local target = targets[math.random(1, #targets)]
  local angle = math.random() * 2 * math.pi
  local position = {
    x = target.position.x + math.cos(angle) * SPAWN_DISTANCE,
    y = target.position.y + math.sin(angle) * SPAWN_DISTANCE,
  }
  s.tornadoes[#s.tornadoes + 1] = { position = position, target = target.position, strength = s.level, life = LIFETIME }
end

local function move_towards(from, to, step)
  local dx, dy = to.x - from.x, to.y - from.y
  local length = math.sqrt(dx * dx + dy * dy)
  if length <= step then return { x = to.x, y = to.y }, length end
  return { x = from.x + dx / length * step, y = from.y + dy / length * step }, length
end

local function update_tornado(surface, tornado)
  local anchor = surface.find_entities_filtered({
    name = ANCHORS, position = tornado.position, radius = ANCHOR_PULL_RADIUS, limit = 1,
  })[1]
  local goal = anchor and anchor.position or tornado.target
  local position, distance = move_towards(tornado.position, goal, STEP)
  tornado.position = position
  tornado.life = tornado.life - 1

  if anchor and distance <= STEP then
    local buffer = anchor.electric_buffer_size or 0
    anchor.energy = math.min(buffer, anchor.energy + ANCHOR_ENERGY * tornado.strength)
    return false
  end

  surface.create_trivial_smoke({ name = "smoke-fast", position = position })
  surface.create_trivial_smoke({ name = "smoke-fast", position = { position.x + 1, position.y - 1 } })
  if not shielded(surface, position) then
    for _, entity in pairs(surface.find_entities_filtered({
      force = "player", position = position, radius = DAMAGE_RADIUS,
    })) do
      if entity.valid and entity.is_entity_with_health and entity.type ~= "character" then
        entity.damage(DAMAGE[tornado.strength] or DAMAGE[1], "neutral", "physical")
      end
    end
  end
  if distance <= STEP then
    -- Дошло до цели — выбирает следующую цель рядом.
    tornado.target = { x = position.x + math.random(-30, 30), y = position.y + math.random(-30, 30) }
  end
  return tornado.life > 0
end

function storm.on_tick()
  local surface = game.get_surface(SURFACE)
  if not surface then return end
  local s = state()
  update_level(surface, s)
  s.counter = s.counter + 1
  if s.level > 0 and s.counter % SPAWN_EVERY == 0 and math.random() < SPAWN_CHANCE[s.level] then
    spawn_tornado(surface, s)
  end
  local alive = {}
  for _, tornado in pairs(s.tornadoes) do
    if update_tornado(surface, tornado) then alive[#alive + 1] = tornado end
  end
  s.tornadoes = alive
end

--- Для тестов и отладки: создать торнадо в точке.
function storm.spawn_at(position, target, strength)
  local s = state()
  s.tornadoes[#s.tornadoes + 1] = { position = position, target = target, strength = strength or 1, life = LIFETIME }
end

function storm.on_init()
  state()
end

return storm
