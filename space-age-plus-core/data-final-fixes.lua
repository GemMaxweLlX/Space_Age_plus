-- space-age-plus-core: финальные правки после всех модулей.

local sap_settings = require("sap_settings")
local util = require("util")
local sap = require("prototypes.api")

-- Жидкости высокого класса открываются на Solaris, если модуль Solaris установлен.
if data.raw.technology["sap-planet-discovery-solaris"] then
  table.insert(data.raw.technology["sap-high-grade-fluids"].prerequisites, "sap-planet-discovery-solaris")
end

-- Колбы планет (prototypes/science.lua и модули планет) -----------------------------------
-- Технологии sap-*, зависящие от технологии открытия планеты (или перечисленные явно), требуют
-- колбу этой планеты и её технологию в требованиях. Все лаборатории принимают новые колбы.
do
  local packs = data.raw["mod-data"][sap.PLANET_PACKS]
  local memo = {}
  local function depends_on(name, target, seen)
    if name == target then return true end
    memo[target] = memo[target] or {}
    if memo[target][name] ~= nil then return memo[target][name] end
    seen = seen or {}
    if seen[name] then return false end
    seen[name] = true
    local tech = data.raw.technology[name]
    local result = false
    for _, pre in pairs(tech and tech.prerequisites or {}) do
      if depends_on(pre, target, seen) then result = true break end
    end
    memo[target][name] = result
    return result
  end
  local function add_pack(tech, pack)
    if not (tech.unit and tech.unit.ingredients) or tech.name == pack then return end
    for _, ingredient in pairs(tech.unit.ingredients) do
      if (ingredient[1] or ingredient.name) == pack then return end
    end
    table.insert(tech.unit.ingredients, { pack, 1 })
    tech.prerequisites = tech.prerequisites or {}
    local has = false
    for _, pre in pairs(tech.prerequisites) do if pre == pack then has = true end end
    if not has then table.insert(tech.prerequisites, pack) end
  end
  for pack, rule in pairs(packs and packs.data or {}) do
    for _, name in pairs(rule.techs or {}) do
      if data.raw.technology[name] then add_pack(data.raw.technology[name], pack) end
    end
    if rule.discovery_tech and data.raw.technology[rule.discovery_tech] then
      for name, tech in pairs(data.raw.technology) do
        if string.sub(name, 1, 4) == "sap-" and name ~= rule.discovery_tech and name ~= pack
            and not depends_on(rule.discovery_tech, name) and depends_on(name, rule.discovery_tech) then
          add_pack(tech, pack)
        end
      end
    end
    for _, lab in pairs(data.raw.lab) do
      local has = false
      for _, input in pairs(lab.inputs) do if input == pack then has = true end end
      if not has then table.insert(lab.inputs, pack) end
    end
  end
end

-- Ванильные планеты тоже открываются через спутники, если включена настройка.
if sap_settings.get("sap-exploration-vanilla-planets") then
  for _, planet in pairs({ "vulcanus", "fulgora", "gleba", "aquilo" }) do
    if data.raw.technology["planet-discovery-" .. planet] then
      sap.register_explorable_planet(planet, { discovery_tech = "planet-discovery-" .. planet })
    end
  end
end

-- Технологии полёта к исследуемым планетам скрыты, пока планету не разведает спутник 2.
local explorable = data.raw["mod-data"][sap.EXPLORABLE_PLANETS]
for _, info in pairs(explorable and explorable.data or {}) do
  local tech = data.raw.technology[info.discovery_tech]
  if tech then
    tech.enabled = false
    tech.visible_when_disabled = false
  end
end

-- Скрытое дерево технологий (docs: Технологии → Базовые техи) --------------------
-- Скрыты: всё, что требует колбы кроме красных, и часть красных технологий из документа.
-- Технологии с триггерами (без колб) не трогаем. Спутники и полёты к планетам ведёт
-- система исследования, их тоже не трогаем.

local RED_HIDDEN = {
  ["military"] = true,
  ["fast-inserter"] = true,
  ["heavy-armor"] = true,
  ["weapon-shooting-speed-1"] = true,
  ["physical-projectile-damage-1"] = true,
}
local NEVER_HIDDEN = {
  ["sap-decipherer"] = true,
  ["sap-satellite-mk1"] = true,
  ["sap-satellite-mk2"] = true,
}
for _, info in pairs(explorable and explorable.data or {}) do
  NEVER_HIDDEN[info.discovery_tech] = true
end

