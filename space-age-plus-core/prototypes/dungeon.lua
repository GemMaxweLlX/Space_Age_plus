-- Подземелья древней расы (scripts/dungeon.lua): вход у хранилищ, двери и замки, стражи,
-- тайники, Хранитель с ключом, древнее ядро в последнем зале.

local util = require("util")

local TINT = { r = 0.5, g = 1, b = 0.85, a = 1 }

local function container(name, base, size)
  local e = util.table.deepcopy(data.raw.container[base])
  e.name = name
  e.inventory_size = size
  e.minable = nil
  return e
end

-- Дверь: глыба 3×3 в коридоре (коридоры шириной 3).
local door = util.table.deepcopy(data.raw["simple-entity-with-owner"]["crash-site-spaceship-wreck-small-1"])
door.name = "sap-ancient-door"
door.minable = nil
door.collision_box = { { -1.4, -1.4 }, { 1.4, 1.4 } }
door.selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } }

-- Энергетический замок: сжигает топливо; когда цикл завершён — дверь открывается.
local power_lock = util.table.deepcopy(data.raw["assembling-machine"]["assembling-machine-1"])
power_lock.name = "sap-ancient-power-lock"
power_lock.icons = { { icon = "__base__/graphics/icons/assembling-machine-1.png", icon_size = 64, tint = TINT } }
power_lock.icon = nil
power_lock.minable = nil
power_lock.crafting_categories = { "sap-ancient-lock" }
power_lock.fixed_recipe = "sap-ancient-lock-cycle"
power_lock.crafting_speed = 1
power_lock.energy_usage = "1MW"
power_lock.energy_source = { type = "burner", fuel_categories = { "chemical", "nuclear" }, effectivity = 1,
                             fuel_inventory_size = 1 }
power_lock.next_upgrade = nil
power_lock.fast_replaceable_group = nil

-- Ловушка: плита в полу, по ней можно ходить; срабатывает скриптом (огонь, разряд, яд, холод).
local landmine = data.raw["land-mine"]["land-mine"]
local trap = {
  type = "simple-entity-with-owner", name = "sap-ancient-trap",
  icons = { { icon = landmine.icon, icon_size = landmine.icon_size or 64, tint = { r = 1, g = 0.4, b = 0.3, a = 1 } } },
  flags = { "placeable-neutral", "not-on-map" },
  collision_box = { { -0.4, -0.4 }, { 0.4, 0.4 } }, selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
  collision_mask = { layers = {} }, render_layer = "floor",
  picture = util.table.deepcopy(landmine.picture_set_enemy or landmine.picture_set),
  max_health = 100, hidden_in_factoriopedia = true,
}

-- Смотритель: босс последнего зала. Пока он жив, тайника с ядром нет.
local warden = util.table.deepcopy(data.raw.unit["behemoth-biter"])
warden.name = "sap-ancient-warden"
warden.max_health = 15000
warden.healing_per_tick = 0.05
warden.loot = nil

local keeper = util.table.deepcopy(data.raw.unit["big-biter"])
keeper.name = "sap-ancient-keeper"
keeper.max_health = 2500
keeper.loot = { { type = "item", name = "sap-ancient-key", amount = 1 } }

data:extend({
  { type = "recipe-category", name = "sap-ancient-lock" },
  container("sap-dungeon-entrance", "crash-site-spaceship-wreck-medium-2", 1),
  container("sap-dungeon-exit", "crash-site-chest-1", 1),
  container("sap-ancient-key-lock", "crash-site-chest-2", 1),
  container("sap-ancient-cache", "crash-site-chest-1", 8),
  (function()
    -- Пьедестал: ядро планеты в нём даёт бонус планеты всей команде.
    local pedestal = container("sap-ancient-pedestal", "crash-site-chest-2", 1)
    pedestal.minable = { mining_time = 1, result = "sap-ancient-pedestal" }
    pedestal.flags = { "placeable-player", "player-creation" }
    pedestal.hidden = nil
    return pedestal
  end)(),
  {
    type = "item", name = "sap-ancient-pedestal", place_result = "sap-ancient-pedestal",
    icons = { { icon = "__base__/graphics/icons/iron-chest.png", icon_size = 64, tint = TINT } },
    subgroup = "sap-tech-data", order = "d-d", stack_size = 10,
  },
  {
    type = "recipe", name = "sap-ancient-pedestal", enabled = false, energy_required = 10,
    ingredients = { { type = "item", name = "steel-plate", amount = 20 }, { type = "item", name = "advanced-circuit", amount = 10 } },
    results = { { type = "item", name = "sap-ancient-pedestal", amount = 1 } },
  },
  {
    -- Открывается, когда команда забирает первое древнее ядро (scripts/dungeon.lua).
    type = "technology", name = "sap-ancient-pedestal",
    icons = { { icon = "__base__/graphics/icons/iron-chest.png", icon_size = 64, tint = TINT } },
    effects = { { type = "unlock-recipe", recipe = "sap-ancient-pedestal" } },
    research_trigger = { type = "scripted", trigger_description = { "technology-trigger.sap-ancient-pedestal" } },
  },
  door, power_lock, keeper, trap, warden,
  {
    type = "item", name = "sap-ancient-key",
    icons = { { icon = "__base__/graphics/icons/processing-unit.png", icon_size = 64, tint = { r = 1, g = 0.9, b = 0.4, a = 1 } } },
    subgroup = "sap-tech-data", order = "d-a", stack_size = 10,
  },
  {
    type = "item", name = "sap-ancient-core",
    icons = { { icon = "__base__/graphics/icons/uranium-235.png", icon_size = 64, tint = TINT } },
    subgroup = "sap-tech-data", order = "d-b", stack_size = 10,
  },
  {
    type = "item", name = "sap-ancient-lock-token", icon = "__base__/graphics/icons/processing-unit.png", icon_size = 64,
    hidden = true, stack_size = 1,
  },
  {
    type = "recipe", name = "sap-ancient-lock-cycle", categories = { "sap-ancient-lock" }, hidden = true, enabled = true,
    energy_required = 30, ingredients = {}, results = { { type = "item", name = "sap-ancient-lock-token", amount = 1 } },
  },
})

-- Новые инопланетные технологии — открываются инопланетными картами из подземелий и хранилищ.
local ALIEN_PACKS = {
  { "automation-science-pack", 1 }, { "logistic-science-pack", 1 }, { "chemical-science-pack", 1 },
  { "space-science-pack", 1 },
}
local function alien_tech(name, icon, effects, count)
  return {
    type = "technology", name = name, icons = { { icon = icon, icon_size = 256, tint = TINT } },
    effects = effects, prerequisites = { "space-science-pack" },
    unit = { count = count, time = 60, ingredients = ALIEN_PACKS },
  }
end
data:extend({
  alien_tech("sap-alien-stasis-field", "__base__/graphics/technology/physical-projectile-damage-1.png",
             { { type = "character-health-bonus", modifier = 150 } }, 2000),
  alien_tech("sap-alien-drift-engines", "__base__/graphics/technology/worker-robots-speed.png",
             { { type = "worker-robot-speed", modifier = 0.3 } }, 2000),
  alien_tech("sap-alien-resonance", "__base__/graphics/technology/research-speed.png",
             { { type = "laboratory-productivity", modifier = 0.1 } }, 3000),
  alien_tech("sap-alien-grip", "__base__/graphics/technology/inserter-capacity.png",
             { { type = "bulk-inserter-capacity-bonus", modifier = 2 } }, 2500),
})
