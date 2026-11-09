-- Система кислорода — runtime (docs: Глобальные механики → Кислород, Вопросы реализации → I13).
--
-- Запас воздуха зависит от брони:
--   нет модульной брони         → запаса нет, вне пузыря здоровье падает сразу;
--   модульная броня             → экстренная система (короткий запас);
--   баллоны в сетке брони       → + запас каждого баллона.
-- Вне пузыря работающего распределителя запас тратится, внутри — заполняется.
-- На планетах без нужды в кислороде (Наувис) и на платформах запас заполняется сразу.
-- Пустой запас → здоровье падает, в чат пишется "Неисправная система жизнеобеспечения".
-- У каждого игрока своя система (G1). Скорость смерти и объём баллона — настройки (G2).

local oxygen = {}

oxygen.TICK_INTERVAL = 60 -- раз в секунду

local DISTRIBUTOR = "sap-oxygen-distributor"
local TANK_EQUIPMENT = "sap-oxygen-tank-equipment"
local GUI_NAME = "sap_oxygen_frame"

-- Запас одного баллона в секундах дыхания.
local TANK_SECONDS = { small = 60, medium = 120, large = 180 }
-- Запас экстренной системы модульной брони, секунд.
local EMERGENCY_SECONDS = 30
-- Доля максимального здоровья, теряемая в секунду без воздуха.
local DAMAGE_FRACTION = { slow = 0.02, medium = 0.05, fast = 0.12 }
local STRICT_MULTIPLIER = 3
-- Сколько секунд дыхания восполняется за секунду внутри пузыря.
local REFILL_PER_SECOND = 20
-- Дыхание после возрождения (персонаж появляется без брони), тиков.
-- Без этого на планете без воздуха возрождение заканчивалось бы новой смертью.
local RESPAWN_GRACE_TICKS = 60 * 60

local planets_cache

local function oxygen_planets()
  if not planets_cache then
    local proto = prototypes.mod_data["sap-oxygen-planets"]
    planets_cache = proto and proto.data or {}
  end
  return planets_cache
end

local function armor_grid(character)
  local inventory = character.get_inventory(defines.inventory.character_armor)
  if not inventory or inventory.is_empty() then return nil end
  local armor = inventory[1]
  return armor.valid_for_read and armor.grid or nil
end

--- Запас воздуха персонажа: экстренная система и баллоны.
local function capacity_of(character)
  local grid = armor_grid(character)
  if not grid then return 0, 0 end
  local per_tank = TANK_SECONDS[settings.global["sap-oxygen-tank-size"].value] or TANK_SECONDS.medium
  return EMERGENCY_SECONDS + grid.count(TANK_EQUIPMENT) * per_tank, EMERGENCY_SECONDS
end

local function damage_per_second(character)
  local fraction = DAMAGE_FRACTION[settings.global["sap-oxygen-death-speed"].value]
    or DAMAGE_FRACTION.medium
  if settings.global["sap-hardcore-strict-oxygen"].value then
    fraction = fraction * STRICT_MULTIPLIER
  end
  return character.max_health * fraction
end

local function get_state(player_index)
  storage.oxygen = storage.oxygen or {}
  local state = storage.oxygen[player_index]
  if not state then
    state = { air = 0, empty_notified = false, emergency_notified = false }
    storage.oxygen[player_index] = state
  end
  return state
end

local function needs_oxygen(surface)
  local planet = surface.planet
  return planet ~= nil and oxygen_planets()[planet.name] ~= nil
end

local function in_bubble(character)
  local distributors = character.surface.find_entities_filtered({
    name = DISTRIBUTOR,
    position = character.position,
    radius = settings.startup["sap-oxygen-distributor-radius"].value,
    force = character.force,
  })
  for _, entity in pairs(distributors) do
    if entity.status == defines.entity_status.working then
      return true
    end
  end
  return false
end

-- Индикатор --------------------------------------------------------------------

local function destroy_gui(player)
  local frame = player.gui.top[GUI_NAME]
  if frame then frame.destroy() end
end

