# Perks / Persistent Status Effects

## Der Koloss — MIT

Observed good architecture:
- canonical perk IDs
- perk ownership synchronized
- drink animation uses one authoritative timeline
- timeline coordinates:
  - raise
  - drink
  - grant moment
  - lower
  - bottle throw/break
  - finish
- remote clients receive cosmetic animation without being allowed to grant themselves the perk

This split between **effect authority** and **presentation timeline** is exactly right.

## PerkDefinition

```text
PerkDefinition
  id
  price
  prerequisites
  maxStacks
  slotCost
  persistentUntilDown?
  effectComponents[]
  drinkPresentation
```

Examples of effect components:
- MaxHealthMultiplier
- ReloadSpeedMultiplier
- FireRateMultiplier
- DamageMultiplier
- ReviveTimeMultiplier
- SprintPolicy
- ExplosionImmunity
- FallDamageImmunity
- WeaponSlotCapacity
- HipSpreadMultiplier
- HeadshotMultiplier

## Never hard-code weapon perk behavior in each weapon

Instead:
```text
effectiveReloadTime =
  weapon.baseReloadTime
  * playerStats.reloadTimeMultiplier
```

Same for:
- fire rate
- movement
- damage
- spread

This is how one Speed Cola implementation can work on every weapon.

## Ownership vs presentation

Authoritative:
- points paid
- perk ID granted
- perk inventory
- gameplay stat modifiers

Presentation:
- bottle/model
- hands animation
- machine audio
- perk HUD icon

A guest may request purchase and play predicted cosmetics only after authority acceptance or carefully reversible prediction.

## Perk slots

Use explicit capacity:
`perkSlotsUsed / perkSlotCapacity`

Maps can:
- have classic cap
- increase cap
- grant permanent slot upgrades
- ignore cap for quest reward if desired

## Perk loss policy

On down/death:
- map/mode defines which perks are lost and when

Do not remove perks merely because the player enters downed state unless the intended game rules say so.

Model:
```text
PerkLossPolicy
  onDown
  onBleedout
  onRespawn
  protectedIds[]
```

## Random perk reward

When granting random perk:
1. build eligible set
2. remove already-owned if duplicates disallowed
3. respect map availability
4. respect slot policy
5. if empty, run configured fallback reward

## Perk-machine transaction

Like wall buys:
- validate machine powered/unlocked
- player in range
- not down/dead
- not already drinking
- enough points
- capacity available

Debit and grant transaction atomically.

## Upgradeable perks

Fan mods demonstrate “pro/perka-punch” perk ideas.

Our engine can support this without special casing:

```text
PerkInstance
  perkId
  tier
  acquiredAt
```

Tier maps to additional components.

## Tests

1. client cosmetic event cannot grant perk
2. purchase cannot double-debit
3. timed drink grant occurs once
4. down/death applies configured loss policy only
5. random perk never grants invalid duplicate
6. perk capacity updates immediately
7. disconnect/reconnect restores authoritative perks
8. stat modifiers recompute from base, not compound drift
