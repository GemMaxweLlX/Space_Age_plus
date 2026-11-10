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
  -- Древний узел (сюжет): колбы всех планет в технологии и по 10 колб каждой планеты в рецепте.
  -- Ядра не тратятся: их кладут в сам узел (концовки открываются, когда там ядро каждой планеты).
  local nexus_tech, nexus_recipe = data.raw.technology["sap-ancient-nexus"], data.raw.recipe["sap-ancient-nexus"]
  if nexus_tech and nexus_recipe then
    local names = {}
    for pack in pairs(packs and packs.data or {}) do names[#names + 1] = pack end
    table.sort(names)
    for _, pack in pairs(names) do
      add_pack(nexus_tech, pack)
      table.insert(nexus_recipe.ingredients, { type = "item", name = pack, amount = 10 })
    end
  end
end

-- Ядра планет (подземелья): у каждой планеты своё ядро и свой бонус, пока ядро лежит
-- в Древнем пьедестале или в Древнем узле. Узел вмещает по ядру каждой планеты.
do
  local CORES = {
    { "nauvis", { r = 0.5, g = 1, b = 0.5 }, "character_health_bonus", 100 },
    { "vulcanus", { r = 1, g = 0.5, b = 0.2 }, "mining_drill_productivity_bonus", 0.1 },
    { "fulgora", { r = 0.8, g = 0.5, b = 1 }, "laboratory_speed_modifier", 0.2 },
    { "gleba", { r = 0.9, g = 1, b = 0.3 }, "manual_crafting_speed_modifier", 0.5 },
    { "aquilo", { r = 0.6, g = 0.9, b = 1 }, "worker_robots_battery_modifier", 0.3 },
    { "solaris", { r = 1, g = 0.85, b = 0.2 }, "laboratory_productivity_bonus", 0.05 },
    { "echaris", { r = 0.3, g = 0.6, b = 1 }, "worker_robots_speed_modifier", 0.2 },
    { "aquara", { r = 0.2, g = 0.9, b = 0.8 }, "character_running_speed_modifier", 0.2 },
    { "nivar", { r = 0.85, g = 0.95, b = 1 }, "bulk_inserter_capacity_bonus", 1 },
  }
  local registry = {}
  local order = 0
  for _, c in pairs(CORES) do
    local planet, tint, modifier, value = c[1], c[2], c[3], c[4]
    if data.raw.planet[planet] then
      order = order + 1
      local item = "sap-ancient-core-" .. planet
      data:extend({ {
        type = "item", name = item,
        icons = { { icon = "__base__/graphics/icons/uranium-235.png", icon_size = 64, tint = tint } },
        localised_name = { "item-name.sap-ancient-core-of", { "space-location-name." .. planet } },
        localised_description = { "item-description.sap-ancient-core-bonus",
                                  { "sap-core-bonus." .. modifier }, tostring(value) },
        subgroup = "sap-tech-data", order = string.format("d-b%02d", order), stack_size = 10,
      } })
      registry[planet] = { item = item, modifier = modifier, value = value }
    end
  end
  data:extend({ { type = "mod-data", name = "sap-ancient-cores", data = registry } })
  local nexus = data.raw.container["sap-ancient-nexus"]
  if nexus and sap_settings.get("sap-dungeons-enabled") ~= false then nexus.inventory_size = math.max(1, order) end
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
