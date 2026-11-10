-- Aquara — спутник Глебы (docs: Планеты → Aquara).
-- Биосфера Глебы, затопленная до островов: тот же рельеф, но ниже уровень суши и выше
-- влажность. Родные пентаподы Глебы убраны — их место занимают водные пентаподы (скрипт).

local util = require("util")
local sap = require("__space-age-plus-core__.prototypes.api")

local TINT = { r = 0.45, g = 0.8, b = 1.0, a = 1.0 }

data:extend({
  { type = "noise-expression", name = "aquara_elevation", expression = "gleba_elevation - 22" },
  { type = "noise-expression", name = "aquara_moisture", expression = "min(1, gleba_moisture + 0.35)" },
})

local planet = util.table.deepcopy(data.raw.planet["gleba"])
planet.name = "aquara"
planet.icon = nil
planet.icons = { { icon = "__space-age__/graphics/icons/gleba.png", icon_size = 64, tint = TINT } }
planet.starmap_icon = nil
planet.starmap_icons = {
  { icon = "__space-age__/graphics/icons/starmap-planet-gleba.png", icon_size = 512, tint = TINT },
}
planet.origin = sap.moon_origin("gleba")
planet.distance = 3.5
planet.orientation = 0.8
planet.magnitude = 0.5
planet.gravity_pull = 5
planet.order = "c[gleba]-b[aquara]"
planet.map_seed_offset = 9021
planet.surface_properties = util.table.deepcopy(planet.surface_properties)
planet.surface_properties.pressure = 1800 -- своё давление: коллектор кислорода по рецепту Aquara

local mgs = planet.map_gen_settings
mgs.property_expression_names.elevation = "aquara_elevation"
mgs.property_expression_names.moisture = "aquara_moisture"
mgs.autoplace_controls["gleba_enemy_base"] = nil
mgs.territory_settings = nil
local entity_settings = mgs.autoplace_settings.entity.settings
entity_settings["gleba-spawner"] = nil
entity_settings["gleba-spawner-small"] = nil

data:extend({
  planet,
  {
    type = "space-connection",
    name = "gleba-aquara",
    subgroup = "planet-connections",
    from = "gleba",
    to = "aquara",
    order = "c-b",
    length = 4000,
    icons = {
      { icon = "__space-age__/graphics/icons/planet-route.png" },
      { icon = "__space-age__/graphics/icons/gleba.png", icon_size = 64, scale = 0.333, shift = { -6, -6 } },
      { icon = "__space-age__/graphics/icons/gleba.png", icon_size = 64, scale = 0.333, shift = { 6, 6 }, tint = TINT },
    },
    asteroid_spawn_definitions = util.table.deepcopy(
      data.raw["space-connection"]["nauvis-gleba"].asteroid_spawn_definitions),
  },
  {
    type = "technology",
    name = "sap-planet-discovery-aquara",
    icons = { { icon = "__space-age__/graphics/technology/gleba.png", icon_size = 256, tint = TINT } },
    essential = true,
    effects = {
      { type = "unlock-space-location", space_location = "aquara", use_icon_overlay_constant = true },
    },
    prerequisites = { "agricultural-science-pack", "sap-oxygen-systems" },
    unit = {
      count = 1000,
      time = 60,
      ingredients = {
        { "automation-science-pack", 1 }, { "logistic-science-pack", 1 }, { "chemical-science-pack", 1 },
        { "space-science-pack", 1 }, { "agricultural-science-pack", 1 },
      },
    },
  },
})

sap.register_explorable_planet("aquara", { discovery_tech = "sap-planet-discovery-aquara", parent = "gleba" })
