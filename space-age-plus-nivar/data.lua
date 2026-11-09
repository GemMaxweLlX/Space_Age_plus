-- space-age-plus-nivar: прототипы (Nivar — спутник Аквило).
local sap = require("__space-age-plus-core__.prototypes.api")

-- Кислород: на поверхности коллектор + криоконцентратор, в пещерах только генератор.
sap.register_oxygen_planet("nivar", { solution = "collector" })
sap.register_oxygen_planet("nivar-caves", { solution = "generator" })

require("prototypes.planet")
require("prototypes.content")
require("prototypes.creatures")
