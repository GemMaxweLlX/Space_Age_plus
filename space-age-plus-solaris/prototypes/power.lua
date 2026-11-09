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

-- Остальные технологии Solaris (docs: Техи планет → Solaris) -------------------------------
local function solaris_tech(name, icon, count, prerequisite)
  return { name = name, icon = icon, count = count or 600,
           prerequisites = { "sap-planet-discovery-solaris", prerequisite }, science = PACKS }
end

local function fire_proof(e, percent)
  e.resistances = e.resistances or {}
  table.insert(e.resistances, { type = "fire", percent = percent })
end

-- Термит Mk2: улучшенное химсоединение, нужно для огнеупорных построек.
data:extend({
  {
    type = "item", name = "sap-thermite-mk2",
    icons = { { icon = "__base__/graphics/icons/explosives.png", icon_size = 64, tint = { r = 1, g = 0.4, b = 0.2, a = 1 } } },
    subgroup = "vulcanus-processes", order = "z[sap]-b2", stack_size = 100,
  },
  {
    type = "recipe", name = "sap-thermite-mk2", categories = { "chemistry" }, enabled = false, energy_required = 6,
    ingredients = {
      { type = "item", name = "sap-thermite", amount = 2 }, { type = "item", name = "sap-lava-clot", amount = 1 },
      { type = "fluid", name = "sulfuric-acid", amount = 20 },
    },
    results = { { type = "item", name = "sap-thermite-mk2", amount = 2 } },
  },
  {
    type = "technology", name = "sap-thermite-mk2",
    icons = { { icon = "__base__/graphics/icons/explosives.png", icon_size = 64, tint = TINT } },
    effects = { { type = "unlock-recipe", recipe = "sap-thermite-mk2" } },
    prerequisites = { "sap-thermite" }, unit = { count = 600, time = 60, ingredients = PACKS },
  },
})

-- Жаропрочный конвейер: 60/с (F2), не страдает от жары и холода.
sap.upgrade({
  base = "turbo-transport-belt", name = "sap-heat-resistant-belt", tint = TINT,
  change = function(e) fire_proof(e, 100) e.max_health = e.max_health * 2 e.heating_energy = "0W" end,
  ingredients = { { "turbo-transport-belt", 1 }, { "sap-heat-resistant-alloy", 1 } }, time = 1,
  tech = solaris_tech("sap-heat-resistant-belt", "__space-age__/graphics/icons/turbo-transport-belt.png", 800, "turbo-transport-belt"),
})
-- Радиатор Mk2: больше мощность отвода тепла (больший радиус, scripts/overheat.lua).
sap.upgrade({
  base = "sap-radiator", name = "sap-radiator-mk2", tint = { r = 1, g = 0.5, b = 0.2, a = 1 },
  change = function(e) e.energy_usage_per_tick = "120kW" end,
  ingredients = { { "sap-radiator", 2 }, { "sap-heat-resistant-crystal", 4 } },
  tech = solaris_tech("sap-radiator-mk2", "__base__/graphics/icons/heat-pipe.png", 600),
})
-- Термотрубки Mk2: выдерживают более высокие температуры.
sap.upgrade({
  base = "heat-pipe", name = "sap-heat-pipe-mk2", tint = TINT,
  change = function(e) e.heat_buffer.max_temperature = 2000 e.heat_buffer.max_transfer = "2GW" end,
  ingredients = { { "heat-pipe", 1 }, { "sap-heat-resistant-alloy", 2 } },
  tech = solaris_tech("sap-heat-pipe-mk2", "__base__/graphics/icons/heat-pipe.png", 700, "nuclear-power"),
})
-- Термоэлектрический генератор: пассивная энергия от перепада температур.
sap.upgrade({
  base = "solar-panel", name = "sap-thermoelectric-generator", tint = { r = 1, g = 0.6, b = 0.3, a = 1 },
  change = function(e) e.production = "150kW" end,
  ingredients = { { "solar-panel", 1 }, { "sap-heat-resistant-crystal", 5 }, { "copper-cable", 10 } },
  tech = solaris_tech("sap-thermoelectric-generator", "__base__/graphics/icons/solar-panel.png", 700, "solar-energy"),
})
-- Зонтик Mk2: перехватывает лучи на ещё большей площади.
sap.upgrade({
  base = "sap-coronal-umbrella", name = "sap-coronal-umbrella-mk2", tint = { r = 1, g = 0.5, b = 0.2, a = 1 },
  change = function(e) e.range_elongation = 70 end,
  ingredients = { { "sap-coronal-umbrella", 2 }, { "sap-heat-resistant-alloy", 10 } },
  tech = solaris_tech("sap-coronal-umbrella-mk2", "__space-age__/graphics/icons/lightning-rod.png", 800, "sap-coronal-umbrella"),
})
-- Жаропрочная броня и огнеупорные стены.
sap.upgrade({
  base = "heavy-armor", name = "sap-heat-resistant-armor", tint = TINT,
  change = function(_, armor) fire_proof(armor, 90) end,
  ingredients = { { "heavy-armor", 1 }, { "sap-heat-scales", 20 }, { "sap-heat-resistant-alloy", 10 } },
  tech = solaris_tech("sap-heat-resistant-armor", "__base__/graphics/icons/heavy-armor.png", 500),
})
sap.upgrade({
  base = "stone-wall", name = "sap-fireproof-wall", tint = TINT,
  change = function(e) fire_proof(e, 100) e.max_health = e.max_health * 3 end,
  ingredients = { { "stone-wall", 1 }, { "sap-thermite-mk2", 1 } }, time = 1,
  tech = solaris_tech("sap-fireproof-wall", "__base__/graphics/icons/wall.png", 500, "sap-thermite-mk2"),
})
