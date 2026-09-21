# Barricades / Windows

Upstream primary reference: `nzp-team/quakec/source/server/entities/window.qc`.

## Runtime entity

NZ:P maps author a point entity named `item_barricade`, which becomes runtime classname `window`.

Default behavior:

- Maximum board count: **6**
- Default starting boards: **6**
- `health` = current board state
- `health_delay` = maximum/repairable board count
- Special spawn flag: **No boards / Not Repairable**
- Default rebuild prompt: “Hold [use] to Rebuild Barrier”
- Separate rebuild and destroy sounds
- Trigger-sized interaction volume around the window

The mapper can start a barricade with fewer than 6 boards and can independently cap how many can be repaired.

## Destruction state machine

Each zombie attack removes one board/state:

`6 -> 5 -> 4 -> 3 -> 2 -> 1 -> 0`

At each step the window plays a destruction animation. On the first transition from fully intact to damaged, NZ:P increments its global “windows down” tracker.

A window at 0 boards can no longer lose another board.

### Required engine state

For our runtime, store explicitly:

- `currentBoards`
- `maxRepairableBoards`
- `repairable`
- `destroyedOrOpen`
- `lastRepairTime`
- `reservedZombieSlots[3]`
- `idleWaitPoint`
- `crossingLandingPoint`
- `repairingPlayer` (transient)
- `carpenterLocked` / automatic-repair state

Do **not** derive gameplay truth from animation frame numbers.

## Player rebuild

When a living player is inside the barricade interaction trigger:

1. Show rebuild use prompt if `currentBoards < maxRepairableBoards`.
2. Require the use button.
3. Enforce the rebuild cadence.
4. Play the rebuild animation/sound.
5. Add one board.
6. Award rebuild score if that player's current-round rebuild cap is not exhausted.

NZ:P base rebuild cadence is approximately **0.75 s per board**.

Speed Cola changes the rebuild animation path to a faster sequence. In our implementation that should be represented as a gameplay multiplier/cadence modifier, not hard-wired animation frame logic.

## Rebuild score

NZ:P awards:

- **10 points per repaired board**
- subject to Double Points when the score call requests it
- subject to the current round's rebuild-score cap
- disabled in modes/modifiers where miscellaneous score earning is disabled

Per-round cap:

`min(50 * round, 500)`

Examples:
- Round 1 -> 50 point cap
- Round 5 -> 250
- Round 10+ -> 500

Keep **board state** and **reward eligibility** independent: a player may still repair after reaching the reward cap.

## Zombie approach geometry

The window generates multiple helper positions from its origin/orientation:

- `box1`
- `box2`
- `box3`
- `idlebox`
- `hop_spot`

These are not decorative. They serialize multiple zombies approaching one barricade and give the AI a deterministic crossing destination.

NZ:P reserves up to **3 approach slots**. If all three are occupied, another zombie waits at the idle point.

This avoids several zombies trying to occupy/cross the same exact point simultaneously.

### Porting rule

Our engine should model this as a small **WindowTraversalQueue**:

- 3 attack/crossing reservations
- 1 waiting queue/area
- reservation released when zombie dies, retargets, crosses, or times out
- stale reservation watchdog
- no hard dependency on render/model state

## Zombie attack integration

When a zombie's goal entity is a window, its attack path calls the window damage routine instead of damaging a player.

Required logic:

- If window has boards: attack removes one board.
- If board count reaches zero: transition zombie from “outside/window attack” to crossing.
- During crossing: temporarily suppress normal chase/attack transitions.
- After crossing landing: release window slot, mark zombie “inside”, resume regular target acquisition.

The original code contains special handling to avoid race conditions where a newly spawned zombie steals a crossing slot from a zombie already using it. Preserve that intent.

## Carpenter

Carpenter automatically repairs damaged windows.

NZ:P behavior includes:

- Power-up only considered useful once enough windows are down.
- A watcher entity iterates damaged windows.
- Windows are temporarily marked while being auto-repaired.
- Repair animation/sound is applied until full.
- On completion, window reservation/temporary state is reset.
- Players receive a Carpenter completion reward through the central score service.

See `POINTS_ECONOMY.md`.

## Tests we should require

1. 6 zombie hits reduce a fresh window to 0.
2. 7th hit does nothing.
3. Player can rebuild exactly up to max repairable boards.
4. Non-repairable window never exposes rebuild action.
5. Reward cap does not prevent physical repair.
6. Double Points affects eligible repair reward.
7. Speed Cola changes repair cadence without changing board accounting.
8. Three zombies can reserve separate window approach slots.
9. Fourth zombie waits instead of overlapping.
10. Zombie death releases reservation.
11. Zombie crosses only after window is sufficiently open.
12. Carpenter fully repairs every eligible damaged window.
13. Carpenter cannot leave stale reservations/locks.
14. Map reload/reset restores board and reservation state deterministically.
15. Multiplayer: server owns board state; clients only animate replicated transitions.
