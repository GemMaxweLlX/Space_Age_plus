-- Подземелья древней расы: одно на планету, своя генерация для каждой планеты.
--
-- Вход ставится рядом с каждым хранилищем древней расы; все входы планеты ведут в одно
-- подземелье, выход возвращает туда, откуда игрок вошёл. Подземелье — отдельная поверхность:
-- залы, соединённые коридорами (стиль зависит от планеты), двери с замками двух видов
-- (энергетический — сжечь топливо; ключевой — ключ с Хранителя в предыдущем зале), стражи,
-- тайники с инопланетными картами (качество растёт с глубиной) и древнее ядро в последнем зале.

local diary = require("scripts.diary")

local dungeon = {}

--- Вызывается, когда древнее ядро забрано из последнего зала: (force, planet). Задаёт control.lua.
dungeon.on_core_taken = nil

dungeon.TICK_INTERVAL = 60

local ENTRANCE, EXIT = "sap-dungeon-entrance", "sap-dungeon-exit"
local DOOR, POWER_LOCK, KEY_LOCK = "sap-ancient-door", "sap-ancient-power-lock", "sap-ancient-key-lock"
local CACHE, KEEPER, KEY, TOKEN = "sap-ancient-cache", "sap-ancient-keeper", "sap-ancient-key", "sap-ancient-lock-token"
local FRAME = "sap_dungeon_frame"
local QUALITY = { "normal", "uncommon", "rare", "epic", "legendary" }
local CORRIDOR = 1 -- полуширина коридора (ширина 3)

-- Оформление и стиль генерации по планетам.
local THEMES = {
  nauvis = { style = "grid", floor = "refined-concrete", accent = "hazard-concrete-left",
             guardians = { "medium-biter", "big-spitter", "big-biter" } },
  vulcanus = { style = "chain", floor = "volcanic-smooth-stone", hazard = "lava",
               guardians = { "sap-scorch", "sap-magmar", "medium-biter", "big-biter" } },
  fulgora = { style = "ring", floor = "fulgoran-paving", accent = "fulgoran-machinery",
              guardians = { "sap-sentinel", "sap-disruptor", "medium-biter", "big-biter" } },
  gleba = { style = "flooded", floor = "midland-turquoise-bark", hazard = "water",
            guardians = { "small-strafer-pentapod", "medium-strafer-pentapod" } },
  aquilo = { style = "cave", floor = "snow-flat", accent = "snow-crests",
             guardians = { "sap-frost", "sap-stalagmite", "medium-biter", "big-biter" } },
}
THEMES.solaris = { style = "chain", floor = "volcanic-smooth-stone", hazard = "lava",
                   guardians = { "sap-scorch", "sap-magmar" } }
THEMES.echaris = { style = "ring", floor = "fulgoran-paving", accent = "fulgoran-machinery",
                   guardians = { "sap-sentinel", "sap-disruptor", "sap-stormbringer" } }
THEMES.aquara = { style = "flooded", floor = "midland-turquoise-bark", hazard = "water",
                  guardians = { "sap-ripple", "sap-surf" } }
THEMES.nivar = { style = "cave", floor = "snow-flat", accent = "snow-crests",
                 guardians = { "sap-frost", "sap-stalagmite", "sap-blizzard" } }
THEMES["nivar-caves"] = THEMES.nivar

local function state()
  storage.dungeons = storage.dungeons or { planets = {}, doors = {}, returns = {} }
  return storage.dungeons
end

