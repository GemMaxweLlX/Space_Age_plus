-- Силовой барьер, костюм стелса, взлом Механитов.

local specials = {}

specials.TICK_INTERVAL = 30

local BARRIERS = {
  ["sap-force-barrier"] = { radius = 12, cost = 5000000 },
  ["sap-force-barrier-mk2"] = { radius = 16, cost = 3000000 },
}
local MECHANITES = { "sap-sentinel", "sap-stormbringer", "sap-disruptor", "sap-annihilator", "sap-overseer" }
local STEALTH_ARMOR = "sap-stealth-suit"
local STEALTH_NOTICE = 6
local STEALTH_SCAN = 24
local HACK_RADIUS = 7
local HACK_CHANCE = 0.5
local HACKABLE = { ["sap-sentinel"] = true, ["sap-stormbringer"] = true, ["sap-disruptor"] = true,
                   ["sap-annihilator"] = true }

local function barriers(surface)
  local names = {}
  for name in pairs(BARRIERS) do names[#names + 1] = name end
  return surface.find_entities_filtered({ name = names })
end

local function run_barriers(surface)
  for _, barrier in pairs(barriers(surface)) do
    local rule = BARRIERS[barrier.name]
    if barrier.energy >= rule.cost then
      for _, unit in pairs(surface.find_entities_filtered({
        type = { "unit", "spider-unit" }, position = barrier.position, radius = rule.radius,
      })) do
        if barrier.energy < rule.cost then break end
        if unit.valid and unit.force ~= barrier.force and not unit.force.get_cease_fire(barrier.force) then
          barrier.energy = barrier.energy - rule.cost
          unit.die(barrier.force, barrier)
        end
      end
    end
  end
end

local function wears_stealth(character)
  local inventory = character.get_inventory(defines.inventory.character_armor)
  return inventory and not inventory.is_empty() and inventory[1].valid_for_read and inventory[1].name == STEALTH_ARMOR
end

local function run_stealth(surface)
  for _, character in pairs(surface.find_entities_filtered({ type = "character" })) do
    if wears_stealth(character) then
      for _, unit in pairs(surface.find_entities_filtered({
        name = MECHANITES, position = character.position, radius = STEALTH_SCAN,
      })) do
        local dx, dy = unit.position.x - character.position.x, unit.position.y - character.position.y
        if dx * dx + dy * dy > STEALTH_NOTICE * STEALTH_NOTICE and unit.commandable then
          unit.commandable.set_command({ type = defines.command.wander, distraction = defines.distraction.none,
                                         radius = 8, ticks_to_wait = 120 })
        end
      end
    end
  end
end

function specials.on_tick()
  for _, surface in pairs(game.surfaces) do
    if not surface.platform then run_barriers(surface) end
  end
  local echaris = game.get_surface("echaris")
  if echaris then run_stealth(echaris) end
end

function specials.on_script_trigger_effect(event)
  if event.effect_id ~= "sap-emp-hack" then return end
  local source = event.cause_entity or event.source_entity
  local force = source and source.valid and source.force
  if not force then return end
  local tech = force.technologies["sap-mechanite-hacking"]
  if not (tech and tech.researched) then return end
  local surface = game.get_surface(event.surface_index)
  local position = event.target_position
  if not (surface and position) then return end
  local hacked = 0
  for _, unit in pairs(surface.find_entities_filtered({ name = MECHANITES, position = position, radius = HACK_RADIUS })) do
    if HACKABLE[unit.name] and unit.force ~= force and math.random() < HACK_CHANCE then
      unit.force = force
      hacked = hacked + 1
    end
  end
  if hacked > 0 then force.print({ "sap-mechanites.hacked", hacked }) end
end

return specials
