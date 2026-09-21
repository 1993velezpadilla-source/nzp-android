# Map Entity Contracts

Primary reference: `nzp-team/assets/source/maps/fgd/hl-nzp.fgd` and `tb-nzp.fgd`.

This is the mapper-facing contract we should preserve conceptually even if our final engine uses JSON, binary map metadata, glTF extras, or custom editor components instead of Quake entities.

## item_barricade

Meaning: zombie entry window / board barrier.

Fields exposed upstream:

- model
- skin
- starting boards
- maximum/repairable boards
- rebuild sound
- destroy sound
- spawn flag: no boards / not repairable
- transform/orientation

Runtime converts this into the barricade controller and generated approach/cross points.

## spawn_zombie

Meaning: zombie spawn point.

Spawn flags:

- `inactive`
- `ground rise`
- `start inside`

Useful runtime fields for us:

- id/UUID
- transform
- zone id
- enabled
- spawn style
- startsInside
- weight
- min/max round
- activation targets/tags
- nav entry reference
- optional window/route group

## path_corner

Meaning: path node for zombie exterior traversal toward a window.

Upstream supports:

- target -> next path node
- wait
- flag that can set the zombie as inside at a path transition

Our engine should turn map path chains into a validated graph at load time.

## trigger_activator

Meaning: mapper trigger that activates targeted spawn points.

Replace mutable classname tricks with direct handles/events.

Example normalized event:

`OnTriggerEntered -> SpawnDirector.EnableGroup("courtyard_east")`

## Zones / doors

NZ:P zoning checks current zone, adjacent zones and door state to decide which spawns remain eligible.

For our engine, maps should author:

- zone volumes
- zone adjacency graph
- door/gate edges
- spawn groups per zone
- window groups per zone
- player-zone membership

Opening a door updates traversal and spawn eligibility.

## Generic interactions

Upstream `trigger_interact` already demonstrates a useful reusable pattern:

- interaction prompt
- optional point cost
- look requirement
- use press
- insufficient-points handling
- sound
- target/action dispatch
- re-arm/disable behavior

This should become our generic InteractionComponent and can power:

- doors
- switches
- traps
- quest items
- ritual objects
- buildables
- Pack-a-Punch activators
- map-specific puzzles

## Suggested portable schema

Each map gameplay entity should contain:

```text
id
type
transform
zone
tags[]
properties{}
links[]
enabled
replicationPolicy
```

Avoid storing direct native pointers in serialized map data.

## Map validation at load

Reject/warn on:

- zombie spawn with no valid nav connection
- window with landing point inside solid geometry
- duplicate entity UUID
- path loop with no intended cycle marker
- trigger target that does not exist
- zone edge referencing missing door
- door connecting the same zone to itself accidentally
- spawn group with zero members
- repairable window with max boards <= 0
- window crossing width smaller than zombie capsule
- spawn inside player start volume

A validation pass is much cheaper than debugging a “zombie just stands there” report on-device.
