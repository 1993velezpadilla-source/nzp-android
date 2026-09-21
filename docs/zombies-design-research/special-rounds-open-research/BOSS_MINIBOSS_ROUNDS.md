# Boss / Miniboss Rounds

Boss scheduling must be a sibling of special-round scheduling, not a pile of checks inside normal enemy AI.

## Fan-made corpus

The inspected nZombies Rezzurrection snapshot contains a boss registry with roughly **45 registrations**, covering many radically different combat shapes:
- large melee heavies
- ranged bosses
- armored/mechanical enemies
- multipart creatures
- teleporting/arena bosses
- recurring minibosses
- round-specific bosses

The exact entities/assets are not the point. The registry proves a single round framework can drive very different boss implementations.

## BossDefinition

```text
BossDefinition
  id
  displayName
  archetypeId

  schedule
    firstEligibleRound
    recurrence
    explicitRounds
    prerequisites
    maxOccurrences

  spawn
    spawnGroup
    specialSpawnRequired
    amountAtOnce

  scaling
    baseHealth
    healthCurve
    damageCurve
    playerCountMultiplier

  encounter
    countsAsRound
    canMixWithNormalZombies
    blocksSpecialRound
    timeoutPolicy

  rewards
  introPresentation
  deathPresentation
```

## Separate “boss injection” from “boss round”

Two useful modes:

### Standalone Boss Round
Normal spawn budget paused/replaced.

### Boss Injection
Boss enters during an otherwise normal wave.

These have different completion semantics.

A boss injected into a normal round should be owned by the normal round but tagged as a boss encounter.

## Scheduler conflict

If boss and special round are both due:

Recommended:
- mandatory scripted encounter wins
- then boss
- then special
- deferred event rescheduled within bounded range

Never discard the delayed event.

## Miniboss budget

Avoid unbounded elite stacking.

Per definition:
- max bosses alive
- max elite “threat cost”
- spawn cooldown
- min distance from previous elite
- player-count scaling

Example threat budget:
```text
normal zombie = 1
special fast enemy = 2
heavy elite = 5
boss = 12
```

A wave can then keep CPU/difficulty bounded without knowing every enemy class.

## Multipart bosses

Need:
- part health / weakpoints
- parent encounter ID
- parts do not increment round population independently unless explicitly configured
- destruction events replicated reliably
- parent death cleans child entities/projectiles

## Summoners

A boss that creates adds must spend from an **add budget**.

Never let spawned adds recursively create unbounded round-owned population.

```text
BossAddBudget
  aliveCap
  totalCap
  respawnDelay
  countsTowardRoundCompletion
```

## Performance

Before boss appears:
- prewarm prefab
- prewarm particles
- prewarm boss audio
- compile/prepare shaders if platform needs it

On Android:
- LOD hierarchy
- bounded dynamic lights
- pooled projectiles
- pooled decals/FX
- animation update distance tiers

## Tests

1. Boss special collision defers one event rather than deleting it.
2. Standalone boss round cannot complete while boss alive.
3. Boss injected in normal round does not duplicate completion counters.
4. Summoned adds obey cap.
5. Boss death removes orphaned projectiles/child entities.
6. Multiplayer client cannot spawn boss.
7. Join-in-progress receives current boss state.
8. Boss state resets on map restart.
9. Boss assets prewarm without frame hitch.
10. Threat budget prevents impossible elite pileup.
