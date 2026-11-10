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

api.CONDENSING = "sap-condensing-generators"

--- Генератор возвращает часть пара водой в соседнюю трубу или бак (docs: паровая турбина
--- Mk2, мега-турбина — «90% воды»). Обработка — scripts/condensing.lua.
--- @param generator string имя прототипа generator
--- @param ratio number доля пара, которая возвращается водой (0.9)
function api.register_condensing_generator(generator, ratio)
  local proto = data.raw["mod-data"] and data.raw["mod-data"][api.CONDENSING]
  if not proto then
    data:extend({ { type = "mod-data", name = api.CONDENSING, data = {} } })
    proto = data.raw["mod-data"][api.CONDENSING]
  end
  proto.data[generator] = ratio
end

local function util_copy(t) return require("util").table.deepcopy(t) end

local ENTITY_TYPES = {
  "assembling-machine", "furnace", "mining-drill", "radar", "roboport", "storage-tank", "pump", "offshore-pump",
  "generator", "pipe", "pipe-to-ground", "heat-pipe", "transport-belt", "underground-belt", "splitter", "wall",
  "gate", "electric-turret", "ammo-turret", "fluid-turret", "electric-pole", "reactor", "burner-generator",
  "lamp", "boiler", "accumulator", "solar-panel", "lab", "agricultural-tower", "inserter", "container",
  "logistic-container", "beacon", "asteroid-collector", "lightning-attractor",
}
local ITEM_TYPES = { "item", "item-with-entity-data", "armor", "gun", "ammo", "capsule", "module", "rail-planner" }

local function find_entity(name)
  for _, t in pairs(ENTITY_TYPES) do
    if data.raw[t] and data.raw[t][name] then return data.raw[t][name] end
  end
  return nil
end

local function find_item(name)
  for _, t in pairs(ITEM_TYPES) do
    if data.raw[t] and data.raw[t][name] then return data.raw[t][name] end
  end
  return nil
end

local function tinted_icons(proto, tint)
  if proto.icons then
    local icons = util_copy(proto.icons)
    for _, layer in pairs(icons) do layer.tint = tint end
    return icons
  end
  return { { icon = proto.icon, icon_size = proto.icon_size or 64, tint = tint } }
end


--- Улучшенная копия ванильной постройки (или брони/оружия) с предметом, рецептом и
--- технологией. Технология создаётся при первом упоминании и дополняется при следующих.
--- @param def table {
---   base = "electric-furnace", name = "sap-electric-furnace-mk2", tint = {...},
---   change = function(entity, item) end,  -- правит копию
---   ingredients = { {"electric-furnace", 1}, {"sap-mechanite-core", 1} }, time = 10,
---   tech = { name = "...", icon = "...", count = 500, prerequisites = {...}, science = {...} } }
function api.upgrade(def)
  local tint = def.tint or { r = 0.8, g = 0.8, b = 1, a = 1 }
  local base_entity = find_entity(def.base)
  local base_item = find_item(def.base)
  assert(base_item, "Space Age+: no item " .. def.base)
  local item = util_copy(base_item)
  item.name = def.name
  item.icons = tinted_icons(base_item, tint)
  item.icon = nil
  item.order = (base_item.order or "z") .. "-z[sap]"
  local entity
  if base_entity and base_item.place_result then
    entity = util_copy(base_entity)
    entity.name = def.name
    entity.icons = tinted_icons(base_entity, tint)
    entity.icon = nil
    if entity.minable then
      entity.minable.result = def.name
      entity.minable.results = nil
    end
    entity.next_upgrade = nil
    entity.placeable_by = nil
    item.place_result = def.name
  end
  if def.change then def.change(entity, item) end
  local ingredients = {}
  for _, i in pairs(def.ingredients) do
    ingredients[#ingredients + 1] = { type = "item", name = i[1], amount = i[2] }
  end
  data:extend({
    item,
    {
      type = "recipe", name = def.name, enabled = false, energy_required = def.time or 10,
      ingredients = ingredients, results = { { type = "item", name = def.name, amount = def.result_count or 1 } },
    },
  })
  if entity then data:extend({ entity }) end

  local tech = data.raw.technology[def.tech.name]
  if not tech then
    data:extend({
      {
        type = "technology",
        name = def.tech.name,
        icons = def.tech.icon and { { icon = def.tech.icon, icon_size = def.tech.icon_size or 64, tint = tint } }
          or tinted_icons(base_item, tint),
        effects = {},
        prerequisites = def.tech.prerequisites,
        unit = { count = def.tech.count or 500, time = 60, ingredients = def.tech.science },
      },
    })
    tech = data.raw.technology[def.tech.name]
  end
  table.insert(tech.effects, { type = "unlock-recipe", recipe = def.name })
  return entity, item
end

api.NO_DELIVERY = "sap-no-delivery-planets"

--- Хардкор «Без доставки с платформы»: если настройка включена, грузовые капсулы с платформ
--- на эту планету возвращаются обратно в хаб (игрока капсула везёт как обычно).
--- @param planet string имя поверхности планеты
--- @param setting string|nil имя startup-настройки (bool); nil — запрет действует всегда
--- @param unless_tech string|nil технология, после которой доставка разрешена
function api.register_no_delivery(planet, setting, unless_tech)
  local proto = data.raw["mod-data"] and data.raw["mod-data"][api.NO_DELIVERY]
  if not proto then
    data:extend({ { type = "mod-data", name = api.NO_DELIVERY, data = {} } })
    proto = data.raw["mod-data"][api.NO_DELIVERY]
  end
  proto.data[planet] = { setting = setting, unless_tech = unless_tech }
end

--- Подсказка в окне «Советы и подсказки» (раздел Space Age+).
--- @param name string имя подсказки (текст: [tips-and-tricks-item-name]/[...-description])
--- @param order string порядок в разделе
--- @param tag string rich text иконки, например "[planet=solaris]"
--- @param trigger table|nil когда подсказка откроется (nil — сразу)
function api.tip(name, order, tag, trigger)
  data:extend({
    {
      type = "tips-and-tricks-item", name = name, category = "space-age-plus", order = order, indent = 1,
      tag = tag, trigger = trigger, starting_status = trigger == nil and "unlocked" or nil,
    },
  })
end

api.TECH_OVERRIDES = "sap-tech-overrides"

local function tech_overrides()
  local proto = data.raw["mod-data"] and data.raw["mod-data"][api.TECH_OVERRIDES]
  if not proto then
    data:extend({ { type = "mod-data", name = api.TECH_OVERRIDES, data = { visible = {}, category = {} } } })
    proto = data.raw["mod-data"][api.TECH_OVERRIDES]
  end
  return proto.data
end

--- Скрытое дерево: эта технология никогда не скрывается (например, сюжетная технология мода).
function api.keep_visible(tech)
  tech_overrides().visible[tech] = true
end

--- Скрытое дерево: категория карт данных для технологии (вместо угадывания по имени).
--- Категории: automation, logistics, mining, production, energy, military, robotics, trains,
--- chemistry, space, biotech, cryotech, sap-energy, sap-military, alien.
function api.set_tech_category(tech, category)
  tech_overrides().category[tech] = category
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
