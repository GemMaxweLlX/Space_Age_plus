-- Технологии Echaris, первая партия (docs: Техи планет → Echaris).
-- Межпланетные материалы (I1): если модуля Nivar или Solaris нет, их материал заменяется
-- похожим ванильным — нивалит → сверхпроводник, жаропрочные кристаллы → карбид вольфрама.

local util = require("util")

local TINT = { r = 0.75, g = 0.7, b = 1.0, a = 1.0 }

local function material(name, fallback)
  return data.raw.item[name] and name or fallback
end
local NIVALITE = material("sap-nivalite", "superconductor")
local HEAT_CRYSTAL = material("sap-heat-resistant-crystal", "tungsten-carbide")

local ECHARIS_PACKS = {
  { "automation-science-pack", 1 }, { "logistic-science-pack", 1 }, { "chemical-science-pack", 1 },
  { "space-science-pack", 1 }, { "electromagnetic-science-pack", 1 },
}

local function tech(name, icon, recipes, count, extra_prereq)
  local effects = {}
  for _, r in pairs(recipes) do effects[#effects + 1] = { type = "unlock-recipe", recipe = r } end
  return {
    type = "technology",
    name = name,
    icons = { { icon = icon, icon_size = 64, tint = TINT } },
    effects = effects,
    prerequisites = { "sap-planet-discovery-echaris", extra_prereq },
    unit = { count = count, time = 60, ingredients = ECHARIS_PACKS },
  }
end

local function recipe(name, ingredients, result_count)
  local list = {}
  for _, i in pairs(ingredients) do list[#list + 1] = { type = "item", name = i[1], amount = i[2] } end
  return {
    type = "recipe", name = name, enabled = false, energy_required = 10,
    ingredients = list,
    results = { { type = "item", name = name, amount = result_count or 1 } },
  }
end

local function copy(type_name, base, name, item_base)
  local e = util.table.deepcopy(data.raw[type_name][base])
  e.name = name
  if e.minable then
    e.minable.result = name
    e.minable.results = nil
  end
  e.next_upgrade = nil
  local item = util.table.deepcopy(data.raw.item[item_base or base] or data.raw.capsule[item_base or base]
    or data.raw["item-with-entity-data"][item_base or base])
  item.name = name
  item.place_result = name
  local icon = item.icon
  item.icon = nil
  item.icons = { { icon = icon, icon_size = item.icon_size or 64, tint = TINT } }
  return e, item
end

-- Дроны Mk2: дольше, быстрее, защищены от бури Echaris -------------------------------
local lrobot, lrobot_item = copy("logistic-robot", "logistic-robot", "sap-logistic-robot-mk2")
lrobot.speed = 0.08
lrobot.max_energy = "3MJ"
lrobot.max_health = 200
local crobot, crobot_item = copy("construction-robot", "construction-robot", "sap-construction-robot-mk2")
crobot.speed = 0.09
crobot.max_energy = "6MJ"
crobot.max_health = 200

-- Аккумулятор Mk2 и солнечная панель Mk2 ----------------------------------------------
local acc, acc_item = copy("accumulator", "accumulator", "sap-accumulator-mk2")
acc.energy_source.buffer_capacity = "15MJ"
acc.energy_source.input_flow_limit = "900kW"
acc.energy_source.output_flow_limit = "900kW"
local solar, solar_item = copy("solar-panel", "solar-panel", "sap-solar-panel-mk2")
solar.production = "100kW"

-- Электромагнитная турель: особо эффективна против Механитов (они слабы к электричеству)
local turret, turret_item = copy("electric-turret", "laser-turret", "sap-em-turret")
turret.attack_parameters.damage_modifier = (turret.attack_parameters.damage_modifier or 1) * 1.5

-- ЭМИ-граната: глушит роботов и оглушает Механитов --------------------------------------
local grenade_projectile = util.table.deepcopy(data.raw.projectile["grenade"])
grenade_projectile.name = "sap-emp-grenade"
grenade_projectile.action = {
  {
    type = "area",
    radius = 7,
    action_delivery = {
      type = "instant",
      target_effects = {
        { type = "damage", damage = { amount = 120, type = "electric" } },
        { type = "create-sticker", sticker = "stun-sticker" },
      },
    },
  },
  {
    type = "direct",
    action_delivery = {
      type = "instant",
      target_effects = { { type = "create-entity", entity_name = "medium-explosion" } },
    },
  },
}
local grenade = util.table.deepcopy(data.raw.capsule["grenade"])
grenade.name = "sap-emp-grenade"
grenade.icon = nil
grenade.icons = { { icon = "__base__/graphics/icons/grenade.png", icon_size = 64, tint = TINT } }
for _, action in pairs(grenade.capsule_action.attack_parameters.ammo_type.action) do
  if action.action_delivery and action.action_delivery.type == "projectile" then
    action.action_delivery.projectile = "sap-emp-grenade"
  end
end

data:extend({
  lrobot, lrobot_item, crobot, crobot_item, acc, acc_item, solar, solar_item, turret, turret_item,
  grenade_projectile, grenade,

  recipe("sap-logistic-robot-mk2", { { "logistic-robot", 1 }, { "sap-mechanite-core", 1 }, { NIVALITE, 2 } }),
  recipe("sap-construction-robot-mk2", { { "construction-robot", 1 }, { "sap-mechanite-core", 1 }, { NIVALITE, 2 } }),
  recipe("sap-accumulator-mk2", { { "accumulator", 2 }, { "supercapacitor", 2 }, { "sap-mechanite-scrap", 5 } }),
  recipe("sap-solar-panel-mk2", { { "solar-panel", 1 }, { HEAT_CRYSTAL, 2 }, { "sap-mechanite-scrap", 5 } }),
  recipe("sap-em-turret", { { "laser-turret", 1 }, { "superconductor", 5 }, { "sap-mechanite-core", 2 } }),
  recipe("sap-emp-grenade", { { "grenade", 1 }, { "supercapacitor", 1 }, { "sap-mechanite-scrap", 2 } }, 2),

  tech("sap-echaris-robots-mk2", "__base__/graphics/icons/logistic-robot.png",
       { "sap-logistic-robot-mk2", "sap-construction-robot-mk2" }, 1500, "construction-robotics"),
  tech("sap-accumulator-mk2", "__base__/graphics/icons/accumulator.png", { "sap-accumulator-mk2" }, 800,
       "electric-energy-accumulators"),
  tech("sap-solar-panel-mk2", "__base__/graphics/icons/solar-panel.png", { "sap-solar-panel-mk2" }, 800, "solar-energy"),
  tech("sap-em-turret", "__base__/graphics/icons/laser-turret.png", { "sap-em-turret" }, 1000, "laser-turret"),
  tech("sap-emp-grenade", "__base__/graphics/icons/grenade.png", { "sap-emp-grenade" }, 500, "military-2"),
})
