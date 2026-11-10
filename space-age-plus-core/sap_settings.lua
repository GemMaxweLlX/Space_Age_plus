-- Настройки Space Age+ с учётом набора (sap-preset). Работает и в data, и в control.
-- Другие модули: local sap_settings = require("__space-age-plus-core__.sap_settings")
--
-- Набор «Свой» (custom) — действуют отдельные настройки. Остальные наборы подменяют
-- значения из таблицы ниже; настройки, которых в наборе нет, берутся как есть.

local sap_settings = {}

local ALL_HARDCORE = {
  "sap-hardcore-strict-oxygen", "sap-hardcore-decipher-only", "sap-hardcore-satellite",
  "sap-hardcore-solaris-aggressive", "sap-hardcore-aquara-aggressive", "sap-hardcore-aquara-permanent-storm",
  "sap-hardcore-echaris-no-delivery", "sap-hardcore-echaris-timed-waves", "sap-hardcore-echaris-no-neutral-zone",
  "sap-hardcore-nivar-no-delivery",
}

local function preset(base, hardcore)
  local p = {}
  for k, v in pairs(base) do p[k] = v end
  for _, name in pairs(ALL_HARDCORE) do p[name] = hardcore end
  return p
end

sap_settings.PRESETS = {
  casual = preset({
    ["sap-techtree-enabled"] = false, ["sap-exploration-vanilla-planets"] = false,
    ["sap-oxygen-death-speed"] = "slow", ["sap-oxygen-tank-size"] = "large",
    ["sap-dungeon-size"] = "small", ["sap-dungeon-guardians"] = "few", ["sap-story-recharge-minutes"] = 10,
  }, false),
  standard = preset({
    ["sap-techtree-enabled"] = true, ["sap-exploration-vanilla-planets"] = true,
    ["sap-oxygen-death-speed"] = "medium", ["sap-oxygen-tank-size"] = "medium",
    ["sap-dungeon-size"] = "normal", ["sap-dungeon-guardians"] = "normal", ["sap-story-recharge-minutes"] = 30,
  }, false),
  hardcore = preset({
    ["sap-techtree-enabled"] = true, ["sap-exploration-vanilla-planets"] = true,
    ["sap-oxygen-death-speed"] = "fast", ["sap-oxygen-tank-size"] = "small",
    ["sap-dungeon-size"] = "large", ["sap-dungeon-guardians"] = "many", ["sap-story-recharge-minutes"] = 60,
  }, true),
}

--- Значение настройки с учётом набора.
function sap_settings.get(name)
  local chosen = settings.startup["sap-preset"] and settings.startup["sap-preset"].value or "custom"
  local overrides = sap_settings.PRESETS[chosen]
  if overrides and overrides[name] ~= nil then return overrides[name] end
  local setting = settings.startup[name] or (settings.global and settings.global[name])
  return setting and setting.value
end

return sap_settings
