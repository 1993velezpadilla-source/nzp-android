# Classic IW Engine WeaponDef Field Taxonomy

Primary technical reference:
`iw4x/iw4x-client`, GPLv3.

Inspected revision returned by GitHub code search:
`06f3c78bf7a4c62a4866f8bc3b56db2555f2dade`

Main path:
`src/Game/Structs.hpp`

This is **not a copy of the struct**. It is a derived taxonomy of gameplay fields that matter to our engine.

## Damage / range

Fields observed:
- `damage`
- `playerDamage`
- `iMeleeDamage`
- `minDamage`
- `minPlayerDamage`
- `fMaxDamageRange`
- `fMinDamageRange`

Engineering implication:
classic weapon definitions carry explicit damage endpoints and range transition data rather than one generic range stat.

## Fire timing

Observed:
- `iFireTime`
- `iFireDelay`
- melee delays/charge fields

`iFireTime` is the key interval for automatic fire behavior.

## ADS

Observed:
- `fAdsZoomFov`
- `iAdsTransInTime`
- `iAdsTransOutTime`
- `fAdsBobFactor`
- `fAdsViewBobMult`
- `fAdsSpread`

## Hip spread

Observed:
- `fHipSpreadStandMin`
- `fHipSpreadDuckedMin`
- `fHipSpreadProneMin`
- `hipSpreadStandMax`
- `hipSpreadDuckedMax`
- `hipSpreadProneMax`
- `fHipSpreadDecayRate`
- `fHipSpreadFireAdd`
- `fHipSpreadTurnAdd`
- `fHipSpreadMoveAdd`

This confirms spread is stateful and posture-aware.

## Gun kick

Observed hip:
- pitch min/max
- yaw min/max
- speed max
- speed decay
- static decay
- reduced-kick bullet count
- reduced-kick percent

Observed ADS:
- equivalent ADS pitch/yaw min/max
- ADS kick speed/decay
- reduced-kick controls

## View kick

Observed independently from gun kick:

Hip:
- view kick pitch min/max
- view kick yaw min/max

ADS:
- view kick pitch min/max
- view kick yaw min/max
- ADS view kick center speed

This separation is important:
**weapon model kick and camera/view recoil are not necessarily the same system.**

## ADS scatter / visual instability

Observed:
- `fAdsViewScatterMin`
- `fAdsViewScatterMax`

Do not collapse this into recoil.

## Movement

Observed:
- `moveSpeedScale`
- `adsMoveSpeedScale`
- `sprintDurationScale`

## Weapon lifecycle timing

Observed:
- reload time
- empty reload time
- reload add/start/end timings
- drop time
- raise time
- alternate drop
- quick drop
- quick raise
- breach/empty raise/drop
- sprint in/loop/out timings

These fields show why “handling” should be many values, not one stat.

## Sway

Observed:
- `swayMaxAngle`
- `swayLerpSpeed`
- horizontal/vertical scales
- shell-shock sway scale
- `adsSwayMaxAngle`
- ADS lerp/pitch/yaw scales

## Magazine / penetration

Observed:
- `iClipSize`
- `penetrateType`
- `penetrateMultiplier`

The IW4x bullet module also explicitly consumes `penetrateType` against surface penetration behavior.

## Why this matters to our game

Our weapon system should preserve:
- spread
- gun kick
- view kick
- sway
- handling times
- movement penalties
- range/damage
- penetration

as separate layers.

That lets us reproduce the *feel architecture* of classic shooters without copying a proprietary gun asset or blindly cloning one title's balance.
