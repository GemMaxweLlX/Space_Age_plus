-- Перегрев механизмов на Solaris (docs: Планеты → Solaris → Перегрев).
--
-- Стадии: нормальная → горячая → критическая (машина останавливается) → сломана (урон).
-- Подключённый к сети радиатор охлаждения рядом снижает нагрев своих соседей.

local overheat = {}

overheat.TICK_INTERVAL = 300 -- раз в 5 секунд

local SURFACE = "solaris"
local RADIATOR = "sap-radiator"
local RADIATOR_RADIUS = 6
local MACHINE_TYPES = { "assembling-machine", "furnace", "mining-drill", "lab" }
local HEAT_UP = 1
local COOL_DOWN = 3
local HOT, CRITICAL, BROKEN = 6, 12, 18
local MAX_HEAT = 24
local BROKEN_DAMAGE_FRACTION = 0.05

local function state()
  storage.overheat = storage.overheat or {}
  return storage.overheat
end

local function status(stage)
  if stage == "hot" then
    return { diode = defines.entity_status_diode.yellow, label = { "sap-solaris.status-hot" } }
  elseif stage == "critical" then
    return { diode = defines.entity_status_diode.red, label = { "sap-solaris.status-critical" } }
  elseif stage == "broken" then
    return { diode = defines.entity_status_diode.red, label = { "sap-solaris.status-broken" } }
  end
  return nil
end

local function stage_of(heat)
  if heat >= BROKEN then return "broken" end
  if heat >= CRITICAL then return "critical" end
  if heat >= HOT then return "hot" end
  return "normal"
end

function overheat.on_tick()
  local surface = game.get_surface(SURFACE)
  if not surface then return end
  local heat = state()

  local cooled = {}
  for _, radiator in pairs(surface.find_entities_filtered({ name = RADIATOR })) do
    if radiator.is_connected_to_electric_network() then
      for _, machine in pairs(surface.find_entities_filtered({
        type = MACHINE_TYPES, position = radiator.position, radius = RADIATOR_RADIUS,
      })) do
        cooled[machine.unit_number] = true
      end
    end
  end

  local seen = {}
  for _, machine in pairs(surface.find_entities_filtered({ type = MACHINE_TYPES })) do
    local id = machine.unit_number
    seen[id] = true
    local value = heat[id] or 0
    if cooled[id] then
      value = math.max(0, value - COOL_DOWN)
    else
      value = math.min(MAX_HEAT, value + HEAT_UP)
    end
    heat[id] = value
    local stage = stage_of(value)
    machine.custom_status = status(stage)
    machine.disabled_by_script = stage == "critical" or stage == "broken"
    if stage == "broken" then
      machine.damage(machine.max_health * BROKEN_DAMAGE_FRACTION, "neutral", "fire")
    end
  end
  for id in pairs(heat) do
    if not seen[id] then heat[id] = nil end
  end
end

return overheat
