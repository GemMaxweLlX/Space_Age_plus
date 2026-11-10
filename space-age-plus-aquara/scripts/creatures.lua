-- Водные пентаподы Aquara: гнёзда Ряби и Прибоя, одиночки-Бездны.
-- Расставляются при генерации карты через очередь (соседние участки ещё не готовы).
-- Хардкор «агрессивные мобы»: пентаподы регулярно атакуют постройки.

local sap_settings = require("__space-age-plus-core__.sap_settings")

local creatures = {}

creatures.TICK_INTERVAL = 121
creatures.ATTACK_INTERVAL = 5 * 60 * 60

local SURFACE = "aquara"
local NEST_CHANCE = 1 / 10
local ABYSS_CHANCE = 1 / 50
local SAFE_RADIUS = 120
local ABYSS_DISTANCE = 350
local ATTACK_GROUP = 5

local function state()
  storage.aquara_creatures = storage.aquara_creatures or { queue = {} }
  return storage.aquara_creatures
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
  if math.random() < NEST_CHANCE then queue[#queue + 1] = { kind = "sap-aquara-nest", position = center } end
  if distance > ABYSS_DISTANCE and math.random() < ABYSS_CHANCE then
    queue[#queue + 1] = { kind = "sap-abyss", position = center }
  end
end

function creatures.on_tick()
  local surface = game.get_surface(SURFACE)
  if not surface then return end
  local s = state()
  if #s.queue == 0 then return end
  local queue = s.queue
  s.queue = {}
  for _, item in pairs(queue) do place(surface, item.kind, item.position, 64) end
end

function creatures.on_attack_tick()
  if not sap_settings.get("sap-hardcore-aquara-aggressive") then return end
  local surface = game.get_surface(SURFACE)
  if not surface then return end
  local nests = surface.find_entities_filtered({ name = "sap-aquara-nest" })
  local targets = surface.find_entities_filtered({ force = "player", type = { "assembling-machine", "furnace",
    "mining-drill", "electric-pole", "container" }, limit = 200 })
  if #nests == 0 or #targets == 0 then return end
  local nest = nests[math.random(1, #nests)]
  local target = targets[math.random(1, #targets)].position
  for _ = 1, ATTACK_GROUP do
    local unit = place(surface, "sap-ripple", nest.position, 10)
    if unit and unit.commandable then
      unit.commandable.set_command({ type = defines.command.attack_area, destination = target, radius = 16 })
    end
  end
end

function creatures.on_init()
  state()
end

return creatures
