# Space_Age_plus
Immerse yourself in new space adventures with the "Space age+" mod for Factorio! This mod adds unique moons for each planet, new resources, as well as many new buildings that will transform your game.

## Модули

Каждый модуль — отдельный мод Factorio (требует DLC Space Age, Factorio 2.1). Все модули зависят от ядра.

| Папка | Что внутри | Статус |
|---|---|---|
| `space-age-plus-core` | Общие механики: кислород, исследование планет, технологии, дневник, захват ульев, жидкости | v0.1: кислород, исследование планет, скрытое дерево технологий (выключено по умолчанию), окно дневника |
| `space-age-plus-debris` | Космический мусор на маршрутах | v0.1: мусор из выброшенного, ракетные обломки, падения |
| `space-age-plus-solaris` | Solaris — планета у Солнца | Заготовка |
| `space-age-plus-echaris` | Echaris — спутник Фульгоры | v0.1: планета, буря, стабилизатор |
| `space-age-plus-aquara` | Aquara — спутник Глебы | Заготовка |
| `space-age-plus-nivar` | Nivar — спутник Аквило | Заготовка |

> Ни один модуль ещё не запускался в самой игре: код проверен по документации API Factorio 2.1.24
> и файлам игры, но не в игре. Перед игрой нужна проверка загрузки.

## Сборка

```bash
tools/package.sh
```

Архивы появятся в `dist/`. Их нужно положить в папку `mods` Factorio.

Проверка Lua: `luacheck .` (настройки в `.luacheckrc`).

## Документы
- [Мастер документ v0.3 (Markdown)](docs/design/README.md) — удобно читать на GitHub.
- [Мастер документ v0.3 (HTML)](docs/space_age_plus_MASTER.html) — оригинал.

После обновления HTML Markdown пересобирается так:

```bash
python3 -I tools/html2md.py docs/space_age_plus_MASTER.html docs/design
```
