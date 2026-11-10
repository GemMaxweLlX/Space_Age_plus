# Space Age+

Space Age+ expands Factorio: Space Age with new planets and moons, an oxygen system, a hidden
technology tree unlocked through data cards, planet exploration with satellites, space debris and
an engineer's diary. It is split into separate mods: the core plus one mod per planet, so each
can be installed on its own (planets need the core).

Requires Factorio 2.1 with the Space Age expansion. *Русская версия: [README.md](README.md).*

> **Status:** early version. Every mod loads in Factorio 2.1.24 and an in-game test suite passes
> (see below). All graphics are placeholders (recoloured vanilla models), and the balance numbers
> are first guesses.

## Mods

| Mod | What it adds |
|---|---|
| `space-age-plus-core` | Oxygen, planet exploration (telescope and two satellite generations), hidden technology tree (data cards, decipherer, logic lab complex, quality versions of technologies with building bonuses), hive capture for Space Age+ planets, high-grade fluid systems, steam turbine Mk2, cisterns, ancient vaults, dungeons and a story with three endings, engineer's diary |
| `space-age-plus-debris` | Items thrown off platforms become debris on the route; rocket wreckage piles up in orbit and falls on planets; special debris near Space Age+ planets |
| `space-age-plus-solaris` | Solaris, the planet next to the Sun: lava, coronal mass ejections, overheating, volcanic gas and molten metal, super boiler and mega turbine, lava creatures |
| `space-age-plus-echaris` | Echaris, moon of Fulgora: permanent magnetic storm, Mechanites and their control servers, capture centers with data cards, force barrier, stealth, hacking |
| `space-age-plus-aquara` | Aquara, moon of Gleba: an ocean world, algae and sea salt, tornado storms with shields and anchors, aquatic pentapods |
| `space-age-plus-nivar` | Nivar, moon of Aquilo: ice desert, dark caves with an elevator, deep drill, cryostorms, insulation, ice and cave creatures |

## Key mechanics

- **Oxygen.** Vulcanus, Fulgora, Gleba, Aquilo and the Space Age+ planets need air. Without modular
  armor a character starts suffocating at once; modular armor has a 30 s emergency system and oxygen
  tank equipment adds more. Distributors create breathable zones; collectors and generators produce
  oxygen.
- **Hidden technology tree** (on by default). Most technologies start hidden. Data cards found in
  wrecks, capture centers and ancient vaults are deciphered into technology choices; better card
  quality offers better-quality technologies, which give their buildings productivity, speed and
  efficiency bonuses.
- **Planet exploration.** A telescope on Nauvis unlocks unreliable generation 1 satellites; ten
  launches unlock generation 2, which fully surveys a planet and unlocks travel to it. Vanilla
  planets work this way too (setting, on by default).
- **Hardcore options** are separate settings: strict oxygen, decipherer only, harder satellites,
  aggressive creatures, permanent storms, no platform delivery, timed waves, no neutral zone.

## For mod authors

Other planet mods can join oxygen, exploration, the hidden tree, hive capture and the diary: see [docs/api.md](docs/api.md).

## Building and installing

```bash
tools/package.sh
```

Copy the archives from `dist/` into Factorio's `mods` folder.

## In-game tests

With an unpacked Factorio 2.1 headless server (it includes Space Age):

```bash
FACTORIO=/path/to/factorio tools/run-tests.sh
```

`MODE=saveload` continues the tests after a real save and load, `MODE=migration` adds the mods to a
game that is already running, `MODE=player` runs with a real (headless) player to test the windows,
oxygen and the elevator. The suite starts with a progression audit that proves every
technology is reachable from a fresh start.

## License

MIT, see [LICENSE](LICENSE).
