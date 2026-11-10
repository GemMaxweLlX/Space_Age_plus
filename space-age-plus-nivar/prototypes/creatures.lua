-- Существа Nivar (docs: Планеты → Nivar → Существа поверхности, Существа пещер).
-- Поверхность: Вьюга (гнёзда, в криобурю — стаями), Ледяной страж (одиночка).
-- Пещеры: Иней и Сталагмит (гнёзда), Бездонный (одиночка в глубине).
-- Графика пока — кусаки и плеватели Наувиса.

local util = require("util")

local TINT = { r = 0.7, g = 0.85, b = 1.0, a = 1.0 }

local RESISTANCES = {
  { type = "physical", decrease = 3, percent = 20 },
  { type = "acid", percent = 50 },
  { type = "fire", percent = -50 },
}

local function copy(type_name, base, name, health, loot)
  local e = util.table.deepcopy(data.raw[type_name][base])
  e.name = name
  e.max_health = health
  e.resistances = util.table.deepcopy(RESISTANCES)
  e.loot = loot
  e.captured_spawner_entity = nil
  e.autoplace = nil
  return e
end

local function drop(name, probability, min, max)
  return { type = "item", name = name, amount_min = min or 1, amount_max = max or 1,
           independent_probability = probability }
end

local blizzard = copy("unit", "medium-biter", "sap-blizzard", 300, { drop("sap-cryo-carapace", 0.5) })
local guardian = copy("unit", "behemoth-biter", "sap-ice-guardian", 5000, { drop("sap-guardian-core", 1, 1, 2) })
local frost = copy("unit", "small-biter", "sap-frost", 80, { drop("sap-cryo-gland", 0.5) })
local stalagmite = copy("unit", "medium-spitter", "sap-stalagmite", 250, { drop("sap-ice-spike", 0.5) })
local bottomless = copy("unit", "behemoth-spitter", "sap-bottomless", 6000, { drop("sap-bottomless-core", 1, 1, 2) })

local blizzard_nest = copy("unit-spawner", "biter-spawner", "sap-blizzard-nest", 600, { drop("sap-cryo-carapace", 1, 2, 4) })
blizzard_nest.result_units = { { "sap-blizzard", { { 0, 1 } } } }
local cave_nest = copy("unit-spawner", "spitter-spawner", "sap-cave-nest", 600,
  { drop("sap-cryo-gland", 1, 2, 4), drop("sap-ice-spike", 1, 1, 3) })
cave_nest.result_units = { { "sap-frost", { { 0, 0.6 } } }, { "sap-stalagmite", { { 0, 0.4 } } } }

local function item(name, icon, order)
  return {
    type = "item", name = name, icons = { { icon = icon, icon_size = 64, tint = TINT } },
    subgroup = "raw-material", order = "z[sap-nivar]-" .. order, stack_size = 100,
  }
end

data:extend({
  blizzard, guardian, frost, stalagmite, bottomless, blizzard_nest, cave_nest,
  item("sap-cryo-carapace", "__base__/graphics/icons/stone.png", "a"),
  item("sap-cryo-gland", "__space-age__/graphics/icons/pentapod-egg.png", "b"),
  item("sap-ice-spike", "__base__/graphics/icons/iron-stick.png", "c"),
  item("sap-guardian-core", "__base__/graphics/icons/uranium-235.png", "d"),
  item("sap-bottomless-core", "__base__/graphics/icons/uranium-238.png", "e"),
})

-- Захват ульев SA+: гнёзда Вьюги (поверхность) и пещерные гнёзда захватываются;
-- Ледяной страж и Бездонный — одиночки, только убить.
local sap = require("__space-age-plus-core__.prototypes.api")
local NIVAR_SCIENCE = {
  { "automation-science-pack", 1 }, { "logistic-science-pack", 1 }, { "chemical-science-pack", 1 },
  { "space-science-pack", 1 }, { "cryogenic-science-pack", 1 }, { "agricultural-science-pack", 1 },
}
sap.capturable_nests({
  planet = "nivar", tint = TINT, discovery_tech = "sap-planet-discovery-nivar",
  nests = { { nest = "sap-blizzard-nest", product = "sap-cryo-carapace" } },
  food_ingredients = {
    { type = "item", name = "sap-cryolite", amount = 1 },
    { type = "item", name = "iron-ore", amount = 2 },
  },
  rocket_ingredients = { { type = "item", name = "sap-cryolite", amount = 4 } },
  science = NIVAR_SCIENCE,
})
sap.capturable_nests({
  planet = "nivar-caves", tint = { r = 0.4, g = 0.5, b = 0.8, a = 1 }, discovery_tech = "sap-planet-discovery-nivar",
  nests = { { nest = "sap-cave-nest", product = "sap-cryo-gland" } },
  food_ingredients = {
    { type = "item", name = "sap-cryolite", amount = 1 },
    { type = "item", name = "sap-dark-ice", amount = 2 },
  },
  rocket_ingredients = { { type = "item", name = "sap-dark-ice", amount = 4 } },
  science = NIVAR_SCIENCE,
})
