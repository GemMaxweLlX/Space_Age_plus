-- Если установлены модули планет SA+, мусор их орбит даёт и их материалы.
local EXTRA = {
  electrified = { "sap-mechanite-scrap", 0.3 },
  heated = { "sap-heat-resistant-crystal", 0.3 },
  biofilm = { "sap-green-algae", 0.4 },
  frozen = { "sap-cryolite", 0.3 },
}
for kind, extra in pairs(EXTRA) do
  local recipe = data.raw.recipe["sap-debris-" .. kind .. "-crushing"]
  if recipe and data.raw.item[extra[1]] then
    table.insert(recipe.results, { type = "item", name = extra[1], amount = 1, independent_probability = extra[2] })
  end
end
