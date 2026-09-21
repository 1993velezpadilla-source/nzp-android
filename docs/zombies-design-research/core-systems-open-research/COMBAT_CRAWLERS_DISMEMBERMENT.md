# Combat / Crawlers / Hit Reactions / Dismemberment

## Der Koloss — MIT

Its gameplay already treats crawler identity as gameplay state, not only animation.

Observed:
- crawler flag is synchronized in zombie snapshots
- crawler has different target/hit geometry
- crawler uses a lower head/body target position
- crawler-specific audio callback
- normal and crawler forms still belong to the same authoritative enemy object

That is the correct model.

## Crawler transition

A zombie becoming a crawler should **not**:
- spawn a second round-counted zombie
- decrement the first one
- reset drop eligibility
- lose owner/round ID

It is a state transition on the same enemy instance.

```text
StandingHumanoid
  -> leg disable/dismember event
  -> CrawlerHumanoid
```

Preserve:
- entity ID
- roundInstanceId
- health
- status effects
- aggro target
- drop eligibility

## Hit zones

Use data:

```text
HitZone
  bone/shape
  damageMultiplier
  tags[]
  detachablePart?
  disableEffect?
```

Examples:
- head
- torso
- upper/lower arm
- upper/lower leg

## Dismemberment

Separate gameplay part state from visual gore.

```text
BodyPartState
  intact
  disabled
  severed
```

Gameplay can work even when gore visuals are disabled for performance/accessibility.

Possible effects:
- leg sever -> crawler
- arm sever -> attack variant changes
- head destroyed -> death or headless timer depending enemy type

## Visual layer

Presentation may:
- hide/skinned-mesh part
- spawn pooled detached limb
- ragdoll limb
- blood particle/decal
- change animation set

On mobile low settings:
- hide part + small FX
- no persistent detached physics limb

## Ragdoll

Do not let gameplay depend on non-deterministic ragdoll simulation.

Server determines:
- death
- impulse summary
- hit zone

Client creates cosmetic ragdoll/limb behavior.

Reference-only public projects show useful layered ragdoll approaches, but if licensing is unclear we only reproduce the high-level design.

## Knockdown vs crawler

Separate states:
- temporary knockdown: zombie gets back up
- crawler: locomotion archetype permanently changed

This matters for Thundergun-style knockback and explosives.

## Penetration

A hit chain should carry:
- original shot ID
- current energy/damage
- hit zone
- penetration count/material

Award hit points once per valid target/hit, not per collider.

## Corpse cleanup

Need explicit corpse budget:
- max ragdolls
- max detached limbs
- max decals
- age-based eviction
- distance/visibility priority

Android should aggressively pool/evict.

## Tests

1. crawler transition does not change round population
2. crawler snapshot uses correct hitbox
3. severed limb cannot be severed twice
4. cosmetic ragdoll cannot cause gameplay damage
5. gore-off mode preserves identical gameplay
6. penetration cannot award duplicate hit points on multiple colliders
7. reset clears detached-part pool
8. corpse budget remains bounded in 1000-kill stress run
