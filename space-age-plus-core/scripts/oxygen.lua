-- Система кислорода — runtime (docs: Глобальные механики → Кислород).
--
-- У каждого игрока свой баллон (G1). Баллон тратится, пока персонаж стоит на планете,
-- которой нужен кислород, и вне пузыря работающего распределителя. Внутри пузыря баллон
-- заполняется. Пустой баллон → персонаж постепенно теряет здоровье, в чат пишется
-- "Неисправная система жизнеобеспечения". Скорость смерти и объём баллона — по 3
-- настройки (G2), хардкор "Строгий кислород" ускоряет смерть.

local oxygen = {}

oxygen.TICK_INTERVAL = 60 -- раз в секунду

local DISTRIBUTOR = "sap-oxygen-distributor"
local GUI_NAME = "sap_oxygen_frame"

-- Объём баллона в секундах дыхания.
local TANK_SECONDS = { small = 60, medium = 180, large = 420 }
-- Доля максимального здоровья, теряемая в секунду с пустым баллоном.
local DAMAGE_FRACTION = { slow = 0.02, medium = 0.05, fast = 0.12 }
local STRICT_MULTIPLIER = 3
-- Сколько секунд дыхания восполняется за секунду внутри пузыря.
local REFILL_PER_SECOND = 20
local LOW_WARNING = 0.25

local planets_cache

local function oxygen_planets()
  if not planets_cache then
    local proto = prototypes.mod_data["sap-oxygen-planets"]
    planets_cache = proto and proto.data or {}
  end
  return planets_cache
end

local function tank_capacity()
  return TANK_SECONDS[settings.global["sap-oxygen-tank-size"].value] or TANK_SECONDS.medium
end

local function damage_per_second(character)
  local fraction = DAMAGE_FRACTION[settings.global["sap-oxygen-death-speed"].value]
    or DAMAGE_FRACTION.medium
  if settings.global["sap-hardcore-strict-oxygen"].value then
    fraction = fraction * STRICT_MULTIPLIER
  end
  return character.max_health * fraction
end

local function radius()
  return settings.startup["sap-oxygen-distributor-radius"].value
end

local function get_state(player_index)
  storage.oxygen = storage.oxygen or {}
  local state = storage.oxygen[player_index]
  if not state then
    state = { air = tank_capacity(), empty_notified = false, low_notified = false }
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
    radius = radius(),
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

local function update_gui(player, state, capacity, inside)
  local frame = player.gui.top[GUI_NAME]
  if not frame then
    frame = player.gui.top.add({ type = "frame", name = GUI_NAME, direction = "vertical" })
    frame.add({ type = "label", name = "label" })
    frame.add({ type = "progressbar", name = "bar" })
    frame.bar.style.horizontally_stretchable = true
  end
  local seconds = math.floor(state.air)
  frame.label.caption = inside
    and { "sap-oxygen.gui-refilling", seconds }
    or { "sap-oxygen.gui-remaining", seconds }
  frame.bar.value = capacity > 0 and state.air / capacity or 0
end

-- Тик -------------------------------------------------------------------------

local function process_player(player)
  local character = player.character
  if not (character and character.valid) or not needs_oxygen(character.surface) then
    destroy_gui(player)
    return
  end

  local state = get_state(player.index)
  local capacity = tank_capacity()
  local seconds = oxygen.TICK_INTERVAL / 60
  local inside = in_bubble(character)

  if inside then
    state.air = math.min(capacity, state.air + REFILL_PER_SECOND * seconds)
  else
    state.air = math.max(0, state.air - seconds)
  end

  if state.air > capacity * LOW_WARNING then
    state.low_notified = false
  elseif state.air > 0 and not state.low_notified then
    state.low_notified = true
    player.print({ "sap-oxygen.low-warning" }, { color = { r = 1, g = 0.8, b = 0.2 } })
  end

  if state.air <= 0 then
    if not state.empty_notified then
      state.empty_notified = true
      player.print({ "sap-oxygen.life-support-failure" }, { color = { r = 1, g = 0.3, b = 0.3 } })
    end
    character.damage(damage_per_second(character) * seconds, "neutral", "sap-suffocation")
  else
    state.empty_notified = false
  end

  if character.valid then
    update_gui(player, state, capacity, inside)
  else
    destroy_gui(player)
  end
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
  local capacity = tank_capacity()
  for _, state in pairs(storage.oxygen) do
    state.air = math.min(state.air, capacity)
  end
end

function oxygen.on_player_reset(event)
  storage.oxygen = storage.oxygen or {}
  storage.oxygen[event.player_index] = nil
  get_state(event.player_index)
end

function oxygen.on_player_removed(event)
  if storage.oxygen then storage.oxygen[event.player_index] = nil end
end

function oxygen.on_settings_changed(event)
  if event.setting == "sap-oxygen-tank-size" then
    oxygen.on_configuration_changed()
  elseif event.setting == "sap-oxygen-enabled"
      and not settings.global["sap-oxygen-enabled"].value then
    for _, player in pairs(game.players) do destroy_gui(player) end
  end
end

return oxygen
