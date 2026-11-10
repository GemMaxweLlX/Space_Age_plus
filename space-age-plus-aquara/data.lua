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
