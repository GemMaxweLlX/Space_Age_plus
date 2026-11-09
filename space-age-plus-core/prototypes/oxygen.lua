-- Система кислорода (docs: Глобальные механики → Кислород).
--   Атмосферный коллектор — собирает местный воздух, свой рецепт для каждой планеты,
--                           не работает без атмосферы.
--   Генератор кислорода   — производит кислород из ресурсов, работает везде.
--   Распределитель        — потребляет кислород и создаёт вокруг себя пузырь с воздухом.
--
-- Графика и баланс — временные (копии ванильного химзавода с тонировкой иконок).

local util = require("util")
local sap = require("prototypes.api")

local RADIUS = settings.startup["sap-oxygen-distributor-radius"].value

local OXYGEN_TINT = { r = 0.55, g = 0.85, b = 1.0, a = 1.0 }

local function tinted_icon(path, tint)
  return { { icon = path, icon_size = 64, tint = tint } }
end

local function copy_machine(name, icon_tint, categories)
  local e = util.table.deepcopy(data.raw["assembling-machine"]["chemical-plant"])
  e.name = name
  e.icons = tinted_icon("__base__/graphics/icons/chemical-plant.png", icon_tint)
  e.icon = nil
  e.minable = { mining_time = 0.2, result = name }
  e.crafting_categories = categories
  e.fast_replaceable_group = nil
  e.next_upgrade = nil
  e.surface_conditions = nil
  return e
end

local function building_item(name, tint, order)
  return {
    type = "item",
    name = name,
    icons = tinted_icon("__base__/graphics/icons/chemical-plant.png", tint),
    subgroup = "sap-oxygen",
    order = order,
    place_result = name,
    stack_size = 20,
  }
end

local function consumable_item(name, icon, tint, order)
  return {
    type = "item",
    name = name,
    icons = tinted_icon(icon, tint),
    subgroup = "sap-oxygen",
    order = order,
    stack_size = 100,
  }
end

data:extend({
  { type = "damage-type", name = "sap-suffocation" },

  { type = "item-subgroup", name = "sap-oxygen", group = "intermediate-products", order = "z-sap-a" },

  { type = "recipe-category", name = "sap-oxygen-collection" },
  { type = "recipe-category", name = "sap-oxygen-generation" },
  { type = "recipe-category", name = "sap-oxygen-distribution" },

  {
    type = "fluid",
    name = "sap-oxygen",
    icons = tinted_icon("__base__/graphics/icons/fluid/steam.png", OXYGEN_TINT),
    subgroup = "fluid",
    order = "z-sap-oxygen",
    default_temperature = 15,
    base_color = { r = 0.45, g = 0.75, b = 1.0 },
    flow_color = { r = 0.75, g = 0.9, b = 1.0 },
  },
})

-- Постройки -------------------------------------------------------------------

local collector = copy_machine("sap-atmospheric-collector", { r = 0.6, g = 0.9, b = 1.0 },
  { "sap-oxygen-collection" })

local generator = copy_machine("sap-oxygen-generator", { r = 0.5, g = 0.7, b = 1.0 },
  { "sap-oxygen-generation" })

local distributor = copy_machine("sap-oxygen-distributor", { r = 0.8, g = 0.95, b = 1.0 },
  { "sap-oxygen-distribution" })
distributor.fixed_recipe = "sap-oxygen-distribution"
distributor.radius_visualisation_specification = {
  sprite = {
    filename = "__base__/graphics/entity/electric-mining-drill/electric-mining-drill-radius-visualization.png",
    width = 10,
    height = 10,
  },
  distance = RADIUS,
}

data:extend({
  collector, generator, distributor,
  building_item("sap-atmospheric-collector", { r = 0.6, g = 0.9, b = 1.0 }, "a"),
  building_item("sap-oxygen-generator", { r = 0.5, g = 0.7, b = 1.0 }, "b"),
  building_item("sap-oxygen-distributor", { r = 0.8, g = 0.95, b = 1.0 }, "c"),
})

-- Расходники коллектора по планетам ----------------------------------------------

data:extend({
  consumable_item("sap-air-filter", "__base__/graphics/icons/iron-gear-wheel.png",
    { r = 0.9, g = 0.9, b = 0.6 }, "d-a"),
  consumable_item("sap-biofilter", "__base__/graphics/icons/iron-gear-wheel.png",
    { r = 0.5, g = 0.9, b = 0.4 }, "d-b"),
  consumable_item("sap-air-concentrator", "__base__/graphics/icons/iron-gear-wheel.png",
    { r = 0.6, g = 0.8, b = 1.0 }, "d-c"),
})

-- Рецепты ---------------------------------------------------------------------

local function oxygen_result(amount)
  return { { type = "fluid", name = "sap-oxygen", amount = amount } }
end

-- Коллектор работает только при давлении своей планеты (ванильные значения Space Age).
local collector_recipe = sap.oxygen_collector_recipe

