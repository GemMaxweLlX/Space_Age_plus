-- space-age-plus-aquara: прототипы (Aquara — спутник Глебы).
local sap = require("__space-age-plus-core__.prototypes.api")

-- Кислород: коллектор + осушитель (docs: Кислород → По планетам).
sap.register_oxygen_planet("aquara", { solution = "collector" })

require("prototypes.planet")
require("prototypes.content")
require("prototypes.creatures")
