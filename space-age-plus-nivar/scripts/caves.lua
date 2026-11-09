-- Пещеры Nivar и лифт (docs: Планеты → Nivar → Пещеры).
--
-- Пещеры — отдельная поверхность скрытой планеты nivar-caves, всегда тёмная.
-- Лифт ставится на поверхности Nivar (или в пещерах): на другом уровне в той же точке
-- появляется его пара. У пары общий склад (linked-container с общим link_id), а в окне
-- лифта есть кнопка спуска/подъёма для игрока. Разобрал один — исчезает и второй.

local caves = {}

local SURFACE = "nivar"
local CAVES = "nivar-caves"
local ELEVATOR = "sap-nivar-elevator"
local FRAME = "sap_nivar_elevator"

local function state()
  storage.nivar_caves = storage.nivar_caves or { next_link = 1, pairs = {} }
  return storage.nivar_caves
end

local function setup_darkness(surface)
  surface.freeze_daytime = true
  surface.daytime = 0.5
end

local function get_caves()
  local surface = game.get_surface(CAVES)
  if not surface then
    surface = game.planets[CAVES].create_surface()
    setup_darkness(surface)
  end
  return surface
end

local function other_surface(surface)
  if surface.name == SURFACE then return get_caves() end
  if surface.name == CAVES then return game.get_surface(SURFACE) or game.planets[SURFACE].create_surface() end
  return nil
end

function caves.on_built(event)
  local entity = event.entity
  if not (entity and entity.valid and entity.name == ELEVATOR) then return end
  local s = state()
  if s.pairs[entity.unit_number] then return end -- это пара, созданная скриптом
  local target = other_surface(entity.surface)
  if not target then
    entity.force.print({ "sap-nivar.wrong-surface" })
    return
  end
  local position = entity.position
  target.request_to_generate_chunks(position, 1)
  target.force_generate_chunk_requests()
  -- Расчищаем место под пару (лёд и камни пещеры уступают лифту).
  for _, blocker in pairs(target.find_entities_filtered({ area = {
    { position.x - 1.5, position.y - 1.5 }, { position.x + 1.5, position.y + 1.5 } } })) do
    if blocker.valid and blocker.type ~= "character" and blocker.name ~= ELEVATOR then blocker.destroy() end
  end
  local partner = target.create_entity({ name = ELEVATOR, position = position, force = entity.force })
  if not partner then
    game.print({ "sap-nivar.no-room" })
    return
  end
  local link = s.next_link
  s.next_link = link + 1
  entity.link_id = link
  partner.link_id = link
  s.pairs[entity.unit_number] = partner
  s.pairs[partner.unit_number] = entity
end

function caves.on_removed(event)
  local entity = event.entity
  if not (entity and entity.valid and entity.name == ELEVATOR) then return end
  local s = state()
  local partner = s.pairs[entity.unit_number]
  s.pairs[entity.unit_number] = nil
  if partner and partner.valid then
    s.pairs[partner.unit_number] = nil
    partner.destroy()
  end
end

-- Кнопка спуска/подъёма ------------------------------------------------------------

local function ensure_gui(player)
  if player.gui.relative[FRAME] then return player.gui.relative[FRAME] end
  local frame = player.gui.relative.add({
    type = "frame", name = FRAME, caption = { "sap-nivar.elevator-title" },
    anchor = { gui = defines.relative_gui_type.linked_container_gui,
               position = defines.relative_gui_position.right, name = ELEVATOR },
  })
  frame.add({ type = "button", name = "go", tags = { sap_action = "elevator" } })
  return frame
end

function caves.on_gui_opened(event)
  local entity = event.entity
  if not (entity and entity.valid and entity.name == ELEVATOR) then return end
  local player = game.get_player(event.player_index)
  if not player then return end
  local frame = ensure_gui(player)
  frame.go.caption = entity.surface.name == CAVES and { "sap-nivar.go-up" } or { "sap-nivar.go-down" }
end

function caves.travel(player, entity)
  local partner = state().pairs[entity.unit_number]
  if not (partner and partner.valid) then
    player.print({ "sap-nivar.no-partner" })
    return false
  end
  local target = partner.surface
  local position = target.find_non_colliding_position("character", partner.position, 8, 0.5)
  if not position then return false end
  player.opened = nil
  player.teleport(position, target)
  return true
end

function caves.on_gui_click(event)
  local element = event.element
  if not (element and element.valid and element.tags and element.tags.sap_action == "elevator") then return end
  local player = game.get_player(event.player_index)
  local entity = player and player.opened
  if entity and entity.object_name == "LuaEntity" and entity.valid and entity.name == ELEVATOR then
    caves.travel(player, entity)
  end
end

function caves.on_surface_created(event)
  local surface = game.get_surface(event.surface_index)
  if surface and surface.name == CAVES then setup_darkness(surface) end
end

function caves.partner_of(entity)
  return state().pairs[entity.unit_number]
end

-- Пещерная броня: +30% к скорости бега в пещерах.
caves.ARMOR_TICK_INTERVAL = 60
local CAVE_ARMOR, CAVE_SPEED = "sap-cave-armor", 0.3

function caves.on_armor_tick()
  local s = state()
  s.boosted = s.boosted or {}
  for _, surface in pairs({ game.get_surface(CAVES), game.get_surface(SURFACE) }) do
    for _, character in pairs(surface.find_entities_filtered({ type = "character" })) do
      local inventory = character.get_inventory(defines.inventory.character_armor)
      local wearing = inventory and not inventory.is_empty() and inventory[1].valid_for_read
        and inventory[1].name == CAVE_ARMOR
      local id = character.unit_number
      if wearing and surface.name == CAVES and not s.boosted[id] then
        character.character_running_speed_modifier = character.character_running_speed_modifier + CAVE_SPEED
        s.boosted[id] = true
      elseif s.boosted[id] and not (wearing and surface.name == CAVES) then
        character.character_running_speed_modifier = character.character_running_speed_modifier - CAVE_SPEED
        s.boosted[id] = nil
      end
    end
  end
end

function caves.on_init()
  state()
end

return caves
