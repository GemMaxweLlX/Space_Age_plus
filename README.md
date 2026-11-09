# Space_Age_plus
Immerse yourself in new space adventures with the "Space age+" mod for Factorio! This mod adds unique moons for each planet, new resources, as well as many new buildings that will transform your game.

## Модули

Каждый модуль — отдельный мод Factorio (требует DLC Space Age, Factorio 2.1). Все модули зависят от ядра.

| Папка | Что внутри | Статус |
|---|---|---|
| `space-age-plus-core` | Общие механики: кислород, исследование планет, технологии, дневник, захват ульев, жидкости | Кислород — первая версия |
| `space-age-plus-debris` | Космический мусор на маршрутах | Заготовка |
| `space-age-plus-solaris` | Solaris — планета у Солнца | Заготовка |
| `space-age-plus-echaris` | Echaris — спутник Фульгоры | Заготовка |
| `space-age-plus-aquara` | Aquara — спутник Глебы | Заготовка |
| `space-age-plus-nivar` | Nivar — спутник Аквило | Заготовка |

## Сборка

```bash
tools/package.sh
```

Архивы появятся в `dist/`. Их нужно положить в папку `mods` Factorio.

Проверка Lua: `luacheck .` (настройки в `.luacheckrc`).

## Документы
- [Мастер документ v0.3 (HTML)](docs/space_age_plus_MASTER.html)
