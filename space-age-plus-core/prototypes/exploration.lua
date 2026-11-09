-- Исследование планет (docs: Глобальные механики → Планеты).
--   Уровень 1 — телескоп: строится на Наувисе, показывает силуэты тел, открывает спутник 1.
--   Уровень 2 — спутник 1 поколения: ненадёжный, шанс найти тело (название и расстояние).
--               10 запусков (хардкор 30-50) → технология спутника 2 поколения.
--   Уровень 3 — спутник 2 поколения: надёжный, разведывает тело и открывает полёт к нему.
-- Логика — scripts/exploration.lua. Технологии спутников скрыты, пока их не откроет скрипт.

local util = require("util")

local TELESCOPE_TINT = { r = 0.8, g = 0.85, b = 1.0, a = 1.0 }

local telescope = util.table.deepcopy(data.raw.radar["radar"])
telescope.name = "sap-telescope"
telescope.icons = { { icon = "__base__/graphics/icons/radar.png", icon_size = 64, tint = TELESCOPE_TINT } }
telescope.icon = nil
telescope.minable = { mining_time = 0.2, result = "sap-telescope" }
telescope.fast_replaceable_group = nil
telescope.next_upgrade = nil

local function satellite_item(name, order)
  return {
    type = "item",
    name = name,
    icons = { { icon = "__base__/graphics/icons/satellite.png", icon_size = 64,
                tint = order == "a" and { r = 1, g = 0.85, b = 0.7, a = 1 } or nil } },
    subgroup = "space-related",
    order = "z[sap]-" .. order .. "[" .. name .. "]",
    stack_size = 1,
    weight = 1 * tons,
    send_to_orbit_mode = "automated",
  }
end

data:extend({
  telescope,
  {
    type = "item",
    name = "sap-telescope",
    icons = { { icon = "__base__/graphics/icons/radar.png", icon_size = 64, tint = TELESCOPE_TINT } },
    subgroup = "defensive-structure",
    order = "z[sap]-a[telescope]",
    place_result = "sap-telescope",
    stack_size = 10,
  },
  satellite_item("sap-satellite-mk1", "a"),
  satellite_item("sap-satellite-mk2", "b"),

  {
    type = "recipe", name = "sap-telescope", enabled = false, energy_required = 10,
    ingredients = {
      { type = "item", name = "steel-plate", amount = 20 },
      { type = "item", name = "electronic-circuit", amount = 20 },
      { type = "item", name = "iron-gear-wheel", amount = 10 },
    },
    results = { { type = "item", name = "sap-telescope", amount = 1 } },
  },
  {
    type = "recipe", name = "sap-satellite-mk1", enabled = false, energy_required = 10,
    ingredients = {
      { type = "item", name = "low-density-structure", amount = 20 },
      { type = "item", name = "solar-panel", amount = 10 },
      { type = "item", name = "processing-unit", amount = 10 },
      { type = "item", name = "radar", amount = 2 },
    },
    results = { { type = "item", name = "sap-satellite-mk1", amount = 1 } },
  },
  {
    type = "recipe", name = "sap-satellite-mk2", enabled = false, energy_required = 30,
    ingredients = {
      { type = "item", name = "low-density-structure", amount = 50 },
      { type = "item", name = "solar-panel", amount = 30 },
      { type = "item", name = "processing-unit", amount = 50 },
      { type = "item", name = "accumulator", amount = 20 },
      { type = "item", name = "radar", amount = 5 },
    },
    results = { { type = "item", name = "sap-satellite-mk2", amount = 1 } },
  },

  {
    type = "technology",
    name = "sap-telescope",
    icons = { { icon = "__base__/graphics/technology/radar.png", icon_size = 256, tint = TELESCOPE_TINT } },
    effects = { { type = "unlock-recipe", recipe = "sap-telescope" } },
    prerequisites = { "logistic-science-pack" },
    unit = {
      count = 100, time = 15,
      ingredients = { { "automation-science-pack", 1 }, { "logistic-science-pack", 1 } },
    },
  },
  {
    -- Открывается скриптом, когда на Наувисе построен телескоп.
    type = "technology",
    name = "sap-satellite-mk1",
    icons = { { icon = "__base__/graphics/icons/satellite.png", icon_size = 64 } },
    effects = { { type = "unlock-recipe", recipe = "sap-satellite-mk1" } },
    prerequisites = { "sap-telescope", "rocket-silo" },
    enabled = false,
    visible_when_disabled = false,
    unit = {
      count = 500, time = 30,
      ingredients = {
        { "automation-science-pack", 1 }, { "logistic-science-pack", 1 },
        { "chemical-science-pack", 1 }, { "production-science-pack", 1 },
        { "utility-science-pack", 1 },
      },
    },
  },
  {
    -- Открывается скриптом после нужного числа запусков спутника 1 поколения.
    type = "technology",
    name = "sap-satellite-mk2",
    icons = { { icon = "__base__/graphics/icons/satellite.png", icon_size = 64,
                tint = { r = 0.7, g = 1, b = 0.8, a = 1 } } },
    effects = { { type = "unlock-recipe", recipe = "sap-satellite-mk2" } },
    prerequisites = { "sap-satellite-mk1" },
    enabled = false,
    visible_when_disabled = false,
    unit = {
      count = 1000, time = 30,
      ingredients = {
        { "automation-science-pack", 1 }, { "logistic-science-pack", 1 },
        { "chemical-science-pack", 1 }, { "production-science-pack", 1 },
        { "utility-science-pack", 1 }, { "space-science-pack", 1 },
      },
    },
  },
})
