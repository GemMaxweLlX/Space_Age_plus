-- Скрытое дерево технологий — runtime (docs: Технологии).
--
-- Дешифратор: игрок кладёт в него карту данных и колбы и нажимает «Расшифровать».
--   Тратится по 10 колб каждого вида. Из скрытых технологий категории карты, которые можно
--   исследовать этими колбами, предлагаются три. Качество карты даёт «улучшенные» варианты
--   (технология запоминается с качеством карты — для бонусов I3). «Выбрать» открывает
--   технологию в дереве, её исследуют в обычной лаборатории. «Обновить» — новый список,
--   но карта может сломаться. После выбора карта может уцелеть (шанс по качеству).
-- ЛЛК: только колбы, шанс 10-20% (настройка), выбор из двух, обычное качество.
--   Хардкор «Только дешифратор» отключает ЛЛК.
-- Обломки с картами появляются на планетах при генерации карты. Стартовый обломок рядом
--   с точкой высадки на Наувисе открывает «Военную промышленность 1».

local techtree = {}

local quality_bonus = require("scripts.quality_bonus")

local DECIPHERER = "sap-decipherer"
local LOGIC_LAB = "sap-logic-lab"
local WRECK = "sap-data-wreck"
local STARTING_WRECK = "sap-starting-wreck"
local CARD_PREFIX = "sap-data-card-"

local PACKS_PER_USE = 10
local OPTIONS_DECIPHER = 3
local OPTIONS_LLK = 2
local REFRESH_BREAK_CHANCE = 0.25

local QUALITY = {
  normal = { improved = 0, survive = 0.10 },
  uncommon = { improved = 1, survive = 0.20 },
  rare = { improved = 2, survive = 0.35 },
  epic = { improved = 3, survive = 0.50 },
  legendary = { improved = 3, survive = 0.75 },
}

local WRECK_CHANCE_NAUVIS = 1 / 30
local WRECK_CHANCE_OTHER = 1 / 60

local FRAME_RELATIVE = "sap_techtree_relative"
local FRAME_CHOICE = "sap_techtree_choice"

-- Данные ------------------------------------------------------------------------

local function enabled()
  return settings.startup["sap-techtree-enabled"].value
end

local function catalog()
  local proto = prototypes.mod_data["sap-tech-catalog"]
  return proto and proto.data or {}
end

local function categories()
  local proto = prototypes.mod_data["sap-tech-categories"]
  return proto and proto.data.list or {}
end

local function state()
  storage.techtree = storage.techtree or {}
  local s = storage.techtree
  s.unlocked = s.unlocked or {} -- [force_index][tech] = quality
  s.pending = s.pending or {} -- [player_index] = выбор в открытом окне
  s.starting_wreck = s.starting_wreck or false
  return s
end

local function unlocked_for(force)
  local s = state()
  s.unlocked[force.index] = s.unlocked[force.index] or {}
  return s.unlocked[force.index]
end

--- Скрывает технологии каталога, которые команда ещё не открыла (нужно для старых сохранений).
local function sync_force(force)
  if not enabled() then return end
  local unlocked = unlocked_for(force)
  for name in pairs(catalog()) do
    local tech = force.technologies[name]
    if tech and not tech.researched then
      local open = unlocked[name] ~= nil
      tech.enabled = open
      tech.visible_when_disabled = false
    end
  end
  quality_bonus.sync_force(force, unlocked)
end

local QUALITY_RANK = { normal = 1, uncommon = 2, rare = 3, epic = 4, legendary = 5 }

local function unlock(force, name, quality)
  quality = quality or "normal"
  local unlocked = unlocked_for(force)
  if (QUALITY_RANK[quality] or 1) >= (QUALITY_RANK[unlocked[name]] or 0) then
    unlocked[name] = quality
  end
  local tech = force.technologies[name]
  if tech then
    tech.enabled = true
  end
  -- Открыта редкая версия → открыты и необычная (обычная — сама технология).
  quality_bonus.unlock_variants(force, name, unlocked[name])
