# Normalized Weapon Stat Schema

## Identity

```text
weaponId
canonicalName
sourceGame
sourceMode
sourcePatch
weaponClass
weaponFamily/platform
fireType
ammoFamily
provenance
```

## Damage

```text
damageProfile:
  baseDamage
  minDamage
  playerDamage?
  ranges[]
    start
    end
    damage
  bodyMultipliers
    head
    neck
    upperTorso
    lowerTorso
    arms
    legs
  armorRules?
  projectileSplash?
```

Never reduce a weapon to a single “Damage” bar.

## Fire behavior

```text
fire:
  roundsPerMinute
  fireIntervalMs
  burstSize
  burstDelayMs
  triggerMode
  preFireDelayMs
  postFireDelayMs
  boltCycleMs
  chargeTimeMs
```

Store raw interval when known because RPM = 60000 / interval_ms can hide rounding.

## Projectile / bullet behavior

```text
ballistics:
  model: hitscan | projectile | hybrid
  muzzleVelocityMps?
  gravityScale?
  drag?
  maxTravelDistance?
  penetrationClass
  penetrationMultiplier
  surfaceRules?
```

Older CoD titles often behave effectively hitscan for ordinary firearms; modern titles expose bullet velocity as a meaningful stat.

## Spread / accuracy

Separate hip spread from ADS bullet spread and from recoil.

```text
spread:
  hip:
    standMin
    standMax
    crouchMin
    crouchMax
    proneMin
    proneMax
    fireAdd
    moveAdd
    turnAdd
    decayRate
  ads:
    baseSpread
    movingSpread?
    bloomPerShot?
    bloomRecovery?
```

## Recoil

Do not use one scalar.

```text
recoil:
  gunKick:
    hipPitchMin
    hipPitchMax
    hipYawMin
    hipYawMax
    adsPitchMin
    adsPitchMax
    adsYawMin
    adsYawMax
    speed
    decay
    reducedKickBullets?
    reducedKickPercent?
  viewKick:
    hipPitchMin
    hipPitchMax
    hipYawMin
    hipYawMax
    adsPitchMin
    adsPitchMax
    adsYawMin
    adsYawMax
    centerSpeed
  pattern:
    deterministicBias?
    horizontalBias?
    verticalBias?
    perShotSamples?
```

This distinction matches classic IW-engine internals where gun kick and view kick are separate controls.

## Handling

```text
handling:
  adsInMs
  adsOutMs
  adsFov
  sprintToFireMs
  tacticalSprintToFireMs?
  sprintInMs
  sprintOutMs
  raiseMs
  quickRaiseMs?
  dropMs
  quickDropMs?
  reloadTacticalMs
  reloadEmptyMs
  reloadAddTimeMs?
  reloadStartMs?
  reloadEndMs?
  swapMs?
```

## Mobility

```text
mobility:
  moveSpeedScale
  adsMoveSpeedScale
  crouchSpeedScale?
  sprintSpeedScale?
  tacticalSprintSpeedScale?
  sprintDurationScale?
```

## Sway / stability

```text
sway:
  hipMaxAngle
  hipLerpSpeed
  hipPitchScale
  hipYawScale
  adsMaxAngle
  adsLerpSpeed
  adsPitchScale
  adsYawScale
  flinch?
```

## Ammunition

```text
ammo:
  magazine
  reserve
  startingReserve?
  reloadType
  chamberedRound?
```

## Progression

```text
progression:
  unlockType
  playerUnlockLevel?
  maxWeaponLevel?
  weaponXPTable?
  unlocks[]
    weaponLevel
    itemId
    itemType
    challenge?
```

## Attachments

```text
attachmentSlots[]
attachmentLimit
compatibleAttachments[]
uniqueConversionKit?
```

Each attachment stores a list of semantic modifiers rather than changing a vague bar.

## Provenance

Every value must carry:

```text
sourceType:
  official
  open_source_struct
  extracted_measurement
  community_test
  wiki
sourceUrl/repository
sourceRevision/patch
observedAt
confidence
notes
```

A value without patch/version is unsafe for live-service games.
