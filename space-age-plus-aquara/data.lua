-- space-age-plus-aquara: прототипы (Aquara — спутник Глебы).
local sap = require("__space-age-plus-core__.prototypes.api")

-- Кислород: коллектор + осушитель (docs: Кислород → По планетам).
sap.register_oxygen_planet("aquara", { solution = "collector" })

require("prototypes.planet")
require("prototypes.content")
require("prototypes.creatures")

-- Подсказки (окно «Советы и подсказки», раздел Space Age+).
sap.tip("sap-aquara-briefing", "u-a", "[planet=aquara]", { type = "research", technology = "sap-planet-discovery-aquara" })
sap.tip("sap-aquara-storms", "u-b", "[item=sap-storm-anchor]", { type = "change-surface", surface = "aquara" })

-- Гидробиологическая колба Aquara (портится): для технологий Aquara.
sap.planet_science_pack({
  name = "sap-hydro-science-pack", icon = "__space-age__/graphics/icons/agricultural-science-pack.png",
  tint = { r = 0.4, g = 0.8, b = 1, a = 1 }, order = "h", pressure = 1800, categories = { "organic" }, spoil_hours = 1,
  ingredients = {
    { type = "item", name = "sap-green-algae", amount = 3 }, { type = "item", name = "sap-sea-salt", amount = 1 },
    { type = "item", name = "bioflux", amount = 1 },
  },
  trigger = { type = "craft-item", item = "sap-sea-salt" }, prerequisites = { "sap-planet-discovery-aquara" },
  discovery_tech = "sap-planet-discovery-aquara",
})
