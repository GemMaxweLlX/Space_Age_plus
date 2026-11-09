-- Solaris — планета у Солнца (docs: Планеты → Solaris).
-- Рельеф — лавовые равнины Вулкануса без демолишеров. Вместо вольфрама и кальцита —
-- магматическая руда и жаропрочные кристаллы. Загрязнения нет, день 80% времени.
-- Коронарная масса — механика молний Фульгоры с собственными «лучами».

local util = require("util")
local sap = require("__space-age-plus-core__.prototypes.api")

local TINT = { r = 1.0, g = 0.75, b = 0.45, a = 1.0 }

local planet = util.table.deepcopy(data.raw.planet["vulcanus"])
planet.name = "solaris"
planet.icon = nil
planet.icons = { { icon = "__space-age__/graphics/icons/vulcanus.png", icon_size = 64, tint = TINT } }
planet.starmap_icon = nil
planet.starmap_icons = {
  { icon = "__space-age__/graphics/icons/starmap-planet-vulcanus.png", icon_size = 512, tint = TINT },
}
planet.distance = 5
planet.orientation = 0.62
planet.magnitude = 0.8
planet.label_orientation = 0.2
planet.order = "a[solaris]"
planet.map_seed_offset = 5113
planet.pollutant_type = nil
planet.surface_properties = {
  ["day-night-cycle"] = 10 * 60 * 60,
  ["solar-power"] = 600,
  pressure = 50, -- почти нет атмосферы: коллектор кислорода не работает, только генератор
  gravity = 30,
}
-- День 80% времени задаёт скрипт при создании поверхности (surface.dusk/evening/...).

-- Карта: без демолишеров, вольфрам → магматическая руда, кальцит → кристаллы, без угля.
local mgs = planet.map_gen_settings
mgs.territory_settings = nil
local names = mgs.property_expression_names
names["entity:sap-magmatic-ore:probability"] = names["entity:tungsten-ore:probability"]
names["entity:sap-magmatic-ore:richness"] = names["entity:tungsten-ore:richness"]
names["entity:sap-heat-resistant-crystal:probability"] = names["entity:calcite:probability"]
names["entity:sap-heat-resistant-crystal:richness"] = names["entity:calcite:richness"]
for _, old in pairs({ "tungsten-ore", "calcite", "coal" }) do
  names["entity:" .. old .. ":probability"] = nil
  names["entity:" .. old .. ":richness"] = nil
end
local entity_settings = mgs.autoplace_settings.entity.settings
entity_settings["tungsten-ore"] = nil
entity_settings["calcite"] = nil
entity_settings["coal"] = nil
entity_settings["sap-magmatic-ore"] = {}
entity_settings["sap-heat-resistant-crystal"] = {}

-- Коронарная масса: «молнии», которые бьют часто. Число лучей — настройка 1-5.
local rays = settings.startup["sap-solaris-coronal-rays"].value
local fulgora_lightning = data.raw.planet["fulgora"].lightning_properties
planet.lightning_properties = util.table.deepcopy(fulgora_lightning)
planet.lightning_properties.lightning_types = { "sap-coronal-ray" }
planet.lightning_properties.lightnings_per_chunk_per_tick = rays / (60 * 30)
local ray_priority = planet.lightning_properties.priority_rules
table.insert(ray_priority, 1, { type = "id", string = "sap-coronal-umbrella", priority_bonus = 20000 })
table.insert(ray_priority, 1, { type = "id", string = "sap-ray-catcher", priority_bonus = 15000 })

local ray = util.table.deepcopy(data.raw.lightning["lightning"])
ray.name = "sap-coronal-ray"

data:extend({
  planet,
  ray,
  {
    type = "space-connection",
    name = "vulcanus-solaris",
    subgroup = "planet-connections",
    from = "vulcanus",
    to = "solaris",
    order = "a-b",
    length = 12000,
    icons = {
      { icon = "__space-age__/graphics/icons/planet-route.png" },
      { icon = "__space-age__/graphics/icons/vulcanus.png", icon_size = 64, scale = 0.333, shift = { -6, -6 } },
      { icon = "__space-age__/graphics/icons/vulcanus.png", icon_size = 64, scale = 0.333, shift = { 6, 6 }, tint = TINT },
    },
    asteroid_spawn_definitions = util.table.deepcopy(
      data.raw["space-connection"]["nauvis-vulcanus"].asteroid_spawn_definitions),
  },
  {
    type = "technology",
    name = "sap-planet-discovery-solaris",
    icons = { { icon = "__space-age__/graphics/technology/vulcanus.png", icon_size = 256, tint = TINT } },
    essential = true,
    effects = {
      { type = "unlock-space-location", space_location = "solaris", use_icon_overlay_constant = true },
    },
    prerequisites = { "metallurgic-science-pack", "sap-oxygen-systems" },
    unit = {
      count = 1000,
      time = 60,
      ingredients = {
        { "automation-science-pack", 1 }, { "logistic-science-pack", 1 }, { "chemical-science-pack", 1 },
        { "space-science-pack", 1 }, { "metallurgic-science-pack", 1 },
      },
    },
  },
})

sap.register_explorable_planet("solaris", { discovery_tech = "sap-planet-discovery-solaris" })