data:extend({
  -- Генератор: работает везде
  {
    type = "recipe",
    name = "sap-oxygen-electrolysis",
    category = "sap-oxygen-generation",
    subgroup = "sap-oxygen",
    order = "f-a",
    enabled = false,
    energy_required = 2,
    ingredients = { { type = "fluid", name = "water", amount = 100 } },
    results = oxygen_result(50),
    main_product = "sap-oxygen",
  },
  {
    type = "recipe",
    name = "sap-oxygen-from-calcite",
    category = "sap-oxygen-generation",
    subgroup = "sap-oxygen",
    order = "f-b",
    enabled = false,
    energy_required = 2,
    ingredients = { { type = "item", name = "calcite", amount = 1 } },
    results = oxygen_result(50),
    main_product = "sap-oxygen",
  },

  -- Коллектор: по планетам
  collector_recipe("fulgora", 800, { { type = "item", name = "sap-air-filter", amount = 1 } }),
  collector_recipe("gleba", 2000, { { type = "item", name = "sap-biofilter", amount = 1 } }),
  collector_recipe("aquilo", 300, { { type = "item", name = "sap-air-concentrator", amount = 1 } }),

  -- Распределитель: просто расходует кислород, пока работает — вокруг есть воздух
  {
    type = "recipe",
    name = "sap-oxygen-distribution",
    category = "sap-oxygen-distribution",
    icons = tinted_icon("__base__/graphics/icons/fluid/steam.png", OXYGEN_TINT),
    hidden = true,
    enabled = false,
    energy_required = 1,
    ingredients = { { type = "fluid", name = "sap-oxygen", amount = 5 } },
    results = {},
  },

  -- Постройки и расходники
  {
    type = "recipe", name = "sap-atmospheric-collector", enabled = false, energy_required = 5,
    ingredients = {
      { type = "item", name = "steel-plate", amount = 10 },
      { type = "item", name = "electronic-circuit", amount = 10 },
      { type = "item", name = "pipe", amount = 10 },
    },
    results = { { type = "item", name = "sap-atmospheric-collector", amount = 1 } },
  },
  {
    type = "recipe", name = "sap-oxygen-generator", enabled = false, energy_required = 5,
    ingredients = {
      { type = "item", name = "steel-plate", amount = 10 },
      { type = "item", name = "advanced-circuit", amount = 5 },
      { type = "item", name = "pipe", amount = 10 },
    },
    results = { { type = "item", name = "sap-oxygen-generator", amount = 1 } },
  },
  {
    type = "recipe", name = "sap-oxygen-distributor", enabled = false, energy_required = 5,
    ingredients = {
      { type = "item", name = "steel-plate", amount = 5 },
      { type = "item", name = "electronic-circuit", amount = 5 },
      { type = "item", name = "pipe", amount = 5 },
    },
    results = { { type = "item", name = "sap-oxygen-distributor", amount = 1 } },
  },
  {
    type = "recipe", name = "sap-air-filter", enabled = false, energy_required = 2,
    ingredients = {
      { type = "item", name = "iron-plate", amount = 1 },
      { type = "item", name = "carbon", amount = 1 },
    },
    results = { { type = "item", name = "sap-air-filter", amount = 1 } },
  },
  {
    type = "recipe", name = "sap-biofilter", enabled = false, energy_required = 2,
    ingredients = {
      { type = "item", name = "plastic-bar", amount = 1 },
      { type = "item", name = "yumako-mash", amount = 2 },
    },
    results = { { type = "item", name = "sap-biofilter", amount = 1 } },
  },
  {
    type = "recipe", name = "sap-air-concentrator", enabled = false, energy_required = 2,
    ingredients = {
      { type = "item", name = "steel-plate", amount = 1 },
      { type = "item", name = "lithium-plate", amount = 1 },
    },
    results = { { type = "item", name = "sap-air-concentrator", amount = 1 } },
  },
})

-- Технология ------------------------------------------------------------------

local function unlock(recipe) return { type = "unlock-recipe", recipe = recipe } end

data:extend({
  {
    type = "technology",
    name = "sap-oxygen-systems",
    icons = tinted_icon("__base__/graphics/icons/fluid/steam.png", OXYGEN_TINT),
    prerequisites = { "space-platform" },
    effects = {
      unlock("sap-oxygen-generator"),
      unlock("sap-oxygen-distributor"),
      unlock("sap-atmospheric-collector"),
      unlock("sap-oxygen-distribution"),
      unlock("sap-oxygen-electrolysis"),
      unlock("sap-oxygen-from-calcite"),
      unlock("sap-air-filter"),
      unlock("sap-biofilter"),
      unlock("sap-air-concentrator"),
      unlock("sap-oxygen-collection-fulgora"),
      unlock("sap-oxygen-collection-gleba"),
      unlock("sap-oxygen-collection-aquilo"),
    },
    unit = {
      count = 300,
      time = 30,
      ingredients = {
        { "automation-science-pack", 1 },
        { "logistic-science-pack", 1 },
        { "chemical-science-pack", 1 },
      },
    },
  },
})
