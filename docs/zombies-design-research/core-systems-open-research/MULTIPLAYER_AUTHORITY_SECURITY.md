# Multiplayer Authority / Network Contracts

Der Koloss Community Edition provides a particularly useful MIT-licensed reference for small co-op Zombies networking.

## Topology lesson

Its co-op is host-authoritative:
- host runs zombie simulation
- clients send inputs / claims
- reliable ordered channel for important events
- unreliable channel for snapshots
- snapshots around 15 Hz
- voice separated from gameplay topology

For our engine, dedicated server or host-authoritative are both valid, but the rule is:

**clients never author economy, quest, zombie death, drops, perks, PaP, doors, or round progression.**

## Reliable vs snapshot state

Reliable:
- purchase result
- perk granted
- door opened
- quest step
- PaP job transitions
- down/revive
- special round start/end
- guaranteed reward

Unreliable snapshot:
- transforms
- animation state
- aim
- current zombie locomotion state
- cosmetic status

## Payload bounds

Der Koloss explicitly bounds network payload complexity and snapshot populations before hot-path processing.

We should have limits for:
- packet bytes
- nested object depth
- string length
- array length
- max players
- max enemies
- finite numeric ranges

Reject NaN/Inf.

## Client event allowlist

Maintain explicit tables:

```text
CLIENT_CAN_REQUEST
  move/input
  shoot
  interact
  purchase
  revive
  use item

AUTHORITY_ONLY_EVENTS
  points changed
  zombie spawned
  zombie died
  drop spawned
  perk granted
  quest progressed
  door opened
  round changed
```

A client never sends “I got 500 points.”

## Identity

Never trust player ID inside a client payload.

Connection/session identity supplies sender ID.

Der Koloss does this for remote perk animation: authenticated sender is the source, not client-supplied PID.

## Replay protection

Transactions need IDs.

Der Koloss uses single-use credit claim IDs and consumes them before deeper gameplay validation to prevent a late invalid packet from becoming valid later.

Apply same pattern to:
- purchases
- hit credits
- board repair credits
- quest item pickup
- box claim
- PaP claim

## Hit reconciliation

Host has a newer target position than the guest rendered.

Use bounded reconciliation:
- verify shot direction
- verify max distance
- verify host-side occlusion
- allow small spatial motion window
- special pellet spread cone
- never trust guest damage value

## Shotgun

One fire action can legitimately contain multiple pellet hit claims.

Rate-limit the **shot action**, while validating a bounded pellet budget for that shot.

Do not rate-limit individual pellet claims in a way that deletes legitimate pellets.

## Snapshots must not mutate reliable ownership

A high-frequency snapshot must not be allowed to change:
- weapon ownership
- PaP tier
- perks
- points
- quest inventory

Those are reliable authority state.

## Disconnect recovery

Need explicit cleanup for:
- PaP owner
- revive lease
- box use
- quest item reservations
- unique weapon lease
- active trap owner
- voice/session mapping

## Join in progress

Snapshot + reliable baseline must reconstruct:
- current round
- remaining enemies
- doors/power
- active powerups and expirations
- box location/state
- PaP machine state
- quest flags/items
- traps/events
- teammate down/perks/loadouts

## Tests

1. spoofed player ID ignored
2. client cannot send authority-only event
3. replayed purchase ID rejected
4. NaN/Inf payload rejected
5. oversized snapshot rejected
6. snapshot cannot change reliable loadout
7. host-side wall blocks claimed hit
8. shotgun pellet budget bounded
9. disconnect releases all leases
10. join-in-progress reconstructs gameplay without duplicate entities
