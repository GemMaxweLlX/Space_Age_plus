-- Конденсация пара: зарегистрированные генераторы (паровая турбина Mk2, мега-турбина Solaris)
-- возвращают долю потраченного пара водой в соседнюю трубу или бак.
-- Пар считается по выработанной энергии: 1 единица пара 500°C = (500 - 15) × 0.2 кДж.

local condensing = {}

condensing.TICK_INTERVAL = 60

local ENERGY_PER_STEAM = (500 - 15) * 200
local SEARCH_RADIUS = 4
local TARGET_TYPES = { "pipe", "pipe-to-ground", "storage-tank" }

local function generators()
  local proto = prototypes.mod_data["sap-condensing-generators"]
  return proto and proto.data or {}
end

local function deliver(generator, amount)
  for _, target in pairs(generator.surface.find_entities_filtered({
    type = TARGET_TYPES, position = generator.position, radius = SEARCH_RADIUS, force = generator.force,
  })) do
    local inserted = target.insert_fluid({ name = "water", amount = amount, temperature = 15 })
    if inserted > 0 then return inserted end
  end
  return 0
end

function condensing.on_tick()
  local list = generators()
  local names = {}
  for name in pairs(list) do names[#names + 1] = name end
  if #names == 0 then return end
  storage.condensed = storage.condensed or 0
  for _, surface in pairs(game.surfaces) do
    for _, generator in pairs(surface.find_entities_filtered({ name = names })) do
      local energy = generator.energy_generated_last_tick * condensing.TICK_INTERVAL
      if energy > 0 then
        local water = energy / ENERGY_PER_STEAM * list[generator.name]
        storage.condensed = storage.condensed + deliver(generator, water)
      end
    end
  end
end

return condensing
