-- Настройки модуля space-age-plus-echaris (см. docs: Глобальные механики → Хардкор).
data:extend({
  { type = "bool-setting", name = "sap-hardcore-echaris-no-delivery", setting_type = "startup", default_value = false, order = "a" },
  { type = "bool-setting", name = "sap-hardcore-echaris-timed-waves", setting_type = "startup", default_value = false, order = "b" },
  { type = "bool-setting", name = "sap-hardcore-echaris-no-neutral-zone", setting_type = "startup", default_value = false, order = "c" },
})
