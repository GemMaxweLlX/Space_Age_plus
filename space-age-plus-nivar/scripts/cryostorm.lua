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

cryostorm.TICK_INTERVAL = 60 -- пятая часть машин раз в секунду (каждая машина — раз в 5 секунд)
local PHASES = 5

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


--- Множитель скорости замерзания без энергии: фундамент ×0.5, замкнутые стены ×0.5.
--- Считается дорого (пять запросов), поэтому кэшируется на минуту.
local PASSIVE_TTL = 60 * 60
local function compute_passive_factor(surface, machine)
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

local function passive_factor(surface, machine, s)
  s.passive = s.passive or {}
  local cached = s.passive[machine.unit_number]
  if cached and game.tick - cached.tick < PASSIVE_TTL then return cached.value end
  local value = compute_passive_factor(surface, machine)
  s.passive[machine.unit_number] = { value = value, tick = game.tick }
  return value
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

-- Пещерные существа слепые, но хорошо слышат: вибрации криобури наверху будят пещерные
-- гнёзда, и Иней идёт к постройкам игрока в пещерах (N3).
local CAVE_PACK = 3
local function wake_caves()
  local caves = game.get_surface("nivar-caves")
  if not caves then return 0 end
  local woken = 0
  for _, nest in pairs(caves.find_entities_filtered({ name = "sap-cave-nest" })) do
    local target = caves.find_entities_filtered({
      force = "player", position = nest.position, radius = PACK_RADIUS, limit = 1,
      type = { "assembling-machine", "furnace", "mining-drill", "electric-pole", "container", "linked-container", "lamp" },
    })[1]
    if target then
      for _ = 1, CAVE_PACK do
        local position = caves.find_non_colliding_position("sap-frost", nest.position, 10, 1)
        local unit = position and caves.create_entity({ name = "sap-frost", position = position, force = nest.force })
        if unit and unit.commandable then
          unit.commandable.set_command({ type = defines.command.attack_area, destination = target.position, radius = 16 })
          woken = woken + 1
        end
      end
    end
  end
  return woken
end
cryostorm.wake_caves = wake_caves

local function update_storm(surface, s)
  if game.tick < s.next_change then return end
  s.active = not s.active
  if s.active then
    s.next_change = game.tick + math.random(STORM_MIN, STORM_MAX)
    game.forces.player.print({ "sap-nivar.cryostorm-start" })
    release_packs(surface)
    wake_caves()
  else
    s.next_change = game.tick + math.random(CALM_MIN, CALM_MAX)
    game.forces.player.print({ "sap-nivar.cryostorm-end" })
  end
end

-- Зоны защиты: позиции источников раскладываются по клеткам, проверка машины — в Lua.
-- Расстояние считается до центра машины с запасом в полразмера машины (EXTRA).
local EXTRA = 1.5

local function build_zones(points, cell_size)
  local cells = {}
  for _, p in pairs(points) do
    local cx, cy = math.floor(p.x / cell_size), math.floor(p.y / cell_size)
    cells[cx] = cells[cx] or {}
    local cell = cells[cx][cy] or {}
    cells[cx][cy] = cell
    cell[#cell + 1] = p
  end
  return cells
end

local function in_zone(cells, cell_size, x, y)
  local cx, cy = math.floor(x / cell_size), math.floor(y / cell_size)
  for dx = -1, 1 do
    local column = cells[cx + dx]
    if column then
      for dy = -1, 1 do
        for _, p in pairs(column[cy + dy] or {}) do
          local ddx, ddy, r = p.x - x, p.y - y, p.r + EXTRA
          if ddx * ddx + ddy * ddy <= r * r then return true end
        end
      end
    end
  end
  return false
end

-- Список машин ведётся по событиям постройки и разборки; раз в RESCAN_CYCLES циклов —
-- полный пересчёт (на случай построек от других модов без события). Всё в storage.
local RESCAN_CYCLES = 10
local MACHINE_SET = {}
for _, t in pairs(MACHINE_TYPES) do MACHINE_SET[t] = true end

function cryostorm.rescan()
  local s = state()
  s.machines = {}
  local surface = game.get_surface(SURFACE)
  if not surface then return end
  for _, machine in pairs(surface.find_entities_filtered({ type = MACHINE_TYPES })) do
    s.machines[machine.unit_number] = machine
  end
end

function cryostorm.track(entity)
  if entity and entity.valid and MACHINE_SET[entity.type] and entity.surface.name == SURFACE then
    local s = state()
    s.machines = s.machines or {}
    s.machines[entity.unit_number] = entity
  end
end

function cryostorm.untrack(entity)
  if entity and entity.valid and entity.unit_number then
    local s = state()
    if s.machines then s.machines[entity.unit_number] = nil end
    s.cold[entity.unit_number] = nil
    if s.passive then s.passive[entity.unit_number] = nil end
  end
end

local function refresh_zones(surface, s)
  local points = {}
  local function add(name, radius)
    for _, source in pairs(surface.find_entities_filtered({ name = name })) do
      if source.is_connected_to_electric_network() then
        points[#points + 1] = { x = source.position.x, y = source.position.y, r = radius }
      end
    end
  end
  for name, radius in pairs(HEATERS) do add(name, radius) end
  add(DOME, DOME_RADIUS)
  s.cell = DOME_RADIUS + EXTRA
  s.zones = build_zones(points, s.cell)
end

function cryostorm.on_tick()
  local surface = game.get_surface(SURFACE)
  if not surface then return end
  local s = state()
  s.phase = ((s.phase or -1) + 1) % PHASES
  if s.phase == 0 or not s.zones then
    update_storm(surface, s)
    s.cycles = (s.cycles or 0) + 1
    if not s.machines or s.cycles % RESCAN_CYCLES == 1 then cryostorm.rescan() end
    refresh_zones(surface, s)
  end

  local phase = s.phase
  for id, machine in pairs(s.machines) do
    if id % PHASES == phase then
      if not machine.valid then
        s.machines[id] = nil
        s.cold[id] = nil
        if s.passive then s.passive[id] = nil end
      else
        local p = machine.position
        local value = s.cold[id] or 0
        if s.active and not in_zone(s.zones, s.cell, p.x, p.y) then
          value = math.min(MAX_COLD, value + passive_factor(surface, machine, s))
        else
          value = math.max(0, value - 3)
        end
        local old_stage = stage_of(s.cold[id] or 0)
        local first = s.cold[id] == nil
        s.cold[id] = value
        local stage = stage_of(value)
        if stage ~= old_stage or first then
          machine.custom_status = STATUS[stage]
          machine.disabled_by_script = stage == "stopped" or stage == "broken"
        end
        if stage == "broken" then
          machine.damage(machine.max_health * BROKEN_DAMAGE_FRACTION, "neutral", "physical")
        end
      end
    end
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
