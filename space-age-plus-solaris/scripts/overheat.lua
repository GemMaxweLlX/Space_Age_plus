-- Перегрев механизмов на Solaris (docs: Планеты → Solaris → Перегрев).
--
-- Стадии: нормальная → горячая → критическая (машина останавливается) → сломана (урон).
-- Подключённый к сети радиатор охлаждения рядом снижает нагрев своих соседей.

local overheat = {}

overheat.TICK_INTERVAL = 60 -- пятая часть машин раз в секунду (каждая машина — раз в 5 секунд)
local PHASES = 5

local SURFACE = "solaris"
local RADIATORS = { ["sap-radiator"] = 6, ["sap-radiator-mk2"] = 10 }
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

-- Список машин ведётся по событиям постройки и разборки (без поиска по всей поверхности).
-- Раз в RESCAN_CYCLES полных циклов — полный пересчёт: на случай построек, созданных
-- другими модами без события. Всё хранится в storage (одинаково у всех игроков).
local RESCAN_CYCLES = 10
local MACHINE_SET = {}
for _, t in pairs(MACHINE_TYPES) do MACHINE_SET[t] = true end

local function cache()
  storage.overheat_cache = storage.overheat_cache or { machines = {}, cycles = 0 }
  return storage.overheat_cache
end

function overheat.rescan()
  local c = cache()
  c.machines = {}
  local surface = game.get_surface(SURFACE)
  if not surface then return end
  for _, machine in pairs(surface.find_entities_filtered({ type = MACHINE_TYPES })) do
    c.machines[machine.unit_number] = machine
  end
end

function overheat.track(entity)
  if entity and entity.valid and MACHINE_SET[entity.type] and entity.surface.name == SURFACE then
    cache().machines[entity.unit_number] = entity
  end
end

function overheat.untrack(entity)
  if entity and entity.valid and entity.unit_number then
    cache().machines[entity.unit_number] = nil
    state()[entity.unit_number] = nil
  end
end

local function refresh_zones(surface, c)
  local points, max_r = {}, 1
  for name, radius in pairs(RADIATORS) do
    for _, radiator in pairs(surface.find_entities_filtered({ name = name })) do
      if radiator.is_connected_to_electric_network() then
        points[#points + 1] = { x = radiator.position.x, y = radiator.position.y, r = radius }
      end
    end
    if radius > max_r then max_r = radius end
  end
  c.cell = max_r + EXTRA
  c.zones = build_zones(points, c.cell)
end

function overheat.on_tick()
  local surface = game.get_surface(SURFACE)
  if not surface then return end
  local heat = state()
  local c = cache()
  c.phase = ((c.phase or -1) + 1) % PHASES
  if c.phase == 0 or not c.zones then
    c.cycles = (c.cycles or 0) + 1
    if c.cycles % RESCAN_CYCLES == 1 then overheat.rescan() end
    refresh_zones(surface, c)
  end

  local phase = c.phase
  for id, machine in pairs(c.machines) do
    if id % PHASES == phase then
      if not machine.valid then
        c.machines[id] = nil
        heat[id] = nil
      else
        local p = machine.position
        local value = heat[id] or 0
        if in_zone(c.zones, c.cell, p.x, p.y) then
          value = math.max(0, value - COOL_DOWN)
        else
          value = math.min(MAX_HEAT, value + HEAT_UP)
        end
        local old_stage = stage_of(heat[id] or 0)
        local first = heat[id] == nil
        heat[id] = value
        local stage = stage_of(value)
        if stage ~= old_stage or first then
          machine.custom_status = status(stage)
          machine.disabled_by_script = stage == "critical" or stage == "broken"
        end
        if stage == "broken" then
          machine.damage(machine.max_health * BROKEN_DAMAGE_FRACTION, "neutral", "fire")
        end
      end
    end
  end
end

return overheat
