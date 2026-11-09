-- Водоросли, морская соль, защита от бурь и технологии Aquara (docs: Техи планет → Aquara).
--   Водоросли трёх видов портятся, как продукты Глебы; морская соль замедляет порчу.
--   Водная башня выращивает водоросли из воды (работает только на Aquara).
--   Для башни нужны биофлюс и углеволокно с Глебы (A4).
--   Штормовой щит защищает постройки от торнадо, штормовой якорь притягивает торнадо
--   и превращает его в энергию (scripts/storm.lua).

local util = require("util")
local sap = require("__space-age-plus-core__.prototypes.api")

local TINT = { r = 0.45, g = 0.8, b = 1.0, a = 1.0 }
local AQUARA_PRESSURE = 1800
local MINUTE = 60 * 60

local AQUARA_PACKS = {
  { "automation-science-pack", 1 }, { "logistic-science-pack", 1 }, { "chemical-science-pack", 1 },
  { "space-science-pack", 1 }, { "agricultural-science-pack", 1 },
}

local function tinted(icon, tint, size) return { { icon = icon, icon_size = size or 64, tint = tint or TINT } } end
local function on_aquara() return { { property = "pressure", min = AQUARA_PRESSURE, max = AQUARA_PRESSURE } } end

-- Предметы ----------------------------------------------------------------------

local function algae(name, tint, spoil_minutes, order)
  return {
    type = "item", name = name, icons = tinted("__space-age__/graphics/icons/yumako-mash.png", tint),
    subgroup = "agriculture-products", order = "z[sap-algae]-" .. order, stack_size = 50,
    spoil_ticks = spoil_minutes * MINUTE, spoil_result = "spoilage",
  }
end

data:extend({
  algae("sap-green-algae", { r = 0.4, g = 0.9, b = 0.4, a = 1 }, 30, "a"),
  algae("sap-deep-algae", { r = 0.2, g = 0.4, b = 0.7, a = 1 }, 20, "b"),
  algae("sap-bioluminescent-algae", { r = 0.5, g = 1, b = 0.9, a = 1 }, 10, "c"),
  algae("sap-salted-algae", { r = 0.8, g = 0.9, b = 0.8, a = 1 }, 120, "d"),
  {
    type = "item", name = "sap-sea-salt", icons = tinted("__space-age__/graphics/icons/calcite.png", { r = 1, g = 1, b = 1, a = 1 }),
    subgroup = "agriculture-products", order = "z[sap-algae]-e", stack_size = 100,
  },
  {
    type = "item", name = "sap-dehumidifier", icons = tinted("__base__/graphics/icons/iron-gear-wheel.png"),
    subgroup = "sap-oxygen", order = "d-e", stack_size = 100,
  },
  { type = "recipe-category", name = "sap-algae-farming" },
})

-- Водная башня ------------------------------------------------------------------

local tower = util.table.deepcopy(data.raw["assembling-machine"]["assembling-machine-2"])
tower.name = "sap-water-tower"
tower.icon = nil
tower.icons = tinted("__space-age__/graphics/icons/agricultural-tower.png")
tower.minable = { mining_time = 0.3, result = "sap-water-tower" }
tower.crafting_categories = { "sap-algae-farming" }
tower.next_upgrade = nil
tower.fast_replaceable_group = nil

-- Защита от бурь --------------------------------------------------------------

local shield = util.table.deepcopy(data.raw.radar["radar"])
shield.name = "sap-storm-shield"
shield.icon = nil
shield.icons = tinted("__base__/graphics/icons/radar.png")
shield.minable = { mining_time = 0.3, result = "sap-storm-shield" }
shield.energy_usage = "1MW"
shield.max_distance_of_sector_revealed = 0
shield.max_distance_of_nearby_sector_revealed = 1
shield.next_upgrade = nil
shield.fast_replaceable_group = nil

local anchor = util.table.deepcopy(data.raw.accumulator["accumulator"])
anchor.name = "sap-storm-anchor"
anchor.icon = nil
anchor.icons = tinted("__base__/graphics/icons/accumulator.png")
anchor.minable = { mining_time = 0.3, result = "sap-storm-anchor" }
anchor.energy_source.buffer_capacity = "200MJ"
anchor.energy_source.input_flow_limit = "0kW"
anchor.energy_source.output_flow_limit = "5MW"
anchor.next_upgrade = nil
anchor.fast_replaceable_group = nil

local function place_item(name, icon_entity, order)
  return {
    type = "item", name = name, icons = icon_entity.icons, subgroup = "production-machine",
    order = "z[sap-aquara]-" .. order, place_result = name, stack_size = 20,
  }
end

data:extend({
  tower, shield, anchor,
  place_item("sap-water-tower", tower, "a"),
  place_item("sap-storm-shield", shield, "b"),
  place_item("sap-storm-anchor", anchor, "c"),
})

-- Рецепты -----------------------------------------------------------------------

local function recipe(def)
  def.type = "recipe"
  def.enabled = false
  return def
end

