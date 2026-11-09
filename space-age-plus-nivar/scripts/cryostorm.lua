-- Криобуря Nivar (docs: Планеты → Nivar → Криобуря).
--
-- Обычный холод — механика Аквило: без тепла постройки замерзают (обогрев 1 уровня).
-- Криобуря идёт поверх неё: пока она длится, машины вне зоны работающего криообогревателя
-- (обогрев 2 уровня) или криозащитного купола проходят стадии
--   холодная → промёрзшая → остановлена → сломана.
-- Пещеры защищены от криобури. В начале бури гнёзда Вьюги выпускают стаи.

local cryostorm = {}

local function diary_add(force, key)
  if force and force.valid and remote.interfaces["sap-diary"] then remote.call("sap-diary", "add", force.name, key) end
end

cryostorm.TICK_INTERVAL = 300

local SURFACE = "nivar"
local HEATERS = { ["sap-cryo-heater"] = 8, ["sap-cryo-heater-mk2"] = 12 }
local DOME, DOME_RADIUS = "sap-cryo-dome", 24
local MACHINE_TYPES = { "assembling-machine", "furnace", "mining-drill", "lab", "inserter" }
local STORM_MIN, STORM_MAX = 2 * 60 * 60, 4 * 60 * 60
local CALM_MIN, CALM_MAX = 4 * 60 * 60, 8 * 60 * 60
local COLD, FROZEN, STOPPED, BROKEN = 3, 6, 12, 18
local MAX_COLD = 24
local BROKEN_DAMAGE_FRACTION = 0.05
local FOUNDATION = "sap-insulating-foundation"
local WALL, WALL_REACH = "sap-insulated-wall", 16
local PACK_SIZE = 4
local PACK_RADIUS = 150

local function state()
  storage.cryostorm = storage.cryostorm or { active = false, next_change = 0, cold = {} }
  return storage.cryostorm
end

local function stage_of(value)
  if value >= BROKEN then return "broken" end
  if value >= STOPPED then return "stopped" end
  if value >= FROZEN then return "frozen" end
  if value >= COLD then return "cold" end
  return "normal"
end

local STATUS = {
  cold = { diode = defines.entity_status_diode.yellow, label = { "sap-nivar.status-cold" } },
  frozen = { diode = defines.entity_status_diode.yellow, label = { "sap-nivar.status-frozen" } },
  stopped = { diode = defines.entity_status_diode.red, label = { "sap-nivar.status-stopped" } },
  broken = { diode = defines.entity_status_diode.red, label = { "sap-nivar.status-broken" } },
}

local function protected_set(surface)
  local set = {}
  local function mark(name, radius)
    for _, source in pairs(surface.find_entities_filtered({ name = name })) do
      if source.is_connected_to_electric_network() then
        for _, machine in pairs(surface.find_entities_filtered({
          type = MACHINE_TYPES, position = source.position, radius = radius,
        })) do
          set[machine.unit_number] = true
        end
      end
    end
  end
  for name, radius in pairs(HEATERS) do mark(name, radius) end
  mark(DOME, DOME_RADIUS)
  return set
end

--- Множитель скорости замерзания без энергии: фундамент ×0.5, замкнутые стены ×0.5.
local function passive_factor(surface, machine)
  local factor = 1
  local p = machine.position
  if surface.get_tile(p.x, p.y).name == FOUNDATION then factor = factor * 0.5 end
  local function wall(area)
    return surface.count_entities_filtered({ name = WALL, area = area, limit = 1 }) > 0
  end
  if wall({ { p.x - 2, p.y - WALL_REACH }, { p.x + 2, p.y } }) and wall({ { p.x - 2, p.y }, { p.x + 2, p.y + WALL_REACH } })
      and wall({ { p.x - WALL_REACH, p.y - 2 }, { p.x, p.y + 2 } }) and wall({ { p.x, p.y - 2 }, { p.x + WALL_REACH, p.y + 2 } }) then
    factor = factor * 0.5
  end
  return factor
end

local function release_packs(surface)
  for _, nest in pairs(surface.find_entities_filtered({ name = "sap-blizzard-nest" })) do
    local target = surface.find_entities_filtered({
      force = "player", position = nest.position, radius = PACK_RADIUS, limit = 1,
      type = { "assembling-machine", "furnace", "mining-drill", "electric-pole", "container" },
    })[1]
    if target then
      diary_add(target.force, "blizzard-storm")
      for _ = 1, PACK_SIZE do
        local position = surface.find_non_colliding_position("sap-blizzard", nest.position, 10, 1)
        local unit = position and surface.create_entity({ name = "sap-blizzard", position = position, force = nest.force })
        if unit and unit.commandable then
          unit.commandable.set_command({ type = defines.command.attack_area, destination = target.position, radius = 16 })
        end
      end
    end
  end
end

local function update_storm(surface, s)
  if game.tick < s.next_change then return end
  s.active = not s.active
  if s.active then
    s.next_change = game.tick + math.random(STORM_MIN, STORM_MAX)
    game.forces.player.print({ "sap-nivar.cryostorm-start" })
    release_packs(surface)
  else
    s.next_change = game.tick + math.random(CALM_MIN, CALM_MAX)
    game.forces.player.print({ "sap-nivar.cryostorm-end" })
  end
end

function cryostorm.on_tick()
  local surface = game.get_surface(SURFACE)
  if not surface then return end
  local s = state()
  update_storm(surface, s)
  local protected = s.active and protected_set(surface) or {}
  local seen = {}
  for _, machine in pairs(surface.find_entities_filtered({ type = MACHINE_TYPES })) do
    local id = machine.unit_number
    seen[id] = true
    local value = s.cold[id] or 0
    if s.active and not protected[id] then
      value = math.min(MAX_COLD, value + passive_factor(surface, machine))
    else
      value = math.max(0, value - 3)
    end
    s.cold[id] = value
    local stage = stage_of(value)
    machine.custom_status = STATUS[stage]
    machine.disabled_by_script = stage == "stopped" or stage == "broken"
    if stage == "broken" then
      machine.damage(machine.max_health * BROKEN_DAMAGE_FRACTION, "neutral", "physical")
    end
  end
  for id in pairs(s.cold) do
    if not seen[id] then s.cold[id] = nil end
  end
end

--- Для тестов: включить или выключить бурю сразу.
function cryostorm.set_active(active)
  local s = state()
  s.active = active
  s.next_change = game.tick + STORM_MAX
end

function cryostorm.on_init()
  state()
end

return cryostorm
