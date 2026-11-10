-- Ядра планет: у каждой планеты своё древнее ядро (последний зал подземелья). Пока ядро лежит
-- в Древнем пьедестале или в Древнем узле команды, команда получает бонус этой планеты
-- (prototypes: data-final-fixes, mod-data "sap-ancient-cores"). Одинаковые ядра не складываются.

local cores = {}

cores.TICK_INTERVAL = 60

--- Вызывается, когда у команды включается бонус ядра: (force, planet). Задаёт control.lua.
cores.on_bonus = nil

local HOLDERS = { ["sap-ancient-pedestal"] = true, ["sap-ancient-nexus"] = true }

local registry_cache
function cores.registry()
  if not registry_cache then
    local proto = prototypes.mod_data["sap-ancient-cores"]
    registry_cache = proto and proto.data or {}
  end
  return registry_cache
end

--- Предмет ядра планеты (общее «древнее ядро» для планет без своего).
function cores.item_of(planet)
  local entry = cores.registry()[planet]
  return entry and entry.item or "sap-ancient-core"
end

local function state()
  storage.cores = storage.cores or { holders = {}, applied = {} }
  return storage.cores
end

function cores.on_built(entity)
  if HOLDERS[entity.name] then state().holders[entity.unit_number] = entity end
end

--- Планеты, чьи ядра лежат в этом хранителе.
function cores.planets_in(entity)
  local result = {}
  local inventory = entity.get_inventory(defines.inventory.chest)
  if not inventory then return result end
  for planet, entry in pairs(cores.registry()) do
    if inventory.get_item_count(entry.item) > 0 then result[planet] = true end
  end
  return result
end

--- Каких ядер не хватает в узле (nil — узла нет).
function cores.missing_in(entity)
  local present = cores.planets_in(entity)
  local missing = {}
  for planet in pairs(cores.registry()) do
    if not present[planet] then missing[#missing + 1] = planet end
  end
  table.sort(missing)
  return missing
end

--- Лежат ли в каком-нибудь узле команды ядра всех планет. Второе значение — чего не хватает
--- в самом полном узле (пусто, если узлов нет — тогда не хватает всего).
function cores.nexus_complete(force)
  if settings.startup["sap-dungeons-enabled"] and settings.startup["sap-dungeons-enabled"].value == false then
    return true, {}
  end
  local best
  for _, entity in pairs(state().holders) do
    if entity.valid and entity.name == "sap-ancient-nexus" and entity.force == force then
      local missing = cores.missing_in(entity)
      if not best or #missing < #best then best = missing end
    end
  end
  if not best then
    best = {}
    for planet in pairs(cores.registry()) do best[#best + 1] = planet end
    table.sort(best)
  end
  return #best == 0, best
end

local function apply(force, planet, sign)
  local entry = cores.registry()[planet]
  if not entry then return end
  local ok = pcall(function() force[entry.modifier] = force[entry.modifier] + sign * entry.value end)
  if not ok then log("sap: cannot apply core bonus " .. entry.modifier) end
end

function cores.on_tick()
  local s = state()
  local active = {}
  for id, entity in pairs(s.holders) do
    if entity.valid then
      local index = entity.force.index
      active[index] = active[index] or {}
      for planet in pairs(cores.planets_in(entity)) do active[index][planet] = true end
    else
      s.holders[id] = nil
    end
  end
  for _, force in pairs(game.forces) do
    local now, before = active[force.index] or {}, s.applied[force.index] or {}
    for planet in pairs(now) do
      if not before[planet] then
        apply(force, planet, 1)
        force.print({ "sap-cores.bonus-on", { "space-location-name." .. planet } })
        if cores.on_bonus then cores.on_bonus(force, planet) end
      end
    end
    for planet in pairs(before) do
      if not now[planet] then
        apply(force, planet, -1)
        force.print({ "sap-cores.bonus-off", { "space-location-name." .. planet } })
      end
    end
    s.applied[force.index] = now
  end
end

--- Бонусы, действующие сейчас (для тестов и окна узла).
function cores.applied(force)
  return state().applied[force.index] or {}
end

function cores.on_configuration_changed()
  registry_cache = nil
  local s = state()
  for _, surface in pairs(game.surfaces) do
    for _, e in pairs(surface.find_entities_filtered({ name = { "sap-ancient-pedestal", "sap-ancient-nexus" } })) do
      s.holders[e.unit_number] = e
    end
  end
end

return cores
