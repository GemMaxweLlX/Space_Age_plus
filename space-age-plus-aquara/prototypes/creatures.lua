-- Водные пентаподы Aquara (docs: Планеты → Aquara → 3 типа водных пентаподов).
-- Рябь и Прибой живут в гнёздах (их можно будет захватить — «Захват ульев SA+»),
-- Бездна — одиночка, только убить. Графика пока — пентаподы Глебы.

local util = require("util")

local TINT = { r = 0.45, g = 0.8, b = 1.0, a = 1.0 }

local function copy(type_name, base, name, health, loot)
  local e = util.table.deepcopy(data.raw[type_name][base])
  e.name = name
  e.max_health = health
  e.loot = loot
  e.captured_spawner_entity = nil
  e.autoplace = nil
  return e
end

local function drop(name, probability, min, max)
  return { type = "item", name = name, amount_min = min or 1, amount_max = max or 1,
           independent_probability = probability }
end

-- Рябь: укус и ядовитый след.
local ripple = copy("spider-unit", "small-strafer-pentapod", "sap-ripple", 120, { drop("sap-venom-gland", 0.5) })
-- Прибой: водяной плевок.
local surf = copy("spider-unit", "medium-strafer-pentapod", "sap-surf", 400, { drop("sap-carapace", 0.5) })
-- Бездна: таран и волна.
local abyss = copy("spider-unit", "big-stomper-pentapod", "sap-abyss", 5000, { drop("sap-abyss-core", 1, 1, 2) })

local nest = copy("unit-spawner", "gleba-spawner-small", "sap-aquara-nest", 600,
  { drop("sap-venom-gland", 1, 2, 4), drop("sap-carapace", 1, 1, 3) })
nest.result_units = {
  { "sap-ripple", { { 0, 0.7 } } },
  { "sap-surf", { { 0, 0.3 } } },
}

local function item(name, icon, order)
  return {
    type = "item", name = name, icons = { { icon = icon, icon_size = 64, tint = TINT } },
    subgroup = "raw-material", order = "z[sap-aquara]-" .. order, stack_size = 100,
  }
end

data:extend({
  ripple, surf, abyss, nest,
  item("sap-venom-gland", "__space-age__/graphics/icons/pentapod-egg.png", "a"),
  item("sap-carapace", "__base__/graphics/icons/stone.png", "b"),
  item("sap-abyss-core", "__base__/graphics/icons/uranium-235.png", "c"),
})
