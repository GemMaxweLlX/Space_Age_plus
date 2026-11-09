-- Постройки, предметы и технологии Nivar (docs: Техи планет → Nivar).
--   Лифт — общий склад между поверхностью и пещерами, через него спускается игрок.
--   Глубинный бур — бурит сквозь лёд и поднимает ресурсы пещер, не спускаясь туда.
--   Криолампы — свет в тёмных пещерах.
--   Криообогреватель и криозащитный купол — защита от криобури (scripts/cryostorm.lua).

local util = require("util")
local sap = require("__space-age-plus-core__.prototypes.api")

local TINT = { r = 0.7, g = 0.85, b = 1.0, a = 1.0 }
local NIVAR_PRESSURE = 250

local NIVAR_PACKS = {
  { "automation-science-pack", 1 }, { "logistic-science-pack", 1 }, { "chemical-science-pack", 1 },
  { "space-science-pack", 1 }, { "cryogenic-science-pack", 1 },
}

local function tinted(icon) return { { icon = icon, icon_size = 64, tint = TINT } } end

local function entity_copy(type_name, base, name, icon)
  local e = util.table.deepcopy(data.raw[type_name][base])
  e.name = name
  e.icon = nil
  e.icons = tinted(icon)
  e.minable = { mining_time = 0.3, result = name }
  e.next_upgrade = nil
  e.fast_replaceable_group = nil
  return e
end

local function place_item(entity, order)
  return {
    type = "item", name = entity.name, icons = entity.icons, subgroup = "production-machine",
    order = "z[sap-nivar]-" .. order, place_result = entity.name, stack_size = 20,
  }
end

local elevator = entity_copy("linked-container", "linked-chest", "sap-nivar-elevator", "__base__/graphics/icons/steel-chest.png")
elevator.inventory_size = 48
elevator.gui_mode = "none"
elevator.hidden = nil
elevator.hidden_in_factoriopedia = nil

local drill = entity_copy("assembling-machine", "assembling-machine-2", "sap-deep-drill",
  "__base__/graphics/icons/electric-mining-drill.png")
drill.crafting_categories = { "sap-deep-drilling" }
drill.energy_usage = "500kW"

local lamp = entity_copy("lamp", "small-lamp", "sap-cryo-lamp", "__base__/graphics/icons/small-lamp.png")
lamp.light = { intensity = 1, size = 60, color = { r = 0.8, g = 0.9, b = 1 } }
lamp.light_when_colored = lamp.light
lamp.always_on = true
lamp.heating_energy = "0W" -- стабильное освещение при экстремальном холоде

local heater = entity_copy("lamp", "small-lamp", "sap-cryo-heater", "__base__/graphics/icons/heat-pipe.png")
heater.energy_usage_per_tick = "100kW"
heater.light = { intensity = 0.4, size = 8, color = { r = 1, g = 0.6, b = 0.3 } }
heater.light_when_colored = heater.light
heater.always_on = true

local dome = entity_copy("radar", "radar", "sap-cryo-dome", "__base__/graphics/icons/radar.png")
dome.energy_usage = "2MW"
dome.max_distance_of_sector_revealed = 0
dome.max_distance_of_nearby_sector_revealed = 1

data:extend({
  { type = "recipe-category", name = "sap-deep-drilling" },
  elevator, drill, lamp, heater, dome,
  place_item(elevator, "a"), place_item(drill, "b"), place_item(lamp, "c"), place_item(heater, "d"),
  place_item(dome, "e"),
  {
    type = "item", name = "sap-cryo-concentrator", icons = tinted("__base__/graphics/icons/iron-gear-wheel.png"),
    subgroup = "sap-oxygen", order = "d-f", stack_size = 100,
  },
  {
    type = "item", name = "sap-nivalite-wire", icons = tinted("__base__/graphics/icons/copper-cable.png"),
    subgroup = "intermediate-product", order = "z[sap-nivar]-a", stack_size = 200,
  },
})

local function recipe(def)
  def.type = "recipe"
  def.enabled = false
  return def
end

local function drilling(ore, amount, seconds)
  return recipe({
    name = "sap-deep-drilling-" .. ore, categories = { "sap-deep-drilling" }, energy_required = seconds,
    icons = data.raw.item["sap-" .. ore].icons,
    ingredients = {},
    results = { { type = "item", name = "sap-" .. ore, amount = amount } },
    surface_conditions = { { property = "pressure", min = NIVAR_PRESSURE, max = NIVAR_PRESSURE } },
  })
end