local function theme_of(planet)
  local t = THEMES[planet] or THEMES.nauvis
  local guardians = {}
  for _, name in pairs(t.guardians) do
    if prototypes.entity[name] then guardians[#guardians + 1] = name end
  end
  if #guardians == 0 then guardians = { "medium-biter" } end
  return t, guardians
end

-- Раскладки --------------------------------------------------------------------------
-- Каждая возвращает залы { x, y, half, round } и рёбра { a, b } (индексы залов); зал 1 — вход.

local function room(rng, x, y, round)
  return { x = x, y = y, half = rng(8, 11), round = round }
end

local function grid_layout(rng)
  local rooms, index, edges = {}, {}, {}
  for gx = 0, 2 do
    for gy = 0, 2 do
      rooms[#rooms + 1] = room(rng, gx * 44, gy * 44)
      index[gx .. "," .. gy] = #rooms
    end
  end
  -- Остовное дерево случайным обходом в глубину от входа.
  local visited, stack = { ["0,0"] = true }, { { 0, 0 } }
  while #stack > 0 do
    local cell = stack[#stack]
    local options = {}
    for _, d in pairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
      local nx, ny = cell[1] + d[1], cell[2] + d[2]
      if nx >= 0 and nx <= 2 and ny >= 0 and ny <= 2 and not visited[nx .. "," .. ny] then
        options[#options + 1] = { nx, ny }
      end
    end
    if #options == 0 then
      table.remove(stack)
    else
      local n = options[rng(1, #options)]
      visited[n[1] .. "," .. n[2]] = true
      edges[#edges + 1] = { index[cell[1] .. "," .. cell[2]], index[n[1] .. "," .. n[2]] }
      stack[#stack + 1] = n
    end
  end
  return rooms, edges
end

local function chain_layout(rng)
  local rooms, edges = {}, {}
  for i = 0, 5 do
    rooms[#rooms + 1] = room(rng, i * 44, rng(-12, 12))
    if i > 0 then edges[#edges + 1] = { i, i + 1 } end
  end
  return rooms, edges
end

local function ring_layout(rng)
  local rooms, edges = {}, {}
  for i = 0, 5 do
    local angle = i / 6 * 2 * math.pi
    rooms[#rooms + 1] = room(rng, math.floor(math.cos(angle) * 64), math.floor(math.sin(angle) * 64))
    if i > 0 then edges[#edges + 1] = { i, i + 1 } end
  end
  rooms[#rooms + 1] = room(rng, 0, 0)
  rooms[#rooms].half = 13
  edges[#edges + 1] = { 6, 7 } -- центр — самый глубокий зал, вход в него с дальнего конца кольца
  return rooms, edges
end

local function cave_layout(rng)
  local rooms, edges = { room(rng, 0, 0, true) }, {}
  local tries = 0
  while #rooms < 7 and tries < 200 do
    tries = tries + 1
    local from = rng(1, #rooms)
    local angle = rng() * 2 * math.pi
    local x = rooms[from].x + math.floor(math.cos(angle) * 42)
    local y = rooms[from].y + math.floor(math.sin(angle) * 42)
    local free = true
    for _, r in pairs(rooms) do
      if (r.x - x) ^ 2 + (r.y - y) ^ 2 < 36 ^ 2 then free = false break end
    end
    if free then
      rooms[#rooms + 1] = room(rng, x, y, true)
      edges[#edges + 1] = { from, #rooms }
    end
  end
  return rooms, edges
end

local LAYOUTS = { grid = grid_layout, chain = chain_layout, ring = ring_layout, flooded = grid_layout, cave = cave_layout }

local function depths(rooms, edges)
  local adjacent = {}
  for i = 1, #rooms do adjacent[i] = {} end
  for _, e in pairs(edges) do
    table.insert(adjacent[e[1]], e[2])
    table.insert(adjacent[e[2]], e[1])
  end
  local depth, queue = { [1] = 0 }, { 1 }
  local parent = {}
  while #queue > 0 do
    local current = table.remove(queue, 1)
    for _, n in pairs(adjacent[current]) do
      if depth[n] == nil then
        depth[n] = depth[current] + 1
        parent[n] = current
        queue[#queue + 1] = n
      end
    end
  end
  return depth, parent
end

-- Плитки --------------------------------------------------------------------------------

-- Плитки хранятся по числовому ключу (быстрее строк): ключ = (x + OFFSET) * SPAN + (y + OFFSET).
local OFFSET, SPAN = 4096, 8192
local function carve(tiles, x, y, name) tiles[(x + OFFSET) * SPAN + y + OFFSET] = name end

local function in_room(r, x, y)
  if r.round then return (x - r.x) ^ 2 + (y - r.y) ^ 2 <= r.half ^ 2 end
  return math.abs(x - r.x) <= r.half and math.abs(y - r.y) <= r.half
end

local function paint_room(tiles, r, theme, rng, style)
  for x = r.x - r.half, r.x + r.half do
    for y = r.y - r.half, r.y + r.half do
      if in_room(r, x, y) then
        local edge = not in_room(r, x + 1, y) or not in_room(r, x - 1, y) or not in_room(r, x, y + 1)
          or not in_room(r, x, y - 1)
        local name = theme.floor
        if edge and theme.accent then name = theme.accent end
        if style == "flooded" and math.max(math.abs(x - r.x), math.abs(y - r.y)) > r.half - 3 then name = theme.hazard end
        carve(tiles, x, y, name)
      end
    end
  end
  -- Лавовое озеро в углу зала (стиль «цепочка»).
  if style == "chain" and theme.hazard then
    local cx = r.x + (rng() < 0.5 and -1 or 1) * (r.half - 4)
    local cy = r.y + (rng() < 0.5 and -1 or 1) * (r.half - 4)
    for x = cx - 2, cx + 2 do
      for y = cy - 2, cy + 2 do
        if (x - cx) ^ 2 + (y - cy) ^ 2 <= 5 then carve(tiles, x, y, theme.hazard) end
      end
    end
  end
end

local function strip(tiles, x0, y0, x1, y1, theme)
  for x = math.min(x0, x1), math.max(x0, x1) do
    for y = math.min(y0, y1), math.max(y0, y1) do carve(tiles, x, y, theme.floor) end
  end
end

--- Коридор от родительского зала к дочернему. Последний отрезок входит в дочерний зал по прямой;
--- на нём, сразу за стеной зала, стоит дверь. Возвращает позицию двери.
local function paint_corridor(tiles, parent, child, theme)
  local dx, dy = child.x - parent.x, child.y - parent.y
  if math.abs(dy) > child.half + 3 then
    -- Вход сверху/снизу: по горизонтали от родителя, затем по вертикали в зал.
    strip(tiles, parent.x, parent.y - CORRIDOR, child.x, parent.y + CORRIDOR, theme)
    strip(tiles, child.x - CORRIDOR, parent.y, child.x + CORRIDOR, child.y, theme)
    local s = dy > 0 and 1 or -1
    return { x = child.x + 0.5, y = child.y - s * (child.half + 2) + 0.5 }
  end
  -- Вход сбоку: по вертикали внутри родителя, затем по горизонтали в зал.
  strip(tiles, parent.x - CORRIDOR, parent.y, parent.x + CORRIDOR, child.y, theme)
  strip(tiles, parent.x, child.y - CORRIDOR, child.x, child.y + CORRIDOR, theme)
  local s = dx > 0 and 1 or -1
  return { x = child.x - s * (child.half + 2) + 0.5, y = child.y + 0.5 }
end

-- Создание ---------------------------------------------------------------------------------

local function place(surface, name, x, y, force, radius)
  local position = surface.find_non_colliding_position(name, { x, y }, radius or 6, 0.5)
  if not position then return nil end
  local e = surface.create_entity({ name = name, position = position, force = force or "neutral" })
  return e
end

local function fill_cache(cache, depth, final)
  local inventory = cache.get_inventory(defines.inventory.chest)
  local quality = QUALITY[math.min(#QUALITY, depth + (final and 2 or 0))]
  inventory.insert({ name = "sap-data-card-alien", count = final and 2 or 1, quality = quality })
  inventory.insert({ name = "sap-alien-data", count = final and 2 or 1 })
  if final then inventory.insert({ name = "sap-ancient-core", count = 1 }) end
end

local function seed_for(planet)
  local h = 7
  for i = 1, #planet do h = (h * 31 + string.byte(planet, i)) % 2147483647 end
  return (game.default_map_gen_settings.seed + h) % 4294967295
end

--- Создаёт подземелье планеты (если ещё нет). Возвращает его запись.
function dungeon.generate(planet)
  local s = state()
  if s.planets[planet] then return s.planets[planet] end
  local theme, guardians = theme_of(planet)
  local generator = game.create_random_generator(seed_for(planet))
  local rng = function(a, b) if a then return generator(a, b) end return generator() end

  local rooms, edges = LAYOUTS[theme.style](rng)
  local depth, parent = depths(rooms, edges)

  -- Без автоплейса: всё вне вырезанных залов — пустота (out-of-map), без врагов и ресурсов.
  local none = { treat_missing_as_default = false, settings = {} }
  local surface = game.create_surface("sap-dungeon-" .. planet, {
    default_enable_all_autoplace_controls = false,
    autoplace_settings = { tile = none, entity = none, decorative = none },
    no_enemies_mode = false, peaceful_mode = false,
  })
  surface.freeze_daytime = true
  surface.daytime = 0.35
  local minx, miny, maxx, maxy = 0, 0, 0, 0
  for _, r in pairs(rooms) do
    minx, maxx = math.min(minx, r.x - r.half), math.max(maxx, r.x + r.half)
    miny, maxy = math.min(miny, r.y - r.half), math.max(maxy, r.y + r.half)
  end
  -- Генерируем чанки, накрывающие подземелье с запасом, и заливаем их целиком: вне залов пустота.
  local cx0, cy0 = math.floor((minx - 20) / 32), math.floor((miny - 20) / 32)
  local cx1, cy1 = math.floor((maxx + 20) / 32), math.floor((maxy + 20) / 32)
  for cx = cx0, cx1 do
    for cy = cy0, cy1 do surface.request_to_generate_chunks({ cx * 32 + 16, cy * 32 + 16 }, 0) end
  end
  surface.force_generate_chunk_requests()

  local tiles = {}
  for _, r in pairs(rooms) do paint_room(tiles, r, theme, rng, theme.style) end
  local doors_at = {}
  for i = 2, #rooms do
    if parent[i] then doors_at[i] = paint_corridor(tiles, rooms[parent[i]], rooms[i], theme) end
  end
  local list, n = {}, 0
  for x = cx0 * 32, cx1 * 32 + 31 do
    local base = (x + OFFSET) * SPAN + OFFSET
    for y = cy0 * 32, cy1 * 32 + 31 do
      n = n + 1
      list[n] = { name = tiles[base + y] or "out-of-map", position = { x, y } }
    end
  end
  surface.set_tiles(list, false, false, false, false)

  local record = { surface = surface.name, start = { x = rooms[1].x, y = rooms[1].y + 3 }, rooms = #rooms,
                   chunks = { cx0, cy0, cx1, cy1 } }
  s.planets[planet] = record

  local exit = place(surface, EXIT, rooms[1].x, rooms[1].y - 3)
  if exit then exit.destructible = false end

  local deepest, deepest_room = 0, 1
  for i, r in pairs(rooms) do
    if depth[i] > deepest then deepest, deepest_room = depth[i], i end
    if i > 1 then
      local d = depth[i]
      for _ = 1, d + 1 do
        place(surface, guardians[rng(1, #guardians)], r.x + rng(-r.half + 3, r.half - 3), r.y + rng(-r.half + 3, r.half - 3),
              "enemy", 8)
      end
      local cache = place(surface, CACHE, r.x, r.y)
      if cache then
        cache.destructible = false
        fill_cache(cache, d, false)
      end
    end
  end
  -- Древнее ядро и лучшие карты — в самом глубоком зале, его охраняют древние стражи.
  local final = rooms[deepest_room]
  local final_cache = place(surface, CACHE, final.x + 3, final.y + 3)
  if final_cache then
    final_cache.destructible = false
    fill_cache(final_cache, deepest, true)
    record.final_cache = final_cache
  end
  for _ = 1, 2 do place(surface, "sap-alien-guardian", final.x + rng(-6, 6), final.y + rng(-6, 6), "enemy", 8) end

  -- Двери: на входе в каждый зал глубже второго; замок — в предыдущем зале.
  for i, r in pairs(rooms) do
    if depth[i] >= 2 then
      local p = rooms[parent[i]]
      local pos = doors_at[i]
      local door = surface.create_entity({ name = DOOR, position = pos, force = "neutral" })
      if door then
        door.destructible = false
        local kind = depth[i] % 2 == 0 and "power" or "key"
        -- Замок — в предыдущем зале, ближе к двери.
        local dx, dy = r.x - p.x, r.y - p.y
        local len = math.max(1, math.sqrt(dx * dx + dy * dy))
        local lock = place(surface, kind == "power" and POWER_LOCK or KEY_LOCK,
                           p.x + dx / len * (p.half - 4), p.y + dy / len * (p.half - 4), "neutral", 8)
        if lock then
          lock.destructible = false
          lock.minable_flag = false
        end
        if kind == "key" then
          place(surface, KEEPER, p.x + rng(-4, 4), p.y + rng(-4, 4), "enemy", 8)
        end
        s.doors[#s.doors + 1] = { door = door, lock = lock, kind = kind, planet = planet }
      end
    end
  end
  record.deepest = deepest
  record.doors = 0
  for _, d in pairs(s.doors) do if d.planet == planet then record.doors = record.doors + 1 end end
  return record
end

--- Чанки подземелья за пределами заготовленной области — пустота.
function dungeon.on_chunk_generated(event)
  local surface = event.surface
  if string.sub(surface.name, 1, 12) ~= "sap-dungeon-" then return end
  local record = state().planets[string.sub(surface.name, 13)]
  local p = event.position
  if record and record.chunks then
    local c = record.chunks
    if p.x >= c[1] and p.x <= c[3] and p.y >= c[2] and p.y <= c[4] then return end
  end
  local list, n = {}, 0
  for x = p.x * 32, p.x * 32 + 31 do
    for y = p.y * 32, p.y * 32 + 31 do
      n = n + 1
      list[n] = { name = "out-of-map", position = { x, y } }
    end
  end
  surface.set_tiles(list, false, false, false, false)
end

-- Двери ---------------------------------------------------------------------------------

local function check_cores(s)
  for planet, record in pairs(s.planets) do
    local cache = record.final_cache
    if cache and not record.core_taken
        and (not cache.valid or cache.get_inventory(defines.inventory.chest).get_item_count("sap-ancient-core") == 0) then
      record.core_taken = true
      local forces = {}
      local surface = game.get_surface(record.surface)
      for _, player in pairs(game.connected_players) do
        if surface and player.surface == surface then forces[player.force.name] = player.force end
      end
      if next(forces) == nil then forces.player = game.forces.player end
      for _, force in pairs(forces) do
        if dungeon.on_core_taken then dungeon.on_core_taken(force, planet) end
      end
    end
  end
end

function dungeon.on_tick()
  local s = state()
  check_cores(s)
  for i = #s.doors, 1, -1 do
    local d = s.doors[i]
    local open = false
    if not (d.door and d.door.valid) then
      table.remove(s.doors, i)
    elseif d.lock and d.lock.valid then
      if d.kind == "power" then
        open = d.lock.get_output_inventory().get_item_count(TOKEN) > 0
      else
        local inventory = d.lock.get_inventory(defines.inventory.chest)
        if inventory.get_item_count(KEY) > 0 then
          inventory.remove({ name = KEY, count = 1 })
          open = true
        end
      end
      if open then
        d.door.destroy()
        d.lock.disabled_by_script = true
        table.remove(s.doors, i)
        game.forces.player.print({ "sap-dungeon.door-opened" })
      end
    end
  end
end

-- Вход и выход ----------------------------------------------------------------------------

function dungeon.place_entrance(surface, near)
  local position = surface.find_non_colliding_position(ENTRANCE, near, 16, 1)
  if not position then return nil end
  local entrance = surface.create_entity({ name = ENTRANCE, position = position, force = "neutral" })
  if entrance then entrance.destructible = false end
  return entrance
end

local function planet_of(surface)
  return surface.planet and surface.planet.name or surface.name
end

function dungeon.enter(player, entrance)
  if state().sealed then
    player.print({ "sap-dungeon.sealed" })
    return
  end
  local planet = planet_of(entrance.surface)
  local record = dungeon.generate(planet)
  state().returns[player.index] = { surface = entrance.surface.name, position = entrance.position }
  local surface = game.get_surface(record.surface)
  local position = surface.find_non_colliding_position("character", record.start, 10, 0.5)
  player.opened = nil
  player.teleport(position, surface)
  player.print({ "sap-dungeon.entered" })
  diary.add(player.force, "story-dungeon")
end

function dungeon.leave(player)
  local back = state().returns[player.index]
  local surface = back and game.get_surface(back.surface) or game.surfaces.nauvis
  local near = back and back.position or { 0, 0 }
  local position = surface.find_non_colliding_position("character", near, 16, 0.5)
  player.opened = nil
  player.teleport(position or near, surface)
end

function dungeon.on_gui_opened(event)
  local entity = event.entity
  if not (entity and entity.valid and (entity.name == ENTRANCE or entity.name == EXIT)) then return end
  local player = game.get_player(event.player_index)
  if not player then return end
  local frame = player.gui.relative[FRAME]
  if not frame then
    frame = player.gui.relative.add({
      type = "frame", name = FRAME, caption = { "sap-dungeon.title" },
      anchor = { gui = defines.relative_gui_type.container_gui, position = defines.relative_gui_position.right,
                 names = { ENTRANCE, EXIT } },
    })
    frame.add({ type = "button", name = "go", tags = { sap_action = "dungeon" } })
  end
  frame.go.caption = entity.name == ENTRANCE and { "sap-dungeon.enter" } or { "sap-dungeon.leave" }
end

function dungeon.on_gui_click(event)
  local element = event.element
  if not (element and element.valid and element.tags and element.tags.sap_action == "dungeon") then return end
  local player = game.get_player(event.player_index)
  local entity = player and player.opened
  if not (entity and entity.object_name == "LuaEntity" and entity.valid) then return end
  if entity.name == ENTRANCE then dungeon.enter(player, entity) elseif entity.name == EXIT then dungeon.leave(player) end
end

--- Концовка «Печать»: игроки поднимаются на поверхность, подземелья обрушиваются навсегда.
function dungeon.seal()
  local s = state()
  s.sealed = true
  for _, record in pairs(s.planets) do
    local surface = game.get_surface(record.surface)
    if surface then
      for _, player in pairs(game.players) do
        if player.surface == surface then dungeon.leave(player) end
      end
      game.delete_surface(surface)
    end
  end
  s.planets = {}
  s.doors = {}
end

--- Для старых сохранений: у хранилищ без входа ставится вход.
function dungeon.add_missing_entrances()
  for _, surface in pairs(game.surfaces) do
    for _, vault in pairs(surface.find_entities_filtered({ name = "sap-alien-vault" })) do
      if surface.count_entities_filtered({ name = ENTRANCE, position = vault.position, radius = 20, limit = 1 }) == 0 then
        dungeon.place_entrance(surface, { vault.position.x + 6, vault.position.y })
      end
    end
  end
end

function dungeon.on_init()
  state()
end

return dungeon
