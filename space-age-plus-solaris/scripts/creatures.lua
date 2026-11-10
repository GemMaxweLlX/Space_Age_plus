-- Лавовые существа Solaris: гнёзда Скорчей и Магмаров, одиночки-Молтены.
-- Расставляются при генерации карты (через очередь — соседние участки ещё не готовы).
-- Хардкор «агрессивные мобы»: существа регулярно атакуют постройки.

local sap_settings = require("__space-age-plus-core__.sap_settings")

local creatures = {}

creatures.TICK_INTERVAL = 121
creatures.ATTACK_INTERVAL = 5 * 60 * 60

local SURFACE = "solaris"
local NEST_CHANCE = 1 / 18
local MOLTEN_CHANCE = 1 / 60
local SAFE_RADIUS = 120
local MOLTEN_DISTANCE = 400
local ATTACK_GROUP = 6

local function state()
  storage.creatures = storage.creatures or { queue = {} }
  return storage.creatures
end

local function place(surface, name, near, radius)
  local position = surface.find_non_colliding_position(name, near, radius, 1)
  if not position then return nil end
  return surface.create_entity({ name = name, position = position, force = "enemy" })
end

function creatures.on_chunk_generated(event)
  local surface = event.surface
  if not (surface and surface.valid and surface.name == SURFACE) then return end
  local area = event.area
  local center = { x = (area.left_top.x + area.right_bottom.x) / 2, y = (area.left_top.y + area.right_bottom.y) / 2 }
  local distance = math.sqrt(center.x ^ 2 + center.y ^ 2)
  if distance < SAFE_RADIUS then return end
  local queue = state().queue
  if math.random() < NEST_CHANCE then
    queue[#queue + 1] = { kind = math.random() < 0.6 and "sap-scorch-nest" or "sap-magmar-nest", position = center }
  end
  if distance > MOLTEN_DISTANCE and math.random() < MOLTEN_CHANCE then
    queue[#queue + 1] = { kind = "sap-molten", position = center }
  end
end

local function setup_daylight(surface)
  -- День 80% времени: короткие сумерки и короткая ночь.
  surface.dusk = 0.4
  surface.evening = 0.45
  surface.morning = 0.55
  surface.dawn = 0.6
end

function creatures.on_surface_created(event)
  local surface = game.get_surface(event.surface_index)
  if surface and surface.name == SURFACE then setup_daylight(surface) end
end

function creatures.on_tick()
  local surface = game.get_surface(SURFACE)
  if not surface then return end
  local s = state()
  if #s.queue == 0 then return end
  local queue = s.queue
  s.queue = {}
  for _, item in pairs(queue) do
    place(surface, item.kind, item.position, 24)
  end
end

function creatures.on_attack_tick()
  if not sap_settings.get("sap-hardcore-solaris-aggressive") then return end
  local surface = game.get_surface(SURFACE)
  if not surface then return end
  local nests = surface.find_entities_filtered({ name = { "sap-scorch-nest", "sap-magmar-nest" } })
  local targets = surface.find_entities_filtered({ force = "player", type = { "assembling-machine", "furnace",
    "mining-drill", "electric-pole", "container" }, limit = 200 })
  if #nests == 0 or #targets == 0 then return end
  local nest = nests[math.random(1, #nests)]
  local target = targets[math.random(1, #targets)].position
  local kind = nest.name == "sap-scorch-nest" and "sap-scorch" or "sap-magmar"
  for _ = 1, ATTACK_GROUP do
    local unit = place(surface, kind, nest.position, 10)
    if unit and unit.commandable then
      unit.commandable.set_command({ type = defines.command.attack_area, destination = target, radius = 16 })
    end
  end
end

function creatures.on_init()
  state()
  local surface = game.get_surface(SURFACE)
  if surface then setup_daylight(surface) end
end

return creatures