data:extend({
  recipe({
    name = "sap-green-algae", categories = { "sap-algae-farming" }, energy_required = 8,
    ingredients = { { type = "fluid", name = "water", amount = 200 } },
    results = { { type = "item", name = "sap-green-algae", amount = 4 } },
    surface_conditions = on_aquara(),
  }),
  recipe({
    name = "sap-deep-algae", categories = { "sap-algae-farming" }, energy_required = 10,
    ingredients = { { type = "fluid", name = "water", amount = 300 }, { type = "item", name = "sap-sea-salt", amount = 1 } },
    results = { { type = "item", name = "sap-deep-algae", amount = 3 } },
    surface_conditions = on_aquara(),
  }),
  recipe({
    name = "sap-bioluminescent-algae", categories = { "sap-algae-farming" }, energy_required = 12,
    ingredients = { { type = "fluid", name = "water", amount = 200 }, { type = "item", name = "bioflux", amount = 1 } },
    results = { { type = "item", name = "sap-bioluminescent-algae", amount = 2 } },
    surface_conditions = on_aquara(),
  }),
  recipe({
    name = "sap-sea-salt", categories = { "chemistry" }, energy_required = 4,
    ingredients = { { type = "fluid", name = "water", amount = 500 } },
    results = { { type = "item", name = "sap-sea-salt", amount = 2 } },
    surface_conditions = on_aquara(),
  }),
  recipe({
    name = "sap-salted-algae", energy_required = 2,
    ingredients = { { type = "item", name = "sap-green-algae", amount = 4 }, { type = "item", name = "sap-sea-salt", amount = 1 } },
    results = { { type = "item", name = "sap-salted-algae", amount = 4 } },
  }),
  recipe({
    name = "sap-algae-nutrients", categories = { "organic" }, energy_required = 2,
    icons = tinted("__space-age__/graphics/icons/nutrients.png"),
    ingredients = { { type = "item", name = "sap-green-algae", amount = 2 } },
    results = { { type = "item", name = "nutrients", amount = 4 } },
  }),
  recipe({
    name = "sap-salted-algae-nutrients", categories = { "organic" }, energy_required = 2,
    icons = tinted("__space-age__/graphics/icons/nutrients.png", { r = 0.8, g = 0.9, b = 0.8, a = 1 }),
    ingredients = { { type = "item", name = "sap-salted-algae", amount = 2 } },
    results = { { type = "item", name = "nutrients", amount = 3 } },
  }),
  recipe({
    name = "sap-deep-algae-gas", categories = { "chemistry" }, energy_required = 4,
    icons = tinted("__base__/graphics/icons/fluid/petroleum-gas.png"),
    ingredients = { { type = "item", name = "sap-deep-algae", amount = 4 } },
    results = { { type = "fluid", name = "petroleum-gas", amount = 60 } },
  }),
  recipe({
    name = "sap-bioluminescent-bioflux", categories = { "organic" }, energy_required = 6,
    icons = tinted("__space-age__/graphics/icons/bioflux.png"),
    ingredients = { { type = "item", name = "sap-bioluminescent-algae", amount = 3 } },
    results = { { type = "item", name = "bioflux", amount = 1 } },
  }),
  recipe({
    name = "sap-water-tower", energy_required = 10,
    ingredients = {
      { type = "item", name = "bioflux", amount = 5 }, { type = "item", name = "carbon-fiber", amount = 10 },
      { type = "item", name = "steel-plate", amount = 10 }, { type = "item", name = "pipe", amount = 10 },
    },
    results = { { type = "item", name = "sap-water-tower", amount = 1 } },
  }),
  recipe({
    name = "sap-storm-shield", energy_required = 10,
    ingredients = {
      { type = "item", name = "carbon-fiber", amount = 20 }, { type = "item", name = "processing-unit", amount = 10 },
      { type = "item", name = "steel-plate", amount = 20 },
    },
    results = { { type = "item", name = "sap-storm-shield", amount = 1 } },
  }),
  recipe({
    name = "sap-storm-anchor", energy_required = 10,
    ingredients = {
      { type = "item", name = "accumulator", amount = 5 }, { type = "item", name = "electric-engine-unit", amount = 10 },
      { type = "item", name = "carbon-fiber", amount = 10 },
    },
    results = { { type = "item", name = "sap-storm-anchor", amount = 1 } },
  }),
  recipe({
    name = "sap-dehumidifier", energy_required = 2,
    ingredients = { { type = "item", name = "carbon-fiber", amount = 1 }, { type = "item", name = "sap-sea-salt", amount = 2 } },
    results = { { type = "item", name = "sap-dehumidifier", amount = 1 } },
  }),
  sap.oxygen_collector_recipe("aquara", AQUARA_PRESSURE, { { type = "item", name = "sap-dehumidifier", amount = 1 } }),
})

-- Технологии ------------------------------------------------------------------

local function unlock(list)
  local effects = {}
  for _, r in pairs(list) do effects[#effects + 1] = { type = "unlock-recipe", recipe = r } end
  return effects
end

for _, r in pairs({ "sap-water-tower", "sap-green-algae", "sap-algae-nutrients", "sap-sea-salt", "sap-dehumidifier",
                    "sap-oxygen-collection-aquara" }) do
  table.insert(data.raw.technology["sap-planet-discovery-aquara"].effects, { type = "unlock-recipe", recipe = r })
end

local function tech(name, icon, recipes, count, prereqs)
  return {
    type = "technology", name = name, icons = tinted(icon), effects = unlock(recipes),
    prerequisites = prereqs, unit = { count = count, time = 60, ingredients = AQUARA_PACKS },
  }
end

data:extend({
  tech("sap-sea-salt-preservation", "__space-age__/graphics/icons/calcite.png",
       { "sap-salted-algae", "sap-salted-algae-nutrients", "sap-deep-algae", "sap-deep-algae-gas" }, 500,
       { "sap-planet-discovery-aquara" }),
  tech("sap-bioluminescent-algae", "__space-age__/graphics/icons/bioflux.png",
       { "sap-bioluminescent-algae", "sap-bioluminescent-bioflux" }, 800, { "sap-sea-salt-preservation" }),
  tech("sap-storm-shield", "__base__/graphics/icons/radar.png", { "sap-storm-shield" }, 600,
       { "sap-planet-discovery-aquara" }),
  tech("sap-storm-anchor", "__base__/graphics/icons/accumulator.png", { "sap-storm-anchor" }, 1000,
       { "sap-storm-shield", "electric-energy-accumulators" }),
})
