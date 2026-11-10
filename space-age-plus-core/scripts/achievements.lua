-- Достижения: слушают сюжетные события (scripts/events.lua) и концовки (scripts/story.lua).
--   sap-first-dungeon — войти в подземелье;
--   sap-warden-slayer — победить Смотрителя;
--   sap-flawless      — победить Смотрителя, не получив урона с момента входа в подземелье;
--   sap-all-cores     — забрать ядра всех планет;
--   sap-ending-*      — каждая концовка (и «вернуться домой»);
--   sap-all-endings   — Пробуждение, Наследие, Печать и Единство в одной игре.
-- Открытые достижения запоминаются в storage (для тестов и чтобы не открывать дважды).

local achievements = {}

local function state()
  storage.achievements = storage.achievements or { unlocked = {}, clean = {} }
  return storage.achievements
end

function achievements.unlock(player, name)
  if not (player and player.valid) then return end
  local s = state()
  s.unlocked[player.index] = s.unlocked[player.index] or {}
  if s.unlocked[player.index][name] then return end
  s.unlocked[player.index][name] = true
  player.unlock_achievement(name)
end

function achievements.unlock_force(force, name)
  for _, player in pairs(force.players) do achievements.unlock(player, name) end
end

function achievements.has(player_index, name)
  local u = state().unlocked[player_index]
  return u ~= nil and u[name] == true
end

--- Вход в подземелье: начинается попытка «без урона».
function achievements.on_enter(player)
  achievements.unlock(player, "sap-first-dungeon")
  state().clean[player.index] = player.surface.name
end

--- Урон персонажу игрока: попытка «без урона» сорвана.
function achievements.on_entity_damaged(event)
  local entity = event.entity
  local player = entity and entity.valid and entity.player
  if player then state().clean[player.index] = nil end
end

--- Сюжетные события (events.listeners).
function achievements.on_event(kind, force, _planet, player)
  if kind == "enter" and player then
    achievements.on_enter(player)
  elseif kind == "warden" then
    local s = state()
    for _, p in pairs(force.players) do
      if p.connected and p.surface.name:sub(1, 12) == "sap-dungeon-" then
        achievements.unlock(p, "sap-warden-slayer")
        if s.clean[p.index] == p.surface.name then achievements.unlock(p, "sap-flawless") end
      end
    end
  elseif kind == "death" and player then
    state().clean[player.index] = nil
  end
end

--- Ядро забрано: все ли ядра планет у команды.
function achievements.on_core_taken(force, taken)
  local registry = prototypes.mod_data["sap-ancient-cores"]
  for planet in pairs(registry and registry.data or {}) do
    if not taken[planet] then return end
  end
  achievements.unlock_force(force, "sap-all-cores")
end

--- Концовка выбрана (или «вернуться домой»: ending = "return").
function achievements.on_ending(force, ending, chosen)
  achievements.unlock_force(force, "sap-ending-" .. ending)
  local seen = {}
  for _, e in pairs(chosen or {}) do seen[e] = true end
  if seen.restore and seen.inherit and seen.seal and seen.unity then
    achievements.unlock_force(force, "sap-all-endings")
  end
end

function achievements.on_player_removed(event)
  local s = state()
  s.unlocked[event.player_index] = nil
  s.clean[event.player_index] = nil
end

return achievements
