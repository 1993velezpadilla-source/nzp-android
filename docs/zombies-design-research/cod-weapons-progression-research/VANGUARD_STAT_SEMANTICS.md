# Call of Duty: Vanguard — Weapon Stat Semantics

Primary official source:
https://www.callofduty.com/blog/2021/11/call-of-duty-vanguard-boot-camp-weapons-loadouts

Snapshot research date: 2026-09-21.

## Why Vanguard matters

Vanguard is one of the clearest official explanations of what Call of Duty's Gunsmith bars actually contain. It gives units for several hidden/sub-stats instead of only qualitative bars.

## Official attachment model

Most Vanguard weapons can equip **up to 10 attachments**.

Attachments are earned through Weapon XP and can come from:

- Muzzle
- Underbarrel
- Barrel
- Magazine
- Ammo Type
- Optic
- Rear Grip
- Stock
- Proficiency
- Kit

This is a useful extreme case for our build system: the engine must not assume the five-slot limit used by COD Mobile/MWII-style builds.

## Firepower

Officially includes:

- Damage — hit points
- Fire Rate — rounds per minute
- Bullet Velocity — meters per second

Magazine/caliber swaps can materially change:

- fire rate
- damage
- penetration
- other weapon properties

This confirms that ammunition/caliber attachments can behave as **conversion layers**, not simple magazine-size modifiers.

## Speed

Officially includes:

- Movement Speed
- Sprint-to-Fire Time — milliseconds

Barrel/stock/grip choices may trade movement/handling against velocity, range or recoil.

## Accuracy

Officially includes:

- recoil
- stability
- hip-fire spread
- Flinch Resistance — described in Newtons by the official guide
- Centering Speed — described as return acceleration in meters per second squared

This reinforces our separation of:

`recoil impulse -> recoil recovery/centering -> spread -> flinch`

## Ammo

Officially includes:

- magazine capacity
- reload behavior
- Penetration — expressed in Newtons in Vanguard's detailed-stat UI
- Concealment — seconds the operator remains revealed

## Gunsmith design lessons

Vanguard explicitly describes examples such as:

- recoil boosters increasing fire rate;
- lightweight barrels increasing handling at the cost of bullet velocity/initial recoil;
- extended barrels improving range while hurting movement/hip accuracy;
- caliber swaps changing damage, RPM and penetration;
- ammo types changing penetration/status behavior;
- heavy stocks favoring control while light stocks favor movement/handling.

Our attachment system therefore needs semantic transforms across multiple subsystems, not UI-stat deltas only.

## Normalized schema additions

Vanguard justifies keeping:

```text
ballistics.muzzleVelocityMps
penetration.forceNewtons?
handling.sprintToFireMs
recoil.centeringAcceleration?
flinch.resistance?
visibility.revealDurationSec?
```

The exact unit meaning is source-title-specific and must carry `sourceGame`.

## Progression

Weapon XP unlocks attachments for the weapon.

Saved custom weapon configurations ("Weapon Mods") are a separate presentation/persistence concept from attachment unlock progression.

## Data status

Official stat semantics: captured.

Full weapon-by-weapon numeric snapshot: not yet imported into this repo; any future import must include the patch/date because Vanguard was live-balanced.
