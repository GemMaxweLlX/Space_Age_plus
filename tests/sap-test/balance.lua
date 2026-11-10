-- Выгрузка цифр баланса из прототипов (tools/balance.py собирает из неё docs/balance.md).
-- Пишет script-output/sap-balance.json.

local balance = {}

local function is_sap(name)
  return string.sub(name, 1, 4) == "sap-"
end

local function ingredients_of(list)
  local out = {}
  for _, i in pairs(list or {}) do out[#out + 1] = { name = i.name, amount = i.amount, type = i.type } end
  return out
end

local function products_of(list)
  local out = {}
  for _, p in pairs(list or {}) do
    out[#out + 1] = { name = p.name, amount = p.amount or p.amount_min, type = p.type, probability = p.probability }
  end
  return out
end

local function damage_of(attack)
  local total = 0
  local ok = pcall(function()
    local function walk(t, depth)
      if type(t) ~= "table" or depth > 8 then return end
      if t.type == "damage" and t.damage and t.damage.amount then total = total + t.damage.amount end
      for _, v in pairs(t) do walk(v, depth + 1) end
    end
    walk(attack.ammo_type, 0)
  end)
  return ok and total or nil
end

function balance.dump()
  local result = { technologies = {}, recipes = {}, units = {}, spawners = {}, buildings = {}, settings = {} }

  for name, t in pairs(prototypes.technology) do
    if is_sap(name) or prototypes.item[name] then
      if is_sap(name) then
        local prereq = {}
        for p in pairs(t.prerequisites) do prereq[#prereq + 1] = p end
        table.sort(prereq)
        local packs = {}
        for _, i in pairs(t.research_unit_ingredients or {}) do packs[#packs + 1] = i.name end
        result.technologies[#result.technologies + 1] = {
          name = name, count = t.research_unit_count, formula = t.research_unit_count_formula,
          time = t.research_unit_energy and t.research_unit_energy / 60, packs = packs, prerequisites = prereq,
          trigger = t.research_trigger and t.research_trigger.type, max_level = t.max_level,
        }
      end
    end
  end

  for name, r in pairs(prototypes.recipe) do
    if is_sap(name) and not r.hidden then
      local cond = {}
      for _, c in pairs(r.surface_conditions or {}) do cond[#cond + 1] = c.property .. " " .. c.min .. "-" .. c.max end
      result.recipes[#result.recipes + 1] = {
        name = name, energy = r.energy, ingredients = ingredients_of(r.ingredients), products = products_of(r.products),
        categories = r.categories, conditions = cond,
      }
    end
  end

  for name, e in pairs(prototypes.entity) do
    if is_sap(name) then
      if e.type == "unit" then
        local a = e.attack_parameters
        result.units[#result.units + 1] = {
          name = name, health = e.get_max_health(), speed = e.speed, range = a and a.range,
          cooldown = a and a.cooldown, damage = a and damage_of(a),
        }
      elseif e.type == "unit-spawner" or e.type == "turret" then
        result.spawners[#result.spawners + 1] = { name = name, type = e.type, health = e.get_max_health() }
      elseif e.get_max_health() and e.get_max_health() > 0 then
        result.buildings[#result.buildings + 1] = {
          name = name, type = e.type, health = e.get_max_health(),
          energy = e.get_max_energy_usage and e.get_max_energy_usage() or nil,
          speed = e.get_crafting_speed and e.get_crafting_speed() or nil,
        }
      end
    end
  end

  for name, s in pairs(prototypes.mod_setting) do
    if is_sap(name) then
      result.settings[#result.settings + 1] = {
        name = name, type = s.setting_type, default = s.default_value, min = s.minimum_value, max = s.maximum_value,
        allowed = s.allowed_values, mod = s.mod,
      }
    end
  end

  for _, list in pairs(result) do table.sort(list, function(a, b) return a.name < b.name end) end
  helpers.write_file("sap-balance.json", helpers.table_to_json(result), false)
  return #result.technologies, #result.recipes, #result.units
end

return balance
