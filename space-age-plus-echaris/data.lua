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
