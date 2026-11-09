-- Общий API ядра для модулей Space Age+ (стадия data).
-- Использование из другого модуля:
--   local sap = require("__space-age-plus-core__.prototypes.api")
--   sap.register_oxygen_planet("solaris", { solution = "generator" })

local api = {}

api.OXYGEN_PLANETS = "sap-oxygen-planets"

local function oxygen_planets()
  local proto = data.raw["mod-data"] and data.raw["mod-data"][api.OXYGEN_PLANETS]
  if not proto then
    proto = { type = "mod-data", name = api.OXYGEN_PLANETS, data = {} }
    data:extend({ proto })
    proto = data.raw["mod-data"][api.OXYGEN_PLANETS]
  end
  return proto.data
end

--- Отмечает планету как требующую кислорода.
--- @param planet string имя прототипа planet
--- @param opts table|nil { solution = "generator" | "collector" } (информативно)
function api.register_oxygen_planet(planet, opts)
  oxygen_planets()[planet] = { solution = (opts and opts.solution) or "generator" }
end

--- Убирает требование кислорода с планеты.
function api.unregister_oxygen_planet(planet)
  oxygen_planets()[planet] = nil
end

--- Рецепт атмосферного коллектора для планеты: работает только при её давлении.
--- Рецепт нужно добавить через data:extend и разблокировать технологией.
--- @param planet string имя планеты (часть имени рецепта)
--- @param pressure number давление атмосферы планеты (surface property "pressure")
--- @param ingredients table ингредиенты (например, фильтр для этой планеты)
--- @param amount number|nil сколько кислорода за цикл (по умолчанию 200)
function api.oxygen_collector_recipe(planet, pressure, ingredients, amount)
  return {
    type = "recipe",
    name = "sap-oxygen-collection-" .. planet,
    categories = { "sap-oxygen-collection" },
    subgroup = "sap-oxygen",
    order = "e-" .. planet,
    icons = { { icon = "__base__/graphics/icons/fluid/steam.png", icon_size = 64,
                tint = { r = 0.55, g = 0.85, b = 1.0, a = 1.0 } } },
    enabled = false,
    energy_required = 5,
    ingredients = ingredients,
    results = { { type = "fluid", name = "sap-oxygen", amount = amount or 200 } },
    main_product = "sap-oxygen",
    surface_conditions = {
      { property = "pressure", min = pressure, max = pressure },
    },
  }
end

--- Точка на звёздной карте, где находится планета-родитель. Нужна спутникам:
--- у спутника `origin` = позиция родителя, а distance/orientation считаются от неё.
--- Ориентация 0 — вверх, по часовой стрелке (как у ванильных планет).
--- @param parent string имя планеты-родителя
--- @return table MapPosition
function api.moon_origin(parent)
  local p = data.raw.planet[parent]
  local base = p.origin or { 0, 0 }
  local bx, by = base.x or base[1], base.y or base[2]
  local angle = 2 * math.pi * p.orientation
  return { bx + p.distance * math.sin(angle), by - p.distance * math.cos(angle) }
end

api.EXPLORABLE_PLANETS = "sap-explorable-planets"

--- Регистрирует планету в системе исследования (телескоп и спутники).
--- Технология открытия планеты будет скрыта, пока спутник 2 поколения её не разведает.
--- @param planet string имя планеты
--- @param opts table { discovery_tech = "имя технологии", parent = "родитель"|nil }
function api.register_explorable_planet(planet, opts)
  local proto = data.raw["mod-data"] and data.raw["mod-data"][api.EXPLORABLE_PLANETS]
  if not proto then
    data:extend({ { type = "mod-data", name = api.EXPLORABLE_PLANETS, data = {} } })
    proto = data.raw["mod-data"][api.EXPLORABLE_PLANETS]
  end
  proto.data[planet] = { discovery_tech = opts.discovery_tech, parent = opts.parent }
end

api.CAPTURABLE = "sap-capturable-nests"

