-- Захват ульев SA+ — runtime (docs: Глобальные механики → Захват ульев SA+).
-- Ракета перекалибрированного захватчика срабатывает скриптом: гнездо своей планеты в точке
-- попадания заменяется захваченной версией. Во время криобури на Nivar есть малый шанс,
-- что гнездо при захвате взорвётся (H3).

local capture = {}

local SEARCH_RADIUS = 3
local CRYOSTORM_FAIL_CHANCE = 0.05

local function registry()
  local proto = prototypes.mod_data["sap-capturable-nests"]
  return proto and proto.data or {}
end

local function cryostorm_active()
  return remote.interfaces["sap-nivar"] and remote.interfaces["sap-nivar"].is_cryostorm
    and remote.call("sap-nivar", "is_cryostorm")
end

function capture.on_script_trigger_effect(event)
  if event.effect_id ~= "sap-capture" then return end
  local surface = game.get_surface(event.surface_index)
  if not surface then return end
  local position = event.target_position or (event.target_entity and event.target_entity.valid and event.target_entity.position)
  if not position then return end
  local nests = registry()
  local names = {}
  for name in pairs(nests) do names[#names + 1] = name end
  if #names == 0 then return end
  local nest = surface.find_entities_filtered({ name = names, position = position, radius = SEARCH_RADIUS, limit = 1 })[1]
  if not nest then return end
  local source = event.cause_entity or event.source_entity
  local force = source and source.valid and source.force or game.forces.player

  local entry = nests[nest.name]
  if (entry.planet == "nivar" or entry.planet == "nivar-caves") and cryostorm_active()
      and math.random() < CRYOSTORM_FAIL_CHANCE then
    force.print({ "sap-capture.cryostorm-failed" })
    nest.die()
    return
  end

  local nest_position = nest.position
  nest.destroy()
  local captive = surface.create_entity({ name = entry.captive, position = nest_position, force = force })
  if captive then
    force.print({ "sap-capture.captured", { "entity-name." .. entry.captive },
                  string.format("[gps=%d,%d,%s]", nest_position.x, nest_position.y, surface.name) })
  end
end

return capture
