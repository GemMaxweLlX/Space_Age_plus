-- Сюжет древней расы и концовки.
--
-- Фрагменты истории — записи дневника: вход в первое подземелье, древнее ядро каждой планеты
-- (забрано из последнего зала), «узор» после трёх ядер. Из ядер и колб всех планет строится
-- Древний узел; в его окне команда выбирает одну из трёх концовок (один раз):
--   restore — Пробуждение: стражи древних становятся союзниками;
--   inherit — Наследие: все технологии древних изучены;
--   seal    — Печать: подземелья обрушиваются, +25% продуктивности добычи.
-- После выбора — эпилог в дневнике и (настройка) экран победы с возможностью продолжить.

local diary = require("scripts.diary")
local dungeon = require("scripts.dungeon")

local story = {}

local NEXUS = "sap-ancient-nexus"
local FRAME = "sap_story_frame"
local ENDINGS = { "restore", "inherit", "seal" }
local KNOWN_PLANETS = { nauvis = true, vulcanus = true, fulgora = true, gleba = true, aquilo = true,
                        solaris = true, echaris = true, aquara = true, nivar = true }

local function state()
  storage.story = storage.story or { endings = {}, cores = {} }
  return storage.story
end

function story.ending_of(force)
  return state().endings[force.index]
end

--- Ядро планеты забрано из подземелья: фрагмент истории (и «узор» на третьем ядре).
function story.on_core_taken(force, planet)
  local s = state()
  s.cores[force.index] = s.cores[force.index] or {}
  local cores = s.cores[force.index]
  if cores[planet] then return end
  cores[planet] = true
  diary.add(force, KNOWN_PLANETS[planet] and ("story-core-" .. planet) or "story-core-other")
  local n = 0
  for _ in pairs(cores) do n = n + 1 end
  if n >= 3 then diary.add(force, "story-pattern") end
end

function story.on_built(entity)
  if entity.name == NEXUS then diary.add(entity.force, "story-nexus") end
end

-- Концовки ------------------------------------------------------------------------------

local EFFECTS = {}

function EFFECTS.restore(force)
  for _, surface in pairs(game.surfaces) do
    for _, e in pairs(surface.find_entities_filtered({ name = { "sap-alien-guardian", "sap-ancient-keeper" },
                                                       force = "enemy" })) do
      e.force = force
    end
  end
end

function EFFECTS.inherit(force)
  for name, tech in pairs(force.technologies) do
    if string.sub(name, 1, 10) == "sap-alien-" then
      tech.enabled = true
      tech.researched = true
    end
  end
end

function EFFECTS.seal(force)
  dungeon.seal()
  force.mining_drill_productivity_bonus = force.mining_drill_productivity_bonus + 0.25
end

--- Выбор концовки командой. Возвращает false, если концовка уже выбрана.
function story.choose(force, ending)
  local s = state()
  if s.endings[force.index] or not EFFECTS[ending] then return false end
  s.endings[force.index] = ending
  EFFECTS[ending](force)
  diary.add(force, "story-ending-" .. ending)
  force.print({ "sap-story.chosen", { "sap-story.ending-" .. ending } }, { color = { r = 0.6, g = 1, b = 0.85 } })
  if settings.global["sap-story-victory"].value then
    game.set_game_state({ game_finished = true, player_won = true, can_continue = true, victorious_force = force })
  end
  for _, player in pairs(force.players) do
    if player.gui.relative[FRAME] then player.gui.relative[FRAME].destroy() end
  end
  return true
end

-- Окно узла -------------------------------------------------------------------------------

function story.on_gui_opened(event)
  local entity = event.entity
  if not (entity and entity.valid and entity.name == NEXUS) then return end
  local player = game.get_player(event.player_index)
  if not player then return end
  if player.gui.relative[FRAME] then player.gui.relative[FRAME].destroy() end
  local frame = player.gui.relative.add({
    type = "frame", name = FRAME, caption = { "sap-story.title" }, direction = "vertical",
    anchor = { gui = defines.relative_gui_type.container_gui, position = defines.relative_gui_position.right,
               names = { NEXUS } },
  })
  local chosen = story.ending_of(player.force)
  local label = frame.add({ type = "label", name = "label",
                            caption = chosen and { "sap-story.already", { "sap-story.ending-" .. chosen } }
                              or { "sap-story.choose" } })
  label.style.single_line = false
  label.style.maximal_width = 300
  for _, ending in pairs(ENDINGS) do
    local button = frame.add({
      type = "button", name = ending, caption = { "sap-story.ending-" .. ending },
      tooltip = { "sap-story.ending-" .. ending .. "-tooltip" },
      tags = { sap_action = "story-ending", ending = ending },
    })
    button.style.horizontally_stretchable = true
    button.enabled = chosen == nil
  end
end

function story.on_gui_click(event)
  local element = event.element
  if not (element and element.valid and element.tags and element.tags.sap_action == "story-ending") then return end
  local player = game.get_player(event.player_index)
  if player then story.choose(player.force, element.tags.ending) end
end

return story
