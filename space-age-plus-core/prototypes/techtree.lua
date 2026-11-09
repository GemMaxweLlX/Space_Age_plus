-- Переосмысление дерева технологий (docs: Технологии).
--   Карты данных  — 15 категорий; качество карты = качество предмета (механика Space Age).
--   Дешифратор    — карта + колбы → выбор из трёх технологий категории карты.
--   ЛЛК           — только колбы, шанс 10-20%, выбор из двух, всегда обычное качество.
--   Обломки       — контейнеры с картами данных, появляются на планетах.
-- Какие технологии скрыты, решает data-final-fixes.lua. Логика — scripts/techtree.lua.

local util = require("util")

local CATEGORIES = {
  automation = { r = 1.0, g = 0.6, b = 0.3 },
  logistics = { r = 1.0, g = 0.9, b = 0.3 },
  mining = { r = 0.7, g = 0.5, b = 0.3 },
  production = { r = 0.9, g = 0.5, b = 0.5 },
  energy = { r = 1.0, g = 1.0, b = 0.6 },
  military = { r = 1.0, g = 0.3, b = 0.3 },
  robotics = { r = 0.5, g = 0.8, b = 1.0 },
  trains = { r = 0.6, g = 0.6, b = 0.6 },
  chemistry = { r = 0.5, g = 1.0, b = 0.7 },
  space = { r = 0.8, g = 0.8, b = 1.0 },
  biotech = { r = 0.5, g = 0.9, b = 0.3 },
  cryotech = { r = 0.6, g = 0.9, b = 1.0 },
  ["sap-energy"] = { r = 1.0, g = 0.7, b = 1.0 },
  ["sap-military"] = { r = 0.8, g = 0.3, b = 0.6 },
  alien = { r = 0.6, g = 1.0, b = 0.9 },
}

local order = 0
for category, tint in pairs(CATEGORIES) do
  order = order + 1
  data:extend({
    {
      type = "item",
      name = "sap-data-card-" .. category,
      icons = { { icon = "__base__/graphics/icons/processing-unit.png", icon_size = 64, tint = tint } },
      subgroup = "sap-tech-data",
      order = string.format("a-%02d", order),
      stack_size = 10,
    },
  })
end

local function container(name, base_name, size, tint)
  local e = util.table.deepcopy(data.raw.container[base_name])
  e.name = name
  e.icons = { { icon = "__base__/graphics/icons/steel-chest.png", icon_size = 64, tint = tint } }
  e.icon = nil
  e.minable = { mining_time = 0.5, result = name }
  e.inventory_size = size
  e.fast_replaceable_group = nil
  e.next_upgrade = nil
  return e
end

local decipherer = container("sap-decipherer", "steel-chest", 16, { r = 0.7, g = 0.6, b = 1.0 })
local logic_lab = container("sap-logic-lab", "steel-chest", 16, { r = 0.6, g = 1.0, b = 0.8 })

-- Обломки с картами данных. Разобрать нельзя — только забрать содержимое.
local wreck = util.table.deepcopy(data.raw.container["crash-site-spaceship-wreck-medium-1"])
wreck.name = "sap-data-wreck"
wreck.inventory_size = 4
local starting_wreck = util.table.deepcopy(data.raw.container["crash-site-spaceship-wreck-big-1"])
starting_wreck.name = "sap-starting-wreck"
starting_wreck.inventory_size = 4

data:extend({
  { type = "item-subgroup", name = "sap-tech-data", group = "intermediate-products", order = "z-sap-b" },
  decipherer,
  logic_lab,
  wreck,
  starting_wreck,
  {
    type = "item", name = "sap-decipherer",
    icons = decipherer.icons, subgroup = "sap-tech-data", order = "b-a",
    place_result = "sap-decipherer", stack_size = 10,
  },
  {
    type = "item", name = "sap-logic-lab",
    icons = logic_lab.icons, subgroup = "sap-tech-data", order = "b-b",
    place_result = "sap-logic-lab", stack_size = 10,
  },
  {
    type = "recipe", name = "sap-decipherer", enabled = false, energy_required = 5,
    ingredients = {
      { type = "item", name = "electronic-circuit", amount = 20 },
      { type = "item", name = "iron-gear-wheel", amount = 10 },
      { type = "item", name = "copper-cable", amount = 20 },
    },
    results = { { type = "item", name = "sap-decipherer", amount = 1 } },
  },
  {
    type = "recipe", name = "sap-logic-lab", enabled = false, energy_required = 5,
    ingredients = {
      { type = "item", name = "electronic-circuit", amount = 10 },
      { type = "item", name = "iron-gear-wheel", amount = 10 },
      { type = "item", name = "copper-cable", amount = 10 },
    },
    results = { { type = "item", name = "sap-logic-lab", amount = 1 } },
  },
  {
    type = "technology",
    name = "sap-decipherer",
    icons = { { icon = "__base__/graphics/technology/research-speed.png", icon_size = 256,
                tint = { r = 0.7, g = 0.6, b = 1.0, a = 1 } } },
    effects = {
      { type = "unlock-recipe", recipe = "sap-decipherer" },
      { type = "unlock-recipe", recipe = "sap-logic-lab" },
    },
    prerequisites = { "automation-science-pack" },
    unit = { count = 30, time = 10, ingredients = { { "automation-science-pack", 1 } } },
  },
  {
    type = "mod-data",
    name = "sap-tech-categories",
    data = { list = (function()
      local list = {}
      for category in pairs(CATEGORIES) do list[#list + 1] = category end
      table.sort(list)
      return list
    end)() },
  },
})
