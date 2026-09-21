# NZ:P Gameplay Core Reference Pack

Purpose: capture the **gameplay knowledge and contracts** from the upstream NZ:P implementation that we need when building/porting our own Zombies runtime. This pack is intentionally a *reference/design extraction*, not a blind copy of the upstream source.

## Covered systems

- Round/wave lifecycle
- Zombie count + health scaling
- Zombie spawn scheduling and spawn-point activation
- Zone/door-aware spawn enable/disable
- Zombie pathing toward barricaded windows
- Window/barricade board state machine
- Zombie board removal + window crossing
- Player barrier rebuild + rebuild score
- Carpenter integration
- Central points/economy pipeline
- Damage/hit/kill scoring
- Double Points behavior
- Mapper entity contract (FGD + .map)
- Porting checklist and tests

## Upstream repositories

Gameplay logic:
- `nzp-team/quakec`
- License file: GNU GPL v2
- Important source paths:
  - `source/server/rounds.qc`
  - `source/server/ai/zombie_core.qc`
  - `source/server/ai/ai_core.qc`
  - `source/server/ai/zoning_core.qc`
  - `source/server/entities/window.qc`
  - `source/server/entities/powerups.qc`
  - `source/server/player/player_core.qc`
  - `source/server/damage.qc`
  - `source/server/entities/triggers.qc`
  - `source/server/gamemodes/core.qc`

Mapper/assets reference:
- `nzp-team/assets`
- License file: CC BY-SA 4.0
- Important source paths:
  - `source/maps/fgd/hl-nzp.fgd`
  - `source/maps/fgd/tb-nzp.fgd`
  - `source/maps/template.map`
  - production map `.map` files containing `item_barricade`, `spawn_zombie`, `path_corner`, zones and door targets.

## Design principle for our engine

Keep these as separate authorities:

1. **RoundDirector** — round number, zombie budget, spawn cadence, special-round type.
2. **SpawnDirector** — active spawn set, random/weighted selection, per-zone activation.
3. **ZombieController** — behavior/navigation/combat.
4. **BarricadeController** — board count, damage, rebuild, crossing slots.
5. **ScoreService** — the only place allowed to add/remove points.
6. **PowerupService** — Double Points, Carpenter and other temporary rules.
7. **MapEntityLayer** — converts map entities into runtime contracts.
8. **Replication/UI layer** — mirrors round/points/barricade state to clients; does not own gameplay truth.

The most important lesson from NZ:P is that windows, zombie routing, scoring, rounds, and zoning are **not isolated features**. Their state is cross-linked. Reimplement the contracts, not just the visible animation.

See the sibling files in this folder for the extracted behavior and implementation checklist.
