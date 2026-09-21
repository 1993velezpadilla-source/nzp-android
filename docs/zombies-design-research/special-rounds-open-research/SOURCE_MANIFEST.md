# Source Manifest / Provenance

Snapshot research performed 2026-09-21.

## Clearly licensed open-source code

### NZ:P
Repository: `nzp-team/quakec`
License: GPL v2.
Covered separately by the NZ:P gameplay-core reference pack.

### nZombies
Repository: `Zet0rz/nzombies`
License file: `LICENSE.txt`
License: GPL v3.
License blob inspected: `ef7e7efc09c9d471c391f05b9567966928085840`

### nZombies Unlimited
Repository: `Zet0rz/nZombies-Unlimited`
License: MIT.
License blob inspected: `9aee9c66c6e687073f5804b9af354e4f8dda71e6`

Important paths:
- `gamemodes/nzombies-unlimited/gamemode/round.lua`
- `lua/nzombies-unlimited/core/entities_tools/spawnpoints_nzu.lua`
- README modular Extension architecture

### Der Koloss Community Edition
Repository: `rishipr/der-koloss-ce`
License: MIT for source code.
Assets have separate licensing; inspect `NOTICE.md`.

Inspected blobs:
- `js/game.js` — `239694c3a47e7bbd83ef08cdf359a99b29b55c13`
- `js/zombies.js` — `4de58e475227551df666bc852268bfab75cb64ac`
- `js/config.js` — `e19fbba8f1209cf53c930fc23cdc8c0d6f905509`
- `js/combat-rules.js` — `3b98d1060b3ca2ba4f4c248051d8a05d5b028f80`
- `LICENSE` — `c13a2ac87ce6851229abeed8ac9626ab29061e23`
- `NOTICE.md` — `3468fe9bd195792dda42952ade8a7afbdc5ed228`

## Source-available / reference-only unless terms clarified

### IW4x Zombies
Repository: `AmethystTower/iw4x-zombies`
README blob: `f88de45c5cfc180fbf8dc17d43b09ba0ed82afb0`

README describes the IW4x edition as open source and encourages modification. A conventional root license file was not resolved in this audit.

Use behavioral/architectural reference unless precise grant/attribution terms are confirmed.

### BO1 Reimagined
Repository: `Jbleezy/BO1-Reimagined`
`License.md` blob: `8d285e964d5adf2cc9d41f02e9e2a01de379f879`

The inspected license file contains warranty disclaimer language but no clear MIT/GPL-style permission grant in the text retrieved.

Reference only unless clarified.

### nZombies Rezzurrection
Repository: `nZombies-Time/nZombies-Rezzurrection`

Repository README says this public snapshot is old/broken.

Important inspected blobs:
- special-round registry:
  `gamemode/gamemodes/nzombies/gamemode/round/sh_special_round.lua`
  blob `858c5d30ac4a3acbc016ba4a6b7f01ab62a8c770`
- boss registry:
  `gamemode/gamemodes/nzombies/gamemode/round/sh_boss_round.lua`
  blob `f11bb135aa825ebef24eb9ff6f29f71e4abbd81b`
- special/normal spawn entity:
  `gamemode/gamemodes/nzombies/entities/entities/nz_spawn_zombie.lua`
  blob `2b855ef44ff45552bf95b7fa8848dc2be07b4b46`

No clean root license was resolved. Treat as behavioral architecture research.

### nZombies Chronicles
Repository: `Ethorbit/nzombies-chronicles`
Inspected as a public community successor/fork; repository observed archived in connector metadata.
Root license not resolved during this pass.
Reference only until provenance clarified.

## Proprietary/reverse-engineering behavior references

Public pages and community research were used to understand:
- Hellhound cadence/rewards
- Jumping Jack challenge reward
- Space Monkey objective-defense behavior
- Pentagon Thief outcomes
- Parasite flying swarm behavior
- Spider special-wave behavior
- Valkyrie weakpoint/self-destruct behavior
- exploding clown behavior

Some public GitHub repositories mirror generated/decompiled Call of Duty GSC. Those are **not** treated as reusable open-source code here.

Rule:
- summarize state machines
- write our own implementation
- do not copy proprietary scripts/assets

## Attribution discipline

Any future direct source import must record:
- repository
- commit/blob
- path
- license
- local destination
- modifications
- attribution requirement

Any asset import must be tracked separately from source-code licensing.