data:extend({
  drilling("nivalite", 1, 4),
  drilling("cryolite", 2, 4),
  drilling("dark-ice", 2, 3),
  recipe({
    name = "sap-nivar-elevator", energy_required = 20,
    ingredients = {
      { type = "item", name = "steel-plate", amount = 50 }, { type = "item", name = "electric-engine-unit", amount = 20 },
      { type = "item", name = "lithium-plate", amount = 20 },
    },
    results = { { type = "item", name = "sap-nivar-elevator", amount = 1 } },
  }),
  recipe({
    name = "sap-deep-drill", energy_required = 20,
    ingredients = {
      { type = "item", name = "electric-mining-drill", amount = 4 }, { type = "item", name = "lithium-plate", amount = 10 },
      { type = "item", name = "processing-unit", amount = 10 },
    },
    results = { { type = "item", name = "sap-deep-drill", amount = 1 } },
  }),
  recipe({
    name = "sap-cryo-lamp", energy_required = 2,
    ingredients = { { type = "item", name = "small-lamp", amount = 1 }, { type = "item", name = "sap-cryolite", amount = 2 } },
    results = { { type = "item", name = "sap-cryo-lamp", amount = 1 } },
  }),
  recipe({
    name = "sap-cryo-heater", energy_required = 5,
    ingredients = { { type = "item", name = "heat-pipe", amount = 4 }, { type = "item", name = "sap-cryolite", amount = 5 } },
    results = { { type = "item", name = "sap-cryo-heater", amount = 1 } },
  }),
  recipe({
    name = "sap-cryo-dome", energy_required = 10,
    ingredients = {
      { type = "item", name = "sap-cryo-heater", amount = 4 }, { type = "item", name = "processing-unit", amount = 10 },
      { type = "item", name = "sap-dark-ice", amount = 20 },
    },
    results = { { type = "item", name = "sap-cryo-dome", amount = 1 } },
  }),
  recipe({
    name = "sap-cryo-concentrator", energy_required = 2,
    ingredients = { { type = "item", name = "sap-cryolite", amount = 1 }, { type = "item", name = "steel-plate", amount = 1 } },
    results = { { type = "item", name = "sap-cryo-concentrator", amount = 1 } },
  }),
  recipe({
    name = "sap-nivalite-wire", energy_required = 1,
    ingredients = { { type = "item", name = "sap-nivalite", amount = 1 }, { type = "item", name = "copper-cable", amount = 2 } },
    results = { { type = "item", name = "sap-nivalite-wire", amount = 2 } },
  }),
  sap.oxygen_collector_recipe("nivar", NIVAR_PRESSURE, { { type = "item", name = "sap-cryo-concentrator", amount = 1 } }),
})

for _, r in pairs({ "sap-nivar-elevator", "sap-cryo-lamp", "sap-cryo-heater", "sap-cryo-concentrator",
                    "sap-oxygen-collection-nivar" }) do
  table.insert(data.raw.technology["sap-planet-discovery-nivar"].effects, { type = "unlock-recipe", recipe = r })
end

