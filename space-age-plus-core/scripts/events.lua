-- Сюжетные события подземелий и ядер → дневник (и достижения, scripts/achievements.lua).

local diary = require("scripts.diary")

local events = {}

--- Записи дневника по событиям подземелий (по одной на команду).
local DIARY = {
  door = "dungeon-door", keeper = "dungeon-keeper", warden = "dungeon-warden", trap = "dungeon-trap",
  death = "dungeon-death", expedition = "dungeon-expedition", pedestal = "dungeon-pedestal",
}

--- Обработчики других модулей (достижения): function(kind, force, planet, player).
events.listeners = {}

function events.handle(kind, force, planet, player)
  if DIARY[kind] then diary.add(force, DIARY[kind]) end
  for _, listener in pairs(events.listeners) do listener(kind, force, planet, player) end
end

return events
