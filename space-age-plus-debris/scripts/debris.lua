-- Космический мусор.
--
-- 1. Предметы, выброшенные с платформы (LuaSpacePlatform::ejected_items), записываются в
--    ячейку: маршрут + отрезок 10% (или орбита планеты, если платформа стоит у планеты).
-- 2. Когда платформа находится в ячейке с мусором, к ней прилетают куски обломков. Вид
--    куска зависит от того, что выбросили: металл, электроника.
-- 3. Мусор общий для всех: кусок, который прилетел к одной платформе, из ячейки убирается.
-- 4. После 20 запусков ракет с планеты каждая следующая ракета оставляет ракетный обломок
--    на орбите. Обломки прилетают к платформам на орбите и иногда падают на планету.

local debris = {}

local function diary_add(force, key)
  if force and force.valid and remote.interfaces["sap-diary"] then remote.call("sap-diary", "add", force.name, key) end
end

debris.TICK_INTERVAL = 60
debris.FALL_INTERVAL = 5 * 60 * 60

local SEGMENTS = 10
local SPAWN_CHANCE = 0.25 -- шанс за проверку, что к платформе прилетит кусок
local CELL_LIMIT = 5000 -- больше мусора в одной ячейке не копится
local FREE_LAUNCHES = 20
local FALL_CHANCE_PER_DEBRIS = 0.02
local FALL_CHANCE_MAX = 0.5
local FALL_RADIUS = 4
local FALL_DAMAGE = 150

-- Особый мусор у планет SA+: половина кусков в их окрестностях — «местного» вида.
local FLAVOR = { echaris = "electrified", solaris = "heated", aquara = "biofilm", nivar = "frozen" }
local FLAVOR_SHARE = 0.5

local function flavor_of(key)
  local orbit = string.match(key, "^orbit:(.+)$")
  if orbit then return FLAVOR[orbit] end
  local route = string.match(key, "^route:(.+)$")
  local connection = route and prototypes.space_connection[route]
  if connection then
    return FLAVOR[connection.from.name] or FLAVOR[connection.to.name]
  end
  return nil
end

local ELECTRONIC_PATTERNS = {
  "circuit", "processing%-unit", "module", "cable", "battery", "capacitor",
  "superconductor", "radar", "roboport", "robot", "combinator",
}

local function state()
  storage.debris = storage.debris or {}
  local s = storage.debris
  s.cells = s.cells or {}
  s.last_ejected = s.last_ejected or {}
  s.launches = s.launches or {}
  return s
end

local function cell(key, segment)
  local cells = state().cells
  cells[key] = cells[key] or {}
  local c = cells[key][segment]
  if not c then
    c = { total = 0, metal = 0, electronic = 0, rocket = 0 }
    cells[key][segment] = c
  end
  return c
end

local function location_of(platform)
  local connection = platform.space_connection
  if connection then
    local segment = math.min(SEGMENTS - 1, math.max(0, math.floor(platform.distance * SEGMENTS)))
    return "route:" .. connection.name, segment
  end
  local location = platform.space_location
  if location then
    return "orbit:" .. location.name, 0
  end
  return nil
end

local function kind_of(item_name)
  for _, pattern in pairs(ELECTRONIC_PATTERNS) do
    if string.find(item_name, pattern) then return "electronic" end
  end
  return "metal"
end

local function add(c, kind, amount)
  if c.total >= CELL_LIMIT then return end
  c[kind] = c[kind] + amount
  c.total = c.total + amount
end

-- Выброшенные предметы -----------------------------------------------------------

local function record_ejected(platform, key, segment)
  local s = state()
  local last = s.last_ejected[platform.index] or 0
  local newest = last
  local c = cell(key, segment)
  for _, ejected in pairs(platform.ejected_items) do
    if ejected.creation_tick > last then
      local item = ejected.item
      local name = type(item) == "table" and (item.name and (item.name.name or item.name)) or item
      if type(name) == "string" then
        add(c, kind_of(name), 1)
        if string.sub(name, 1, 14) == "sap-data-card-" then diary_add(platform.force, "jettisoned-card") end
      end
      if ejected.creation_tick > newest then newest = ejected.creation_tick end
    end
  end
  s.last_ejected[platform.index] = newest
end

-- Прилёт обломков ----------------------------------------------------------------

local function pick_kind(c)
  local roll = math.random() * c.total
  for _, kind in pairs({ "rocket", "electronic", "metal" }) do
    if roll < c[kind] then return kind end
    roll = roll - c[kind]
  end
  return "metal"
end

local function spawn_chunk(platform, c, key)
  if c.total <= 0 or math.random() >= SPAWN_CHANCE then return end
  local hub = platform.hub
  if not (hub and hub.valid) then return end
  local kind = pick_kind(c)
  if c[kind] <= 0 then return end
  c[kind] = c[kind] - 1
  c.total = c.total - 1
  local origin = hub.position
  local flavor = flavor_of(key)
  if flavor and math.random() < FLAVOR_SHARE then kind = flavor end
  platform.create_asteroid_chunks({
    {
      name = "sap-debris-" .. kind,
      position = { origin.x + math.random(-30, 30), origin.y - 60 },
      movement = { 0, 0.05 },
    },
  })
end

function debris.on_tick()
  for _, force in pairs(game.forces) do
    for _, platform in pairs(force.platforms) do
      if platform.valid and platform.hub and platform.hub.valid then
        local key, segment = location_of(platform)
        if key then
          record_ejected(platform, key, segment)
          spawn_chunk(platform, cell(key, segment), key)
        end
      end
    end
  end
end

-- Ракетные обломки --------------------------------------------------------------

function debris.on_rocket_launched(event)
  local silo = event.rocket_silo
  if not (silo and silo.valid) then return end
  local planet = silo.surface.planet
  if not planet then return end
  local s = state()
  s.launches[planet.name] = (s.launches[planet.name] or 0) + 1
  if s.launches[planet.name] > FREE_LAUNCHES then
    add(cell("orbit:" .. planet.name, 0), "rocket", 1)
  end
end

local function fall_on(surface, c)
  local chunk = surface.get_random_chunk()
  if not chunk then return end
  local position = { x = chunk.x * 32 + math.random(0, 31), y = chunk.y * 32 + math.random(0, 31) }
  c.rocket = c.rocket - 1
  c.total = c.total - 1
  surface.create_entity({ name = "big-explosion", position = position })
  for _, entity in pairs(surface.find_entities_filtered({ position = position, radius = FALL_RADIUS })) do
    if entity.valid and entity.is_entity_with_health and entity.health then
      entity.damage(FALL_DAMAGE, "neutral", "physical")
    end
  end
  local wreck_position = surface.find_non_colliding_position("sap-fallen-debris", position, 8, 0.5)
  if wreck_position then
    surface.create_entity({ name = "sap-fallen-debris", position = wreck_position, force = "neutral" })
  end
  local gps = string.format("[gps=%d,%d,%s]", position.x, position.y, surface.name)
  game.print({ "sap-debris.fallen", { "space-location-name." .. surface.planet.name }, gps })
end

function debris.on_fall_tick()
  for key, segments in pairs(state().cells) do
    local planet_name = string.match(key, "^orbit:(.+)$")
    local c = segments[0]
    if planet_name and c and c.rocket > 0 then
      local surface = game.get_surface(planet_name)
      local chance = math.min(FALL_CHANCE_MAX, c.rocket * FALL_CHANCE_PER_DEBRIS)
      if surface and surface.planet and math.random() < chance then
        fall_on(surface, c)
      end
    end
  end
end

function debris.on_init()
  state()
end

function debris.on_configuration_changed()
  state()
end

return debris
