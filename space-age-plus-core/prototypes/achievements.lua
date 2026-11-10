-- Достижения Space Age+ (открываются скриптом, scripts/achievements.lua). Иконки пока ванильные.

local function achievement(name, icon, order)
  return {
    type = "achievement", name = name, order = "z[sap]-" .. order,
    icon = "__base__/graphics/achievement/" .. icon .. ".png", icon_size = 128,
  }
end

data:extend({
  achievement("sap-first-dungeon", "watch-your-step", "a"),
  achievement("sap-warden-slayer", "golem", "b"),
  achievement("sap-flawless", "keeping-your-hands-clean", "c"),
  achievement("sap-all-cores", "tech-maniac", "d"),
  achievement("sap-ending-restore", "minions", "e"),
  achievement("sap-ending-inherit", "research-with-space", "f"),
  achievement("sap-ending-seal", "terraformer", "g"),
  achievement("sap-ending-return", "so-long-and-thanks-for-all-the-fish", "h"),
  achievement("sap-ending-unity", "you-are-doing-it-right", "i"),
  achievement("sap-all-endings", "smoke-me-a-kipper-i-will-be-back-for-breakfast", "j"),
})
