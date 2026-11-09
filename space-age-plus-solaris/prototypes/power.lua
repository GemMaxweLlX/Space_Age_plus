-- Энергетика Solaris (docs: Solaris → Коронарная масса: «Приёмник → бойлер → мега-турбина →
-- 90% воды → бойлер», восполнение 10% воды — лёд или цистерны с платформы).
--   Сверхбойлер — теплообменник с большим запасом тепла; тепло в него передаёт захватчик
--   луча, стоящий рядом (scripts/power.lua).
--   Мега-турбина — только для сверхбойлера: огромная выработка, 90% пара возвращается водой.

local util = require("util")
local sap = require("__space-age-plus-core__.prototypes.api")

local TINT = { r = 1.0, g = 0.75, b = 0.45, a = 1.0 }
local PACKS = {
  { "automation-science-pack", 1 }, { "logistic-science-pack", 1 }, { "chemical-science-pack", 1 },
  { "space-science-pack", 1 }, { "metallurgic-science-pack", 1 },
}

local function copy(type_name, base, name, icon)
  local e = util.table.deepcopy(data.raw[type_name][base])
  e.name = name
  e.icon = nil
  e.icons = { { icon = icon, icon_size = 64, tint = TINT } }
  e.minable = { mining_time = 0.5, result = name }
  e.next_upgrade = nil
  e.fast_replaceable_group = nil
  return e
end

local function item(entity, order)
  return {
    type = "item", name = entity.name, icons = entity.icons, subgroup = "energy",
    order = "z[sap-solaris]-" .. order, place_result = entity.name, stack_size = 10,
  }
end

local boiler = copy("boiler", "heat-exchanger", "sap-super-boiler", "__base__/graphics/icons/heat-boiler.png")
boiler.energy_consumption = "30MW"
boiler.energy_source.max_temperature = 1000
boiler.energy_source.specific_heat = "10MJ"
boiler.energy_source.max_transfer = "60MW"

local boiler2 = util.table.deepcopy(boiler)
boiler2.name = "sap-super-boiler-mk2"
boiler2.minable.result = "sap-super-boiler-mk2"
boiler2.energy_consumption = "60MW"
boiler2.energy_source.max_transfer = "120MW"

local turbine = copy("generator", "steam-turbine", "sap-mega-turbine", "__base__/graphics/icons/steam-turbine.png")
turbine.fluid_usage_per_tick = 4
turbine.effectivity = 1
sap.register_condensing_generator("sap-mega-turbine", 0.9)

data:extend({
  boiler, boiler2, turbine,
  item(boiler, "b"), item(boiler2, "c"), item(turbine, "d"),
  {
    type = "recipe", name = "sap-super-boiler", enabled = false, energy_required = 10,
    ingredients = {
      { type = "item", name = "heat-exchanger", amount = 2 }, { type = "item", name = "sap-heat-resistant-alloy", amount = 20 },
    },
    results = { { type = "item", name = "sap-super-boiler", amount = 1 } },
  },
  {
    type = "recipe", name = "sap-super-boiler-mk2", enabled = false, energy_required = 15,
    ingredients = {
      { type = "item", name = "sap-super-boiler", amount = 1 }, { type = "item", name = "sap-molten-core", amount = 1 },
      { type = "item", name = "tungsten-carbide", amount = 20 },
    },
    results = { { type = "item", name = "sap-super-boiler-mk2", amount = 1 } },
  },
  {
    type = "recipe", name = "sap-mega-turbine", enabled = false, energy_required = 15,
    ingredients = {
      { type = "item", name = "steam-turbine", amount = 3 }, { type = "item", name = "sap-heat-resistant-alloy", amount = 30 },
      { type = "item", name = "tungsten-plate", amount = 20 },
    },
    results = { { type = "item", name = "sap-mega-turbine", amount = 1 } },
  },
  {
    type = "technology", name = "sap-super-boiler",
    icons = { { icon = "__base__/graphics/icons/heat-boiler.png", icon_size = 64, tint = TINT } },
    effects = {
      { type = "unlock-recipe", recipe = "sap-super-boiler" },
      { type = "unlock-recipe", recipe = "sap-mega-turbine" },
    },
    prerequisites = { "sap-ray-catcher", "nuclear-power" },
    unit = { count = 1200, time = 60, ingredients = PACKS },
  },
  {
    type = "technology", name = "sap-super-boiler-mk2",
    icons = { { icon = "__base__/graphics/icons/heat-boiler.png", icon_size = 64, tint = { r = 1, g = 0.5, b = 0.3, a = 1 } } },
    effects = { { type = "unlock-recipe", recipe = "sap-super-boiler-mk2" } },
    prerequisites = { "sap-super-boiler" },
    unit = { count = 2000, time = 60, ingredients = PACKS },
  },
})
