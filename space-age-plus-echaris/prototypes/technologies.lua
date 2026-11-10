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

-- Остальные технологии Echaris (docs: Техи планет → Echaris) ------------------------------
local sap = require("__space-age-plus-core__.prototypes.api")

local function echaris_tech(name, icon, count, prerequisites)
  return { name = name, icon = icon, count = count or 800,
           prerequisites = { "sap-planet-discovery-echaris", prerequisites }, science = ECHARIS_PACKS }
end

-- Улучшения Mk2
sap.upgrade({
  base = "centrifuge", name = "sap-centrifuge-mk2", tint = TINT,
  change = function(e) e.crafting_speed = e.crafting_speed * 2 end,
  ingredients = { { "centrifuge", 1 }, { "sap-mechanite-core", 2 }, { NIVALITE, 5 } },
  tech = echaris_tech("sap-centrifuge-mk2", "__base__/graphics/icons/centrifuge.png", 800, "uranium-processing"),
})
sap.upgrade({
  base = "electric-furnace", name = "sap-electric-furnace-mk2", tint = TINT,
  change = function(e) e.crafting_speed = e.crafting_speed * 1.5 e.energy_usage = "126kW" end,
  ingredients = { { "electric-furnace", 1 }, { "sap-mechanite-scrap", 5 }, { "supercapacitor", 2 } },
  tech = echaris_tech("sap-electric-furnace-mk2", "__base__/graphics/icons/electric-furnace.png", 800, "advanced-material-processing-2"),
})
sap.upgrade({
  base = "assembling-machine-3", name = "sap-assembling-machine-mk2plus", tint = TINT,
  change = function(e) e.crafting_speed = 2.5 end,
  ingredients = { { "assembling-machine-3", 1 }, { "sap-mechanite-core", 2 }, { "superconductor", 5 } },
  tech = echaris_tech("sap-assembling-machine-mk2plus", "__base__/graphics/icons/assembling-machine-3.png", 1200, "automation-3"),
})
sap.upgrade({
  base = "storage-tank", name = "sap-storage-tank-mk2", tint = TINT,
  change = function(e) e.fluid_box.volume = e.fluid_box.volume * 2 end,
  ingredients = { { "storage-tank", 1 }, { "sap-mechanite-scrap", 5 } },
  tech = echaris_tech("sap-storage-tank-mk2", "__base__/graphics/icons/storage-tank.png", 500, "fluid-handling"),
})
sap.upgrade({
  base = "radar", name = "sap-radar-mk2", tint = TINT,
  change = function(e)
    e.max_distance_of_sector_revealed = e.max_distance_of_sector_revealed * 2
    e.max_distance_of_nearby_sector_revealed = e.max_distance_of_nearby_sector_revealed * 2
  end,
  ingredients = { { "radar", 1 }, { "sap-mechanite-core", 1 } },
  tech = echaris_tech("sap-radar-mk2", "__base__/graphics/icons/radar.png", 500, "radar"),
})
sap.upgrade({
  base = "roboport", name = "sap-roboport-mk2", tint = TINT,
  change = function(e)
    e.robot_slots_count = e.robot_slots_count * 2
    e.charging_energy = "1MW"
    e.charging_station_count = (e.charging_station_count or 4) * 2
  end,
  ingredients = { { "roboport", 1 }, { "sap-mechanite-core", 2 }, { NIVALITE, 5 } },
  tech = echaris_tech("sap-roboport-mk2", "__base__/graphics/icons/roboport.png", 1000, "sap-echaris-robots-mk2"),
})
sap.upgrade({
  base = "roboport", name = "sap-logistic-beacon-mk2", tint = { r = 0.6, g = 0.6, b = 1, a = 1 },
  change = function(e) e.logistics_radius = e.logistics_radius * 2 e.construction_radius = e.construction_radius * 1.5 end,
  ingredients = { { "roboport", 1 }, { "sap-mechanite-core", 3 }, { "processing-unit", 10 } },
  tech = echaris_tech("sap-logistic-beacon-mk2", "__base__/graphics/icons/roboport.png", 1000, "sap-roboport-mk2"),
})

