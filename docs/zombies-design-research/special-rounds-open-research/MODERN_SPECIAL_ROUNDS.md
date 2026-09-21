# Modern / Franchise Special-Round Catalog

Behavioral research only. This file tracks newer special-enemy patterns so the engine does not freeze its design around WaW/BO1–BO3.

## Common special-round contract

Across public documentation, special rounds remain commonly:
- shorter than normal zombie rounds
- built around a distinct enemy family
- recurring after a configurable interval
- announced with strong audio/visual identity
- often tied to a guaranteed utility/ammo reward

Our engine should keep those as **definition fields**, not hard-coded assumptions.

## Black Ops 6-era patterns

### Vermin
Combat role:
- low-health pack enemy
- bite + medium-range lunge
- can serve as dedicated special-round population
- can also appear infrequently in normal waves

Engine modules:
- `GroundChase`
- `LungeAttack`
- `SpecialRoundEligible`
- `NormalRoundMutation`

### Parasite
Combat role:
- air-domain ranged swarm
- projectile spit
- special-wave and non-special appearances depending on map

Engine modules:
- `AirSteering`
- `ProjectileAttack`
- air alive cap
- normal-round mutation

### Toxic Zombie
Combat role:
- otherwise zombie-like mover
- explosive/toxic death
- persistent hazardous puddle/area denial
- can replace the usual special-round family

Engine modules:
- `GroundChase`
- `DeathExplosion`
- `HazardVolumeOnDeath`
- pooled damage-over-time volume

### Kommando Klaus
Combat role:
- robotic special-wave enemy
- self-destruct behavior
- can drop quest-relevant parts
- special waves can therefore feed map quest state

Engine modules:
- `RushController`
- `SelfDestruct`
- `QuestDropTable`

Important lesson:
Special rounds may be both combat content **and quest progression sources**. Their loot events need a quest-safe server-authoritative hook.

## Black Ops 7-era patterns

### Ravager
Combat role:
- fast quadruped/pack hunter
- special round
- later normal-round mixing
- can interact with discarded world loot in its behavior

Engine modules:
- `QuadrupedChase`
- `WorldItemSense`
- `Burrow/Reposition` or special traversal ability
- normal-round mutation

### Rad-Hound
Combat role:
- hound-derived rush enemy
- low individual durability
- radioactive/explosive death identity

Engine modules:
- hound controller
- `DeathBurst`
- status/element tag

### Necropincer
This is a useful modern **elite/normal-wave** pattern rather than just a special-round replacement:
- melee stab/slam
- ranged trident throw
- defensive shield/block state
- weakpoint can break/disable defense
- begins entering normal waves after a round threshold

Engine lesson:
Our `EnemyArchetype` must support combining:
- melee
- ranged
- defense
- weakpoint/part state
- threshold-based normal-wave injection

## Why these matter

Older special enemies often changed only:
- speed
- health
- spawn style

Modern special enemies increasingly change:
- movement domain
- attack range
- weakpoints
- defense states
- death hazards
- interaction with loot/objectives
- quest drops
- evolution/transformation
- normal-round mutation

Therefore our enemy system must be **component-driven**, while SpecialRoundDirector only manages schedule/composition/completion.

## Capability matrix

| Archetype | Ground | Air | Ranged | Leap | Explode | Hazard | Weakpoint | Objective/World | Normal Mix |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Hound | yes | no | no | optional | optional | optional | optional | no | yes |
| Vermin | yes | no | no | yes | no | no | head | no | yes |
| Parasite | no | yes | yes | no | no | optional | head | no | yes |
| Toxic zombie | yes | no | no | no | yes | yes | head | no | map-dependent |
| Kommando-style robot | yes | optional | optional | no | yes | no | optional | quest drops | map-dependent |
| Ravager | yes | no | no | special traversal | optional | no | head | world loot | yes |
| Rad-Hound | yes | no | no | optional | yes | radiation effect | head | no | configurable |
| Necropincer-like elite | yes | no | yes | no | no | no | shield/core | no | yes |

## Engine requirement added by modern research

Add these reusable systems to the earlier checklist:

- [ ] persistent hazard-volume pool
- [ ] quest-safe enemy drop table
- [ ] world-item sensing/interaction
- [ ] defensive block/shield state
- [ ] multipart/weakpoint disable events
- [ ] enemy transformation/evolution hook
- [ ] special-round enemy -> normal-round mutation policy
- [ ] elemental/status tags independent of visual skin
