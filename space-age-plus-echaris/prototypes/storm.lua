-- Постоянная магнитная буря Echaris (docs: Echaris → Постоянная буря; Вопросы реализации → I6).
--
-- Буря замедляет все машины на поверхности (surface.global_effect): постройки работают на
-- 50-70% от нормы. Стабилизатор — маяк со скрытым модулем, который ровно компенсирует
-- текущую силу бури у машин в своей зоне. Несколько стабилизаторов не складываются.
-- Сила бури меняется: модули стабилизаторов меняет скрипт (control.lua).

local util = require("util")

local TINT = { r = 0.75, g = 0.7, b = 1.0, a = 1.0 }

data:extend({
  { type = "module-category", name = "sap-storm-compensation" },
})

-- Уровни бури: 1 → машины на 70%, 2 → на 60%, 3 → на 50%.
for level, penalty in ipairs({ 0.3, 0.4, 0.5 }) do
  data:extend({
    {
      type = "module",
      name = "sap-storm-compensation-" .. level,
      icons = { { icon = "__base__/graphics/icons/speed-module.png", icon_size = 64, tint = TINT } },
      category = "sap-storm-compensation",
      tier = level,
      effect = { speed = penalty },
      hidden = true,
      hidden_in_factoriopedia = true,
      subgroup = "module",
      order = "z[sap]-" .. level,
      stack_size = 1,
      flags = { "not-stackable" },
    },
  })
end

-- Нужно, чтобы эффект N стабилизаторов в сумме был равен эффекту одного.
local profile = {}
for n = 1, 64 do profile[n] = 1 / n end

local stabilizer = util.table.deepcopy(data.raw.beacon["beacon"])
stabilizer.name = "sap-storm-stabilizer"
stabilizer.icons = { { icon = "__base__/graphics/icons/beacon.png", icon_size = 64, tint = TINT } }
stabilizer.icon = nil
stabilizer.minable = { mining_time = 0.2, result = "sap-storm-stabilizer" }
stabilizer.module_slots = 1
stabilizer.allowed_module_categories = { "sap-storm-compensation" }
stabilizer.allowed_effects = { "speed" }
stabilizer.distribution_effectivity = 1
stabilizer.distribution_effectivity_bonus_per_quality_level = 0
stabilizer.profile = profile
stabilizer.beacon_counter = "same_type"
stabilizer.supply_area_distance = 12
stabilizer.energy_usage = "800kW"
stabilizer.fast_replaceable_group = nil
stabilizer.next_upgrade = nil

data:extend({
  stabilizer,
  {
    type = "item",
    name = "sap-storm-stabilizer",
    icons = { { icon = "__base__/graphics/icons/beacon.png", icon_size = 64, tint = TINT } },
    subgroup = "module",
    order = "z[sap]-a[stabilizer]",
    place_result = "sap-storm-stabilizer",
    stack_size = 10,
  },
  {
    type = "recipe",
    name = "sap-storm-stabilizer",
    enabled = false,
    energy_required = 10,
    ingredients = {
      { type = "item", name = "supercapacitor", amount = 5 },
      { type = "item", name = "superconductor", amount = 5 },
      { type = "item", name = "steel-plate", amount = 10 },
      { type = "item", name = "processing-unit", amount = 5 },
    },
    results = { { type = "item", name = "sap-storm-stabilizer", amount = 1 } },
  },
})

table.insert(data.raw.technology["sap-planet-discovery-echaris"].effects,
  { type = "unlock-recipe", recipe = "sap-storm-stabilizer" })
