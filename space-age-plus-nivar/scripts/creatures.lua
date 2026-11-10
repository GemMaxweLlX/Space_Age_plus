-- Существа Nivar: на поверхности — гнёзда Вьюги и Ледяные стражи, в пещерах — гнёзда
-- Инея и Сталагмита и Бездонные в глубине. Расставляются через очередь при генерации.

local creatures = {}

creatures.TICK_INTERVAL = 121

local PLACEMENT = {
  ["nivar"] = {
    safe = 120,
    { kind = "sap-blizzard-nest", chance = 1 / 15 },
    { kind = "sap-ice-guardian", chance = 1 / 60, distance = 350 },
  },
  ["nivar-caves"] = {
    safe = 40,
    { kind = "sap-cave-nest", chance = 1 / 12 },
    { kind = "sap-bottomless", chance = 1 / 50, distance = 300 },
  },
}

local function state()
  storage.nivar_creatures = storage.nivar_creatures or { queue = {} }
  return storage.nivar_creatures
end

function creatures.on_chunk_generated(event)
  local surface = event.surface
  local rules = surface and surface.valid and PLACEMENT[surface.name]
  if not rules then return end
  local area = event.area
  local center = { x = (area.left_top.x + area.right_bottom.x) / 2, y = (area.left_top.y + area.right_bottom.y) / 2 }
  local distance = math.sqrt(center.x ^ 2 + center.y ^ 2)
  if distance < rules.safe then return end
  local queue = state().queue
  for _, rule in ipairs(rules) do
    if distance >= (rule.distance or 0) and math.random() < rule.chance then
      queue[#queue + 1] = { surface = surface.name, kind = rule.kind, position = center }
    end
  end
end

function creatures.on_tick()
  local s = state()
  if #s.queue == 0 then return end
  local queue = s.queue
  s.queue = {}
  for _, item in pairs(queue) do
    local surface = game.get_surface(item.surface)
    local position = surface and surface.find_non_colliding_position(item.kind, item.position, 48, 1)
    if position then surface.create_entity({ name = item.kind, position = position, force = "enemy" }) end
  end
end

function creatures.on_init()
  state()
end

return creatures
