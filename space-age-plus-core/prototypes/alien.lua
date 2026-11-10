-- Инопланетные хранилища древней расы (docs: Технологии → Источники тех данных;
-- Дневник → Находки). В документе — «подземелья»; первая версия — запечатанные хранилища
-- на поверхностях планет (и в пещерах Nivar) под охраной древних стражей.
-- Внутри: карта данных «Инопланетные» и зашифрованные инопланетные данные, которые
-- расшифровывает дешифратор. Инопланетные технологии открываются только этими картами.

local util = require("util")

local TINT = { r = 0.5, g = 1, b = 0.85, a = 1 }

local vault = util.table.deepcopy(data.raw.container["crash-site-spaceship"])
vault.name = "sap-alien-vault"
vault.inventory_size = 6
vault.minable = nil

local guardian = util.table.deepcopy(data.raw.turret["medium-worm-turret"])
guardian.name = "sap-alien-guardian"
guardian.autoplace = nil
guardian.max_health = guardian.max_health * 2

data:extend({
  vault, guardian,
  {
    type = "item", name = "sap-alien-data",
    icons = { { icon = "__base__/graphics/icons/processing-unit.png", icon_size = 64, tint = { r = 0.3, g = 0.3, b = 0.3, a = 1 } } },
    subgroup = "sap-tech-data", order = "c-a", stack_size = 10,
  },
  {
    type = "item", name = "sap-alien-data-decrypted",
    icons = { { icon = "__base__/graphics/icons/processing-unit.png", icon_size = 64, tint = TINT } },
    subgroup = "sap-tech-data", order = "c-b", stack_size = 10,
  },
})

local ALIEN_PACKS = {
  { "automation-science-pack", 1 }, { "logistic-science-pack", 1 }, { "chemical-science-pack", 1 },
  { "space-science-pack", 1 },
}
local function alien_tech(name, icon, effects, count)
  return {
    type = "technology", name = name,
    icons = { { icon = icon, icon_size = 256, tint = TINT } },
    effects = effects, prerequisites = { "space-science-pack" },
    unit = { count = count, time = 60, ingredients = ALIEN_PACKS },
  }
end

data:extend({
  alien_tech("sap-alien-geometry", "__base__/graphics/technology/mining-productivity.png",
             { { type = "mining-drill-productivity-bonus", modifier = 0.1 } }, 1500),
  alien_tech("sap-alien-conservation", "__base__/graphics/technology/research-speed.png",
             { { type = "laboratory-speed", modifier = 0.2 } }, 1500),
  alien_tech("sap-alien-lattice", "__base__/graphics/technology/worker-robots-storage.png",
             { { type = "worker-robot-storage", modifier = 1 } }, 2000),
})
