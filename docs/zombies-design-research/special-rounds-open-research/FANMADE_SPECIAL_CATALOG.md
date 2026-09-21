# Fan-Made Special-Round Catalog

Source corpus inspected: `nZombies-Time/nZombies-Rezzurrection`, old/broken public snapshot.

**Licensing/provenance is not clean enough for direct source reuse in this project.**
This file records design breadth and balance patterns only.

## Generic registry discovered

The snapshot's special-round registry contains **56 named registrations**.

### Dedicated/special enemy waves

- Hellhounds
- Plague Hounds
- Hellhounds (Cold War)
- Pests
- Helldonkeys
- Keepers
- Apothicon Fury
- Nova Crawlers
- Radroaches
- Nova Bombers
- Poison Catalyst
- Plasma Catalyst
- Sizzler
- Water Catalyst
- Jolting Jacks
- Lickers
- Hunter Beta
- Tempest
- Raptors
- Facehuggers
- The Pack (Dead Space)
- Sentinel Bots
- Bomber Zombies
- Spiders
- Frogs
- Grenade Zombies
- Cloakers
- Spider Crawlers
- Xenomorphs
- Tickers
- Wretch
- Sire
- Husk
- Nemacyte
- Run Yo Pockets
- SS Fire Skeletons

### Normal-wave special mutations registered through same system

- Burning Zombies
- Burning Zombies (Ascension)
- Burning Zombies (Buried)
- Burning Clowns
- Burning Zombies (Call of the Dead)
- Burning Zombies (Der Eisendrache)
- Burning Zombies (FIVE)
- Burning Zombies (Gorod Krovi)
- Burning Zombies (TranZit)
- Burning Zombies (Hazmat)
- Burning Zombies (Moon)
- Burning Zombies (Mob of the Dead)
- Burning Zombies (Nuketown)
- Burning Zombies (Origins)
- Burning Zombies (Shangri-La)
- Burning Boney Bois
- Burning Zombies (Shadows of Evil)
- Burning Zombies (Shi no Numa)
- Burning Zombies (Templar)
- Burning Zombies (Zetsubou no Shima)

## Useful data pattern

Many dedicated specials share the same table shape:

- weighted enemy class list
- spawn-delay function based on player count
- count function based on round/player count
- per-spawn callback that changes health

Some later definitions clamp count and HP.

That tells us the engine needs:
- arbitrary curves/functions or curve IDs
- min/max caps
- weighted mixed composition
- spawn callback/event
- distinction between `specialTypes` and `normalTypes`-style usage

## Mixed-composition example pattern

One fan-made special wave uses three roles:
- runner
- ranged spitter
- brute

with different weights.

This is more valuable than making every special round mono-enemy. Our definition format must allow heterogeneous wave composition.

## Boss registry breadth

The same snapshot contains about **45 boss registrations**, including:

- Margwa
- Lambent Gunker
- Ubermorph
- Panzermorder
- Dilophosaurus
- Brute
- Swamp Warden
- Divider
- William Birkin forms
- Nemesis
- Boomer
- George Romero
- Licker/Hunter/Sentinel/Raptor boss variants
- Tank
- Fleshpound
- Tyrant
- Scrake
- Patriarch
- Gigan
- Mangler
- Avogadro
- Krasny Soldat
- Meuchler
- Panzer variants
- Cosmonaut variants
- Brutus
- Napalm Zombie
- Shrieker Zombie
- Thrasher

Again: these names/assets are reference material. The engineering takeaway is that a **registry + common encounter contract** scales much further than switch statements.

## Balance pattern worth adopting

Rather than copying exact health numbers:

```text
health = curve(base, round)
health = clamp(health, min?, max?)
count  = clamp(round * players * scalar, min, max)
delay  = clamp(base - players * acceleration, min, max)
```

Then let each special definition choose named curves.

## Our original equivalent catalog

For our own game we can create legally clean archetypes inspired by the combat roles rather than names/assets:

- Ember Hound
- Rot Hound
- Screecher
- Ceiling Skitter
- Web Stalker
- Acid Wasp
- Shock Drone
- Burrower
- Exploder
- Armored Brute
- Spitter
- Phase Stalker
- Swarmling
- Carrier
- Harvester
- Warden

All plug into the same registry.
