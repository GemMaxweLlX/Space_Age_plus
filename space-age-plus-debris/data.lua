-- space-age-plus-debris: прототипы космического мусора (docs: Глобальные механики → Мусор).
--   Обломки — куски-астероиды трёх видов: металлические, электронные, ракетные.
--   Их ловит обычный сборщик астероидов, а дробилка перерабатывает в ресурсы.
--   Упавший на планету ракетный обломок — обломок корабля, который можно разобрать.

local util = require("util")

local KINDS = {
  metal = { tint = { r = 0.75, g = 0.75, b = 0.8, a = 1 }, results = {
    { type = "item", name = "iron-plate", amount = 3 },
    { type = "item", name = "copper-plate", amount = 2 },
    { type = "item", name = "steel-plate", amount = 1, independent_probability = 0.3 },
  } },
  electronic = { tint = { r = 0.6, g = 1, b = 0.6, a = 1 }, results = {
    { type = "item", name = "copper-cable", amount = 4 },
    { type = "item", name = "electronic-circuit", amount = 1 },
    { type = "item", name = "advanced-circuit", amount = 1, independent_probability = 0.25 },
    { type = "item", name = "processing-unit", amount = 1, independent_probability = 0.05 },
  } },
  rocket = { tint = { r = 1, g = 0.7, b = 0.5, a = 1 }, results = {
    { type = "item", name = "steel-plate", amount = 3 },
    { type = "item", name = "low-density-structure", amount = 1, independent_probability = 0.3 },
    { type = "item", name = "plastic-bar", amount = 2, independent_probability = 0.5 },
    { type = "item", name = "rocket-fuel", amount = 1, independent_probability = 0.1 },
  } },
}

-- Мусор на орбитах и маршрутах планет SA+ (docs: Мусор → По орбитам SA+).
KINDS["electrified"] = { tint = { r = 0.6, g = 0.6, b = 1, a = 1 }, results = {
  { type = "item", name = "copper-cable", amount = 6 },
  { type = "item", name = "supercapacitor", amount = 1, independent_probability = 0.1 },
} }
KINDS["heated"] = { tint = { r = 1, g = 0.5, b = 0.2, a = 1 }, results = {
  { type = "item", name = "iron-plate", amount = 3 },
  { type = "item", name = "tungsten-plate", amount = 1, independent_probability = 0.2 },
} }
KINDS["biofilm"] = { tint = { r = 0.4, g = 0.9, b = 0.5, a = 1 }, results = {
  { type = "item", name = "spoilage", amount = 3 },
  { type = "item", name = "nutrients", amount = 2, independent_probability = 0.5 },
} }
KINDS["frozen"] = { tint = { r = 0.8, g = 0.95, b = 1, a = 1 }, results = {
  { type = "item", name = "ice", amount = 4 },
  { type = "item", name = "iron-plate", amount = 1 },
} }

local unlocks = {}

for kind, def in pairs(KINDS) do
  local name = "sap-debris-" .. kind
  local icons = { { icon = "__space-age__/graphics/icons/metallic-asteroid-chunk.png", icon_size = 64, tint = def.tint } }

  local chunk = util.table.deepcopy(data.raw["asteroid-chunk"]["metallic-asteroid-chunk"])
  chunk.name = name
  chunk.icon = nil
  chunk.icons = icons
  chunk.minable = { mining_time = 0.2, result = name }

  local item = util.table.deepcopy(data.raw.item["metallic-asteroid-chunk"])
  item.name = name
  item.icon = nil
  item.icons = icons
  item.subgroup = "space-material"
  item.order = "z[sap-debris]-" .. kind

  data:extend({
    chunk,
    item,
    {
      type = "recipe",
      name = name .. "-crushing",
      icons = icons,
      categories = { "crushing" },
      subgroup = "space-crushing",
      order = "z[sap-debris]-" .. kind,
      auto_recycle = false,
      enabled = false,
      energy_required = 2,
      ingredients = { { type = "item", name = name, amount = 1 } },
      results = def.results,
    },
  })
  unlocks[#unlocks + 1] = { type = "unlock-recipe", recipe = name .. "-crushing" }
end

-- Обломок, упавший на планету.
local wreck = util.table.deepcopy(data.raw["simple-entity-with-owner"]["crash-site-spaceship-wreck-small-1"])
wreck.name = "sap-fallen-debris"
wreck.minable = { mining_time = 1, results = { { type = "item", name = "sap-debris-rocket", amount = 3 } } }
wreck.placeable_by = nil
data:extend({ wreck })

data:extend({
  {
    type = "technology",
    name = "sap-debris-recycling",
    icons = { { icon = "__space-age__/graphics/icons/metallic-asteroid-chunk.png", icon_size = 64,
                tint = KINDS.rocket.tint } },
    effects = unlocks,
    prerequisites = { "space-platform" },
    unit = {
      count = 200, time = 30,
      ingredients = {
        { "automation-science-pack", 1 }, { "logistic-science-pack", 1 }, { "chemical-science-pack", 1 },
      },
    },
  },
})

-- Подсказки (окно «Советы и подсказки», раздел Space Age+).
local sap = require("__space-age-plus-core__.prototypes.api")
sap.tip("sap-debris", "m", "[item=sap-debris-metal]", { type = "research", technology = "space-platform" })
