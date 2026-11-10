-- Проверка прохождения: можно ли со старта получить и исследовать каждую технологию.
--
-- Модель игры (повторяем, пока что-то меняется):
--   * исследовать можно открытую технологию, если её требования изучены и все её колбы
--     можно произвести (рецепт колбы открыт с начала или изученной технологией);
--   * дешифратор открывает скрытую технологию, если её категория карт где-то выпадает,
--     все её требования уже открыты, а колбы производятся;
--   * телескоп → спутник 1 → спутник 2 → технологии полёта к планетам.
-- Возвращает список технологий, до которых добраться нельзя.

local progression = {}

-- Колбы, которые получаются не рецептом (или рецептом, который проверять бессмысленно).
local function pack_sources()
  local sources = {}
  for name, recipe in pairs(prototypes.recipe) do
    for _, product in pairs(recipe.products) do
      if product.type == "item" then
        sources[product.name] = sources[product.name] or {}
        table.insert(sources[product.name], name)
      end
    end
  end
  return sources
end

--- @param excluded table|nil категории карт, которые считаем недоступными (для самопроверки)
function progression.audit(force, excluded)
  local catalog = prototypes.mod_data["sap-tech-catalog"].data
  local variants = prototypes.mod_data["sap-quality-techs"] and prototypes.mod_data["sap-quality-techs"].data.variants or {}
  local explorable = prototypes.mod_data["sap-explorable-planets"].data
  local card_categories = {}
  for _, c in pairs(prototypes.mod_data["sap-tech-categories"].data.list) do
    if not (excluded and excluded[c]) then card_categories[c] = true end
  end

  local sources = pack_sources()
  local recipe_unlocked_by = {}
  for name, tech in pairs(prototypes.technology) do
    for _, effect in pairs(tech.effects) do
      if effect.type == "unlock-recipe" then
        recipe_unlocked_by[effect.recipe] = recipe_unlocked_by[effect.recipe] or {}
        table.insert(recipe_unlocked_by[effect.recipe], name)
      end
    end
  end

  local discovery = {}
  for _, info in pairs(explorable) do discovery[info.discovery_tech] = true end

  local unlocked, researched = {}, {}
  for name, tech in pairs(force.technologies) do
    if tech.enabled then unlocked[name] = true end
    if tech.researched then researched[name] = true end
  end

  local function recipe_available(recipe)
    if force.recipes[recipe] and force.recipes[recipe].enabled then return true end
    for _, tech in pairs(recipe_unlocked_by[recipe] or {}) do
      if researched[tech] then return true end
    end
    return false
  end

  local function pack_available(pack)
    for _, recipe in pairs(sources[pack] or {}) do
      if recipe_available(recipe) then return true end
    end
    return false
  end

  local function packs_ok(tech)
    for _, ingredient in pairs(tech.research_unit_ingredients) do
      if not pack_available(ingredient.name) then return false end
    end
    return true
  end

  -- Триггеры «скрафти предмет» и «построй» выполнимы, только если предмет можно получить.
  local function trigger_ok(trigger)
    local item
    if trigger.type == "craft-item" then
      item = trigger.item
    elseif trigger.type == "build-entity" then
      local entity = trigger.entity
      local proto = prototypes.entity[type(entity) == "table" and entity.name or entity]
      local places = proto and proto.items_to_place_this
      item = places and places[1] and places[1].name
      if not item then return true end
    else
      return true
    end
    if type(item) == "table" then item = item.name end
    return pack_available(item)
  end

  local function prerequisites_in(tech, set_a, set_b)
    for name in pairs(tech.prerequisites) do
      if not (set_a[name] or (set_b and set_b[name])) then return false end
    end
    return true
  end

  local changed = true
  local rounds = 0
  while changed and rounds < 500 do
    changed = false
    rounds = rounds + 1
    for name, tech in pairs(prototypes.technology) do
      -- Дешифратор открывает скрытую технологию.
      if not unlocked[name] and catalog[name] and card_categories[catalog[name].category]
          and prerequisites_in(tech, unlocked, researched) and packs_ok(tech) then
        unlocked[name] = true
        changed = true
      end
      -- Версии по качеству открываются вместе с базовой (дешифратором).
      if not unlocked[name] and variants[name] and unlocked[variants[name].base] then
        unlocked[name] = true
        changed = true
      end
      -- Исследование.
      if unlocked[name] and not researched[name] and prerequisites_in(tech, researched) then
        local ok
        if tech.research_trigger then ok = trigger_ok(tech.research_trigger) else ok = packs_ok(tech) end
        if ok then
          researched[name] = true
          changed = true
          -- Исследование планет.
          if name == "sap-telescope" then unlocked["sap-satellite-mk1"] = true end
          if name == "sap-satellite-mk1" then unlocked["sap-satellite-mk2"] = true end
          if name == "sap-satellite-mk2" then
            for tech_name in pairs(discovery) do unlocked[tech_name] = true end
          end
        end
      end
    end
  end

  local stuck = {}
  for name, tech in pairs(prototypes.technology) do
    if not researched[name] and not tech.hidden then
      stuck[#stuck + 1] = name
    end
  end
  table.sort(stuck)
  return stuck, rounds
end

return progression
