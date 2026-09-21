# Round Stall / Stuck Enemy Recovery

A round-based survival game has a hard requirement:

**every round must eventually end if players can still kill enemies.**

One unreachable or logically leaked enemy can ruin an entire run.

## Real failure patterns found in open source

Der Koloss documents several production-style failures:

- a window occupancy claim remained held after the claiming zombie was removed through a path that did not run normal cleanup
- once every window became falsely occupied, waves fell back to undesirable spawn behavior
- a relocated zombie could still hold a live window claim forever
- zombies wedged in door/wall geometry could remain alive and stall a round
- a naive global “not close enough to player after N seconds” watchdog teleported legitimate long-distance pathing zombies
- a progress detector that fired whenever the target distance was not shrinking punished enemies correctly taking the long route around obstacles

These are exactly the bugs we need to design out.

## Resource leases

Window/spawn ownership should be a lease:

```text
SpawnLease
  resourceId
  enemyId
  acquiredAt
  expiresAt?
```

Release on:
- enemy death
- enemy crosses window
- enemy respawn/relocation
- enemy removed
- round reset

Additionally, run periodic self-healing:
if lease owner entity does not exist, reclaim lease.

## Progress tracking

Do not define “progress” only as distance-to-player shrinking.

Track:
- actual movement distance
- path waypoint advancement
- nav cell changes
- interaction progress (breaking boards)
- vertical movement
- recent valid attack/target contact

```text
EnemyProgress
  lastPosition
  distanceTravelledWindow
  lastWaypointIndex
  lastMeaningfulProgressAt
```

## Recovery ladder

Use least disruptive fix first.

### Level 1 — Repath
If stuck briefly:
- invalidate current path
- compute a new path

### Level 2 — Local depenetration
If inside geometry:
- find nearest valid nav cell/local clear position
- move only enough to become valid

### Level 3 — Release stale interaction lease
If enemy abandoned/was relocated away from window:
- release its barricade/spawn reservation

### Level 4 — Controlled respawn
If no meaningful progress for a long bounded interval:
- issue replacement spawn ticket near reachable player area
- preserve round ownership
- destroy old entity only after replacement accepted

### Level 5 — Fail-safe refund
If no legal spawn exists:
- refund/requeue enemy population ticket
- never leave an unkillable invisible round count

## Round population invariant

At all times:

```text
remaining =
  authoritativeAlive
  + pendingSpawnTickets
```

Every enemy/ticket transition must preserve the total.

No path should silently increment/decrement twice.

## Respawn safety

Respawn target:
- legal zone
- reachable
- adequate collision clearance
- correct elevation policy
- not directly inside player
- compatible with enemy movement domain

## Player fairness

Recovery teleport/respawn should prefer:
- out of immediate line of sight
- outside minimum attack distance
- not behind player at point-blank range

The system exists to unstick gameplay, not punish the player.

## Debug overlay

Show:
- enemy ID
- round ID
- current state
- current target
- path status
- stuck time
- last meaningful progress
- held leases
- pending respawn ticket

## Tests

1. deleting enemy through abnormal path releases window lease
2. relocation releases old barricade claim
3. legitimate long route does not trigger teleport
4. door-closing wedge depenetrates locally
5. impossible enemy is eventually replaced
6. replacement preserves round population exactly
7. no replacement spawns inside player
8. reset leaves zero leases/tickets
9. 100 simulated rounds never hang
10. every round reports zero alive + zero pending at completion
