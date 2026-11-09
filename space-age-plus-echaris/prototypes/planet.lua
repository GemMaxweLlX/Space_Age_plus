-- Echaris — спутник Фульгоры (docs: Планеты → Echaris).
-- Первая версия: рельеф, руины и лом Фульгоры (цивилизация Фульгорианцев), постоянная буря.
-- Уникальные ресурсы, Механиты и центры захвата — следующие версии.

local util = require("util")
local sap = require("__space-age-plus-core__.prototypes.api")

local TINT = { r = 0.75, g = 0.7, b = 1.0, a = 1.0 }

local planet = util.table.deepcopy(data.raw.planet["fulgora"])
planet.name = "echaris"
planet.icon = nil
planet.icons = { { icon = "__space-age__/graphics/icons/fulgora.png", icon_size = 64, tint = TINT } }
planet.starmap_icon = nil
planet.starmap_icons = {
  { icon = "__space-age__/graphics/icons/starmap-planet-fulgora.png", icon_size = 512, tint = TINT },
}
-- Спутник: вращается вокруг Фульгоры.
planet.origin = sap.moon_origin("fulgora")
planet.distance = 3
planet.orientation = 0.15
planet.magnitude = 0.45
planet.gravity_pull = 5
planet.label_orientation = 0.3
planet.order = "d[fulgora]-b[echaris]"
planet.map_seed_offset = 7341
planet.surface_properties = {
  ["day-night-cycle"] = 5 * 60 * 60,
  ["magnetic-field"] = 140,
  ["solar-power"] = 15,
  pressure = 600, -- своё давление: коллектор кислорода работает по своему рецепту
  gravity = 4,
}
-- Постоянная магнитная буря: молнии чаще, чем на Фульгоре.
if planet.lightning_properties then
  planet.lightning_properties.lightnings_per_chunk_per_tick = 1 / (60 * 6)
end

data:extend({
  planet,
  {
    type = "space-connection",
    name = "fulgora-echaris",
    subgroup = "planet-connections",
    from = "fulgora",
    to = "echaris",
    order = "d-b",
    length = 4000,
    asteroid_spawn_definitions = util.table.deepcopy(
      data.raw["space-connection"]["nauvis-fulgora"].asteroid_spawn_definitions),
  },
  {
    type = "technology",
    name = "sap-planet-discovery-echaris",
    icons = {
      { icon = "__space-age__/graphics/technology/fulgora.png", icon_size = 256, tint = TINT },
    },
    essential = true,
    effects = {
      { type = "unlock-space-location", space_location = "echaris", use_icon_overlay_constant = true },
      { type = "unlock-recipe", recipe = "sap-emp-filter" },
      { type = "unlock-recipe", recipe = "sap-oxygen-collection-echaris" },
    },
    prerequisites = { "electromagnetic-science-pack", "sap-oxygen-systems" },
    unit = {
      count = 1000,
      time = 60,
      ingredients = {
        { "automation-science-pack", 1 },
        { "logistic-science-pack", 1 },
        { "chemical-science-pack", 1 },
        { "space-science-pack", 1 },
        { "electromagnetic-science-pack", 1 },
      },
    },
  },
})

-- Кислород: коллектор + ЭМИ-фильтр (docs: Кислород → По планетам).
data:extend({
  {
    type = "item",
    name = "sap-emp-filter",
    icons = { { icon = "__base__/graphics/icons/iron-gear-wheel.png", icon_size = 64, tint = TINT } },
    subgroup = "sap-oxygen",
    order = "d-d",
    stack_size = 100,
  },
  {
    type = "recipe",
    name = "sap-emp-filter",
    enabled = false,
    energy_required = 2,
    ingredients = {
      { type = "item", name = "copper-cable", amount = 4 },
      { type = "item", name = "supercapacitor", amount = 1 },
    },
    results = { { type = "item", name = "sap-emp-filter", amount = 1 } },
  },
  sap.oxygen_collector_recipe("echaris", 600, { { type = "item", name = "sap-emp-filter", amount = 1 } }),
})

sap.register_explorable_planet("echaris", { discovery_tech = "sap-planet-discovery-echaris", parent = "fulgora" })
