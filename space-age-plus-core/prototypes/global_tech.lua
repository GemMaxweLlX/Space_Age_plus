-- Глобальные технологии (docs: Техи планет → Глобальные).
-- Система жидкостей высокого класса открывается на Solaris (если модуль установлен — после
-- открытия Solaris), но постройки работают везде.

local sap = require("prototypes.api")

local TINT = { r = 1, g = 0.8, b = 0.6, a = 1 }
local FLUID_PACKS = {
  { "automation-science-pack", 1 }, { "logistic-science-pack", 1 }, { "chemical-science-pack", 1 },
  { "space-science-pack", 1 }, { "metallurgic-science-pack", 1 },
}
local FLUID_TECH = {
  name = "sap-high-grade-fluids", icon = "__base__/graphics/icons/pipe.png", count = 800,
  prerequisites = { "metallurgic-science-pack" }, science = FLUID_PACKS,
}

local function scale_fluid_boxes(entity, factor)
  for _, key in pairs({ "fluid_box", "output_fluid_box" }) do
    if entity[key] and entity[key].volume then entity[key].volume = entity[key].volume * factor end
  end
end

-- Трубы сверхвысоких температур: любые жидкости включая лаву, вдвое больший объём (поток).
sap.upgrade({
  base = "pipe", name = "sap-high-temperature-pipe", tint = TINT,
  change = function(e) scale_fluid_boxes(e, 2) e.fast_replaceable_group = "pipe" end,
  ingredients = { { "pipe", 1 }, { "tungsten-plate", 1 } }, time = 1, tech = FLUID_TECH,
})
sap.upgrade({
  base = "pipe-to-ground", name = "sap-high-temperature-pipe-to-ground", tint = TINT,
  change = function(e) scale_fluid_boxes(e, 2) e.fast_replaceable_group = "pipe" end,
  ingredients = { { "pipe-to-ground", 2 }, { "tungsten-plate", 4 } }, time = 2, result_count = 2, tech = FLUID_TECH,
})
-- Помпа Mk2: давление на больших расстояниях.
sap.upgrade({
  base = "pump", name = "sap-pump-mk2", tint = TINT,
  change = function(e) e.pumping_speed = e.pumping_speed * 2 scale_fluid_boxes(e, 2) end,
  ingredients = { { "pump", 1 }, { "tungsten-plate", 5 }, { "electric-engine-unit", 2 } }, tech = FLUID_TECH,
})
-- Сверхпрочный насос: 2400/с, любые жидкости (F1).
sap.upgrade({
  base = "offshore-pump", name = "sap-heavy-duty-pump", tint = TINT,
  change = function(e) e.pumping_speed = 40 scale_fluid_boxes(e, 4) end,
  ingredients = { { "offshore-pump", 2 }, { "tungsten-plate", 10 }, { "electric-engine-unit", 5 } }, tech = FLUID_TECH,
})
-- Улучшенная нефтекачалка Mk2: все жидкие ресурсы быстрее, меньше энергии.
sap.upgrade({
  base = "pumpjack", name = "sap-pumpjack-mk2", tint = TINT,
  change = function(e) e.mining_speed = e.mining_speed * 2 e.energy_usage = "70kW" end,
  ingredients = { { "pumpjack", 1 }, { "tungsten-carbide", 10 }, { "electric-engine-unit", 5 } }, tech = FLUID_TECH,
})

-- Паровая турбина Mk2: энергия + 90% пара возвращается водой.
sap.upgrade({
  base = "steam-turbine", name = "sap-steam-turbine-mk2", tint = { r = 0.7, g = 0.9, b = 1, a = 1 },
  change = function(e) e.fluid_usage_per_tick = e.fluid_usage_per_tick * 1.5 end,
  ingredients = { { "steam-turbine", 1 }, { "processing-unit", 5 }, { "low-density-structure", 5 } },
  tech = {
    name = "sap-steam-turbine-mk2", icon = "__base__/graphics/icons/steam-turbine.png", count = 600,
    prerequisites = { "nuclear-power", "low-density-structure" },
    science = { { "automation-science-pack", 1 }, { "logistic-science-pack", 1 }, { "chemical-science-pack", 1 },
                { "production-science-pack", 1 } },
  },
})
sap.register_condensing_generator("sap-steam-turbine-mk2", 0.9)

-- Цистерна: 500 единиц жидкости (бочка = 100). Рецепты наполнения — data-updates.lua.
data:extend({
  {
    type = "item", name = "sap-cistern",
    icons = { { icon = "__base__/graphics/icons/storage-tank.png", icon_size = 64, tint = { r = 0.8, g = 0.8, b = 0.8, a = 1 } } },
    subgroup = "intermediate-product", order = "z[sap-cistern]", stack_size = 10,
  },
  {
    type = "recipe", name = "sap-cistern", enabled = false, energy_required = 4,
    ingredients = { { type = "item", name = "steel-plate", amount = 5 } },
    results = { { type = "item", name = "sap-cistern", amount = 1 } },
  },
  {
    type = "technology", name = "sap-cistern",
    icons = { { icon = "__base__/graphics/icons/storage-tank.png", icon_size = 64 } },
    effects = { { type = "unlock-recipe", recipe = "sap-cistern" } },
    prerequisites = { "fluid-handling" },
    unit = { count = 150, time = 30, ingredients = { { "automation-science-pack", 1 }, { "logistic-science-pack", 1 } } },
  },
})
