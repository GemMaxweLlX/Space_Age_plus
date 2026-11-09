-- Ресурсы, постройки и технологии Solaris, первая версия (docs: Техи планет → Solaris).
--   Ресурсы: магматическая руда, жаропрочные кристаллы.
--   Материалы: жаропрочный сплав, термит.
--   Коронарная масса: зонтик (громоотвод без выработки, огромный радиус) и захватчик луча
--   (поглощает луч и даёт энергию). Сверхбойлер и мега-турбина — следующая версия.
--   Перегрев: радиатор охлаждения защищает постройки рядом (scripts/overheat.lua).

local util = require("util")

local TINT = { r = 1.0, g = 0.75, b = 0.45, a = 1.0 }

local SOLARIS_PACKS = {
  { "automation-science-pack", 1 }, { "logistic-science-pack", 1 }, { "chemical-science-pack", 1 },
  { "space-science-pack", 1 }, { "metallurgic-science-pack", 1 },
}

local function tinted(icon, size) return { { icon = icon, icon_size = size or 64, tint = TINT } } end

-- Ресурсы ---------------------------------------------------------------------------

local function resource(name, base, item_base, tint)
  local r = util.table.deepcopy(data.raw.resource[base])
  r.name = name
  r.icon = nil
  r.icons = { { icon = data.raw.resource[base].icon, icon_size = 64, tint = tint } }
  r.minable.result = name
  r.minable.results = nil
  if r.stages and r.stages.sheet then r.stages.sheet.tint = tint end
  -- autoplace остаётся (вероятность 0), а реальное место задаёт карта Solaris (property_expression_names)
  local item = util.table.deepcopy(data.raw.item[item_base])
  item.name = name
  item.icon = nil
  item.icons = { { icon = data.raw.item[item_base].icon, icon_size = 64, tint = tint } }
  item.random_tint_color = nil
  return r, item
end

local ore, ore_item = resource("sap-magmatic-ore", "tungsten-ore", "tungsten-ore", { r = 1, g = 0.5, b = 0.3, a = 1 })
local crystal, crystal_item = resource("sap-heat-resistant-crystal", "calcite", "calcite", { r = 1, g = 0.9, b = 0.4, a = 1 })
data:extend({ ore, ore_item, crystal, crystal_item })

-- Вулканический газ и расплавленный металл (docs: Solaris → Ресурсы) ----------------------
local GAS_COLOR = { r = 0.8, g = 0.5, b = 0.3 }
local METAL_COLOR = { r = 1, g = 0.45, b = 0.15 }
local vent = util.table.deepcopy(data.raw.resource["sulfuric-acid-geyser"])
vent.name = "sap-volcanic-vent"
vent.icon = nil
vent.icons = tinted("__space-age__/graphics/icons/sulfuric-acid-geyser.png")
vent.minable.results = { { type = "fluid", name = "sap-volcanic-gas", amount_min = 10, amount_max = 10 } }
vent.minable.result = nil
vent.autoplace = { probability_expression = 0 } -- место задаёт карта Solaris
data:extend({
  vent,
  {
    type = "fluid", name = "sap-volcanic-gas", subgroup = "fluid", order = "z[sap]-a",
    icons = tinted("__base__/graphics/icons/fluid/petroleum-gas.png"),
    default_temperature = 400, max_temperature = 400, gas_temperature = 0,
    base_color = GAS_COLOR, flow_color = GAS_COLOR,
  },
  {
    type = "fluid", name = "sap-molten-metal", subgroup = "fluid", order = "z[sap]-b",
    icons = tinted("__space-age__/graphics/icons/fluid/molten-iron.png"),
    default_temperature = 1600, max_temperature = 2000,
    base_color = METAL_COLOR, flow_color = METAL_COLOR,
  },
})

-- Материалы -------------------------------------------------------------------------

data:extend({
  {
    type = "item", name = "sap-heat-resistant-alloy",
    icons = tinted("__space-age__/graphics/icons/tungsten-plate.png"),
    subgroup = "vulcanus-processes", order = "z[sap]-a", stack_size = 100,
  },
  {
    type = "item", name = "sap-thermite",
    icons = tinted("__base__/graphics/icons/explosives.png"),
    subgroup = "vulcanus-processes", order = "z[sap]-b", stack_size = 100,
  },
  {
    type = "recipe", name = "sap-magmatic-ore-melting", categories = { "metallurgy" },
    icons = tinted("__space-age__/graphics/icons/fluid/molten-iron.png"),
    subgroup = "vulcanus-processes", order = "z[sap]-c",
    enabled = false, energy_required = 16,
    ingredients = {
      { type = "item", name = "sap-magmatic-ore", amount = 20 },
      { type = "fluid", name = "lava", amount = 200 },
    },
    results = {
      { type = "fluid", name = "molten-iron", amount = 300 },
      { type = "fluid", name = "molten-copper", amount = 150 },
    },
    main_product = "molten-iron",
  },
  {
    type = "recipe", name = "sap-molten-metal", categories = { "metallurgy" },
    enabled = false, energy_required = 8,
    ingredients = {
      { type = "item", name = "sap-magmatic-ore", amount = 10 },
      { type = "fluid", name = "sap-volcanic-gas", amount = 50 },
    },
    results = { { type = "fluid", name = "sap-molten-metal", amount = 200 } },
  },
  {
    type = "recipe", name = "sap-volcanic-gas-separation", categories = { "chemistry" },
    icons = tinted("__base__/graphics/icons/fluid/sulfuric-acid.png"),
    enabled = false, energy_required = 2,
    ingredients = { { type = "fluid", name = "sap-volcanic-gas", amount = 50 }, { type = "fluid", name = "water", amount = 20 } },
    results = { { type = "fluid", name = "sulfuric-acid", amount = 40 }, { type = "item", name = "sulfur", amount = 1 } },
    main_product = "sulfuric-acid",
  },
  {
    type = "recipe", name = "sap-heat-resistant-alloy", categories = { "metallurgy" },
    enabled = false, energy_required = 8,
    ingredients = {
      { type = "item", name = "sap-heat-resistant-crystal", amount = 2 },
      { type = "fluid", name = "sap-molten-metal", amount = 40 },
    },
    results = { { type = "item", name = "sap-heat-resistant-alloy", amount = 2 } },
  },
  {
    type = "recipe", name = "sap-thermite", categories = { "chemistry" },
    enabled = false, energy_required = 4,
    ingredients = {
      { type = "item", name = "iron-plate", amount = 2 },
      { type = "item", name = "sap-heat-resistant-crystal", amount = 1 },
      { type = "fluid", name = "sap-volcanic-gas", amount = 30 },
    },
    results = { { type = "item", name = "sap-thermite", amount = 2 } },
  },
})

