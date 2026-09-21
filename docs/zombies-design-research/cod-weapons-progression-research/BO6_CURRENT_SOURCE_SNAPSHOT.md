# Black Ops 6 — Weapon System / Current Source Snapshot

Research snapshot: 2026-09-21.

## Official stat model

Official Call of Duty sources define four major categories.

### Firepower
Includes the weapon damage profile, Fire Rate and Bullet Velocity.

### Accuracy
Includes:
- Hip Fire Accuracy
- Flinch Resistance
- Recoil Gun Kick
- Centering Speed

Expanded/detail views expose more granular values.

### Handling
Includes:
- ADS time
- reload quickness
- empty reload quickness
- Sprint-to-Fire time

### Mobility
Includes:
- movement speed
- crouch movement speed
- sprint speed
- ADS movement speed

Official source:
https://www.callofduty.com/guides/blackops6/pre-game/call-of-duty-guides-black-ops-6-multiplayer-pre-game-weapons-and-loadouts

## Gunsmith philosophy

The official Black Ops 6 global-systems briefing describes a streamlined attachment grammar.

Instead of having one stat affected by many confusing attachment categories, attachment families have clearer jobs. The example given is Rear Grips improving combinations of:

- Sprint-to-Fire
- Slide-to-Fire
- Dive-to-Fire
- ADS speed

The detailed view exposes over 30 weapon statistics.

## Weapon leveling

Official BO6 progression rules:

- each weapon has its own Weapon Level journey;
- most Primary weapons have roughly 40–50 Weapon Levels;
- levels unlock weapon-specific attachments or a Class Optic;
- the Optic category is accessible from Weapon Level 1;
- once a Class Optic has been unlocked it can be used on compatible weapons in that class;
- Global Weapon Builds carry the build across Multiplayer, Zombies and Warzone.

Official source:
https://www.callofduty.com/blog/2024/08/call-of-duty-next-black-ops-6-reveal-global-systems-key-innovations-announcement

## Player-level weapon unlocks

Launch progression also separated **player-level weapon ownership** from **weapon-level attachment progression**.

Examples in the official launch article:

- XM4 — immediately available
- AK-74 — Player Level 10
- AMES 85 — 19
- GPR 91 — 28
- MODEL L — 40
- GOBLIN MK 2 — 46
- AS VAL — 55

This distinction belongs in our schema:

```text
playerUnlock -> grants weapon
weaponXPLevels -> grants attachments
```

## Prestige interaction

BO6 Classic Prestige can relock base items earned through player level, but official documentation says Weapon Progression itself, camos and reticles are not reset.

Weapon Builds are preserved even if the base weapon must later be re-earned through player level.

## Current technical snapshot source

CODMunity current comparator page:
https://codmunity.gg/weapon-stats/bo6

Research caveat:
This is a community/current data source, not an Activision official source. Date every numeric import.

Example current/base LC10 snapshot observed in research:

```text
Bullet velocity: 600 m/s in current BO6 comparator context
Fire rate: 800 RPM
Movement: 5 m/s
Crouch movement: 2.8 m/s in the selected comparator context
Sprint: 6.6 m/s
ADS movement: 3.6 m/s
Gun kick: 33.75
Horizontal recoil: 10.19
Vertical recoil: 33.36
```

A weapon detail page also reports a historical/current-source base record around:

```text
ADS: 210 ms
Sprint-to-fire: 123 ms
Reload: 2630 ms
Bullet velocity: 550 m/s
RPM: 800
Magazine: 34
Hipfire max: 7.35
```

The discrepancy in displayed velocity/context is precisely why every future numeric row needs:

- source URL
- mode
- attachment state
- observed date
- patch/season
- whether attachment stats had finished loading

## Attachment loading caveat

Current comparator URLs can contain attachments while the page states that attachment statistics are still loading. In that state the displayed numbers can still be **base weapon values**.

Our scraper/importer must never infer attachment deltas from a URL alone.

## Next BO6 ingestion target

Per weapon:

- base damage segments/body multipliers
- fire rate
- velocity
- ADS/STF/reload/swap
- movement/crouch/sprint/ADS movement
- gun kick
- horizontal/vertical recoil
- hip min/max
- magazine
- all compatible attachments
- exact attachment transform when source exposes it
- Zombies overrides/rarity/PaP in a separate layer
