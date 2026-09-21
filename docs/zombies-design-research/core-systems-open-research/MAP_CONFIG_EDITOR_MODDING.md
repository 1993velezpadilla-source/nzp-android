# Map Config / Editor / Modding Architecture

## nZombies Unlimited — MIT

Its architecture separates the engine from map Configs and extensions.

Important ideas:
- Sandbox-based map authoring
- configs save world entities and metadata
- configs can declare addon dependencies
- logic graph is editable independently of engine code
- extensions can add perks, powerups, zombies, bosses and whole systems
- map authors can control spawners and interactions through logic

This is exactly the direction our portable engine should take.

## Map package

Recommended:

```text
MapPackage/
  map.json
  geometry/
  nav/
  entities.json
  spawns.json
  logic.json
  quests.json
  audio.json
  lighting.json
  assets.json
  manifest.json
```

No map-specific code should be required for ordinary features.

## Map manifest

```text
id
version
authors
license
engineMinVersion
dependencies[]
assetPacks[]
entryScene
checksum
```

## Entity definitions

Map entities reference stable engine types:
- door
- debris
- barricade
- zombie spawn
- special spawn
- air volume
- player spawn
- box anchor
- wall buy
- perk machine
- PaP
- trap
- quest item
- build station
- logic trigger
- audio emitter
- FX emitter

## Extension registry

Engine exposes registries:
- EnemyArchetype
- Powerup
- Perk
- Weapon
- Trap
- LogicNode
- Interaction
- SpawnProfile

A mod package can register new data/components without patching RoundDirector.

## Dependency mismatch

nZombies contains a useful “mismatch correction” concept: when a config expects content the user does not have, the system can identify missing weapon/perk/etc. references.

Our loader should:
1. validate manifest
2. resolve dependencies
3. report missing IDs before gameplay
4. optionally map compatible substitutions
5. never silently spawn null entities

## Editor requirements

Eventually expose:
- place/move entities
- spawn groups
- zone links
- doors
- nav preview
- quest/logic graph
- fog/weather/lighting
- audio zones
- special-round selection
- boss schedule
- validation warnings

Mobile can use simplified placement; desktop can be full editor.

## Preflight validator

Before map starts, verify:
- every referenced asset exists
- every entity ID unique
- every logic edge resolves
- every door opens valid zones
- every spawn has legal nav/air domain
- at least one player spawn
- round spawn network can reach player zones
- required quest/buildable parts have enough anchors
- box has legal anchor
- PaP/required objective references resolve

## Versioning

Map data needs migration.

```text
schemaVersion
engineVersion
```

Provide explicit migrations:
`v4 -> v5`

Never reinterpret old fields silently.

## Licensing manifest

Every asset pack tracks:
- source URL/repository
- author
- license
- attribution text
- modification status
- commercial-use allowance

Keep code license separate from asset license.

## Tests

1. missing dependency fails before match
2. duplicate entity IDs rejected
3. bad logic edge rejected
4. old schema migrates deterministically
5. map reset restores initial entity state
6. map package contains no absolute device paths
7. Android path/case behavior tested
8. asset manifest catches prohibited/unlicensed content
