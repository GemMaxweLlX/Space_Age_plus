-- Дополнительные колбы ванильных планет. Каждая делается только на своей планете и нужна
-- технологиям Space Age+, связанным с этой планетой (колбы Solaris, Echaris, Aquara и Nivar
-- добавляют модули планет).

local sap = require("prototypes.api")

local function pack_icon(base) return "__base__/graphics/icons/" .. base .. ".png" end
local function sa_icon(base) return "__space-age__/graphics/icons/" .. base .. ".png" end

-- Наувис: колба первопроходца — для кислорода, спутников, мусора, турбины Mk2.
sap.planet_science_pack({
  name = "sap-pioneer-science-pack", icon = pack_icon("automation-science-pack"), tint = { r = 0.6, g = 1, b = 0.6, a = 1 },
  order = "a", pressure = 1000, categories = { "crafting" },
  ingredients = {
    { type = "item", name = "raw-fish", amount = 1 }, { type = "item", name = "advanced-circuit", amount = 2 },
    { type = "item", name = "steel-plate", amount = 2 },
  },
  trigger = { type = "craft-item", item = "advanced-circuit", count = 50 }, prerequisites = { "advanced-circuit" },
  techs = { "sap-oxygen-systems", "sap-satellite-mk1", "sap-satellite-mk2", "sap-debris-recycling", "sap-steam-turbine-mk2" },
})
-- Вулканус: тектоническая колба.
sap.planet_science_pack({
  name = "sap-tectonic-science-pack", icon = sa_icon("metallurgic-science-pack"), tint = { r = 1, g = 0.5, b = 0.3, a = 1 },
  order = "b", pressure = 4000, categories = { "metallurgy" },
  ingredients = {
    { type = "item", name = "tungsten-carbide", amount = 2 }, { type = "item", name = "calcite", amount = 2 },
    { type = "fluid", name = "lava", amount = 100 },
  },
  trigger = { type = "craft-item", item = "tungsten-carbide" }, prerequisites = { "metallurgic-science-pack" },
  discovery_tech = "planet-discovery-vulcanus",
})
-- Фульгора: ионная колба.
sap.planet_science_pack({
  name = "sap-ionic-science-pack", icon = sa_icon("electromagnetic-science-pack"), tint = { r = 0.6, g = 0.6, b = 1, a = 1 },
  order = "c", pressure = 800, categories = { "electromagnetics" },
  ingredients = {
    { type = "item", name = "holmium-plate", amount = 1 }, { type = "item", name = "superconductor", amount = 1 },
    { type = "item", name = "battery", amount = 1 },
  },
  trigger = { type = "craft-item", item = "superconductor" }, prerequisites = { "electromagnetic-science-pack" },
  discovery_tech = "planet-discovery-fulgora",
})
-- Глеба: симбиотическая колба (портится).
sap.planet_science_pack({
  name = "sap-symbiotic-science-pack", icon = sa_icon("agricultural-science-pack"), tint = { r = 0.8, g = 1, b = 0.4, a = 1 },
  order = "d", pressure = 2000, categories = { "organic" }, spoil_hours = 1,
  ingredients = {
    { type = "item", name = "bioflux", amount = 1 }, { type = "item", name = "jelly", amount = 2 },
    { type = "item", name = "pentapod-egg", amount = 1 },
  },
  trigger = { type = "craft-item", item = "bioflux" }, prerequisites = { "agricultural-science-pack" },
  discovery_tech = "planet-discovery-gleba",
})
-- Аквило: криостазисная колба.
sap.planet_science_pack({
  name = "sap-cryostasis-science-pack", icon = sa_icon("cryogenic-science-pack"), tint = { r = 0.7, g = 0.9, b = 1, a = 1 },
  order = "e", pressure = 300, categories = { "cryogenics" },
  ingredients = {
    { type = "item", name = "lithium-plate", amount = 1 }, { type = "item", name = "ice", amount = 2 },
    { type = "fluid", name = "ammoniacal-solution", amount = 20 },
  },
  trigger = { type = "craft-item", item = "lithium-plate" }, prerequisites = { "cryogenic-science-pack" },
  discovery_tech = "planet-discovery-aquilo",
})
