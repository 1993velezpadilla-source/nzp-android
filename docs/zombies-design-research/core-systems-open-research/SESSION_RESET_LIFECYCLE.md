# Session Reset / Lifecycle Contract

Round-based games accumulate a huge amount of transient state.
A restart that leaves even one timer, lease or callback alive can corrupt the next match.

## Reset must be a first-class operation

Do not rely on entity destruction side effects alone.

Define:

```text
GameSession
  sessionId
  state
  registries
  runtime systems
```

Every async action carries the current `sessionId`.

If callback fires for an old session:
- discard it

## Reset order

Suggested:

1. stop accepting new player transactions
2. mark session terminating
3. cancel quest timers
4. cancel PaP/Box/revive jobs
5. expire powerups
6. stop traps/hazards
7. remove enemies/projectiles
8. release spawn/window/item leases
9. clear drops
10. clear ragdolls/FX
11. restore map entities
12. reset power/doors/teleporters
13. reset player lifecycle/inventory
14. clear network transient ledgers
15. create new session ID

## Systems that must expose Reset()

- RoundDirector
- SpawnDirector
- SpecialRoundDirector
- BossDirector
- DropDirector
- Economy
- MysteryBox
- PaP
- Perks
- Revive
- QuestGraph
- Trap/Hazard
- PowerGrid
- Teleporters
- AI leases/path state
- AudioDirector
- FX pools

## Async callbacks

Common stale callbacks:
- timer after Box closes
- PaP ready timer
- delayed door animation
- revive completion
- powerup expiration
- quest timer
- delayed spawn
- boss phase delay
- audio end callback

Guard every one with:
`if callback.sessionId != currentSessionId -> ignore`

## Pool reset

Pools must return objects to neutral state:
- transforms
- ownership IDs
- timers
- materials
- status effects
- callbacks/listeners

A pooled projectile retaining old owner is a classic hidden bug.

## Network reset

Authority broadcasts:
`SessionReset(newSessionId, baselineState)`

Clients discard:
- old snapshots
- old reliable job events
- pending hit claims
- pending purchases

Packets tagged with old session are rejected.

## Tests

1. restart during PaP processing
2. restart during Box result
3. restart while player being revived
4. restart during special round
5. restart during active trap
6. restart during quest timer
7. stale packet from old session rejected
8. zero active leases/jobs/timers after reset
9. 50 repeated resets do not grow memory/entity count
10. first round after reset behaves identically to fresh process
