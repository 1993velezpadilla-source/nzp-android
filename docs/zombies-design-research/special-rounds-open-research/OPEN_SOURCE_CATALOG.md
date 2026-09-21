# Open / Fan-Made Source Catalog

## 1. NZ:P

Repository: `nzp-team/quakec`

License: GNU GPL v2.

Best research areas:
- classic round calculation
- Hellhound rounds
- zombie/dog spawn points
- window traversal
- zoning
- points and powerups

Already extracted in:
`docs/zombies-design-research/nzp-reference/gameplay-core/`

---

## 2. nZombies

Repository: `Zet0rz/nzombies`

License: GNU GPL v3 (`LICENSE.txt`).

Useful properties:
- mapper can choose boss/special rounds
- door-aware navigation
- creative/config authoring
- zombie/boss variants
- modular map mechanics
- multiplayer-oriented Garry's Mod implementation

Use as a copyleft architectural/code reference with GPL obligations respected if code is directly reused.

---

## 3. nZombies Unlimited

Repository: `Zet0rz/nZombies-Unlimited`

License: MIT.

This is architecturally important because it was intentionally rebuilt around modularity.

Useful systems:
- Extensions can add Zombies and Bosses.
- Spawn points have queues when occupied.
- Spawner distribution can divide a wave across active spawn points.
- Round owns registered zombies explicitly.
- Logic system can control spawners and map mechanics.
- Configs choose which extensions are enabled.

Caveat: its current core source explicitly notes that full Special Round support was still future work in that branch. We should therefore use **its modular framework and spawner design**, not assume it is the canonical implementation of finished special rounds.

---

## 4. Der Koloss Community Edition

Repository: `rishipr/der-koloss-ce`

License: MIT for source code; assets have separate terms in `NOTICE.md`.

Important source:
- `js/game.js`
- `js/zombies.js`
- `js/config.js`
- `js/combat-rules.js`

Useful Hellhound design:
- explicit `dogRound` state
- next-dog-round scheduling function
- player-scaled dog count
- separate dog spawn behavior
- dogs do not use boarded-window traversal
- dog-round-specific fog/audio/HUD
- final-dog reward is guarded against duplicate callbacks
- host is gameplay authority in co-op
- reset clears next/last dog-round state

Interesting implementation:
- first standard dog round is anchored around round 5
- later dog rounds schedule 5–7 rounds after the previous
- a late-start/debug game anchors the first special wave a few rounds after the start instead of losing dog rounds forever
- dog count is capped
- special hound geometry is prewarmed during transition to avoid first-spawn hitch

These are implementation ideas, not mandatory balance values for our game.

---

## 5. IW4x Zombies / MW2: Reimagined Zombies

Repository: `AmethystTower/iw4x-zombies`

README calls the IW4x version open source and explicitly invites downloading/modifying it. A conventional root LICENSE was not found during this audit.

Treat as **source-available/reference until exact redistribution terms are verified**.

Useful behavior:
- Hellhound-only special rounds
- dogs are faster but less durable/damaging
- burning dog variant/explosion
- guaranteed Max Ammo after special wave
- later normal rounds can replace a percentage of normal zombies with dogs
- up to 8-player-oriented balancing
- complex navigation / jumping / climbing

Architecture lesson:
A special enemy does not need to remain special-wave-only forever. The same archetype can have:
- `specialRoundEligible`
- `normalRoundMixStart`
- `normalReplacementChance`

---

## 6. BO1 Reimagined

Repository: `Jbleezy/BO1-Reimagined`

Its `License.md` contains warranty/disclaimer language but, in the version inspected, did not present a normal explicit permission grant comparable to MIT/GPL.

Treat as **behavior/reference only unless licensing is clarified**.

Useful Hellhound observations:
- first dog round deliberately fixed to round 5 or 6
- 4- vs 5-round gaps were rebalanced
- later mid-round dogs
- dog health tuned per recurring special wave
- fire/explosion behavior
- bugs around prematurely completing dog rounds demonstrate why spawned-special enemies need round ownership

---

## 7. nZombies Rezzurrection

Repository: `nZombies-Time/nZombies-Rezzurrection`

The repository itself labels this version old/broken. No root license was found in this audit. It is an edited descendant of older nZombies code.

Treat as **architecture/reference only unless provenance and licensing are resolved**.

Despite that caution, it is an extremely useful research corpus because it contains:
- generic special-round registry
- generic boss registry
- weighted enemy compositions
- normal/special spawn pools
- spawn callbacks
- count/delay modifiers
- special-round Max Ammo behavior
- dozens of fan-made enemy types

The design concepts are worth reproducing in our own clean implementation.

---

## 8. nZombies Chronicles

Repository: `Ethorbit/nzombies-chronicles`

Community successor/fork with zombie/boss variants, spawners, multiplayer fixes and performance/security work.

The inspected repository was archived and a root license file was not resolved during this pass. Use as reference until provenance is verified.

---

# Reuse policy for our project

### Green: direct study/reimplementation friendly
- MIT sources: nZombies Unlimited, Der Koloss source code
- our own clean implementation derived from public behavior

### Yellow: copyleft
- NZ:P GPLv2
- nZombies GPLv3

Direct copying can impose distribution/source obligations. Keep provenance.

### Red/reference only until clarified
- repositories with no clear license grant
- old derivative repositories with uncertain attribution
- decompiled/generated/leaked proprietary Call of Duty scripts
- ripped proprietary assets

For Red sources, capture **behavioral contracts and tests**, not copied source.
