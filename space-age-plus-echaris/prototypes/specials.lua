-- Особые технологии Echaris (docs: Echaris → Зоны и центры; Техи планет → Echaris).
--   Силовой барьер (и Mk2): ваншот Механитов, вошедших в зону; каждый выстрел тратит заряд.
--   Костюм стелса: Механиты дальше 6 клеток не замечают игрока (scripts/specials.lua).
--   Протокол тихого захвата: открытие центра захвата не поднимает тревогу.
--   Взлом Механитов: ЭМИ-граната переманивает Механитов на сторону игрока.

local sap = require("__space-age-plus-core__.prototypes.api")

local TINT = { r = 0.75, g = 0.7, b = 1.0, a = 1.0 }
local PACKS = {
  { "automation-science-pack", 1 }, { "logistic-science-pack", 1 }, { "chemical-science-pack", 1 },
  { "space-science-pack", 1 }, { "electromagnetic-science-pack", 1 },
}
local function nivalite() return data.raw.item["sap-nivalite"] and "sap-nivalite" or "superconductor" end

sap.upgrade({
  base = "accumulator", name = "sap-force-barrier", tint = { r = 0.5, g = 0.4, b = 1, a = 1 },
  change = function(e)
    e.energy_source.buffer_capacity = "50MJ"
    e.energy_source.input_flow_limit = "2MW"
    e.energy_source.output_flow_limit = "0W"
  end,
  ingredients = { { "accumulator", 2 }, { "sap-mechanite-core", 5 }, { "supercapacitor", 10 } },
  tech = { name = "sap-force-barrier", icon = "__base__/graphics/icons/accumulator.png", count = 1000,
           prerequisites = { "sap-planet-discovery-echaris" }, science = PACKS },
})
sap.upgrade({
  base = "accumulator", name = "sap-force-barrier-mk2", tint = { r = 0.3, g = 0.2, b = 1, a = 1 },
  change = function(e)
    e.energy_source.buffer_capacity = "150MJ"
    e.energy_source.input_flow_limit = "5MW"
    e.energy_source.output_flow_limit = "0W"
  end,
  ingredients = { { "sap-force-barrier", 1 }, { "sap-mechanite-core", 10 }, { nivalite(), 10 } },
  tech = { name = "sap-force-barrier-mk2", icon = "__base__/graphics/icons/accumulator.png", count = 1500,
           prerequisites = { "sap-force-barrier" }, science = PACKS },
})
sap.upgrade({
  base = "modular-armor", name = "sap-stealth-suit", tint = { r = 0.3, g = 0.3, b = 0.4, a = 1 },
  ingredients = { { "modular-armor", 1 }, { "sap-mechanite-core", 5 }, { "supercapacitor", 10 } },
  tech = { name = "sap-stealth-suit", icon = "__base__/graphics/icons/modular-armor.png", count = 800,
           prerequisites = { "sap-planet-discovery-echaris" }, science = PACKS },
})

local function flag_tech(name, icon, count, prerequisite)
  return {
    type = "technology", name = name, icons = { { icon = icon, icon_size = 64, tint = TINT } },
    effects = {}, prerequisites = { prerequisite }, unit = { count = count, time = 60, ingredients = PACKS },
  }
end
data:extend({
  flag_tech("sap-silent-capture-protocol", "__base__/graphics/icons/processing-unit.png", 800, "sap-stealth-suit"),
  flag_tech("sap-mechanite-hacking", "__base__/graphics/icons/processing-unit.png", 1500, "sap-emp-grenade"),
})

-- ЭМИ-граната: сначала взлом (скрипт), потом урон — только по врагам, чтобы взломанные выжили.
local projectile = data.raw.projectile["sap-emp-grenade"]
for _, action in pairs(projectile.action) do
  if action.type == "area" then action.force = "enemy" end
end
table.insert(projectile.action, 1, {
  type = "direct",
  action_delivery = { type = "instant", target_effects = { { type = "script", effect_id = "sap-emp-hack" } } },
})
