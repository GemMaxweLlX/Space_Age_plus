-- space-age-plus-solaris: прототипы (Solaris — планета у Солнца).
local sap = require("__space-age-plus-core__.prototypes.api")

-- Кислород: только генератор, атмосферы почти нет (docs: Кислород → По планетам).
sap.register_oxygen_planet("solaris", { solution = "generator" })

require("prototypes.planet")
require("prototypes.content")
require("prototypes.power")
require("prototypes.creatures")

-- Улучшенная капсула доставки (S4): без неё грузовые капсулы на Solaris не садятся.
sap.register_no_delivery("solaris", nil, "sap-improved-delivery-capsule")
data:extend({
  {
    type = "technology", name = "sap-improved-delivery-capsule",
    icons = { { icon = "__base__/graphics/icons/cargo-pod.png", icon_size = 64, tint = { r = 1, g = 0.75, b = 0.45, a = 1 } } },
    effects = {}, prerequisites = { "sap-planet-discovery-solaris" },
    unit = {
      count = 500, time = 60,
      ingredients = {
        { "automation-science-pack", 1 }, { "logistic-science-pack", 1 }, { "chemical-science-pack", 1 },
        { "space-science-pack", 1 }, { "metallurgic-science-pack", 1 },
      },
    },
  },
})

-- Подсказки (окно «Советы и подсказки», раздел Space Age+).
sap.tip("sap-solaris-briefing", "s-a", "[planet=solaris]", { type = "research", technology = "sap-planet-discovery-solaris" })
sap.tip("sap-solaris-heat", "s-b", "[item=sap-radiator]", { type = "change-surface", surface = "solaris" })
