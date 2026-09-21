# Traps / World Events / Interactive Hazards

A reusable Zombies engine needs traps as first-class systems, not one-off map scripts.

nZombies publicly advertises trap support, and nZombies-derived repositories contain electric trap entities and map-side effects. The specific old derivative assets/code are not all cleanly licensed for our use, so this document captures the gameplay contract.

## TrapDefinition

```text
id
activationCost
powerRequirement
cooldown
activeDuration
targetFilter
damageProfile
ownerCreditPolicy
fxProfile
audioProfile
statePersistence
```

## Trap runtime state

```text
DISABLED
READY
ACTIVATING
ACTIVE
COOLDOWN
```

Authority owns state/timestamps.

## Examples our generic system should support

### Electric barrier
- continuous volume/beam
- damages enemies crossing
- optional instant kill or DPS
- owner/team point credit policy

### Fire trap
- persistent hazard volume
- burn status

### Flinger / launcher
- impulse enemies
- kill outside bounds safely credited

### Turret
- target acquisition
- ammo/duration
- projectile/hitscan
- owner attribution

### Crusher / door hazard
- moving geometry
- overlap damage
- safe player exclusion policy

### Environmental event
- lightning
- bomber strike
- gas leak
- moving wall
- temporary room lockdown

## Activation transaction

Validate:
- player can interact
- power available
- trap READY
- enough points
- no conflicting quest state

Then debit and commit state atomically.

## Damage attribution

Trap kills still need:
- authoritative enemy death
- round ownership decrement
- drop eligibility rule
- points/kill credit policy

Do not bypass CombatSystem and directly delete zombie entities.

## Drop policy

Some traps should suppress random powerups.

Expose:
`dropEligibility = Normal | NoRandomDrops | NoDrops`

Scripted guaranteed rewards still bypass it.

## HazardVolume

Generic runtime:

```text
shape
transform
damagePerTick
tickRate
statusEffect
teamFilter
expiresAt
sourceId
```

Reuse for:
- fire
- acid
- gas
- electricity
- boss puddles
- toxic zombie deaths

## World event controller

Large map events should be timeline/state data:
- warning
- active
- recovery

Examples:
- siren -> bombing -> debris/fire
- lightning storm
- lockdown
- poison fog
- moving machinery

The event should emit logic-graph signals so quests can react to it.

## Performance rules

Android:
- bounded active hazard volumes
- no per-particle collision
- pooled VFX
- spatial query at fixed tick
- one damage query per hazard tick, not per rendered frame
- dynamic lights capped by importance

## Tests

1. purchase cannot activate trap twice
2. cooldown survives dropped packets
3. trap kill decrements correct round
4. trap kill drop policy obeyed
5. owner disconnect does not break trap
6. hazard expiration deterministic
7. reset removes every active hazard
8. player-safe trap cannot damage players
9. large event cannot spawn unbounded effects
10. logic graph receives activation/completion exactly once
