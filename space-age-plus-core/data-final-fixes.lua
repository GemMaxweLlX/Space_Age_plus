-- space-age-plus-core: финальные правки после всех модулей.
local sap = require("prototypes.api")

-- Ванильные планеты тоже открываются через спутники, если включена настройка.
if settings.startup["sap-exploration-vanilla-planets"].value then
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

local function category_of(name)
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
local techtree_enabled = settings.startup["sap-techtree-enabled"].value
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
