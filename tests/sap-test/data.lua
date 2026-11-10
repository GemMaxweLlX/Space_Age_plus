-- Проверка API ядра для других модов (docs/api.md): keep_visible и set_tech_category.
local sap = require("__space-age-plus-core__.prototypes.api")

local function tech(name)
  return {
    type = "technology", name = name, icon = "__base__/graphics/technology/automation-1.png", icon_size = 256,
    effects = {}, prerequisites = { "logistic-science-pack" },
    unit = { count = 10, time = 5, ingredients = { { "automation-science-pack", 1 }, { "logistic-science-pack", 1 } } },
  }
end
data:extend({ tech("sap-test-visible-tech"), tech("sap-test-categorized-tech") })
sap.keep_visible("sap-test-visible-tech")
sap.set_tech_category("sap-test-categorized-tech", "trains")
