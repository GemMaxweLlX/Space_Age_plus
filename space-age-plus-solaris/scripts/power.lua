-- Захватчик луча → тепло сверхбойлера. Захватчик, стоящий рядом со сверхбойлером, отдаёт
-- накопленную энергию луча в его тепловой запас (вместо электросети).

local power = {}

power.TICK_INTERVAL = 60

local SURFACE = "solaris"
local CATCHER = "sap-ray-catcher"
local BOILERS = { "sap-super-boiler", "sap-super-boiler-mk2" }
local RADIUS = 8
local SPECIFIC_HEAT = 10000000 -- Дж на градус (как в прототипе сверхбойлера)
local MAX_TEMPERATURE = 1000

function power.on_tick()
  local surface = game.get_surface(SURFACE)
  if not surface then return end
  for _, catcher in pairs(surface.find_entities_filtered({ name = CATCHER })) do
    if catcher.energy > 0 then
      local boiler = surface.find_entities_filtered({ name = BOILERS, position = catcher.position, radius = RADIUS, limit = 1 })[1]
      if boiler and boiler.temperature then
        boiler.temperature = math.min(MAX_TEMPERATURE, boiler.temperature + catcher.energy / SPECIFIC_HEAT)
        catcher.energy = 0
      end
    end
  end
end

--- Для тестов: зарядить захватчик, как будто в него попал луч.
function power.charge(catcher, energy)
  catcher.energy = energy
end

return power
