# Zombie AI and Window Traversal

Primary upstream references:

- `source/server/ai/ai_core.qc`
- `source/server/ai/zombie_core.qc`
- `source/server/entities/window.qc`
- mapper `path_corner` contract from the NZ:P FGD

## High-level state machine

A practical clean implementation should model:

`Spawn -> OutsidePath -> WindowQueue -> WindowAttack -> WindowCross -> InsideChase -> AttackPlayer -> Dead`

Additional substates:

- ground rise
- crawler
- special attack
- stunned
- retargeting
- waiting for traversal reservation

## Path to window

Mapper `path_corner` entities provide a chain used while the zombie walks toward the window.

The window itself owns helper points and queue slots.

When the zombie's goal is a `window`, the AI switches behavior from normal walking/chasing into window-specific approach logic.

## Window reservations

NZ:P keeps three window “box owner” slots.

Behavior:

- if all three are free, first arriving zombie claims slot 1
- otherwise it tries slot 2
- then slot 3
- if all are occupied and zombie is close enough, it moves to the idle/wait point
- each claimed slot has a goal position
- timeout/reload-delay style logic helps prevent stale occupancy

This exists to prevent collision pileups and traversal races.

For our engine, implement explicit reservation tokens:

`WindowReservation { windowId, slotIndex, zombieId, acquiredAt }`

Release on:

- zombie death
- despawn
- retarget
- successful crossing
- timeout
- window/map reset

## Attacking boards

The zombie attack handler checks whether its goal is a window.

If yes, it invokes window damage rather than player damage.

Window damage:

- refuses to act when open/empty
- removes one board
- plays destroy sound/animation
- updates global damaged-window state

The zombie should not begin crossing while boards still block traversal.

## Crossing

NZ:P contains a dedicated hop/climb animation sequence and snaps/finishes at the window's `hop_spot`.

The exact animation frames are implementation detail; the useful contract is:

1. reserve crossing slot
2. align to approach point
3. play crossing animation / root motion
4. temporarily suppress ordinary chase logic
5. place/validate zombie at landing point
6. change outside/inside state
7. release reservation
8. reacquire normal target/path

For our engine, movement should be capsule-safe. Never rely on a final blind teleport if collision would place the zombie inside solid geometry.

## Start-inside / rise variants

Spawn flags allow zombies to:

- begin inactive
- rise from ground
- begin as already “inside”

These flags should initialize the AI state machine rather than create separate zombie classes.

## Why this matters for our first map

A Nacht-sized map will feel wrong if zombies simply path directly to players through openings.

The recognizable Zombies pacing comes from:

- exterior spawn
- constrained approach lane
- barricade stop
- board destruction
- serialized window crossing
- only then full interior pursuit

So the map blueprint should place spawn/path/window groups as a gameplay unit.

## Recommended map grouping

For each playable entry window:

- 1 barricade entity
- 1 interior landing point
- 1 waiting area
- 3 approach/attack slots generated or authored
- one or more exterior spawn points
- a valid exterior nav/path connection to the window
- zone id / activation conditions

## AI tests

1. Zombie with intact target window attacks boards, not player.
2. Multiple zombies serialize at a single window.
3. No two zombies own the same reservation.
4. Destroyed zombie immediately frees its slot.
5. Open window transitions zombie to cross state.
6. After crossing, zombie becomes an interior chaser.
7. Start-inside zombie skips exterior/window phase.
8. Ground-rise zombie cannot attack until rise completes.
9. Navigation failure triggers safe replan instead of permanent stall.
10. Network clients receive state/animation but cannot choose AI transitions.
