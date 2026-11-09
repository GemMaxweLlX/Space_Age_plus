-- Дневник инженера (docs: Дневник; Вопросы реализации → I10).
-- Tab в Factorio уже занят ("подтвердить сообщение"), поэтому по умолчанию J.
-- Игрок может переназначить клавишу в настройках управления.
data:extend({
  {
    type = "custom-input",
    name = "sap-toggle-diary",
    key_sequence = "J",
    consuming = "none",
    order = "a",
  },
})