local function tech(name, icon, recipes, count, prereqs)
  local effects = {}
  for _, r in pairs(recipes) do effects[#effects + 1] = { type = "unlock-recipe", recipe = r } end
  return {
    type = "technology", name = name, icons = tinted(icon), effects = effects,
    prerequisites = prereqs, unit = { count = count, time = 60, ingredients = NIVAR_PACKS },
  }
end

data:extend({
  tech("sap-deep-drill", "__base__/graphics/icons/electric-mining-drill.png",
       { "sap-deep-drill", "sap-deep-drilling-nivalite", "sap-deep-drilling-cryolite", "sap-deep-drilling-dark-ice" },
       800, { "sap-planet-discovery-nivar" }),
  tech("sap-cryo-dome", "__base__/graphics/icons/radar.png", { "sap-cryo-dome" }, 1000, { "sap-planet-discovery-nivar" }),
  tech("sap-nivalite-wire", "__base__/graphics/icons/copper-cable.png", { "sap-nivalite-wire" }, 600,
       { "sap-planet-discovery-nivar" }),
})

-- Остальные технологии Nivar (docs: Техи планет → Nivar) ----------------------------------
local function nivar_tech(name, icon, count, prerequisite)
  return { name = name, icon = icon, count = count or 600,
           prerequisites = { "sap-planet-discovery-nivar", prerequisite }, science = NIVAR_PACKS }
end

-- Криообогреватель Mk2: меньше потребление, больше радиус (scripts/cryostorm.lua).
sap.upgrade({
  base = "sap-cryo-heater", name = "sap-cryo-heater-mk2", tint = { r = 0.5, g = 0.7, b = 1, a = 1 },
  change = function(e) e.energy_usage_per_tick = "70kW" end,
  ingredients = { { "sap-cryo-heater", 2 }, { "sap-nivalite-wire", 10 } },
  tech = nivar_tech("sap-cryo-heater-mk2", "__base__/graphics/icons/heat-pipe.png", 700),
})
-- Криопроводящие трубы и пещерный конвейер: не замерзают без обогрева.
sap.upgrade({
  base = "pipe", name = "sap-cryo-pipe", tint = TINT,
  change = function(e) e.heating_energy = "0W" e.fast_replaceable_group = "pipe" end,
  ingredients = { { "pipe", 1 }, { "sap-cryolite", 1 } }, time = 1,
  tech = nivar_tech("sap-cryo-pipe", "__base__/graphics/icons/pipe.png", 400),
})
sap.upgrade({
  base = "pipe-to-ground", name = "sap-cryo-pipe-to-ground", tint = TINT,
  change = function(e) e.heating_energy = "0W" e.fast_replaceable_group = "pipe" end,
  ingredients = { { "pipe-to-ground", 2 }, { "sap-cryolite", 4 } }, time = 2, result_count = 2,
  tech = nivar_tech("sap-cryo-pipe", "__base__/graphics/icons/pipe.png", 400),
})
sap.upgrade({
  base = "express-transport-belt", name = "sap-cave-belt", tint = TINT,
  change = function(e) e.heating_energy = "0W" end,
  ingredients = { { "express-transport-belt", 1 }, { "sap-cryolite", 1 } }, time = 1,
  tech = nivar_tech("sap-cave-belt", "__base__/graphics/icons/express-transport-belt.png", 500),
})
-- Глубинный бур Mk2: быстрее, глубже.
sap.upgrade({
  base = "sap-deep-drill", name = "sap-deep-drill-mk2", tint = { r = 0.5, g = 0.7, b = 1, a = 1 },
  change = function(e) e.crafting_speed = e.crafting_speed * 2 end,
  ingredients = { { "sap-deep-drill", 1 }, { "sap-nivalite-wire", 20 }, { "sap-guardian-core", 1 } },
  tech = nivar_tech("sap-deep-drill-mk2", "__base__/graphics/icons/electric-mining-drill.png", 1000, "sap-deep-drill"),
})
-- Криоброня: защита от атак Вьюги и ледяного дыхания.
sap.upgrade({
  base = "power-armor", name = "sap-cryo-armor", tint = TINT,
  change = function(_, item)
    item.resistances = { { type = "physical", decrease = 10, percent = 45 }, { type = "acid", decrease = 10, percent = 50 },
                         { type = "explosion", decrease = 10, percent = 40 } }
  end,
  ingredients = { { "power-armor", 1 }, { "sap-cryo-carapace", 30 }, { "sap-nivalite-wire", 20 } },
  tech = nivar_tech("sap-cryo-armor", "__base__/graphics/icons/power-armor.png", 800, "power-armor"),
})

-- Защита от криобури без энергии (docs: Техи планет → Nivar → Защита от холода) ------------
-- Изолирующий фундамент: машина на нём замерзает в криобурю вдвое медленнее.
local foundation_tile = util.table.deepcopy(data.raw.tile["refined-concrete"])
foundation_tile.name = "sap-insulating-foundation"
foundation_tile.minable = { mining_time = 0.1, result = "sap-insulating-foundation" }
foundation_tile.tint = { r = 0.7, g = 0.8, b = 1, a = 1 }
foundation_tile.frozen_variant = nil -- иначе на холодной планете плитка превращается в замёрзший бетон
foundation_tile.thawed_variant = nil
local foundation_item = util.table.deepcopy(data.raw.item["refined-concrete"])
foundation_item.name = "sap-insulating-foundation"
foundation_item.icon = nil
foundation_item.icons = tinted("__base__/graphics/icons/refined-concrete.png")
foundation_item.place_as_tile.result = "sap-insulating-foundation"
foundation_item.order = "z[sap-nivar]-f"
data:extend({
  foundation_tile, foundation_item,
  recipe({
    name = "sap-insulating-foundation", energy_required = 2,
    ingredients = { { type = "item", name = "refined-concrete", amount = 10 }, { type = "item", name = "sap-cryolite", amount = 2 } },
    results = { { type = "item", name = "sap-insulating-foundation", amount = 10 } },
  }),
  tech("sap-insulating-foundation", "__base__/graphics/icons/refined-concrete.png", { "sap-insulating-foundation" }, 500,
       { "sap-planet-discovery-nivar" }),
})
-- Термоизоляционные стены: машина, у которой такие стены есть со всех четырёх сторон
-- (в пределах 16 клеток), замерзает вдвое медленнее (scripts/cryostorm.lua).
sap.upgrade({
  base = "stone-wall", name = "sap-insulated-wall", tint = TINT,
  change = function(e) e.max_health = e.max_health * 2 end,
  ingredients = { { "stone-wall", 1 }, { "sap-dark-ice", 2 } }, time = 1,
  tech = nivar_tech("sap-insulated-wall", "__base__/graphics/icons/wall.png", 500),
})
-- Пещерная броня: лёгкая, в пещерах персонаж бегает на 30% быстрее (scripts/caves.lua).
sap.upgrade({
  base = "heavy-armor", name = "sap-cave-armor", tint = { r = 0.4, g = 0.45, b = 0.6, a = 1 },
  ingredients = { { "heavy-armor", 1 }, { "sap-ice-spike", 10 }, { "sap-cryo-gland", 5 } },
  tech = nivar_tech("sap-cave-armor", "__base__/graphics/icons/heavy-armor.png", 600),
})