end

-- Кандидаты ---------------------------------------------------------------------

local function inventory_of(entity)
  return entity.get_inventory(defines.inventory.chest)
end

--- Виды колб в инвентаре, которых хватает на одно использование.
local function available_packs(inventory)
  local packs = {}
  for _, stack in pairs(inventory.get_contents()) do
    local proto = prototypes.item[stack.name]
    if proto and proto.type == "tool" and inventory.get_item_count(stack.name) >= PACKS_PER_USE then
      packs[stack.name] = true
    end
  end
  return packs
end

local function consume_packs(inventory, packs)
  for pack in pairs(packs) do
    inventory.remove({ name = pack, count = PACKS_PER_USE })
  end
end

local function find_card(inventory)
  for _, stack in pairs(inventory.get_contents()) do
    if string.sub(stack.name, 1, #CARD_PREFIX) == CARD_PREFIX then
      local quality = stack.quality
      if type(quality) ~= "string" then quality = quality and quality.name or "normal" end
      return { name = stack.name, quality = quality, category = string.sub(stack.name, #CARD_PREFIX + 1) }
    end
  end
  return nil
end

local function remove_card(inventory, card)
  inventory.remove({ name = card.name, count = 1, quality = card.quality })
end

local function prerequisites_open(tech)
  for _, pre in pairs(tech.prerequisites) do
    if not (pre.researched or pre.enabled) then return false end
  end
  return true
end

--- Скрытые технологии команды, подходящие под категорию и набор колб.
local function candidates(force, category, packs)
  local list = {}
  for name, info in pairs(catalog()) do
    local tech = force.technologies[name]
    if tech and not tech.enabled and not tech.researched
        and (category == nil or info.category == category) then
      local ok = #info.packs > 0
      for _, pack in pairs(info.packs) do
        if not packs[pack] then ok = false break end
      end
      if ok and prerequisites_open(tech) then list[#list + 1] = name end
    end
  end
  table.sort(list)
  return list
end

local function pick(list, count)
  local result, pool = {}, { table.unpack(list) }
  for _ = 1, math.min(count, #pool) do
    local i = math.random(1, #pool)
    result[#result + 1] = table.remove(pool, i)
  end
  return result
end

local function roll_options(force, card, packs)
  local names = pick(candidates(force, card.category, packs), OPTIONS_DECIPHER)
  local improved = QUALITY[card.quality] and QUALITY[card.quality].improved or 0
  local options = {}
  for i, name in ipairs(names) do
    options[i] = { tech = name, quality = i <= improved and card.quality or "normal" }
  end
  return options
end

-- Окна --------------------------------------------------------------------------

local function close_choice(player)
  local frame = player.gui.screen[FRAME_CHOICE]
  if frame then frame.destroy() end
  state().pending[player.index] = nil
end

local function show_choice(player, pending)
  local screen = player.gui.screen
  if screen[FRAME_CHOICE] then screen[FRAME_CHOICE].destroy() end
  local frame = screen.add({ type = "frame", name = FRAME_CHOICE, direction = "vertical",
                             caption = { "sap-techtree.choice-title" } })
  frame.auto_center = true
  local row = frame.add({ type = "flow", direction = "horizontal" })
  for i, option in ipairs(pending.options) do
    local card = row.add({ type = "frame", direction = "vertical", style = "inside_shallow_frame_with_padding" })
    card.add({ type = "sprite", sprite = "technology/" .. option.tech })
    card.add({ type = "label", caption = prototypes.technology[option.tech].localised_name })
    card.add({ type = "label", caption = { "sap-techtree.quality",
      { "quality-name." .. option.quality } } })
    card.add({ type = "button", caption = { "sap-techtree.choose" },
               tags = { sap_action = "choose", index = i } })
  end
  local buttons = frame.add({ type = "flow", direction = "horizontal" })
  if pending.can_refresh then
    buttons.add({ type = "button", caption = { "sap-techtree.refresh" }, tags = { sap_action = "refresh" } })
  end
  buttons.add({ type = "button", caption = { "sap-techtree.cancel" }, tags = { sap_action = "cancel" } })
end

local function ensure_relative(player)
  if player.gui.relative[FRAME_RELATIVE] then return end
  local frame = player.gui.relative.add({
    type = "frame", name = FRAME_RELATIVE, direction = "vertical",
    caption = { "sap-techtree.panel-title" },
    anchor = { gui = defines.relative_gui_type.container_gui,
               position = defines.relative_gui_position.right,
               names = { DECIPHERER, LOGIC_LAB } },
  })
  frame.add({ type = "label", name = "hint", caption = { "sap-techtree.panel-hint" } })
  frame.add({ type = "button", name = "run", caption = { "sap-techtree.run" }, tags = { sap_action = "run" } })
end

-- Действия ----------------------------------------------------------------------

local function run_decipherer(player, entity)
  local inventory = inventory_of(entity)
  local card = find_card(inventory)
  if not card then
    player.print({ "sap-techtree.no-card" })
    return
  end
  local packs = available_packs(inventory)
  if next(packs) == nil then
    player.print({ "sap-techtree.no-packs", PACKS_PER_USE })
    return
  end
  local options = roll_options(player.force, card, packs)
  if #options == 0 then
    player.print({ "sap-techtree.nothing-to-decipher" })
    return
  end
  consume_packs(inventory, packs)
  local pending = { entity = entity, card = card, packs = packs, options = options, can_refresh = true }
  state().pending[player.index] = pending
  show_choice(player, pending)
end

local function run_logic_lab(player, entity)
  if settings.startup["sap-hardcore-decipher-only"].value then
    player.print({ "sap-techtree.llk-disabled" })
    return
  end
  local inventory = inventory_of(entity)
  local packs = available_packs(inventory)
  if next(packs) == nil then
    player.print({ "sap-techtree.no-packs", PACKS_PER_USE })
    return
  end
  consume_packs(inventory, packs)
  local chance = settings.global["sap-llk-chance"].value / 100
  if math.random() >= chance then
    player.print({ "sap-techtree.llk-failed" })
    return
  end
  local list = categories()
  local category = list[math.random(1, #list)]
  local names = pick(candidates(player.force, category, packs), OPTIONS_LLK)
  if #names == 0 then
    names = pick(candidates(player.force, nil, packs), OPTIONS_LLK)
  end
  if #names == 0 then
    player.print({ "sap-techtree.nothing-to-decipher" })
    return
  end
  local options = {}
  for i, name in ipairs(names) do options[i] = { tech = name, quality = "normal" } end
  local pending = { entity = entity, options = options, can_refresh = false }
  state().pending[player.index] = pending
  show_choice(player, pending)
end

local function choose(player, index)
  local pending = state().pending[player.index]
  if not pending then return end
  local option = pending.options[index]
  if not option then return end
  unlock(player.force, option.tech, option.quality)
  player.force.print({ "sap-techtree.unlocked", prototypes.technology[option.tech].localised_name,
                       { "quality-name." .. option.quality } })
  if pending.card and pending.entity and pending.entity.valid then
    local survive = QUALITY[pending.card.quality] and QUALITY[pending.card.quality].survive or 0
    if math.random() >= survive then
      remove_card(inventory_of(pending.entity), pending.card)
      player.print({ "sap-techtree.card-used" })
    else
      player.print({ "sap-techtree.card-survived" })
    end
  end
  close_choice(player)
end

local function refresh(player)
  local pending = state().pending[player.index]
  if not (pending and pending.card and pending.entity and pending.entity.valid) then
    close_choice(player)
    return
  end
  if math.random() < REFRESH_BREAK_CHANCE then
    remove_card(inventory_of(pending.entity), pending.card)
    player.print({ "sap-techtree.card-broken" })
    close_choice(player)
    return
  end
  local options = roll_options(player.force, pending.card, pending.packs)
  if #options == 0 then
    close_choice(player)
    return
  end
  pending.options = options
  show_choice(player, pending)
end

-- События -----------------------------------------------------------------------

function techtree.on_gui_opened(event)
  if not enabled() then return end
  local entity = event.entity
  if not (entity and entity.valid) then return end
  local player = game.get_player(event.player_index)
  if not player then return end
  if entity.name == DECIPHERER or entity.name == LOGIC_LAB then
    ensure_relative(player)
    local frame = player.gui.relative[FRAME_RELATIVE]
    frame.run.caption = entity.name == DECIPHERER and { "sap-techtree.run" } or { "sap-techtree.run-llk" }
    frame.hint.caption = entity.name == DECIPHERER and { "sap-techtree.panel-hint" }
      or { "sap-techtree.panel-hint-llk", settings.global["sap-llk-chance"].value }
  elseif entity.name == STARTING_WRECK then
    local s = state()
    if not s.starting_wreck then
      s.starting_wreck = true
      unlock(player.force, "military", "normal")
      player.force.print({ "sap-techtree.starting-wreck" })
    end
  end
end

function techtree.on_gui_click(event)
  local element = event.element
  if not (element and element.valid and element.tags and element.tags.sap_action) then return end
  local player = game.get_player(event.player_index)
  if not player then return end
  local action = element.tags.sap_action
  if action == "run" then
    local entity = player.opened
    if not (entity and entity.object_name == "LuaEntity" and entity.valid) then return end
    if entity.name == DECIPHERER then
      run_decipherer(player, entity)
    elseif entity.name == LOGIC_LAB then
      run_logic_lab(player, entity)
    end
  elseif action == "choose" then
    choose(player, element.tags.index)
  elseif action == "refresh" then
    refresh(player)
  elseif action == "cancel" then
    close_choice(player)
  end
end

function techtree.on_chunk_generated(event)
  if not enabled() then return end
  local surface = event.surface
  if not (surface and surface.valid and surface.planet) then return end
  local chance = surface.name == "nauvis" and WRECK_CHANCE_NAUVIS or WRECK_CHANCE_OTHER
  if math.random() >= chance then return end
  local area = event.area
  local center = { x = (area.left_top.x + area.right_bottom.x) / 2, y = (area.left_top.y + area.right_bottom.y) / 2 }
  local position = surface.find_non_colliding_position(WRECK, center, 16, 1)
  if not position then return end
  local wreck = surface.create_entity({ name = WRECK, position = position, force = "neutral" })
  if not wreck then return end
  -- Дальше от центра — выше шанс качественной карты.
  local distance = math.sqrt(center.x ^ 2 + center.y ^ 2)
  local roll = math.random() + math.min(distance / 4000, 0.5)
  local quality = roll > 1.45 and "legendary" or roll > 1.3 and "epic" or roll > 1.1 and "rare"
    or roll > 0.85 and "uncommon" or "normal"
  local list = categories()
  local category = list[math.random(1, #list)]
  wreck.get_inventory(defines.inventory.chest).insert({ name = CARD_PREFIX .. category, count = 1, quality = quality })
end

local function place_starting_wreck()
  local s = state()
  if s.starting_wreck_placed then return end
  local surface = game.get_surface("nauvis")
  if not surface then return end
  local position = surface.find_non_colliding_position(STARTING_WRECK, { 12, -8 }, 32, 1)
  if not position then return end
  surface.create_entity({ name = STARTING_WRECK, position = position, force = "neutral" })
  s.starting_wreck_placed = true
end

local function sync_all()
  for _, force in pairs(game.forces) do sync_force(force) end
end

function techtree.on_init()
  state()
  if not enabled() then return end
  sync_all()
  place_starting_wreck()
end

function techtree.on_configuration_changed()
  state()
  if not enabled() then return end
  sync_all()
end

--- Для тестов и скриптов других модулей: открыть технологию как через дешифратор.
function techtree.unlock(force, name, quality)
  unlock(force, name, quality)
end

function techtree.on_force_created(event)
  sync_force(event.force)
end

return techtree