local function update_gui(player, state, capacity, inside, grace_seconds)
  local frame = player.gui.top[GUI_NAME]
  if not frame then
    frame = player.gui.top.add({ type = "frame", name = GUI_NAME, direction = "vertical" })
    frame.add({ type = "label", name = "label" })
    frame.add({ type = "progressbar", name = "bar" })
    frame.bar.style.horizontally_stretchable = true
  end
  local seconds = math.floor(state.air)
  if grace_seconds then
    frame.label.caption = { "sap-oxygen.gui-respawn-grace", grace_seconds }
  elseif capacity <= 0 then
    frame.label.caption = inside and { "sap-oxygen.gui-in-bubble" } or { "sap-oxygen.gui-no-supply" }
  elseif inside then
    frame.label.caption = { "sap-oxygen.gui-refilling", seconds }
  else
    frame.label.caption = { "sap-oxygen.gui-remaining", seconds }
  end
  frame.bar.value = capacity > 0 and state.air / capacity or 0
end

-- Тик -------------------------------------------------------------------------

--- Один шаг кислородной системы для персонажа. player может быть nil (тесты): тогда нет
--- сообщений и индикатора. Возвращает false, если кислород здесь не нужен.
local function process_character(character, state, player)
  local function say(message, color)
    if player then player.print(message, { color = color }) end
  end
  local capacity, emergency = capacity_of(character)

  if not needs_oxygen(character.surface) then
    -- Пригодный воздух (Наувис) или система жизнеобеспечения платформы.
    state.air = capacity
    state.empty_notified = false
    state.emergency_notified = false
    return false
  end

  local seconds = oxygen.TICK_INTERVAL / 60
  local inside = in_bubble(character)

  if state.grace_until and game.tick < state.grace_until then
    state.air = math.min(capacity, state.air + (inside and REFILL_PER_SECOND * seconds or 0))
    if player then update_gui(player, state, capacity, inside, math.ceil((state.grace_until - game.tick) / 60)) end
    return true
  end
  state.grace_until = nil

  if inside then
    state.air = math.min(capacity, state.air + REFILL_PER_SECOND * seconds)
  else
    state.air = math.max(0, math.min(capacity, state.air) - seconds)
  end

  if inside or state.air > emergency then
    state.emergency_notified = false
  elseif emergency > 0 and state.air > 0 and not state.emergency_notified then
    state.emergency_notified = true
    say({ "sap-oxygen.emergency-active", math.floor(state.air) }, { r = 1, g = 0.8, b = 0.2 })
  end

  if state.air <= 0 and not inside then
    if not state.empty_notified then
      state.empty_notified = true
      say({ "sap-oxygen.life-support-failure" }, { r = 1, g = 0.3, b = 0.3 })
    end
    character.damage(damage_per_second(character) * seconds, "neutral", "sap-suffocation")
  else
    state.empty_notified = false
  end

  if player then
    if character.valid then update_gui(player, state, capacity, inside) else destroy_gui(player) end
  end
  return true
end

local function process_player(player)
  local character = player.character
  if not (character and character.valid) then
    destroy_gui(player)
    return
  end
  if not process_character(character, get_state(player.index), player) then
    destroy_gui(player)
  end
end

--- Для тестов: персонажи без игроков с собственным состоянием баллона.
function oxygen.test_step(character, initial_air)
  storage.oxygen_test = storage.oxygen_test or {}
  local state = storage.oxygen_test[character.unit_number]
  if not state then
    state = { air = initial_air or 0, empty_notified = false, emergency_notified = false }
    storage.oxygen_test[character.unit_number] = state
  end
  process_character(character, state, nil)
  return state.air
end

function oxygen.on_tick()
  if not settings.global["sap-oxygen-enabled"].value then return end
  for _, player in pairs(game.connected_players) do
    process_player(player)
  end
end

-- События ---------------------------------------------------------------------

function oxygen.on_init()
  storage.oxygen = {}
end

function oxygen.on_configuration_changed()
  storage.oxygen = storage.oxygen or {}
  planets_cache = nil
end

function oxygen.on_player_created(event)
  storage.oxygen = storage.oxygen or {}
  storage.oxygen[event.player_index] = nil
end

function oxygen.on_player_respawned(event)
  local state = get_state(event.player_index)
  state.air = 0
  state.grace_until = game.tick + RESPAWN_GRACE_TICKS
  state.empty_notified = false
  state.emergency_notified = false
end

function oxygen.on_player_removed(event)
  if storage.oxygen then storage.oxygen[event.player_index] = nil end
end

function oxygen.on_settings_changed(event)
  if event.setting == "sap-oxygen-enabled" and not settings.global["sap-oxygen-enabled"].value then
    for _, player in pairs(game.players) do destroy_gui(player) end
  end
end

return oxygen
