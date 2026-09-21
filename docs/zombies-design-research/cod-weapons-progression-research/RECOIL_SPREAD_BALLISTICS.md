# Recoil / Spread / Ballistics Research

## Recoil is several systems

Classic IW-engine definitions demonstrate at least:

### Gun kick
Visual/weapon-axis kick:
- pitch min/max
- yaw min/max
- speed
- decay
- reduced kick for early bullets

### View kick
Camera kick:
- pitch min/max
- yaw min/max
- recentering speed

### Sway
Slow aiming drift:
- max angle
- pitch/yaw scale
- ADS-specific values

### Spread
Projectile/ray direction uncertainty:
- hip spread by posture
- fire/move/turn additions
- decay
- ADS spread

A modern implementation may additionally have deterministic recoil patterns and bloom.

## COD Mobile measurement lesson

Historical research by path.exe measured vertical and horizontal recoil using 3D angular change of the recoil path rather than only the size of bullet groups on a wall.

That matters because:

`recoil != spread`

A gun can have:
- strong predictable recoil but tight spread
- low recoil but poor bullet spread
- good first-shot behavior but poor sustained bloom

## Suggested runtime model

```text
shot n:
  aimDirection
  + viewKickImpulse
  + gunKickImpulse
  + deterministicPattern[n]
  + randomRecoilNoise
  + spreadConeSample
  -> final shot direction/projectile
```

## Recoil pattern representation

Optional:

```text
RecoilPattern
  samples[]
    pitch
    yaw
  loopPolicy
  randomJitter
  recenterRate
```

This lets an AK-like weapon climb differently from an MP5-like weapon without merely changing one scalar.

## First-shot / reduced-kick behavior

The classic IW struct exposes reduced-kick bullet count and percentage.

Support:

```text
firstShots:
  count
  kickMultiplier
```

This can create:
- accurate opening burst
- harsher sustained fire
- burst-fire identity

## Damage range

Support piecewise curves:

```text
RangeSegment
  maxDistance
  damage
```

or interpolation between max-damage and min-damage endpoints when source title uses it.

## Time to kill

Derived, never authored when sufficient raw data exists.

For full-auto hits:

`TTK = (shotsToKill - 1) * fireInterval`

but only after accounting for:
- burst delay
- pre-fire delay
- projectile travel
- armor
- hit-location multiplier

## Bullet velocity

For projectile-based modern weapons:
`travelTime = distance / muzzleVelocity`

If gravity applies:
integrate trajectory or use engine projectile simulation.

Do not add fake bullet drop to a historical hitscan title just because modern CoD has velocity data.

## Penetration

Classic IW weapon data has:
- penetrate type
- penetration multiplier

Our engine should combine:
- weapon penetration class
- material resistance
- remaining projectile energy/damage

## Shotguns

Need additional fields:
- pellet count
- per-pellet damage
- spread distribution
- pellet cap / aggregate damage cap if source game uses one
- ADS spread behavior
- range per pellet

## Validation capture protocol

For data measured from gameplay:

### RPM
- high-FPS video or audio transient timing
- >= 20 shots when possible
- report mean + median interval

### Recoil
- fixed FOV
- fixed wall distance
- no attachments
- no recoil compensation
- multiple magazines
- convert pixels to angular displacement

### Spread
- isolate recoil where possible
- large sample count
- fixed distance
- record radial/angular distribution

### ADS/sprint-to-fire
- frame timing
- high FPS
- repeated trials

Store capture conditions with every measurement.
