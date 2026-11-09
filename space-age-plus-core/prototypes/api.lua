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
    category = "sap-oxygen-collection",
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

return api
