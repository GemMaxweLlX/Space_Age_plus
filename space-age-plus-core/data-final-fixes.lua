-- space-age-plus-core: финальные правки после всех модулей.
local sap = require("prototypes.api")

-- Ванильные планеты тоже открываются через спутники, если включена настройка.
if settings.startup["sap-exploration-vanilla-planets"].value then
  for _, planet in pairs({ "vulcanus", "fulgora", "gleba", "aquilo" }) do
    if data.raw.technology["planet-discovery-" .. planet] then
      sap.register_explorable_planet(planet, { discovery_tech = "planet-discovery-" .. planet })
    end
  end
end

-- Технологии полёта к исследуемым планетам скрыты, пока планету не разведает спутник 2.
local explorable = data.raw["mod-data"][sap.EXPLORABLE_PLANETS]
for _, info in pairs(explorable and explorable.data or {}) do
  local tech = data.raw.technology[info.discovery_tech]
  if tech then
    tech.enabled = false
    tech.visible_when_disabled = false
  end
end
