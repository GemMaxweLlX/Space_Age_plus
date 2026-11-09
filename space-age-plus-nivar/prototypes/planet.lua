-- Nivar — спутник Аквило (docs: Планеты → Nivar).
-- Поверхность: ледяная пустыня (рельеф Аквило, поднятый над океаном), холоднее Аквило,
--   постройкам нужен обогрев (как на Аквило). Ресурсов на поверхности нет.
-- Пещеры: отдельная скрытая «планета» nivar-caves со своей поверхностью. Там нивалит,
--   криолит и тёмный лёд. Попасть туда можно только лифтом (scripts/caves.lua).

local util = require("util")
local sap = require("__space-age-plus-core__.prototypes.api")

local TINT = { r = 0.7, g = 0.85, b = 1.0, a = 1.0 }
local NIVAR_PRESSURE = 250
local CAVES_PRESSURE = 260

local function cave_noise(seed, scale)
  return "quick_multioctave_noise{x = x, y = y, seed0 = map_seed, seed1 = " .. seed .. ",\z
          input_scale = " .. scale .. ", output_scale = 1, offset_x = 0, octaves = 3,\z
          octave_input_scale_multiplier = 0.5, octave_output_scale_multiplier = 0.75}"
end

local function ore_probability(seed)
  return "(distance > 12) * (" .. cave_noise(seed, "1/48") .. " > 0.55)"
end

data:extend({
  { type = "noise-expression", name = "nivar_elevation", expression = "aquilo_elevation + 20" },
  { type = "noise-expression", name = "nivar_caves_elevation", expression = "30" },
  { type = "noise-expression", name = "nivar_nivalite_probability", expression = ore_probability(4101) },
  { type = "noise-expression", name = "nivar_cryolite_probability", expression = ore_probability(4202) },
  { type = "noise-expression", name = "nivar_dark_ice_probability", expression = ore_probability(4303) },
  { type = "noise-expression", name = "nivar_ore_richness", expression = "600 + distance * 4" },
})

-- Поверхность ------------------------------------------------------------------------

local planet = util.table.deepcopy(data.raw.planet["aquilo"])
planet.name = "nivar"
planet.icon = nil
planet.icons = { { icon = "__space-age__/graphics/icons/aquilo.png", icon_size = 64, tint = TINT } }
planet.starmap_icon = nil
planet.starmap_icons = {
  { icon = "__space-age__/graphics/icons/starmap-planet-aquilo.png", icon_size = 512, tint = TINT },
}
planet.origin = sap.moon_origin("aquilo")
planet.distance = 3.5
planet.orientation = 0.4
planet.magnitude = 0.5
planet.gravity_pull = 5
planet.order = "e[aquilo]-b[nivar]"
planet.map_seed_offset = 6177
planet.surface_properties = util.table.deepcopy(planet.surface_properties)
planet.surface_properties.pressure = NIVAR_PRESSURE

local mgs = planet.map_gen_settings
mgs.property_expression_names.elevation = "nivar_elevation"
mgs.property_expression_names["entity:crude-oil:probability"] = nil
mgs.property_expression_names["entity:crude-oil:richness"] = nil
mgs.autoplace_controls = {}
mgs.autoplace_settings.entity.settings = {}

-- Пещеры ------------------------------------------------------------------------------

local caves = util.table.deepcopy(planet)
caves.name = "nivar-caves"
caves.hidden = true
caves.order = "e[aquilo]-c[nivar-caves]"
caves.map_seed_offset = 6178
caves.surface_properties.pressure = CAVES_PRESSURE
caves.lightning_properties = nil
local cmg = caves.map_gen_settings
cmg.property_expression_names = util.table.deepcopy(mgs.property_expression_names)
cmg.property_expression_names.elevation = "nivar_caves_elevation"
for _, ore in pairs({ "nivalite", "cryolite", "dark-ice" }) do
  local key = string.gsub(ore, "-", "_")
  cmg.property_expression_names["entity:sap-" .. ore .. ":probability"] = "nivar_" .. key .. "_probability"
  cmg.property_expression_names["entity:sap-" .. ore .. ":richness"] = "nivar_ore_richness"
  cmg.autoplace_settings.entity.settings["sap-" .. ore] = {}
end

-- Ресурсы пещер ------------------------------------------------------------------------

local function resource(name, base, tint)
  local r = util.table.deepcopy(data.raw.resource[base])
  r.name = name
  r.icon = nil
  r.icons = { { icon = data.raw.resource[base].icon, icon_size = 64, tint = tint } }
  r.minable.result = name
  r.minable.results = nil
  r.minable.required_fluid = nil
  r.minable.fluid_amount = nil
  r.category = nil
  if r.stages and r.stages.sheet then r.stages.sheet.tint = tint end
  r.autoplace = { probability_expression = 0 }
  local item = util.table.deepcopy(data.raw.item[base] or data.raw.item["stone"])
  item.name = name
  item.icon = nil
  item.icons = r.icons
  item.random_tint_color = nil
  item.subgroup = "raw-resource"
  item.order = "z[sap-nivar]-" .. name
  return r, item
end

local nivalite, nivalite_item = resource("sap-nivalite", "tungsten-ore", { r = 0.5, g = 0.7, b = 1, a = 1 })
local cryolite, cryolite_item = resource("sap-cryolite", "calcite", { r = 0.7, g = 0.95, b = 1, a = 1 })
local dark_ice, dark_ice_item = resource("sap-dark-ice", "stone", { r = 0.3, g = 0.35, b = 0.5, a = 1 })

data:extend({
  planet, caves, nivalite, nivalite_item, cryolite, cryolite_item, dark_ice, dark_ice_item,
  {
    type = "space-connection",
    name = "aquilo-nivar",
    subgroup = "planet-connections",
    from = "aquilo",
    to = "nivar",
    order = "e-b",
    length = 4000,
    icons = {
      { icon = "__space-age__/graphics/icons/planet-route.png" },
      { icon = "__space-age__/graphics/icons/aquilo.png", icon_size = 64, scale = 0.333, shift = { -6, -6 } },
      { icon = "__space-age__/graphics/icons/aquilo.png", icon_size = 64, scale = 0.333, shift = { 6, 6 }, tint = TINT },
    },
    asteroid_spawn_definitions = util.table.deepcopy(
      data.raw["space-connection"]["fulgora-aquilo"].asteroid_spawn_definitions),
  },
  {
    type = "technology",
    name = "sap-planet-discovery-nivar",
    icons = { { icon = "__space-age__/graphics/technology/aquilo.png", icon_size = 256, tint = TINT } },
    essential = true,
    effects = {
      { type = "unlock-space-location", space_location = "nivar", use_icon_overlay_constant = true },
    },
    prerequisites = { "cryogenic-science-pack", "sap-oxygen-systems" },
    unit = {
      count = 1500,
      time = 60,
      ingredients = {
        { "automation-science-pack", 1 }, { "logistic-science-pack", 1 }, { "chemical-science-pack", 1 },
        { "space-science-pack", 1 }, { "cryogenic-science-pack", 1 },
      },
    },
  },
})

sap.register_explorable_planet("nivar", { discovery_tech = "sap-planet-discovery-nivar", parent = "aquilo" })
