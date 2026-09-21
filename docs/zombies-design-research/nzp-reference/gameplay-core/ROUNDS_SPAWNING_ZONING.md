# Rounds, Zombie Spawning, and Zoning

Primary upstream references:

- `source/server/rounds.qc`
- `source/server/ai/zombie_core.qc`
- `source/server/ai/zoning_core.qc`
- `source/server/entities/triggers.qc`
- `source/server/gamemodes/core.qc`

## Round lifecycle

NZ:P keeps the round director responsible for:

- round transition timing
- round type (normal / special)
- zombie total
- remaining zombies
- active zombies
- spawn cadence
- zombie health
- fog/special-round setup
- trap refresh
- round-end triggers
- achievements/mode callbacks

Our implementation should keep this logic server-authoritative.

## Zombie count

Classic normal-round baseline starts from **24** and applies a player/round multiplier.

Conceptually:

- base count = 24
- multiplier starts at `max(round / 5, 1)`
- from round 10 onward multiplier is further scaled by `round * 0.15`
- solo adds a smaller multiplier contribution
- multiplayer adds contribution per extra player
- early rounds are reduced:
  - round 1: 25%
  - round 2: 30%
  - round 3: 50%
  - round 4: 70%
  - round 5: 90%
- special/dog rounds use a separate player-count formula
- gamemode callback can replace/modify the result
- difficulty can further multiply the result

Important: preserve the **extension point**. Count calculation should not be hard-coded in UI or map scripts.

## Zombie health

Classic upstream formula:

- rounds <= 10:
  - `health = 50 + round * 100`
- rounds > 10:
  - start from 1040
  - multiply by **1.1** once for every round above 10

Then the active gamemode gets a final override callback.

For our engine, use a pure function:

`health = ZombieHealthForRound(round, mode, difficulty)`

and unit-test it independently.

## Spawn cadence

The upstream system keeps a zombie spawn timer and spawn delay.

Important extracted behavior:

- Round 1 starts around **2 seconds** between zombie spawns.
- Each new round reduces spawn delay by roughly **5%**.
- Lower bound: **0.08 s**.
- Actual spawn routine refuses to spawn until the timer expires.
- After a spawn, next spawn time is scheduled again.

Do not tie spawn cadence to framerate.

## Spawn pool

A map entity `spawn_zombie` is registered into the active spawn pool and assigned a contiguous `spawn_id`.

Spawn selection:

1. Ensure spawn timer is ready.
2. Ensure a reusable zombie entity/slot is available.
3. Pick a random active spawn id.
4. Resolve the corresponding active `spawn_zombie`.
5. Spawn the zombie.
6. Advance spawn timer.

The upstream code explicitly reassigns IDs when the active spawn set changes so random selection never targets a disabled hole.

For our runtime, prefer an explicit vector/list of active spawn handles instead of mutable numeric IDs.

## Map spawn flags

FGD exposes `spawn_zombie` flags:

- **1 = inactive**
- **2 = ground rise**
- **4 = start inside**

Represent them as named enum flags.

## Zoning

NZ:P can enable/disable zombie and dog spawn points based on the player's current zone and door connectivity.

Behavioral model:

- active class names:
  - `spawn_zombie`
  - `spawn_dog`
- inactive counterparts:
  - `spawn_zombie_disabled`
  - `spawn_dog_disabled`
- before recalculating, currently active spawns can be disabled
- the zone system examines current player zone, adjacent zones, and door state
- only reachable/appropriate zone spawns are reactivated
- active spawn IDs are rebuilt afterward

This is essential for map pacing: opening a door should alter where zombies may enter, not simply add geometry access.

## Trigger-based activation

`trigger_activator` can activate spawn points targeted by mapper wiring. Older map compatibility paths also transform `spawn_zombie_in` / `spawn_zombie_away` into active spawn points and then reassign IDs.

For our map layer, normalize all of these into:

`SpawnDirector.SetSpawnEnabled(spawnHandle, bool)`

No gameplay system should need to rename entity class strings at runtime.

## Active-zombie budget

Keep separate counters:

- total zombies scheduled this round
- zombies remaining to be killed
- zombies currently alive
- zombies not yet spawned

Do not use a single number for all four meanings.

Round completes only when the remaining/active conditions are satisfied and no delayed/special state is still pending.

## Spawn safety rules for our engine

Before accepting a spawn:

- spawn point must be active
- associated zone must be eligible
- nav route must be valid
- physical capsule must not be blocked
- avoid spawning directly inside player collision
- optionally reject points currently visible to players when map design requires hidden spawning
- respect global max-active-zombie budget
- use deterministic server RNG seed for multiplayer/replays if we add deterministic simulation

## Tests

1. Round 1 count matches formula.
2. 1P/2P/4P totals scale correctly.
3. Early-round reductions apply only to intended rounds.
4. Round 10/11 health transition is continuous enough and follows formula.
5. Spawn delay never falls below 0.08 s.
6. Spawn timer is frame-rate independent.
7. Disabled spawns are never selected.
8. Enabling/disabling a spawn cannot leave an invalid random index.
9. Opening/closing a zone gate changes eligible spawn set.
10. Inactive/ground-rise/start-inside flags produce correct spawn behavior.
11. No spawn when active-zombie pool is exhausted.
12. Round does not end while an eligible zombie is alive.
13. Multiplayer clients cannot authoritatively spawn zombies.
