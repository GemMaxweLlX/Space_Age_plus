# Space Age+ API for other mods

Space Age+ Core exposes a small API so that other planet mods can join its mechanics: oxygen,
satellite exploration, the hidden technology tree, hive capture, cisterns and condensing
turbines, the diary and the hint window. *Краткое описание на русском — в конце файла.*

All examples assume your mod depends on the core:

```json
"dependencies": ["base >= 2.1.0", "space-age >= 2.1.0", "? space-age-plus-core >= 0.1.0"]
```

With an optional dependency (`?`), guard every call:

```lua
if mods["space-age-plus-core"] then
  local sap = require("__space-age-plus-core__.prototypes.api")
  -- calls below
end
```

## Data stage (`data.lua` or `data-updates.lua`)

Call these in `data.lua` or `data-updates.lua`, **not** in `data-final-fixes.lua`: the core
builds its lists (hidden technologies, quality versions, explorable planets) in its own
`data-final-fixes.lua`.

```lua
local sap = require("__space-age-plus-core__.prototypes.api")
```

### Oxygen

| Function | What it does |
|---|---|
| `sap.register_oxygen_planet(planet, { solution = "generator" \| "collector" })` | Characters on this planet's surface need oxygen. |
| `sap.unregister_oxygen_planet(planet)` | Removes the requirement (e.g. to make a vanilla planet breathable). |
| `sap.oxygen_collector_recipe(planet, pressure, ingredients, amount?)` | Returns an atmospheric collector recipe that works only at this planet's `pressure` surface property. Add it with `data:extend` and unlock it with a technology. |

Planets need distinct pressure values for collector recipes to stay planet-specific.

### Exploration

| Function | What it does |
|---|---|
| `sap.register_explorable_planet(planet, { discovery_tech = "...", parent = "..." })` | The planet's discovery technology stays hidden until a generation 1 satellite finds the planet (then it is visible but locked) and a generation 2 satellite surveys it (then it can be researched). |
| `sap.moon_origin(parent)` | Star-map position of `parent`, for `planet.origin` of a moon; `distance`/`orientation` are then relative to the parent. |

### Hidden technology tree

Technologies that need more than red science are hidden at the start and unlocked by data cards
whose category matches the technology. The category is guessed from the technology's name.

| Function | What it does |
|---|---|
| `sap.keep_visible(tech)` | This technology is never hidden. |
| `sap.set_tech_category(tech, category)` | Data card category for this technology: `automation`, `logistics`, `mining`, `production`, `energy`, `military`, `robotics`, `trains`, `chemistry`, `space`, `biotech`, `cryotech`, `sap-energy`, `sap-military`, `alien`. |

Hidden technologies that unlock machines, furnaces, mining drills or labs automatically get
quality versions with building bonuses.

### Hive capture

```lua
sap.capturable_nests({
  planet = "myplanet", tint = { r = 1, g = 0.6, b = 0.3, a = 1 },
  discovery_tech = "planet-discovery-myplanet",
  nests = { { nest = "my-nest", product = "my-material" } },
  food_ingredients = { { type = "item", name = "my-local-ore", amount = 2 } },  -- + 1 bioflux
  rocket_ingredients = { { type = "item", name = "my-alloy", amount = 2 } },    -- + 1 capture rocket
  science = { { "automation-science-pack", 1 }, { "agricultural-science-pack", 1 } },
})
```

Creates the "Capture recalibration: planet" technology, a planet-specific capture rocket (the
vanilla rocket does not capture these nests), food, and captive versions of the nests that eat
only that food, produce `product` and turn hostile again when starved. Nests must be
`unit-spawner` prototypes without `captured_spawner_entity`.

### Other

| Function | What it does |
|---|---|
| `sap.register_condensing_generator(generator, ratio)` | The generator returns `ratio` of the steam it uses as water into a neighbouring pipe or storage tank (steam turbine Mk2 and the mega turbine use 0.9). |
| `sap.register_no_delivery(planet, setting?, unless_tech?)` | Cargo pods from platforms are sent back to their hub instead of landing on this planet. `setting` is a startup bool setting that turns the rule on (nil = always), `unless_tech` lifts it once researched. Pods carrying a player always land. |
| `sap.upgrade({ base, name, tint, change, ingredients, time, result_count, tech })` | Builds an improved copy of a vanilla building, armor or gun: entity, item, recipe, and adds the recipe to the technology `tech.name` (created on first use with `tech.icon`, `tech.count`, `tech.prerequisites`, `tech.science`). `change(entity, item)` edits the copy. |
| `sap.tip(name, order, tag, trigger?)` | An entry in the "Space Age+" section of Tips and tricks. Text from `[tips-and-tricks-item-name]` and `[tips-and-tricks-item-description]` in your locale. `trigger` is a TipTrigger (nil = shown from the start). |

## Runtime (`control.lua`)

### Settings with the preset applied

```lua
local sap_settings = require("__space-age-plus-core__.sap_settings")
if sap_settings.get("sap-hardcore-strict-oxygen") then ... end
```

`get(name)` returns the value of a Space Age+ setting, taking the "Space Age+ preset" startup
setting into account (Casual / Standard / Hardcore override individual settings). Use it for your
own hardcore settings too if you add them to `sap_settings.PRESETS`.

### Diary

```lua
if remote.interfaces["sap-diary"] then
  remote.call("sap-diary", "add", force.name, "my-entry")
end
```

Adds a diary entry for the force, once per key. Put the text in your locale:

```ini
[sap-diary-title]
my-entry=First visit to My Planet

[sap-diary-text]
my-entry=Strange place. The engineer's words go here.
```

`remote.call("sap-diary", "entries", force_name)` returns the keys the force already has.

### Other remote interfaces

`sap-core`, `sap-echaris`, `sap-solaris`, `sap-aquara` and `sap-nivar` also contain functions used
by the test suite (names starting with `test_` and a few others). They are not a stable API and
may change.

---

## Кратко на русском

Другие моды могут подключаться к механикам Space Age+ через API ядра.
- **Стадия data** (`data.lua` или `data-updates.lua`, но не `data-final-fixes.lua`):
  - кислород на своей планете — `register_oxygen_planet`;
  - разведка спутниками — `register_explorable_planet`;
  - управление скрытым деревом — `keep_visible`, `set_tech_category`;
  - захват своих гнёзд — `capturable_nests`;
  - запрет доставки — `register_no_delivery`;
  - конденсация — `register_condensing_generator`;
  - улучшенные копии построек — `upgrade`;
  - подсказки — `tip`.
- **Стадия control:**
  - настройки с учётом набора — `sap_settings.get`;
  - записи дневника — `remote.call("sap-diary", "add", ...)`.
