-- Лавовые существа Solaris (docs: Планеты → Solaris → Три типа лавовых существ).
-- Скорч и Магмар живут в гнёздах (гнёзда можно будет захватить — «Захват ульев SA+»),
-- Молтен — одиночка, только убить. Графика пока временная — кусаки и плеватели.
-- Мобы пассивны: на Solaris нет загрязнения, на которое они реагируют. Хардкор
-- «агрессивные мобы» отправляет их в атаку скриптом.

local util = require("util")

local TINT = { r = 1.0, g = 0.55, b = 0.3, a = 1.0 }

local RESISTANCES = {
  { type = "fire", percent = 100 },
  { type = "physical", decrease = 2, percent = 10 },
  { type = "explosion", percent = 20 },
}

local function creature(base_type, base, name, health, loot)
  local e = util.table.deepcopy(data.raw[base_type][base])
  e.name = name
  e.max_health = health
  e.resistances = util.table.deepcopy(RESISTANCES)
  e.loot = loot
  e.captured_spawner_entity = nil
  return e
end

local function drop(name, probability, min, max)
  return { type = "item", name = name, amount_min = min or 1, amount_max = max or 1,
           independent_probability = probability }
end

local scorch = creature("unit", "small-biter", "sap-scorch", 60, { drop("sap-heat-scales", 0.5) })
scorch.movement_speed = scorch.movement_speed * 1.3
local magmar = creature("unit", "medium-spitter", "sap-magmar", 160, { drop("sap-lava-clot", 0.5) })
local molten = creature("unit", "behemoth-biter", "sap-molten", 4000, { drop("sap-molten-core", 1, 1, 2) })

local scorch_nest = creature("unit-spawner", "biter-spawner", "sap-scorch-nest", 400,
  { drop("sap-heat-scales", 1, 3, 6) })
scorch_nest.result_units = { { "sap-scorch", { { 0, 1 } } } }
scorch_nest.autoplace = nil
local magmar_nest = creature("unit-spawner", "spitter-spawner", "sap-magmar-nest", 500,
  { drop("sap-lava-clot", 1, 3, 6) })
magmar_nest.result_units = { { "sap-magmar", { { 0, 0.7 } } }, { "sap-scorch", { { 0, 0.3 } } } }
magmar_nest.autoplace = nil

local function item(name, icon, order)
  return {
    type = "item", name = name, icons = { { icon = icon, icon_size = 64, tint = TINT } },
    subgroup = "raw-material", order = "z[sap-solaris]-" .. order, stack_size = 100,
  }
end

data:extend({
  scorch, magmar, molten, scorch_nest, magmar_nest,
  item("sap-heat-scales", "__base__/graphics/icons/stone.png", "a"),
  item("sap-lava-clot", "__base__/graphics/icons/coal.png", "b"),
  item("sap-molten-core", "__base__/graphics/icons/uranium-235.png", "c"),
})

-- Захват ульев SA+: Скорч и Магмар захватываются (Молтен — одиночка, только убить).
local sap = require("__space-age-plus-core__.prototypes.api")
sap.capturable_nests({
  planet = "solaris", tint = TINT, discovery_tech = "sap-planet-discovery-solaris",
  nests = {
    { nest = "sap-scorch-nest", product = "sap-heat-scales" },
    { nest = "sap-magmar-nest", product = "sap-lava-clot" },
  },
  food_ingredients = {
    { type = "item", name = "sap-thermite", amount = 1 },
    { type = "item", name = "sap-magmatic-ore", amount = 2 },
  },
  rocket_ingredients = { { type = "item", name = "sap-heat-resistant-alloy", amount = 2 } },
  science = {
    { "automation-science-pack", 1 }, { "logistic-science-pack", 1 }, { "chemical-science-pack", 1 },
    { "space-science-pack", 1 }, { "metallurgic-science-pack", 1 }, { "agricultural-science-pack", 1 },
  },
})
