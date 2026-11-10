-- space-age-plus-nivar: прототипы (Nivar — спутник Аквило).
local sap = require("__space-age-plus-core__.prototypes.api")

-- Кислород: на поверхности коллектор + криоконцентратор, в пещерах только генератор.
sap.register_oxygen_planet("nivar", { solution = "collector" })
sap.register_oxygen_planet("nivar-caves", { solution = "generator" })

require("prototypes.planet")
require("prototypes.content")
require("prototypes.creatures")

-- Хардкор «Без доставки с платформы».
sap.register_no_delivery("nivar", "sap-hardcore-nivar-no-delivery")

-- Подсказки (окно «Советы и подсказки», раздел Space Age+).
sap.tip("sap-nivar-briefing", "v-a", "[planet=nivar]", { type = "research", technology = "sap-planet-discovery-nivar" })
sap.tip("sap-nivar-caves", "v-b", "[item=sap-nivar-elevator]", { type = "change-surface", surface = "nivar" })

-- Глубинная колба Nivar: для технологий Nivar.
sap.planet_science_pack({
  name = "sap-deep-science-pack", icon = "__space-age__/graphics/icons/cryogenic-science-pack.png",
  tint = { r = 0.4, g = 0.5, b = 0.9, a = 1 }, order = "i", pressure = 250, categories = { "cryogenics" },
  ingredients = {
    { type = "item", name = "sap-nivalite", amount = 2 }, { type = "item", name = "sap-dark-ice", amount = 2 },
    { type = "item", name = "sap-cryolite", amount = 1 },
  },
  trigger = { type = "craft-item", item = "sap-cryo-concentrator" }, prerequisites = { "sap-planet-discovery-nivar" },
  discovery_tech = "sap-planet-discovery-nivar",
})
