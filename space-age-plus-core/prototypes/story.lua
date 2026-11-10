-- Сюжет (scripts/story.lua): древние ядра из подземелий открывают историю древней расы;
-- из ядер и колб всех планет строится Древний узел, в котором выбирается концовка.
-- Ингредиенты технологии и рецепта узла (колбы всех планет, ядро на каждую планету)
-- дописывает data-final-fixes, когда известны все колбы.

local sap = require("prototypes.api")
local util = require("util")

local TINT = { r = 0.5, g = 1, b = 0.85, a = 1 }

local nexus = util.table.deepcopy(data.raw.container["crash-site-spaceship"])
nexus.name = "sap-ancient-nexus"
nexus.inventory_size = 1
nexus.minable = { mining_time = 2, result = "sap-ancient-nexus" }
nexus.flags = { "placeable-player", "player-creation" }
nexus.hidden = nil
nexus.icons = { { icon = "__base__/graphics/icons/crash-site-spaceship.png", icon_size = 64, tint = TINT } }
nexus.icon = nil

data:extend({
  nexus,
  {
    type = "item", name = "sap-ancient-nexus", place_result = "sap-ancient-nexus",
    icons = { { icon = "__base__/graphics/icons/crash-site-spaceship.png", icon_size = 64, tint = TINT } },
    subgroup = "sap-tech-data", order = "d-c", stack_size = 1,
  },
  {
    type = "recipe", name = "sap-ancient-nexus", enabled = false, energy_required = 60,
    ingredients = {
      { type = "item", name = "refined-concrete", amount = 100 },
      { type = "item", name = "processing-unit", amount = 50 },
    },
    results = { { type = "item", name = "sap-ancient-nexus", amount = 1 } },
  },
  {
    type = "technology", name = "sap-ancient-nexus",
    icons = { { icon = "__base__/graphics/technology/research-speed.png", icon_size = 256, tint = TINT } },
    effects = { { type = "unlock-recipe", recipe = "sap-ancient-nexus" } },
    prerequisites = { "sap-alien-resonance", "space-science-pack" },
    unit = {
      count = 1000, time = 60,
      ingredients = { { "automation-science-pack", 1 }, { "logistic-science-pack", 1 },
                      { "chemical-science-pack", 1 }, { "space-science-pack", 1 } },
    },
  },
})
sap.set_tech_category("sap-ancient-nexus", "alien")
sap.tip("sap-story", "k", "[item=sap-ancient-core]")
