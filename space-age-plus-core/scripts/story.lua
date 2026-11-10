-- Сюжет древней расы и концовки.
--
-- Фрагменты истории — записи дневника: вход в первое подземелье, древнее ядро каждой планеты
-- (забрано из последнего зала), «узор» после трёх ядер. Из ядер и колб всех планет строится
-- Древний узел. В его окне команда проходит этапы:
--   choose  — выбор концовки:
--               restore — Пробуждение: стражи древних становятся союзниками;
--               inherit — Наследие: все технологии древних изучены;
--               seal    — Печать: подземелья обрушиваются, +25% продуктивности добычи;
--   decide  — после концовки: вернуться домой (финал, экран победы) или остаться;
--   recharge — остались: узел перезаряжается (настройка sap-story-recharge-minutes), затем снова choose —
--               доступны концовки, которые ещё не выбраны; после двух разных концовок
--               открывается секретная — unity (Единство), она всегда последняя;
--   done    — история завершена (вернулись домой или Единство).

local diary = require("scripts.diary")
local dungeon = require("scripts.dungeon")

local story = {}

local sap_settings = require("sap_settings")

--- Перезарядка узла после «остаться», тиков (настройка, по умолчанию 30 минут).
local function recharge_ticks()
  return (sap_settings.get("sap-story-recharge-minutes") or 30) * 60 * 60
end

local NEXUS = "sap-ancient-nexus"
local FRAME = "sap_story_frame"
local ENDINGS = { "restore", "inherit", "seal" }
local UNITY_AFTER = 2 -- сколько разных концовок нужно для секретной
local KNOWN_PLANETS = { nauvis = true, vulcanus = true, fulgora = true, gleba = true, aquilo = true,
                        solaris = true, echaris = true, aquara = true, nivar = true }

local function state()
  storage.story = storage.story or { endings = {}, cores = {} }
  return storage.story
end

--- Состояние команды: { chosen = { ending, ... }, stage = "choose"|"decide"|"recharge"|"done", ready_at }.
local function force_state(force)
  local s = state()
  local fs = s.endings[force.index]
  if type(fs) == "string" then fs = { chosen = { fs }, stage = "decide" } end -- сохранения 0.1.0 до «остаться»
  if not fs then fs = { chosen = {}, stage = "choose" } end
  s.endings[force.index] = fs
  return fs
end

local function has_chosen(fs, ending)
  for _, e in pairs(fs.chosen) do if e == ending then return true end end
  return false
end

