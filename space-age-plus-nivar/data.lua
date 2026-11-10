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