-- Коронарная масса ------------------------------------------------------------------

local function attractor(name, base, efficiency, elongation)
  local e = util.table.deepcopy(data.raw["lightning-attractor"][base])
  e.name = name
  e.icon = nil
  e.icons = tinted(data.raw.item[base].icon)
  e.minable = { mining_time = 0.5, result = name }
  e.efficiency = efficiency
  e.range_elongation = elongation
  e.fast_replaceable_group = nil
  e.next_upgrade = nil
  local item = util.table.deepcopy(data.raw.item[base])
  item.name = name
  item.place_result = name
  item.icon = nil
  item.icons = e.icons
  return e, item
end

-- Зонтик: перехватывает лучи на большой площади, энергии не даёт.
local umbrella, umbrella_item = attractor("sap-coronal-umbrella", "lightning-rod", 0, 40)
umbrella.energy_source = nil
-- Захватчик луча: поглощает луч и превращает в энергию.
local catcher, catcher_item = attractor("sap-ray-catcher", "lightning-collector", 0.6, 25)

-- Радиатор охлаждения: пока подключён к сети, защищает постройки рядом от перегрева.
local radiator = util.table.deepcopy(data.raw.lamp["small-lamp"])
radiator.name = "sap-radiator"
radiator.icon = nil
radiator.icons = tinted("__base__/graphics/icons/heat-pipe.png")
radiator.minable = { mining_time = 0.2, result = "sap-radiator" }
radiator.energy_usage_per_tick = "50kW"
radiator.next_upgrade = nil

data:extend({
  umbrella, umbrella_item, catcher, catcher_item, radiator,
  {
    type = "item", name = "sap-radiator", icons = radiator.icons,
    subgroup = "energy", order = "z[sap]-a[radiator]", place_result = "sap-radiator", stack_size = 50,
  },
  {
    type = "recipe", name = "sap-coronal-umbrella", enabled = false, energy_required = 10,
    ingredients = {
      { type = "item", name = "lightning-rod", amount = 2 },
      { type = "item", name = "sap-heat-resistant-alloy", amount = 10 },
    },
    results = { { type = "item", name = "sap-coronal-umbrella", amount = 1 } },
  },
  {
    type = "recipe", name = "sap-ray-catcher", enabled = false, energy_required = 10,
    ingredients = {
      { type = "item", name = "lightning-collector", amount = 1 },
      { type = "item", name = "sap-heat-resistant-alloy", amount = 20 },
      { type = "item", name = "sap-heat-resistant-crystal", amount = 10 },
    },
    results = { { type = "item", name = "sap-ray-catcher", amount = 1 } },
  },
  {
    type = "recipe", name = "sap-radiator", enabled = false, energy_required = 4,
    ingredients = {
      { type = "item", name = "heat-pipe", amount = 2 },
      { type = "item", name = "sap-heat-resistant-alloy", amount = 2 },
    },
    results = { { type = "item", name = "sap-radiator", amount = 1 } },
  },
})

-- Технологии ------------------------------------------------------------------------

local function tech(name, icon, recipes, count, prereqs)
  local effects = {}
  for _, r in pairs(recipes) do effects[#effects + 1] = { type = "unlock-recipe", recipe = r } end
  return {
    type = "technology", name = name, icons = tinted(icon),
    effects = effects, prerequisites = prereqs,
    unit = { count = count, time = 60, ingredients = SOLARIS_PACKS },
  }
end

-- Базовая переработка открывается вместе с полётом: без неё на Solaris не выжить.
for _, r in pairs({ "sap-magmatic-ore-melting", "sap-molten-metal", "sap-volcanic-gas-separation",
                    "sap-heat-resistant-alloy", "sap-radiator" }) do
  table.insert(data.raw.technology["sap-planet-discovery-solaris"].effects, { type = "unlock-recipe", recipe = r })
end

data:extend({
  tech("sap-thermite", "__base__/graphics/icons/explosives.png", { "sap-thermite" }, 500,
       { "sap-planet-discovery-solaris" }),
  tech("sap-coronal-umbrella", "__space-age__/graphics/icons/lightning-rod.png", { "sap-coronal-umbrella" }, 600,
       { "sap-planet-discovery-solaris", "lightning-collector" }),
  tech("sap-ray-catcher", "__space-age__/graphics/icons/lightning-collector.png", { "sap-ray-catcher" }, 1000,
       { "sap-coronal-umbrella" }),
})