-- Новые технологии
sap.upgrade({
  base = "big-electric-pole", name = "sap-power-relay-tower", tint = TINT,
  change = function(e) e.maximum_wire_distance = 64 e.supply_area_distance = 4 end,
  ingredients = { { "big-electric-pole", 2 }, { NIVALITE, 4 }, { "sap-mechanite-scrap", 5 } },
  tech = echaris_tech("sap-power-relay-tower", "__base__/graphics/icons/big-electric-pole.png", 800, "electric-energy-distribution-2"),
})
sap.upgrade({
  base = "tesla-turret", name = "sap-echaris-discharger", tint = TINT,
  change = function(e) e.attack_parameters.damage_modifier = (e.attack_parameters.damage_modifier or 1) * 1.5 end,
  ingredients = { { "tesla-turret", 1 }, { "sap-mechanite-core", 3 } },
  tech = echaris_tech("sap-echaris-discharger", "__space-age__/graphics/icons/tesla-turret.png", 1200, "tesla-weapons"),
})
sap.upgrade({
  base = "tesla-turret", name = "sap-suppressor-turret", tint = { r = 0.5, g = 0.5, b = 1, a = 1 },
  change = function(e) e.attack_parameters.range = e.attack_parameters.range + 8 end,
  ingredients = { { "tesla-turret", 1 }, { "supercapacitor", 10 }, { "sap-mechanite-scrap", 10 } },
  tech = echaris_tech("sap-suppressor-turret", "__space-age__/graphics/icons/tesla-turret.png", 1000, "tesla-weapons"),
})
sap.upgrade({
  base = "rocket-turret", name = "sap-emp-flak-cannon", tint = TINT,
  change = function(e)
    e.attack_parameters.range = e.attack_parameters.range + 10
    e.attack_parameters.damage_modifier = (e.attack_parameters.damage_modifier or 1) * 2
  end,
  ingredients = { { "rocket-turret", 1 }, { "sap-mechanite-core", 2 }, { "supercapacitor", 5 } },
  tech = echaris_tech("sap-emp-flak-cannon", "__space-age__/graphics/icons/rocket-turret.png", 1000, "rocket-turret"),
})
sap.upgrade({
  base = "submachine-gun", name = "sap-plasma-carbine", tint = TINT,
  change = function(_, item) item.attack_parameters.damage_modifier = (item.attack_parameters.damage_modifier or 1) * 2.5 end,
  ingredients = { { "submachine-gun", 1 }, { "supercapacitor", 5 }, { "sap-mechanite-core", 1 } },
  tech = echaris_tech("sap-plasma-carbine", "__base__/graphics/icons/submachine-gun.png", 600, "military-3"),
})
sap.upgrade({
  base = "power-armor-mk2", name = "sap-echaris-exoskeleton", tint = TINT,
  change = function(_, item)
    item.resistances = item.resistances or {}
    table.insert(item.resistances, { type = "electric", decrease = 20, percent = 80 })
  end,
  ingredients = { { "power-armor-mk2", 1 }, { "sap-mechanite-core", 10 }, { NIVALITE, 20 } },
  tech = echaris_tech("sap-echaris-exoskeleton", "__base__/graphics/icons/power-armor-mk2.png", 1500, "power-armor-mk2"),
})

-- Модульный реактор: компактный, без воды — ядерное топливо сразу в электричество.
local reactor = util.table.deepcopy(data.raw["burner-generator"]["burner-generator"])
reactor.name = "sap-modular-reactor"
reactor.hidden = nil
reactor.icon = nil
reactor.icons = { { icon = "__base__/graphics/icons/nuclear-reactor.png", icon_size = 64, tint = TINT } }
reactor.minable = { mining_time = 1, result = "sap-modular-reactor" }
reactor.max_power_output = "30MW"
reactor.burner.fuel_categories = { "nuclear" }
reactor.burner.burnt_inventory_size = 1
reactor.burner.effectivity = 0.5
data:extend({
  reactor,
  {
    type = "item", name = "sap-modular-reactor", icons = reactor.icons, subgroup = "energy",
    order = "f[nuclear-energy]-z[sap-modular-reactor]", place_result = "sap-modular-reactor", stack_size = 10,
  },
  recipe("sap-modular-reactor", { { "steel-plate", 100 }, { "sap-mechanite-core", 10 }, { NIVALITE, 20 },
                                  { "processing-unit", 20 } }),
  tech("sap-modular-reactor", "__base__/graphics/icons/nuclear-reactor.png", { "sap-modular-reactor" }, 1500, "nuclear-power"),
})

-- Архивный дешифратор: выше шанс карт высокого качества в центрах Echaris (scripts/mechanites.lua).
data:extend({
  {
    type = "technology", name = "sap-archive-decipherer",
    icons = { { icon = "__base__/graphics/technology/research-speed.png", icon_size = 256, tint = TINT } },
    effects = {},
    prerequisites = { "sap-planet-discovery-echaris" },
    unit = { count = 1000, time = 60, ingredients = ECHARIS_PACKS },
  },
})
