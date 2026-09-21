# Power Grid / Zones / Teleporters

Classic Zombies progression depends heavily on power, doors, room topology and unlock chains.

## Der Koloss — MIT

Useful implementation patterns found:

- map rooms are explicit topology data
- doors connect named rooms
- nav links preserve direction where needed (e.g. drops are not ladders)
- power is explicit map state
- power can open/enable previously sealed systems
- teleporters have explicit map definitions, room, floor/elevation and clearance
- teleporter prompt has states such as:
  - no power
  - charging
  - recharging
  - ready
- PaP can remain dormant until all required teleporters are linked
- map startup/preflight audits egress and structural invariants

A particularly useful lesson:
**teleporters are topology/gameplay objects, not decorative props.**
Their floor, room and clearance belong in data that validators can inspect.

## Power network

Do not use one global boolean forever.

Support:

```text
PowerCircuit
  id
  powered
  sourceNodes[]
  consumers[]
  prerequisites[]
```

Small maps can have one circuit.
Future maps can have:
- generators
- substations
- temporary power
- local outages
- quest-controlled circuits

## Consumer contract

A consumer declares:
- requiredCircuit
- behaviorWhenUnpowered
- behaviorOnPowerRestored

Consumers:
- perk machine
- PaP
- trap
- teleporter
- door
- light group
- elevator
- quest console

## Zones / rooms

Map topology:

```text
Zone
  id
  bounds/navGroup
  neighbors
  environmentProfile
  spawnGroups[]
```

Doors change graph connectivity.

SpawnDirector should use current open-zone graph, not Euclidean distance alone.

## Door opening

Opening a door must atomically:
1. debit points if needed
2. update door state
3. update zone graph
4. invalidate/rebuild relevant navigation cache
5. enable newly reachable spawn groups
6. emit quest/logic event
7. replicate state

## Teleporter state

```text
OFFLINE
READY_TO_LINK
LINKING
LINKED
CHARGING
READY
ACTIVE
COOLDOWN
```

Map can simplify this.

## Linking

A linked teleporter is persistent team state for the match.

Use stable ID and authority timestamp.

If PaP unlocks after N links:
```text
UnlockCondition = Count(linkedTeleporters) >= required
```

not hard-coded `teleLinks == 3`.

## Teleport destination safety

Before moving players:
- validate destination clear
- preserve team grouping policy
- resolve overlap
- prevent falling through unloaded geometry
- update room/zone immediately
- reconcile zombies/aggro if needed

## Teleporter side effects

Some maps may:
- kill nearby enemies
- revive players
- grant random powerup
- trigger quest event

Those are configurable output actions through logic graph.

## Tests

1. door updates zone graph once
2. one-way nav link never becomes reverse path
3. powered consumer cannot activate without circuit
4. all-link condition unlocks PaP once
5. teleporter destination clearance validated
6. join-in-progress receives linked/power state
7. reset returns circuits/links to initial state
8. map preflight catches teleporter at invalid elevation
9. closing/opening topology cannot strand spawn system
