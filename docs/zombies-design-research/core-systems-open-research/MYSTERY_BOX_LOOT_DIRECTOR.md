# Mystery Box / Loot Director

## Open implementations

### nZombies Unlimited — MIT

Observed design:
- global weapon pool
- weapons can opt out of box
- weapon world models are cached
- map has multiple Mystery Box spawn points
- spawn points can be occupied or **reserved**
- random relocation chooses only free/unreserved points
- helper can create an additional box independently

Reservation is an important concurrency primitive.

### Der Koloss — MIT

Observed design:
- explicit Box state machine
- idle -> cycling -> ready/teddy -> reset
- world-display weapon is distinct from first-person viewmodel
- first two completed weapon spins cannot produce Teddy
- Teddy probability is a pure gameplay rule
- box tracks completed weapon spins

Separating gameplay selection from world presentation makes the system testable.

### IW4x behavior

Useful production ideas:
- fixed number of initial uses before first Teddy
- after first move, Fire Sale becomes eligible
- limited wonder weapons can be one-player-only
- “pity” protection can force a limited weapon after many unsuccessful box uses
- pity resets when guarantee is produced even if player declines the result

## Proposed state machine

```text
IDLE
  -> PURCHASED
  -> CYCLING
  -> RESULT_READY
      -> TAKEN -> CLOSING -> IDLE
      -> EXPIRED -> CLOSING -> IDLE
      -> TEDDY -> MOVING -> IDLE
```

Every transition is server-authoritative.

## BoxUse record

```text
BoxUse
  useId
  boxInstanceId
  buyerPlayerId
  pointsPaid
  selectedResult
  startedAt
  readyAt
  expiresAt
  state
```

This prevents:
- another player claiming the wrong result
- duplicate take packets
- reconnect confusion
- a delayed event from completing a newer box spin

## Loot selection pipeline

1. build eligible pool
2. remove map-disabled weapons
3. remove ownership-limited unavailable items
4. apply player-specific exclusions
5. apply quest/state restrictions
6. apply pity rule
7. weighted roll
8. reserve selected unique item if needed
9. publish immutable result

Do not reroll during presentation animation.

## Teddy / move logic

Map declares:
- box spawn anchors
- initial anchor
- blocked anchors
- relocation delay
- whether same anchor may repeat

Use a reservation during relocation.

Two boxes (for Fire Sale or custom maps) must not choose the same anchor accidentally unless allowed.

## Fire Sale

Treat Fire Sale as a **temporary spawn policy override**:

- instantiate/enable boxes at all eligible anchors
- price override
- duration
- on expiry, restore canonical single-box state

Do not mutate the permanent box location table destructively.

## Pity system

Optional original design:

```text
PityRule
  tag = "wonder"
  failureCount
  threshold
  eligiblePlayers? / teamShared?
  resetWhenGenerated
```

Keep it data-driven per map.

## Result timeout

If a weapon is not taken:
- box closes
- reservation/unique lease released if appropriate
- no refund unless map explicitly says so

## Tests

1. first-use Teddy policy enforced
2. occupied/reserved location cannot be selected
3. two simultaneous boxes cannot collide on same anchor
4. unique weapon cannot be generated twice
5. result cannot be stolen by wrong player if map disallows it
6. late take packet cannot claim next spin
7. pity threshold deterministic
8. Fire Sale expiration restores canonical box
9. disconnect mid-spin resolves/refunds according to policy
10. map reset clears every reservation
