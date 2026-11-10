-- space-age-plus-core: правки после всех data.lua (бочки к этому моменту уже созданы).

-- Цистерны: для каждой жидкости, которую можно разлить в бочки, — цистерна на 500 единиц.
local CISTERN = 500
local tech = data.raw.technology["sap-cistern"]
local fluids = {}
for name, fluid in pairs(data.raw.fluid) do
  if data.raw.item[name .. "-barrel"] and not fluid.hidden then fluids[#fluids + 1] = name end
end
table.sort(fluids)
for _, name in pairs(fluids) do
  local fluid = data.raw.fluid[name]
  local fluid_icons = fluid.icons or { { icon = fluid.icon, icon_size = fluid.icon_size or 64 } }
  local icons = { { icon = "__base__/graphics/icons/storage-tank.png", icon_size = 64 } }
  for _, layer in pairs(fluid_icons) do
    local l = { icon = layer.icon, icon_size = layer.icon_size or 64, tint = layer.tint }
    l.scale = 0.25
    l.shift = { 6, 6 }
    icons[#icons + 1] = l
  end
  local item = "sap-" .. name .. "-cistern"
  data:extend({
    {
      type = "item", name = item, icons = icons, subgroup = "intermediate-product",
      order = "z[sap-cistern]-" .. name, stack_size = 10,
      localised_name = { "sap-cistern.filled", fluid.localised_name or { "fluid-name." .. name } },
    },
    {
      type = "recipe", name = item, categories = { "crafting-with-fluid" }, enabled = false, energy_required = 1,
      icons = icons, hide_from_player_crafting = true, auto_recycle = false,
      localised_name = { "sap-cistern.fill", fluid.localised_name or { "fluid-name." .. name } },
      ingredients = { { type = "item", name = "sap-cistern", amount = 1 }, { type = "fluid", name = name, amount = CISTERN } },
      results = { { type = "item", name = item, amount = 1 } },
    },
    {
      type = "recipe", name = "sap-empty-" .. name .. "-cistern", categories = { "crafting-with-fluid" }, enabled = false,
      energy_required = 1, icons = icons, hide_from_player_crafting = true, auto_recycle = false,
      localised_name = { "sap-cistern.empty", fluid.localised_name or { "fluid-name." .. name } },
      ingredients = { { type = "item", name = item, amount = 1 } },
      results = { { type = "item", name = "sap-cistern", amount = 1 }, { type = "fluid", name = name, amount = CISTERN } },
    },
  })
  table.insert(tech.effects, { type = "unlock-recipe", recipe = item })
  table.insert(tech.effects, { type = "unlock-recipe", recipe = "sap-empty-" .. name .. "-cistern" })
end
