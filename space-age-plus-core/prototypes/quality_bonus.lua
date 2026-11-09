-- Бонусы технологий по качеству (docs: Вопросы реализации → I3).
-- Технология, открытая и исследованная в лучшем качестве, даёт своим постройкам понемногу
-- продуктивности, скорости и экономии энергии. Бонус передаёт невидимый маяк под каждой
-- постройкой со скрытым модулем своего качества (scripts/quality_bonus.lua).
-- Версии технологий по качеству создаёт data-final-fixes.lua.

local util = require("util")

local BONUS = {
  uncommon = { productivity = 0.02, speed = 0.05, consumption = -0.05 },
  rare = { productivity = 0.04, speed = 0.10, consumption = -0.10 },
  epic = { productivity = 0.06, speed = 0.15, consumption = -0.15 },
  legendary = { productivity = 0.10, speed = 0.25, consumption = -0.25 },
}

data:extend({ { type = "module-category", name = "sap-tech-bonus" } })

local tier = 0
for quality, effect in pairs(BONUS) do
  tier = tier + 1
  data:extend({
    {
      type = "module",
      name = "sap-tech-bonus-" .. quality,
      icons = { { icon = "__base__/graphics/icons/productivity-module.png", icon_size = 64 } },
      category = "sap-tech-bonus",
      tier = tier,
      effect = effect,
      hidden = true,
      hidden_in_factoriopedia = true,
      subgroup = "module",
      order = "z[sap-tech-bonus]-" .. tier,
      stack_size = 1,
    },
  })
end

local beacon = util.table.deepcopy(data.raw.beacon["beacon"])
beacon.name = "sap-tech-bonus-beacon"
beacon.icons = { { icon = "__base__/graphics/icons/beacon.png", icon_size = 64 } }
beacon.icon = nil
beacon.minable = nil
beacon.hidden = true
beacon.hidden_in_factoriopedia = true
beacon.flags = { "not-on-map", "placeable-off-grid", "not-blueprintable", "not-deconstructable",
                 "not-repairable", "no-copy-paste", "not-in-kill-statistics", "not-upgradable" }
beacon.selectable_in_game = false
beacon.collision_box = { { -0.1, -0.1 }, { 0.1, 0.1 } }
beacon.selection_box = { { -0.1, -0.1 }, { 0.1, 0.1 } }
beacon.collision_mask = { layers = {} }
beacon.energy_source = { type = "void" }
beacon.energy_usage = "1W"
beacon.supply_area_distance = 0
beacon.module_slots = 1
beacon.allowed_effects = { "productivity", "speed", "consumption" }
beacon.allowed_module_categories = { "sap-tech-bonus" }
beacon.distribution_effectivity = 1
beacon.distribution_effectivity_bonus_per_quality_level = 0
beacon.profile = { 1 }
beacon.beacon_counter = "same_type"
beacon.graphics_set = nil
beacon.radius_visualisation_picture = nil
beacon.fast_replaceable_group = nil
beacon.next_upgrade = nil
beacon.corpse = nil
beacon.dying_explosion = nil

data:extend({ beacon })
