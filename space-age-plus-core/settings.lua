-- Настройки ядра Space Age+ (docs: Глобальные механики → Кислород, Хардкор).
-- Каждая хардкор-опция включается отдельно, общей кнопки нет.
data:extend({
  -- Кислород
  { type = "bool-setting", name = "sap-oxygen-enabled", setting_type = "runtime-global",
    default_value = true, order = "a-a" },
  { type = "string-setting", name = "sap-oxygen-death-speed", setting_type = "runtime-global",
    default_value = "medium", allowed_values = { "slow", "medium", "fast" }, order = "a-b" },
  { type = "string-setting", name = "sap-oxygen-tank-size", setting_type = "runtime-global",
    default_value = "medium", allowed_values = { "small", "medium", "large" }, order = "a-c" },
  { type = "int-setting", name = "sap-oxygen-distributor-radius", setting_type = "startup",
    default_value = 16, minimum_value = 8, maximum_value = 64, order = "a-d" },

  -- Исследование планет
  { type = "bool-setting", name = "sap-exploration-vanilla-planets", setting_type = "startup",
    default_value = true, order = "b-a" },

  -- Дерево технологий
  { type = "bool-setting", name = "sap-techtree-enabled", setting_type = "startup",
    default_value = true, order = "c-a" },
  { type = "int-setting", name = "sap-llk-chance", setting_type = "runtime-global",
    default_value = 15, minimum_value = 10, maximum_value = 20, order = "c-b" },

  -- Глобальные хардкор-опции
  { type = "bool-setting", name = "sap-hardcore-strict-oxygen", setting_type = "runtime-global",
    default_value = false, order = "z-a" },
  { type = "bool-setting", name = "sap-hardcore-decipher-only", setting_type = "startup",
    default_value = false, order = "z-b" },
  { type = "bool-setting", name = "sap-hardcore-satellite", setting_type = "startup",
    default_value = false, order = "z-c" },
})
