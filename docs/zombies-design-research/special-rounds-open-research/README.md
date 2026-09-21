# Special Rounds / Alternate Enemy Waves — Open Research Pack

Purpose: expand the NZ:P gameplay-core research into a reusable design library for **special rounds, alternate enemy waves, flying swarms, minibosses and boss scheduling**.

This pack combines:

1. Open-source/fan-made implementations whose architecture can be studied.
2. Publicly documented behavior from successful round-based Zombies games.
3. Reverse-engineering/community findings used only as behavioral reference where source licensing is not suitable for reuse.

## Core conclusion

Do **not** implement one engine subsystem per enemy family.

The engine should own one generic system:

`SpecialRoundDefinition -> SpecialRoundDirector -> EnemyArchetypeRegistry -> SpawnDirector`

A map/config then declares whether a special wave contains:

- Hellhounds
- Plague/Fire Hounds
- flying Parasite-style bugs
- spiders/crawlers
- teleporting/leaping enemies
- suicide bombers / rolling elementals
- drones
- objective attackers
- thieves
- mixed compositions
- minibosses
- full boss encounters

without changing RoundDirector code.

## Pack contents

- `OPEN_SOURCE_CATALOG.md` — repositories, usefulness and license status.
- `SPECIAL_ROUND_ARCHITECTURE.md` — proposed generic runtime/data model.
- `HELLHOUND_DOG_ROUNDS.md` — dog-wave behavior across independent implementations.
- `FLYING_SWARM_ROUNDS.md` — Parasite/"mosquito"/flying bug architecture.
- `SPECIAL_ENEMY_ARCHETYPES.md` — spiders, teleporters, drones, suicide enemies, objective attackers, thieves and mixed rounds.
- `BOSS_MINIBOSS_ROUNDS.md` — boss scheduling and conflict rules.
- `FANMADE_SPECIAL_CATALOG.md` — large fan-made registry found in nZombies Rezzurrection.
- `OFFICIAL_BEHAVIOR_REFERENCE.md` — useful documented patterns from official Zombies games; behavioral reference only.
- `MODERN_SPECIAL_ROUNDS.md` — BO6/BO7-era mechanics: Vermin, Toxic enemies, Kommando-style robots, Ravagers, Rad-Hounds and modern elite patterns.
- `IMPLEMENTATION_CHECKLIST.md` — engine gate and tests.
- `SOURCE_MANIFEST.md` — provenance, source files and licensing cautions.

## Strongest reusable sources

### nZombies Unlimited
MIT licensed. Especially useful for:
- modular extensions
- spawn queues
- round ownership
- spawner distribution
- logic-map composition
- adding new zombies/bosses without hard-coding the core

### Der Koloss Community Edition
MIT source code. Especially useful for:
- compact modern JavaScript implementation
- host-authoritative multiplayer
- dedicated Hellhound round state
- explicit dog-round scheduling/count functions
- hound-specific spawn restrictions
- guaranteed final-dog reward guard
- validators around gameplay/network invariants

### nZombies
GPLv3. Especially useful for:
- mature Garry's Mod Zombies architecture
- special/boss round configuration
- mapper-driven content
- navigation and door locking

### NZ:P
GPLv2. Already covered by the sibling NZ:P reference pack. Useful baseline for classic rounds, dogs, windows, score, spawning and zoning.

## Reference-only sources

Some public repositories contain valuable behavior but do not expose a clean reusable license grant, or are old derivatives with uncertain provenance. Their source is treated here as **reference**, not code to paste into our engine.

Likewise, leaked/decompiled/generated Call of Duty scripts are **behavioral research only**. We use them to understand state machines and edge cases, never as source material for direct copying.

## Design rule

Our implementation should be original, data-driven and platform-neutral.

A special enemy definition should say **what it does**. Android/desktop rendering, animation and audio should be replaceable implementations behind that gameplay contract.
