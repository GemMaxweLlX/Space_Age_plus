-- space-age-plus-echaris: прототипы (Echaris — спутник Фульгоры).
local sap = require("__space-age-plus-core__.prototypes.api")

-- Кислород: коллектор + ЭМИ-фильтр (docs: Кислород → По планетам).
sap.register_oxygen_planet("echaris", { solution = "collector" })

require("prototypes.planet")
require("prototypes.storm")
require("prototypes.mechanites")
require("prototypes.technologies")
require("prototypes.specials")

-- Хардкор «Без доставки с платформы».
sap.register_no_delivery("echaris", "sap-hardcore-echaris-no-delivery")

-- Подсказки (окно «Советы и подсказки», раздел Space Age+).
sap.tip("sap-echaris-briefing", "t-a", "[planet=echaris]", { type = "research", technology = "sap-planet-discovery-echaris" })
sap.tip("sap-echaris-mechanites", "t-b", "[entity=sap-sentinel]", { type = "change-surface", surface = "echaris" })

-- Кибернетическая колба Echaris: для технологий Echaris.
sap.planet_science_pack({
  name = "sap-cybernetic-science-pack", icon = "__space-age__/graphics/icons/electromagnetic-science-pack.png",
  tint = { r = 0.75, g = 0.6, b = 1, a = 1 }, order = "g", pressure = 600, categories = { "electromagnetics" },
  ingredients = {
    { type = "item", name = "sap-mechanite-core", amount = 1 }, { type = "item", name = "supercapacitor", amount = 1 },
    { type = "item", name = "sap-mechanite-scrap", amount = 3 },
  },
  trigger = { type = "craft-item", item = "sap-emp-filter" }, prerequisites = { "sap-planet-discovery-echaris" },
  discovery_tech = "sap-planet-discovery-echaris",
})
