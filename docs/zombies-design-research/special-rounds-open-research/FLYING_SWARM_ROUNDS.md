# Flying Swarm Rounds — Parasite / “Mosquito” / Giant Bug Pattern

The user's “flying mosquito / giant bug wave” maps cleanly to the **flying swarm special-round archetype** exemplified by Parasite-style enemies.

We should build this as a generic air-domain system, not one hard-coded creature.

## Behavior pattern

Public analysis of flying Parasite waves shows a strong recurring structure:

- dedicated special wave
- separate flying spawn anchors
- flying enemies maintain range rather than behaving like ground melee zombies
- projectile attack
- rapid spawn cadence
- player-count-scaled total
- explicit maximum simultaneously alive
- special fog/color/audio
- guaranteed end reward
- later ability to mix the flyer into normal rounds

Community/reverse-engineering analysis of Shadows of Evil reports a useful shape:
- around 10 flyers in solo
- multiplayer total scales with player count
- simultaneous alive count capped per player with a global ceiling
- very fast swarm spawning
- final reward after all wave-owned flyers are dead

Those exact numbers are **reference balance**, not something our engine needs to copy.

## Critical discovery: flying spawner state

Public Black Ops 3 research documents a bug where a Parasite can fly back toward a prior district because the logical flying spawner/anchor was not updated correctly.

Engine lesson:

**Never store an air enemy's long-term home/respawn anchor as an incidental mutable world object.**

Use:

```text
AirSpawnTicket
  roundInstanceId
  spawnVolumeId
  chosenPoint
  targetPlayerId
  validUntil
```

The enemy should not later navigate back to an old special-round spawn anchor unless that behavior is intentional.

## AirSpawnVolume

Ground navmesh nodes are insufficient.

Map authors should place volumes:

```text
AirSpawnVolume
  bounds
  zone
  minAltitude
  maxAltitude
  coverRequired?
  visibilityPolicy
  linksToAirVolumes[]
  allowedArchetypes[]
```

Spawn point validation:
- not inside solid geometry
- adequate radius for creature wings/body
- reachable air volume to target
- not below floor / inside ceiling
- optional out-of-view preference
- safe distance from player camera
- reward drop must not inherit unreachable aerial position

## Flyer movement

Recommended controller:

`AirSteeringController`

Inputs:
- target position/velocity
- preferred attack range
- altitude band
- obstacle probes
- neighboring flyers
- map air-volume bounds

Steering terms:
- seek/lead target
- separation
- obstacle avoidance
- altitude restoration
- boundary return
- attack-orbit/strafe
- escape/reposition after firing

Do not run full global pathfinding every frame.

Use:
- spatial hash/grid for neighbors
- fixed number of obstacle rays per AI tick
- staggered target updates
- lower AI rate than render rate
- interpolation client-side

## Ranged attack

Generic `FlyerSpitter`:
- telegraph
- projectile spawn
- projectile velocity
- splash/direct damage
- cooldown
- line-of-fire check
- optional screen impairment/status effect

Projectile must be server authoritative.

Clients may predict visuals but not damage.

## Alive cap

Flying swarms become expensive quickly because each entity adds:
- steering
- projectile checks
- visibility
- animation
- audio
- FX

Therefore special-round definitions need a separate `aliveCapPolicy`.

Example:
```text
aliveCap = min(globalCap, players * perPlayerCap)
```

This is distinct from total enemies in the wave.

## Spawn cadence

Special flying rounds can intentionally spawn faster than normal zombies because they do not have window traversal queues.

Keep:
- `totalCount`
- `aliveCap`
- `spawnDelay`

as independent parameters.

## Reward placement

Never spawn the guaranteed Max Ammo at the dead flyer's raw airborne position.

Use a `RewardResolver`:
1. take death position
2. trace/find reachable ground
3. validate player-accessible nav area
4. if invalid, choose nearest designated reward anchor
5. replicate the resolved position

This avoids unreachable drops.

## Giant bug variants

The same air system can support:

### Parasite-style spitter
- low HP
- ranged acid
- prefers mid-range

### Armored Wasp
- weakpoint head/thorax
- strafing burst
- tougher but lower count

### Carrier Bug
- slow flying elite
- releases tiny ground/flying adds
- add count bounded by parent budget

### Exploder Moth
- closes distance after damage threshold
- self-destructs
- strong telegraph
- cannot chain-spawn explosions without cap

### Queen / Giant Bug miniboss
- boss health pool
- phase changes by health
- summon cap
- arena air-volume requirements
- separate boss reward

## Tests

1. Flyer never needs a ground navmesh path.
2. Air spawn is never inside solid geometry.
3. Old district/spawn anchor cannot pull current flyer backward.
4. Alive cap enforced independently of total wave count.
5. Projectile damage server-authoritative.
6. 4-player swarm remains within CPU budget.
7. Final reward resolves onto reachable ground.
8. Flyer mixed into normal round still counts toward correct owning round.
9. Target disconnect/down causes safe retarget.
10. No flyer survives round reset/map reload.
