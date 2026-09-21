# Special Enemy Archetypes

The useful thing to copy from successful Zombies design is not a specific copyrighted creature; it is the **combat problem** that creature creates.

## 1. Rush Quadruped

Examples in research:
- Hellhound
- Plague/Fire Hound
- tiger-like special enemy

Problem imposed:
- fast target acquisition
- pressure on players who rely on slow trains
- fewer traversal constraints than humanoid zombies

Components:
- `RushController`
- `MeleeAttack`
- optional `DeathBurst`

---

## 2. Flying Ranged Swarm

Examples:
- Parasite-style flyer
- giant insect / mosquito concept

Problem:
- forces vertical aim
- punishes stationary play
- ranged crossfire instead of body blocking

Components:
- `AirSteeringController`
- `ProjectileAttack`
- `AirSpawnProfile`

---

## 3. Weakpoint Drone

Example pattern:
- Valkyrie-style drone

Problem:
- moving aerial target
- parts/weakpoints matter
- destroying components changes behavior

Components:
- `AirSteeringController`
- `DamageablePartSet`
- `WeakpointCore`
- `SelfDestructState`

Possible state:
`PATROL -> ATTACK -> PART_BROKEN -> EXPOSED -> CHARGE -> EXPLODE`

---

## 4. Wall/Spider Crawler

Examples:
- spider special wave
- crawler variants

Problem:
- small hitbox
- fast lateral movement
- web/ranged debuff possibilities

Components:
- `SurfaceCrawlerController`
- `BiteAttack`
- optional `WebProjectile`

Engine requirement:
Do not fake ceiling/wall movement by teleporting every frame. Author traversal links/surface navigation where needed.

---

## 5. Teleporting / Leaping Harasser

Example:
- Jumping Jack-style special

Problem:
- breaks predictable kiting routes
- appears/repositions near player
- rewards accurate or controlled play

Components:
- `GroundController`
- `ShortTeleportAbility`
- `LeapAttack`

Round can attach a performance challenge:
- accuracy
- melee-only
- no player damage
- time target

Challenge reward is independent from guaranteed completion reward.

---

## 6. Suicide Charger

Examples:
- Insanity Elemental/"meatball"
- explosive clown
- bomber/ticker types

Problem:
- forces immediate target priority
- area denial
- chain-reaction potential

Components:
- `RushController`
- `ProximityFuse`
- `ExplosionOnContact`

Safety:
- hard cap simultaneously alive
- chain explosions cannot recursively multiply without budget
- telegraph audio/visual before lethal burst

---

## 7. Objective Attacker

Example pattern:
- Space Monkey attacking perk machines

The enemy's primary target is a **world objective**, not the closest player.

Components:
- `ObjectiveSelector`
- `ObjectiveDamage`
- `PlayerFallbackAttack`

Round challenge:
Protect all objectives -> bonus reward.

This is important because it turns a special round into **defense gameplay** instead of another extermination wave.

---

## 8. Thief / Nonlethal Pursuer

Example pattern:
- Pentagon Thief

Primary goal:
- reach a player
- steal/disable a resource
- escape

Completion can have three outcomes:
- killed before theft
- killed after theft
- escaped

Each outcome maps to different rewards/restoration.

This requires a generic `EncounterOutcome`, not simply “kill count reached zero.”

---

## 9. Mixed Composition

Fan-made registry research demonstrates weighted combinations such as runner/spitter/brute variants within one special wave.

Definition:
```text
composition:
  Runner   weight 100
  Spitter  weight 75
  Brute    weight 50
```

Use normalized weighted selection; weights do not need to sum to 100.

Add composition constraints:
- max brutes alive
- min ranged alive
- no two elites back-to-back
- per-player cap

---

## 10. Normal-Round Mutator

Some special types become part of ordinary waves later.

Instead of a new round:
```text
NormalRoundMutation
  enemyId
  startRound
  replacementChance
  maxAlive
  cooldown
```

Use this for:
- dogs after late rounds
- spiders after threshold
- parasites after threshold
- armored/elemental variants

---

# Behavior-component library

Our engine should aim for reusable components:

- GroundChase
- QuadrupedChase
- AirSteering
- SurfaceCrawler
- RangedProjectile
- MeleeSwipe
- Leap
- Teleport
- ProximityExplode
- DeathExplosion
- GasCloud
- WebSlow
- WeakpointParts
- ObjectiveAttack
- ResourceSteal
- SummonAdds
- Enrage
- Armor
- Shield
- Retreat/Reposition

An “enemy type” is a composition of components plus stats/presentation.
