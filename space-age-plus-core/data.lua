-- space-age-plus-core: прототипы общих механик.
local sap = require("prototypes.api")

-- Кислород: ванильные планеты (docs: Кислород → По планетам). Наувису кислород не нужен.
sap.register_oxygen_planet("vulcanus", { solution = "generator" })
sap.register_oxygen_planet("fulgora", { solution = "collector" })
sap.register_oxygen_planet("gleba", { solution = "collector" })
sap.register_oxygen_planet("aquilo", { solution = "collector" })

-- Реестр исследуемых планет (заполняют модули планет, см. api.register_explorable_planet).
data:extend({ { type = "mod-data", name = sap.EXPLORABLE_PLANETS, data = {} } })

require("prototypes.oxygen")
require("prototypes.diary")
require("prototypes.exploration")
require("prototypes.techtree")
require("prototypes.quality_bonus")
require("prototypes.global_tech")
