-- Постоянная магнитная буря Echaris.
--
-- Машины: surface.global_effect замедляет все машины; стабилизаторы (маяки) получают
--         скрытый модуль, который ровно компенсирует текущий уровень бури в их зоне.
-- Дроны (решение I6, смешанный вариант): вне зоны стабилизатора дроны получают урон и
--         разряжаются; роботодоки вне зоны теряют энергию и не заряжают дронов.
--         Factorio не позволяет скриптом выключить роботодок, поэтому "сидят дома"
--         сделано через обесточивание.

local storm = {}

storm.TICK_INTERVAL = 120 -- раз в 2 секунды

local SURFACE = "echaris"
local STABILIZER = "sap-storm-stabilizer"
local PENALTY = { 0.3, 0.4, 0.5 } -- замедление машин по уровням бури
local LEVEL_MIN_TICKS = 3 * 60 * 60 -- уровень держится 3-8 минут
local LEVEL_MAX_TICKS = 8 * 60 * 60
local ROBOT_DAMAGE_FRACTION = 0.04 -- доля здоровья за проверку
local ROBOT_ENERGY_DRAIN = 0.15 -- доля энергии за проверку
local PROTECTED_ROBOTS = { -- дроны Mk2 со встроенной защитой от бури
  ["sap-logistic-robot-mk2"] = true,
  ["sap-construction-robot-mk2"] = true,
}

local function state()
  storage.storm = storage.storm or { level = 2, next_change = 0, stabilizers = {} }
  return storage.storm
end

local function get_surface()
  local surface = game.get_surface(SURFACE)
  return surface and surface.valid and surface or nil
end

local function zone_radius()
  return prototypes.entity[STABILIZER].get_supply_area_distance() + 1
end

local function protected(surface, position, radius)
  return surface.count_entities_filtered({
    name = STABILIZER, position = position, radius = radius, limit = 1,
  }) > 0
end

-- Модули стабилизаторов -------------------------------------------------------

local function refresh_stabilizer(entity, level)
  local inventory = entity.get_module_inventory()
  if not inventory then return end
  local wanted = "sap-storm-compensation-" .. level
  if inventory.get_item_count(wanted) == 1 and #inventory.get_contents() == 1 then return end
  inventory.clear()
  inventory.insert({ name = wanted, count = 1 })
end

local function refresh_all_stabilizers(surface, level)
  for _, entity in pairs(surface.find_entities_filtered({ name = STABILIZER })) do
    refresh_stabilizer(entity, level)
  end
end

function storm.on_stabilizer_built(event)
  local entity = event.entity
  if entity and entity.valid and entity.surface.name == SURFACE then
    refresh_stabilizer(entity, state().level)
  elseif entity and entity.valid then
    -- Вне Echaris стабилизатор не нужен и не должен ускорять машины.
    local inventory = entity.get_module_inventory()
    if inventory then inventory.clear() end
  end
end

-- Уровень бури ----------------------------------------------------------------

local function apply_level(surface, level)
  surface.global_effect = { speed = -PENALTY[level] }
  refresh_all_stabilizers(surface, level)
end

local function update_level(surface)
  local s = state()
  if game.tick < s.next_change then return end
  s.level = math.random(1, #PENALTY)
  s.next_change = game.tick + math.random(LEVEL_MIN_TICKS, LEVEL_MAX_TICKS)
  apply_level(surface, s.level)
end

-- Дроны и роботодоки -----------------------------------------------------------

local function hit_robots(surface, radius)
  local robots = surface.find_entities_filtered({ type = { "construction-robot", "logistic-robot" } })
  for _, robot in pairs(robots) do
    if robot.valid and not PROTECTED_ROBOTS[robot.name] and not protected(surface, robot.position, radius) then
      robot.energy = robot.energy * (1 - ROBOT_ENERGY_DRAIN)
      robot.damage(robot.max_health * ROBOT_DAMAGE_FRACTION, "neutral", "electric")
    end
  end
end

local function drain_roboports(surface, radius)
  for _, roboport in pairs(surface.find_entities_filtered({ type = "roboport" })) do
    if not protected(surface, roboport.position, radius) then
      roboport.energy = 0
    end
  end
end

-- События ---------------------------------------------------------------------

function storm.on_tick()
  local surface = get_surface()
  if not surface then return end
  update_level(surface)
  refresh_all_stabilizers(surface, state().level) -- вдруг модуль вынули вручную
  local radius = zone_radius()
  hit_robots(surface, radius)
  drain_roboports(surface, radius)
end

function storm.on_surface_created(event)
  local surface = game.get_surface(event.surface_index)
  if surface and surface.name == SURFACE then
    apply_level(surface, state().level)
  end
end

function storm.on_init()
  state()
  local surface = get_surface()
  if surface then apply_level(surface, state().level) end
end

function storm.on_configuration_changed()
  storm.on_init()
end

return storm
