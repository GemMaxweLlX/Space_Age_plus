-- Механиты Echaris (docs: Планеты → Echaris → 5 типов Механитов, Зоны и центры).
-- Механиты не живые (H4): гнёзда — это серверы контроля, захватить их нельзя.
-- Графика пока временная — кусаки и плеватели Наувиса.
-- Поведение (ЭМИ, подкрепления, тревога, волны) — scripts/mechanites.lua.

local util = require("util")

local MECHANITE_RESISTANCES = {
  { type = "physical", decrease = 4, percent = 30 },
  { type = "fire", percent = 80 },
  { type = "acid", percent = 100 },
  { type = "poison", percent = 100 },
  { type = "electric", percent = -50 },
}

local LOOT_SCRAP = {
  { type = "item", name = "sap-mechanite-scrap", amount = 1, independent_probability = 0.5 },
}

local function unit(base_type, base_name, name, opts)
  local e = util.table.deepcopy(data.raw[base_type][base_name])
  e.name = name
  e.max_health = opts.health
  e.resistances = util.table.deepcopy(opts.resistances or MECHANITE_RESISTANCES)
  e.movement_speed = e.movement_speed * (opts.speed or 1)
  e.distance_per_frame = e.distance_per_frame * (opts.speed or 1)
  e.loot = opts.loot or LOOT_SCRAP
  e.absorptions_to_join_attack = nil
  if opts.damage_modifier and e.attack_parameters then
    e.attack_parameters.damage_modifier = opts.damage_modifier
  end
  return e
end

local units = {
  -- Патруль, реагирует на шум, вызывает подкрепления.
  unit("unit", "medium-biter", "sap-sentinel", { health = 180 }),
  -- Подзаряжается от бури — всегда усилен.
  unit("unit", "small-biter", "sap-stormbringer", { health = 90, speed = 1.4, damage_modifier = 2 }),
  -- ЭМИ: вырубает дронов и турели.
  unit("unit", "medium-spitter", "sap-disruptor", { health = 220 }),
  -- Медленный, пробивает броню.
  unit("unit", "big-biter", "sap-annihilator", {
    health = 1500, speed = 0.6, damage_modifier = 2,
    resistances = {
      { type = "physical", decrease = 12, percent = 50 },
      { type = "fire", percent = 80 },
      { type = "acid", percent = 100 },
      { type = "poison", percent = 100 },
      { type = "electric", percent = -50 },
    },
    loot = { { type = "item", name = "sap-mechanite-scrap", amount_min = 2, amount_max = 4 } },
  }),
  -- Координатор, при смерти — тревога.
  unit("unit", "big-spitter", "sap-overseer", {
    health = 800,
    loot = { { type = "item", name = "sap-mechanite-core", amount = 1 } },
  }),
}
data:extend(units)

local function server(name, health, result_units)
  local e = util.table.deepcopy(data.raw["unit-spawner"]["biter-spawner"])
  e.name = name
  e.max_health = health
  e.resistances = util.table.deepcopy(MECHANITE_RESISTANCES)
  e.result_units = result_units
  e.autoplace = nil -- серверы ставит скрипт вокруг центров захвата
  e.captured_spawner_entity = nil
  e.loot = { { type = "item", name = "sap-mechanite-core", amount_min = 2, amount_max = 4 } }
  e.max_count_of_owned_units = 10
  e.spawning_cooldown = { 600, 300 }
  return e
end

data:extend({
  server("sap-control-server", 600, {
    { "sap-sentinel", { { 0, 0.5 } } },
    { "sap-stormbringer", { { 0, 0.4 } } },
    { "sap-disruptor", { { 0, 0.1 } } },
  }),
  server("sap-control-server-heavy", 1500, {
    { "sap-sentinel", { { 0, 0.3 } } },
    { "sap-stormbringer", { { 0, 0.25 } } },
    { "sap-disruptor", { { 0, 0.2 } } },
    { "sap-annihilator", { { 0, 0.15 } } },
    { "sap-overseer", { { 0, 0.1 } } },
  }),
})

-- Центры захвата: внутри карты данных своего типа. Открыть можно, только когда
-- рядом не осталось серверов контроля.
for _, center in pairs({ "data", "suppression", "assembly", "energy" }) do
  local e = util.table.deepcopy(data.raw.container["crash-site-spaceship-wreck-big-1"])
  e.name = "sap-center-" .. center
  e.inventory_size = 8
  data:extend({ e })
end

local TINT = { r = 0.75, g = 0.7, b = 1.0, a = 1.0 }
data:extend({
  {
    type = "item",
    name = "sap-mechanite-scrap",
    icons = { { icon = "__base__/graphics/icons/iron-gear-wheel.png", icon_size = 64, tint = TINT } },
    subgroup = "raw-material",
    order = "z[sap]-a[mechanite-scrap]",
    stack_size = 100,
  },
  {
    type = "item",
    name = "sap-mechanite-core",
    icons = { { icon = "__base__/graphics/icons/processing-unit.png", icon_size = 64, tint = TINT } },
    subgroup = "raw-material",
    order = "z[sap]-b[mechanite-core]",
    stack_size = 50,
  },
})