-- Категория технологии по имени. Порядок важен: первое совпадение побеждает.
local CATEGORY_RULES = {
  { "alien", { "^sap%-alien" } },
  { "sap-military", { "^sap%-.*weapon", "^sap%-.*turret", "^sap%-.*armor", "^sap%-.*emp" } },
  { "sap-energy", { "^sap%-.*energy", "^sap%-.*reactor", "^sap%-.*boiler", "^sap%-.*turbine" } },
  { "military", { "military", "weapon", "damage", "turret", "armor", "gun", "artillery", "defense",
                  "laser", "flamethrower", "land%-mine", "explosives", "projectile", "flammables",
                  "shield", "discharge", "tank", "railgun", "shotgun", "grenade", "rocketry" } },
  { "robotics", { "robot", "roboport", "logistic%-system", "construction" } },
  { "trains", { "rail", "train", "locomotive", "wagon" } },
  { "space", { "space", "rocket", "planet", "asteroid", "platform", "thruster", "satellite",
               "telescope", "promethium", "debris" } },
  { "biotech", { "agri", "bio", "gleba", "yumako", "jellynut", "spoil", "nutrient", "captive",
                 "capture", "overgrowth", "carbon%-fiber", "heating" } },
  { "cryotech", { "cryo", "aquilo", "lithium", "fusion", "quantum", "foundation", "ammonia" } },
  { "energy", { "solar", "electric%-energy", "steam", "nuclear", "kovarex", "uranium", "energy",
                "power", "accumulator", "battery", "lightning", "oxygen" } },
  { "chemistry", { "oil", "plastic", "sulfur", "coal%-liquefaction", "lubricant", "chemical",
                   "explosive", "acid" } },
  { "mining", { "mining", "drill", "pump", "calcite", "tungsten" } },
  { "logistics", { "logistics", "inserter", "belt", "loader", "stack", "fluid", "toolbelt",
                   "bulk", "storage" } },
  { "automation", { "automation", "assembl", "circuit", "electronics", "lamp", "combinator",
                    "processing%-unit", "decipher" } },
}

local overrides = data.raw["mod-data"][sap.TECH_OVERRIDES]
overrides = overrides and overrides.data or { visible = {}, category = {} }
for name in pairs(overrides.visible) do NEVER_HIDDEN[name] = true end

local function category_of(name)
  if overrides.category[name] then return overrides.category[name] end
  for _, rule in ipairs(CATEGORY_RULES) do
    for _, pattern in ipairs(rule[2]) do
      if string.find(name, pattern) then return rule[1] end
    end
  end
  return "production"
end

local function ingredient_names(tech)
  local names = {}
  for _, ingredient in pairs(tech.unit and tech.unit.ingredients or {}) do
    names[#names + 1] = ingredient[1] or ingredient.name
  end
  return names
end

local catalog = {}
local techtree_enabled = sap_settings.get("sap-techtree-enabled")
for name, tech in pairs(data.raw.technology) do
  if tech.unit and not NEVER_HIDDEN[name] then
    local packs = ingredient_names(tech)
    local only_red = #packs > 0
    for _, pack in pairs(packs) do
      if pack ~= "automation-science-pack" then only_red = false end
    end
    if not only_red or RED_HIDDEN[name] then
      catalog[name] = { category = category_of(name), packs = packs }
      if techtree_enabled then
        tech.enabled = false
        tech.visible_when_disabled = false
      end
    end
  end
end

data:extend({ { type = "mod-data", name = "sap-tech-catalog", data = catalog } })

-- Версии технологий по качеству (I3) ----------------------------------------------
-- Только для скрытых технологий, которые открывают постройки: машины, печи, буры,
-- лаборатории. Цена ×1.5 / ×2 / ×3 / ×5. Версии скрыты, их открывает дешифратор.

local QUALITY_COST = { uncommon = 1.5, rare = 2, epic = 3, legendary = 5 }
local BONUS_TYPES = { ["assembling-machine"] = true, furnace = true, ["mining-drill"] = true, lab = true }

local function placed_entity(recipe_name)
  local recipe = data.raw.recipe[recipe_name]
  if not (recipe and recipe.results) then return nil end
  for _, result in pairs(recipe.results) do
    if result.type == "item" then
      local item = data.raw.item[result.name]
      local entity_name = item and item.place_result
      if entity_name then
        for type_name in pairs(BONUS_TYPES) do
          if data.raw[type_name][entity_name] then return entity_name end
        end
      end
    end
  end
  return nil
end

local quality_data = { buildings = {}, variants = {}, bases = {} }
for name in pairs(catalog) do
  local tech = data.raw.technology[name]
  if tech and tech.unit and tech.unit.count and not tech.unit.count_formula then
    local buildings = {}
    for _, effect in pairs(tech.effects or {}) do
      if effect.type == "unlock-recipe" then
        local entity_name = placed_entity(effect.recipe)
        if entity_name then buildings[#buildings + 1] = entity_name end
      end
    end
    if #buildings > 0 then
      quality_data.bases[name] = {}
      for _, entity_name in pairs(buildings) do quality_data.buildings[entity_name] = name end
      for quality, multiplier in pairs(QUALITY_COST) do
        local variant = util.table.deepcopy(tech)
        variant.name = name .. "-sap-" .. quality
        variant.localised_name = { "sap-techtree.quality-tech", tech.localised_name or { "technology-name." .. name },
                                   { "quality-name." .. quality } }
        variant.localised_description = tech.localised_description or { "technology-description." .. name }
        variant.unit.count = math.ceil(tech.unit.count * multiplier)
        variant.enabled = false
        variant.visible_when_disabled = false
        variant.upgrade = false
        variant.essential = false
        data:extend({ variant })
        quality_data.variants[variant.name] = { base = name, quality = quality }
        quality_data.bases[name][quality] = variant.name
      end
    end
  end
end

data:extend({ { type = "mod-data", name = "sap-quality-techs", data = quality_data } })