--- Захват ульев SA+ (docs: Глобальные механики → Захват ульев SA+).
--- Создаёт для планеты: технологию «Перекалибровка захватчика: планета», свою ракету захвата
--- (ванильная гнёзда SA+ не берёт), корм (биофлюс Глебы + местные ресурсы) и захваченные
--- версии гнёзд. Захваченное гнездо ест только корм своей планеты и производит её материал;
--- без корма теряет здоровье и снова становится вражеским гнездом.
--- @param def table {
---   planet = "solaris", tint = {...}, discovery_tech = "...",
---   nests = { { nest = "sap-scorch-nest", product = "sap-heat-scales" }, ... },
---   food_ingredients = { {type, name, amount}, ... },  -- к ним добавляется биофлюс
---   rocket_ingredients = { {type, name, amount}, ... }, -- к ним добавляется ракета захвата
---   science = { {pack, 1}, ... } }
function api.capturable_nests(def)
  local util = require("util")
  local planet = def.planet
  local tint = def.tint or { r = 1, g = 1, b = 1, a = 1 }
  local food = "sap-" .. planet .. "-food"
  local rocket = "sap-capture-rocket-" .. planet
  local nest_names = {}

  local registry = data.raw["mod-data"] and data.raw["mod-data"][api.CAPTURABLE]
  if not registry then
    data:extend({ { type = "mod-data", name = api.CAPTURABLE, data = {} } })
    registry = data.raw["mod-data"][api.CAPTURABLE]
  end

  data:extend({
    { type = "fuel-category", name = food },
    {
      type = "item", name = food,
      icons = { { icon = "__space-age__/graphics/icons/bioflux.png", icon_size = 64, tint = tint } },
      subgroup = "agriculture-products", order = "z[sap-food]-" .. planet, stack_size = 100,
      fuel_value = "6MJ", fuel_categories = { food },
    },
  })
  local food_ingredients = { { type = "item", name = "bioflux", amount = 1 } }
  for _, i in pairs(def.food_ingredients) do food_ingredients[#food_ingredients + 1] = i end

  local unlocks = {
    { type = "unlock-recipe", recipe = food },
    { type = "unlock-recipe", recipe = rocket },
  }

  for _, entry in pairs(def.nests) do
    local captive_name = "sap-captive-" .. entry.nest
    local captive = util.table.deepcopy(data.raw["assembling-machine"]["captive-biter-spawner"])
    captive.name = captive_name
    captive.icon = nil
    captive.icons = { { icon = "__space-age__/graphics/icons/captive-biter-spawner.png", icon_size = 64, tint = tint } }
    captive.minable = nil
    captive.placeable_by = nil
    captive.fast_replaceable_group = nil
    captive.fixed_recipe = captive_name .. "-harvest"
    captive.energy_source.fuel_categories = { food }
    captive.dying_trigger_effect = {
      type = "create-entity", entity_name = entry.nest, as_enemy = true, ignore_no_enemies_mode = true,
    }
    data:extend({
      captive,
      {
        type = "recipe", name = captive_name .. "-harvest", categories = { "captive-spawner-process" },
        icons = data.raw.item[entry.product].icons or { { icon = data.raw.item[entry.product].icon, icon_size = 64 } },
        hidden = true, enabled = true, energy_required = 15,
        ingredients = {},
        results = { { type = "item", name = entry.product, amount = 1 } },
      },
    })
    registry.data[entry.nest] = { captive = captive_name, planet = planet }
    nest_names[#nest_names + 1] = entry.nest
  end

  local projectile = util.table.deepcopy(data.raw.projectile["capture-robot-rocket"])
  projectile.name = rocket
  projectile.action = {
    type = "direct",
    action_delivery = {
      type = "instant",
      target_effects = {
        { type = "script", effect_id = "sap-capture" },
        { type = "create-entity", entity_name = "capture-robot-explosion" },
      },
    },
  }
  local ammo = util.table.deepcopy(data.raw.ammo["capture-robot-rocket"])
  ammo.name = rocket
  ammo.icon = nil
  ammo.icons = { { icon = "__space-age__/graphics/icons/capture-bot.png", icon_size = 64, tint = tint } }
  ammo.ammo_type.action.action_delivery.projectile = rocket
  ammo.ammo_type.target_filter = nest_names
  ammo.order = "d[rocket-launcher]-d[capture]-z[sap]-" .. planet

  local rocket_ingredients = { { type = "item", name = "capture-robot-rocket", amount = 1 } }
  for _, i in pairs(def.rocket_ingredients) do rocket_ingredients[#rocket_ingredients + 1] = i end

  data:extend({
    projectile, ammo,
    {
      type = "recipe", name = food, enabled = false, energy_required = 4, categories = { "organic" },
      ingredients = food_ingredients, results = { { type = "item", name = food, amount = 2 } },
    },
    {
      type = "recipe", name = rocket, enabled = false, energy_required = 10,
      ingredients = rocket_ingredients, results = { { type = "item", name = rocket, amount = 1 } },
    },
    {
      type = "technology",
      name = "sap-capture-recalibration-" .. planet,
      localised_name = { "sap-capture.tech-name", { "space-location-name." .. planet } },
      localised_description = { "sap-capture.tech-description", { "space-location-name." .. planet } },
      icons = { { icon = "__space-age__/graphics/technology/captive-biter-spawner.png", icon_size = 256, tint = tint } },
      effects = unlocks,
      prerequisites = { "captivity", def.discovery_tech },
      unit = { count = 500, time = 60, ingredients = def.science },
    },
  })
end

return api
