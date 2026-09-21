# Generic Special Round Architecture

## Goal

One engine system must be capable of expressing:

- pure Hellhound waves
- flying bug/Parasite swarms
- spiders
- teleporters
- suicide enemies
- objective-defense rounds
- one-enemy thief encounters
- mixed special enemy rosters
- a normal zombie wave with special enemies injected
- miniboss injections
- standalone boss rounds

without adding a new hard-coded round type.

## Data model

Recommended conceptual schema:

```text
SpecialRoundDefinition
  id
  displayName

  schedule
    earliestRound
    firstRoundRange
    recurrenceMin
    recurrenceMax
    explicitRounds[]
    prerequisiteTags[]
    exclusionTags[]

  composition[]
    enemyArchetypeId
    weight
    minRound
    maxRound
    minAlive
    maxAlive

  countPolicy
  aliveCapPolicy
  spawnDelayPolicy
  healthScalePolicy
  damageScalePolicy
  speedScalePolicy

  spawnProfile
    allowedSpawnGroups[]
    movementDomain       // ground, air, wall, ceiling, teleport
    canUseWindows
    canUseRisers
    visibilityRules

  presentation
    introCue
    announcerCue
    fogProfile
    colorGrade
    ambientProfile
    hudLabel

  rewards
    guaranteed[]
    performanceChallenges[]

  normalRoundMix
    enabled
    startRound
    replacementChance
    maxAlive
    cooldown

  callbacks/events
    roundStart
    enemySpawn
    enemyDeath
    objectiveChanged
    roundComplete
```

## Runtime authorities

### RoundDirector
Chooses whether the next round is:
- normal
- special
- boss
- scripted/quest

It does **not** know how a Parasite flies or a dog attacks.

### SpecialRoundDirector
Instantiates the selected definition and owns:
- total count
- spawned count
- alive count
- completion condition
- challenge state
- guaranteed reward
- round presentation state

### EnemyArchetypeRegistry
Maps IDs to behavior components/prefabs.

Examples:
- `rush_hound`
- `flyer_spitter`
- `crawler_webber`
- `teleporter_leaper`
- `suicide_charger`
- `objective_attacker`
- `weapon_thief`
- `weakpoint_drone`

### SpawnDirector
Receives a **movement-domain-specific** spawn request.

It owns separate eligible pools for:
- ground/navmesh
- riser
- window exterior
- air volume
- ceiling
- scripted teleport
- boss arena

## Round ownership

Every enemy spawned for a round gets:

```text
roundInstanceId
spawnTicketId
enemyArchetypeId
countsTowardCompletion
specialRoundId?
bossEncounterId?
```

This prevents classic bugs where:
- a teleporter-spawned dog dies and prematurely advances a dog round
- normal-round specials get counted as special-round enemies
- delayed projectile/minion entities block a round forever
- respawned/replaced enemies get counted twice

## Completion contract

Never complete a special wave from “alive enemies == 0” alone.

Require:

```text
spawnBudgetExhausted
AND authoritativeEnemiesAlive == 0
AND pendingSpawnTickets == 0
AND requiredObjectivesComplete
AND no scripted hold remains
```

## Reward guard

Guaranteed final-wave rewards need a one-shot token:

```text
RewardGate
  roundInstanceId
  rewardId
  committed=false
```

The server atomically commits it before spawning the reward.

This directly avoids duplicate Max Ammo when simultaneous death callbacks occur.

## Scheduler

Use a schedule object rather than magic round checks.

Examples:

### Classic dog style
- first: 5–6
- recur: +4–7

### Fixed cadence
- first: 5–7
- recur: +5

### Staged mixed specials
- first wave A
- second wave B
- third wave A+B
- then random interval

### Triggered special
- only once power is on
- only once player has a perk
- only after quest state
- only after a particular room opens

## Conflict resolver

Boss and special waves need explicit priority.

Suggested:

1. mandatory quest/script round
2. scheduled boss
3. scheduled special
4. normal round

If two collide:
- preserve the loser as `deferredRound`
- do not silently discard it
- reschedule using a bounded delay

## Determinism

For multiplayer:
- server/host chooses round type and RNG seed
- weighted composition is resolved server-side
- clients receive selected definition + authoritative events
- clients never independently decide which special enemy spawns

## Performance

Special rounds often create burstier AI loads than normal rounds.

Require:
- prefab/model/audio prewarm during intermission
- bounded alive cap
- pooled FX
- pooled projectile objects
- no path allocations in per-frame hot loop
- staggered target/path replans
- air-navigation spatial hash rather than all-vs-all avoidance

## Modding goal

Eventually a new special round should be addable by a JSON/data file plus enemy prefab registration, with zero changes to RoundDirector.
