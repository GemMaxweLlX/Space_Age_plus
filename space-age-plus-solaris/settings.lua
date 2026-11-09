-- Настройки модуля space-age-plus-solaris (см. docs: Глобальные механики → Хардкор).
data:extend({
  { type = "int-setting", name = "sap-solaris-coronal-rays", setting_type = "startup", default_value = 3, minimum_value = 1, maximum_value = 5, order = "a" },
  { type = "bool-setting", name = "sap-hardcore-solaris-aggressive", setting_type = "startup", default_value = false, order = "b" },
})
