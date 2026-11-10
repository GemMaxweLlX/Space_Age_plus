-- Бонусы технологий по качеству — runtime (I3).
--
-- Дешифратор открыл технологию качества Q → открыты её версии всех качеств до Q
-- (обычная — это сама технология). Игрок сам выбирает, какую исследовать.
-- Исследована версия качества Q → базовая технология считается исследованной, а все
-- постройки этой технологии у команды получают бонус качества Q (невидимый маяк).
-- Позже можно исследовать версию лучше — бонус вырастет.

local quality_bonus = {}

local ORDER = { "normal", "uncommon", "rare", "epic", "legendary" }
local RANK = {}
for i, q in ipairs(ORDER) do RANK[q] = i end

local BEACON = "sap-tech-bonus-beacon"

local function data()
  local proto = prototypes.mod_data["sap-quality-techs"]
  return proto and proto.data or { buildings = {}, variants = {}, bases = {} }
end

local function state()
  storage.quality_bonus = storage.quality_bonus or {}
  local s = storage.quality_bonus
  s.researched = s.researched or {} -- [force_index][base] = quality
  s.beacons = s.beacons or {} -- [unit_number] = beacon
  return s
end

local function researched_for(force)
  local s = state()
  s.researched[force.index] = s.researched[force.index] or {}
  return s.researched[force.index]
end

--- Открывает версии технологии всех качеств не выше `quality`.
function quality_bonus.unlock_variants(force, base, quality)
  local variants = data().bases[base]
  if not variants then return end
  for q, variant in pairs(variants) do
    local tech = force.technologies[variant]
    if tech and not tech.researched and RANK[q] <= (RANK[quality] or 1) then
      tech.enabled = true
    end
  end
end

--- Для старых сохранений: версии, которые команда уже открыла, должны быть доступны.
function quality_bonus.sync_force(force, unlocked)
  for base, variants in pairs(data().bases) do
    local quality = unlocked[base]
    for q, variant in pairs(variants) do
      local tech = force.technologies[variant]
      if tech and not tech.researched then
        tech.enabled = quality ~= nil and RANK[q] <= (RANK[quality] or 1)
        tech.visible_when_disabled = false
      end
    end
  end
end

-- Маяки ---------------------------------------------------------------------------

local function remove_beacon(entity_id)
  local s = state()
  local beacon = s.beacons[entity_id]
  if beacon and beacon.valid then beacon.destroy() end
  s.beacons[entity_id] = nil
end

local function apply(entity)
  if not (entity and entity.valid and entity.unit_number) then return end
  local base = data().buildings[entity.name]
  if not base then return end
  local quality = researched_for(entity.force)[base]
  remove_beacon(entity.unit_number)
  if not quality or quality == "normal" then return end
  local beacon = entity.surface.create_entity({
    name = BEACON, position = entity.position, force = entity.force, create_build_effect_smoke = false,
  })
  if not beacon then return end
  beacon.get_module_inventory().insert({ name = "sap-tech-bonus-" .. quality, count = 1 })
  state().beacons[entity.unit_number] = beacon
end

local function refresh_buildings(force, base)
  local names = {}
  for entity_name, tech in pairs(data().buildings) do
    if tech == base then names[#names + 1] = entity_name end
  end
  if #names == 0 then return end
  for _, surface in pairs(game.surfaces) do
    for _, entity in pairs(surface.find_entities_filtered({ name = names, force = force })) do
      apply(entity)
    end
  end
end

-- События ---------------------------------------------------------------------------

function quality_bonus.on_research_finished(event)
  local tech = event.research
  local info = data().variants[tech.name]
  if not info then return end
  local force = tech.force
  local base = force.technologies[info.base]
  if base and not base.researched then base.researched = true end
  local researched = researched_for(force)
  if RANK[info.quality] > (RANK[researched[info.base]] or 1) then
    researched[info.base] = info.quality
    refresh_buildings(force, info.base)
    force.print({ "sap-techtree.quality-researched", prototypes.technology[info.base].localised_name,
                  { "quality-name." .. info.quality } })
  end
end

function quality_bonus.on_built(event)
  apply(event.entity)
end

function quality_bonus.on_removed(event)
  local entity = event.entity
  if entity and entity.valid and entity.unit_number then remove_beacon(entity.unit_number) end
end

--- Качество, с которым у команды исследована технология (для тестов и интерфейса).
function quality_bonus.researched_quality(force, base)
  return researched_for(force)[base]
end

function quality_bonus.on_init()
  state()
end

return quality_bonus
