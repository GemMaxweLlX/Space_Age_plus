-- space-age-plus-solaris: прототипы (Solaris — планета у Солнца).
local sap = require("__space-age-plus-core__.prototypes.api")

-- Кислород: только генератор, атмосферы почти нет (docs: Кислород → По планетам).
sap.register_oxygen_planet("solaris", { solution = "generator" })

require("prototypes.planet")
require("prototypes.content")
require("prototypes.power")
require("prototypes.creatures")
