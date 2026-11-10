-- Советы и подсказки Space Age+ (окно «Советы и подсказки» в игре).
-- Тексты — locale [tips-and-tricks-item-name] / [tips-and-tricks-item-description].
-- Подсказки планет добавляют модули планет (api.tip).

local sap = require("prototypes.api")

data:extend({
  { type = "tips-and-tricks-item-category", name = "space-age-plus", order = "l-[space-age-plus]" },
  {
    type = "tips-and-tricks-item", name = "sap-briefing", category = "space-age-plus", order = "a",
    is_title = true, starting_status = "unlocked", tag = "[item=sap-oxygen-tank-equipment]",
  },
})

sap.tip("sap-oxygen", "b", "[fluid=sap-oxygen]", { type = "research", technology = "sap-oxygen-systems" })
sap.tip("sap-hidden-tree", "c", "[item=sap-data-card-logistics]", nil)
sap.tip("sap-decipherer", "d", "[item=sap-decipherer]", { type = "research", technology = "sap-decipherer" })
sap.tip("sap-exploration", "e", "[item=sap-satellite-mk1]", { type = "research", technology = "sap-telescope" })
sap.tip("sap-quality-tech", "f", "[item=sap-data-card-production]", { type = "research", technology = "sap-decipherer" })
sap.tip("sap-capture", "g", "[item=capture-robot-rocket]", { type = "research", technology = "captivity" })
sap.tip("sap-diary", "h", "[virtual-signal=signal-info]", nil)
