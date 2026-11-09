-- Исследование планет — runtime (docs: Глобальные механики → Планеты).
--
-- Статусы планеты для каждой команды (force):
--   не найдена      → технология полёта скрыта полностью;
--   найдена (спутник 1)  → технология видна, но заблокирована;
--   разведана (спутник 2) → технология полёта доступна для исследования.
-- Технология спутника 1 открывается, когда на Наувисе построен телескоп.
-- Технология спутника 2 — после 10 запусков спутника 1 (хардкор: 30-50).

local exploration = {}

local diary = require("scripts.diary")

local TELESCOPE = "sap-telescope"
local MK1 = "sap-satellite-mk1"
local MK2 = "sap-satellite-mk2"

local FIND_CHANCE = 0.5
local FIND_CHANCE_HARDCORE = 0.25
local LAUNCHES_NORMAL = 10
local LAUNCHES_HARDCORE_MIN, LAUNCHES_HARDCORE_MAX = 30, 50

local function hardcore()
  return settings.startup["sap-hardcore-satellite"].value
end

local function explorable()
  local proto = prototypes.mod_data["sap-explorable-planets"]
  return proto and proto.data or {}
end

local function force_state(force)
  storage.exploration = storage.exploration or {}
  local s = storage.exploration[force.index]
  if not s then
    s = {
      telescope = false,
      launches = 0,
      launches_needed = hardcore() and math.random(LAUNCHES_HARDCORE_MIN, LAUNCHES_HARDCORE_MAX)
        or LAUNCHES_NORMAL,
      found = {},
      scouted = {},
    }
    storage.exploration[force.index] = s
  end
  return s
end

local function planet_name(planet)
  return { "space-location-name." .. planet }
end

local function tech(force, name)
  local t = force.technologies[name]
  return t and t.valid and t or nil
end

--- Приводит технологии команды в соответствие со статусами планет.
local function sync_force(force)
  local s = force_state(force)
  for planet, info in pairs(explorable()) do
    local t = tech(force, info.discovery_tech)
    if t and not t.researched then
      t.enabled = s.scouted[planet] == true
      t.visible_when_disabled = s.found[planet] == true
    end
  end
  local mk1 = tech(force, MK1)
  if mk1 and not mk1.researched then
    mk1.enabled = s.telescope
    mk1.visible_when_disabled = false
  end
  local mk2 = tech(force, MK2)
  if mk2 and not mk2.researched then
    mk2.enabled = s.launches >= s.launches_needed
    mk2.visible_when_disabled = mk1 ~= nil and mk1.researched
  end
end

local function sorted_planets(filter)
  local list = {}
  for planet in pairs(explorable()) do
    if filter(planet) then list[#list + 1] = planet end
  end
  table.sort(list)
  return list
end

-- Телескоп ---------------------------------------------------------------------

function exploration.on_built(event)
  local entity = event.entity
  if not (entity and entity.valid and entity.name == TELESCOPE) then return end
  if entity.surface.name ~= "nauvis" then return end
  local force = entity.force
  local s = force_state(force)
  if s.telescope then return end
  s.telescope = true
  sync_force(force)
  local unknown = #sorted_planets(function(p) return not s.found[p] end)
  force.print({ "sap-exploration.telescope-built", unknown })
end

-- Спутники ---------------------------------------------------------------------

local function launch_mk1(force, s)
  s.launches = s.launches + 1
  local candidates = sorted_planets(function(p) return not s.found[p] end)
  local chance = hardcore() and FIND_CHANCE_HARDCORE or FIND_CHANCE
  if #candidates > 0 and math.random() < chance then
    local planet = candidates[math.random(1, #candidates)]
    s.found[planet] = true
    local distance = math.floor(prototypes.space_location[planet].distance * 1000 + 0.5)
    force.print({ "sap-exploration.mk1-found", planet_name(planet), distance })
    diary.on_satellite(force, "mk1-found", planet, s.launches)
  else
    force.print({ "sap-exploration.mk1-nothing" })
    diary.on_satellite(force, "mk1-nothing", nil, s.launches)
  end
  diary.on_satellite(force, "mk1", nil, s.launches)
  if s.launches == s.launches_needed then
    force.print({ "sap-exploration.mk2-ready" })
    diary.on_satellite(force, "mk2-ready", nil, s.launches)
  end
end

local function launch_mk2(force, s)
  local target = sorted_planets(function(p) return s.found[p] and not s.scouted[p] end)[1]
  if not target then
    -- Ничего не найдено спутником 1 — спутник 2 ищет сам.
    target = sorted_planets(function(p) return not s.scouted[p] end)[1]
  end
  if not target then
    force.print({ "sap-exploration.mk2-nothing" })
    return
  end
  s.found[target] = true
  s.scouted[target] = true
  force.print({ "sap-exploration.mk2-scouted", planet_name(target) })
  diary.on_satellite(force, "scouted", target, s.launches)
end

function exploration.on_rocket_launch_ordered(event)
  local rocket, silo = event.rocket, event.rocket_silo
  if not (rocket and rocket.valid and silo and silo.valid) then return end
  local pod = rocket.attached_cargo_pod
  if not (pod and pod.valid) then return end
  local destination = pod.cargo_pod_destination
  -- Спутники, отправленные на платформу, не считаются запуском на орбиту.
  if destination and (destination.type == defines.cargo_destination.space_platform
      or destination.type == defines.cargo_destination.station) then
    return
  end
  local inventory = pod.get_inventory(defines.inventory.cargo_unit)
  if not inventory then return end
  local force = silo.force
  local s = force_state(force)
  -- Считаем спутники любого качества (get_item_count без качества видит только обычные).
  local mk1, mk2 = 0, 0
  for _, stack in pairs(inventory.get_contents()) do
    if stack.name == MK1 then mk1 = mk1 + stack.count end
    if stack.name == MK2 then mk2 = mk2 + stack.count end
  end
  for _ = 1, mk1 do launch_mk1(force, s) end
  for _ = 1, mk2 do launch_mk2(force, s) end
  sync_force(force)
end

-- Жизненный цикл --------------------------------------------------------------

local function sync_all()
  for _, force in pairs(game.forces) do
    if #force.players > 0 or force.name == "player" then sync_force(force) end
  end
end

function exploration.on_init()
  storage.exploration = {}
  sync_all()
end

function exploration.on_configuration_changed()
  storage.exploration = storage.exploration or {}
  sync_all()
end

function exploration.on_force_created(event)
  sync_force(event.force)
end

function exploration.on_research_finished(event)
  local name = event.research.name
  if name == MK1 then sync_force(event.research.force) end
end

return exploration