--- Последняя выбранная концовка команды (nil — ещё не выбрана).
function story.ending_of(force)
  local fs = force_state(force)
  return fs.chosen[#fs.chosen]
end

function story.stage_of(force)
  local fs = force_state(force)
  if fs.stage == "recharge" and game.tick >= (fs.ready_at or 0) then fs.stage = "choose" end
  return fs.stage
end

function story.endings_of(force)
  return force_state(force).chosen
end

--- Какие концовки сейчас можно выбрать.
function story.available(force)
  local fs = force_state(force)
  local result = {}
  if story.stage_of(force) ~= "choose" then return result end
  for _, ending in pairs(ENDINGS) do
    if not has_chosen(fs, ending) then result[ending] = true end
  end
  if #fs.chosen >= UNITY_AFTER then result.unity = true end
  return result
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

-- Единство: союз с древними и их знания (без обрушения подземелий).
function EFFECTS.unity(force)
  EFFECTS.restore(force)
  EFFECTS.inherit(force)
end

local function victory(force)
  if settings.global["sap-story-victory"].value then
    game.set_game_state({ game_finished = true, player_won = true, can_continue = true, victorious_force = force })
  end
end

local function refresh_windows(force)
  for _, player in pairs(force.players) do
    local opened = player.opened
    if player.gui.relative[FRAME] and opened and opened.object_name == "LuaEntity" and opened.valid
        and opened.name == NEXUS then
      story.build_window(player)
    end
  end
end

local function say(force, message)
  force.print(message, { color = { r = 0.6, g = 1, b = 0.85 } })
end

--- Выбор концовки командой. Возвращает false, если сейчас её выбрать нельзя.
function story.choose(force, ending)
  if not (EFFECTS[ending] and story.available(force)[ending]) then return false end
  local fs = force_state(force)
  table.insert(fs.chosen, ending)
  EFFECTS[ending](force)
  diary.add(force, "story-ending-" .. ending)
  say(force, { "sap-story.chosen", { "sap-story.ending-" .. ending } })
  if ending == "unity" then
    fs.stage = "done"
    victory(force)
  else
    fs.stage = "decide"
  end
  refresh_windows(force)
  return true
end

--- После концовки: "return" — вернуться домой (финал), "stay" — остаться и открыть другие концовки.
function story.decide(force, decision)
  local fs = force_state(force)
  if fs.stage ~= "decide" then return false end
  if decision == "return" then
    fs.stage = "done"
    diary.add(force, "story-return")
    say(force, { "sap-story.returned" })
    victory(force)
  elseif decision == "stay" then
    fs.stage = "recharge"
    fs.ready_at = game.tick + recharge_ticks()
    diary.add(force, "story-stay")
    say(force, { "sap-story.stayed", math.ceil(recharge_ticks() / 3600) })
  else
    return false
  end
  refresh_windows(force)
  return true
end

--- Для тестов: узел заряжен сразу.
function story.test_recharge(force)
  local fs = force_state(force)
  if fs.stage == "recharge" then fs.ready_at = game.tick end
end

--- Раз в минуту: сообщить о перезарядке узла.
function story.on_tick()
  for _, force in pairs(game.forces) do
    local fs = state().endings[force.index]
    if type(fs) == "table" and fs.stage == "recharge" and game.tick >= (fs.ready_at or 0) then
      fs.stage = "choose"
      say(force, { "sap-story.recharged" })
      diary.add(force, "story-recharged")
      refresh_windows(force)
    end
  end
end

-- Окно узла -------------------------------------------------------------------------------

local function ending_list(fs)
  local list = { "" }
  for i, e in pairs(fs.chosen) do
    if i > 1 then list[#list + 1] = ", " end
    list[#list + 1] = { "sap-story.ending-" .. e }
  end
  return list
end

local function add_button(frame, name, caption, tooltip, tags, enabled)
  local button = frame.add({ type = "button", name = name, caption = caption, tooltip = tooltip, tags = tags })
  button.style.horizontally_stretchable = true
  button.enabled = enabled
  return button
end

function story.build_window(player)
  if player.gui.relative[FRAME] then player.gui.relative[FRAME].destroy() end
  local frame = player.gui.relative.add({
    type = "frame", name = FRAME, caption = { "sap-story.title" }, direction = "vertical",
    anchor = { gui = defines.relative_gui_type.container_gui, position = defines.relative_gui_position.right,
               names = { NEXUS } },
  })
  local force = player.force
  local fs = force_state(force)
  local stage = story.stage_of(force)
  local caption
  if stage == "choose" then
    caption = #fs.chosen == 0 and { "sap-story.choose" } or { "sap-story.choose-again", ending_list(fs) }
  elseif stage == "decide" then
    caption = { "sap-story.decide", { "sap-story.ending-" .. fs.chosen[#fs.chosen] } }
  elseif stage == "recharge" then
    caption = { "sap-story.recharging", math.ceil((fs.ready_at - game.tick) / 3600) }
  else
    caption = { "sap-story.done", ending_list(fs) }
  end
  local label = frame.add({ type = "label", name = "label", caption = caption })
  label.style.single_line = false
  label.style.maximal_width = 300

  if stage == "decide" then
    add_button(frame, "return", { "sap-story.return" }, { "sap-story.return-tooltip" },
               { sap_action = "story-decide", decision = "return" }, true)
    add_button(frame, "stay", { "sap-story.stay" }, { "sap-story.stay-tooltip" },
               { sap_action = "story-decide", decision = "stay" }, true)
    return
  end
  if stage == "done" then return end
  local available = story.available(force)
  for _, ending in pairs(ENDINGS) do
    local tooltip = has_chosen(fs, ending) and { "sap-story.already-chosen" } or { "sap-story.ending-" .. ending .. "-tooltip" }
    add_button(frame, ending, { "sap-story.ending-" .. ending }, tooltip,
               { sap_action = "story-ending", ending = ending }, available[ending] == true)
  end
  -- Секретная концовка видна только тогда, когда открыта.
  if available.unity then
    add_button(frame, "unity", { "sap-story.ending-unity" }, { "sap-story.ending-unity-tooltip" },
               { sap_action = "story-ending", ending = "unity" }, true)
  end
end

function story.on_gui_opened(event)
  local entity = event.entity
  if not (entity and entity.valid and entity.name == NEXUS) then return end
  local player = game.get_player(event.player_index)
  if player then story.build_window(player) end
end

function story.on_gui_click(event)
  local element = event.element
  if not (element and element.valid and element.tags) then return end
  local action = element.tags.sap_action
  if action ~= "story-ending" and action ~= "story-decide" then return end
  local player = game.get_player(event.player_index)
  if not player then return end
  if action == "story-ending" then
    story.choose(player.force, element.tags.ending)
  else
    story.decide(player.force, element.tags.decision)
  end
end

return story
