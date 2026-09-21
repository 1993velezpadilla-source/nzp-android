# Quest Logic / Easter Eggs / Buildables

## nZombies Unlimited — MIT

Its README describes a powerful graph-style logic system:

- Button -> Door
- Button -> Timer -> Zone -> Teleport
- Randomizer -> Item Spawners for buildable parts
- Soul Collector -> Game Win
- spawners themselves can be controlled

Its `logic_manager.lua` implements reusable logic units with:
- typed inputs
- outputs/connections
- settings
- entity-tying
- networked creation/sync
- dynamic connection/disconnection
- installable logic on entities

This is the right conceptual foundation for our map quests.

## Do not script every quest as one giant function

Create a graph/event runtime.

### LogicNode

```text
nodeId
type
settings
inputs
outputs
persistentState
authority
```

### LogicEdge

```text
sourceNode
sourcePort
targetNode
targetPort
condition?
transform?
```

## Initial node library

### Inputs / events
- InteractButton
- AreaEntered
- AreaExited
- EnemyKilled
- EnemyKilledInZone
- RoundStarted
- RoundEnded
- PowerOn
- DoorOpened
- ItemPickedUp
- BuildableCompleted
- BossKilled
- TimerElapsed
- PlayerCount
- AllPlayersPresent

### State / logic
- Counter
- BooleanLatch
- Sequence
- AND
- OR
- NOT
- Compare
- Randomizer
- Once
- Cooldown
- Timer
- Branch
- StateMachine

### World actions
- OpenDoor
- EnableSpawner
- DisableSpawner
- SpawnItem
- SpawnEnemy
- Teleport
- PlaySound
- PlayVO
- PlayFX
- ChangeFog/Lighting
- EnableTrap
- GivePoints
- GivePowerup
- SetQuestFlag
- StartBoss
- WinGame

## Buildables

Use generic definitions:

```text
BuildableDefinition
  id
  requiredPartTags[]
  stationId
  outputItemId
  consumeParts
  buildDuration
```

Parts are ordinary quest items with:
- unique instance/slot
- spawn pool
- pickup owner policy
- persistent team state

## Random part placement

Map defines groups:

```text
PartSpawnGroup
  groupId
  anchors[]
  chooseCount
```

At match start authority chooses seed + anchors once.

Clients receive the result.

Do not reroll when a player approaches.

## Team vs personal quest state

Every quest flag declares scope:
- match/team
- per-player
- per-character
- persistent account (future)

Most classic map Easter eggs are team state.

## Soul collector

Generic:
```text
SoulCollector
  zone
  eligibleEnemyTags
  requiredKills
  creditRule
```

Credit can require:
- death inside radius
- killer inside radius
- specific weapon
- special condition

Never infer from VFX alone.

## Sequence robustness

Quest graphs must handle:
- event arriving twice
- player disconnect
- item destroyed
- round transition
- map reset
- join in progress
- host migration if ever supported

Use idempotent nodes:
A Once node that has fired stays fired.

## Save/debug tooling

Developer overlay should show:
- current quest state
- node states
- counters
- active timers
- held items
- last event
- blocked condition reason

This will save enormous debugging time on complex maps.

## Proprietary script research

Publicly mirrored/generated Call of Duty GSC can reveal behavioral sequencing, but we should not copy proprietary script source into our engine.

Use it only to derive:
- node types
- state transitions
- edge cases
- test scenarios

Then implement our own graph system.

## Tests

1. double event cannot advance sequence twice
2. random part placement deterministic from seed
3. reconnect receives current quest flags/items
4. buildable consumes exactly required parts
5. item cannot be duplicated by simultaneous pickup
6. Soul Collector credits eligible kills only
7. WinGame can fire once
8. map reset clears transient quest state
9. disabled spawner cannot spawn through stale ticket
10. quest graph can be validated for missing node references before map starts
