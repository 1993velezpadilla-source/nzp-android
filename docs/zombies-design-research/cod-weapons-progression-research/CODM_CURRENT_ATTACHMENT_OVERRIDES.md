# COD Mobile Current Attachment Overrides — 2026 Research

Snapshot: 2026-09-21.

## Key architecture correction

In current COD Mobile, an attachment name can have **different numeric effects on different weapons**.

Therefore this is wrong:

```text
attachment["YKM Combat Stock"] -> one universal modifier set
```

Use:

```text
AttachmentDefinition
  canonicalId
  slot
  genericBehaviorTags[]

WeaponAttachmentOverride
  weaponId
  attachmentId
  unlockLevel
  modifiers[]
  patch
  source
```

Historical universal/common values remain useful as test vectors, but current ingestion must support overrides.

## Current Rytec AMR example

Source: Zilliongamer Rytec AMR Gunsmith page, updated 2026-09-18.

Examples reported:

### Muzzles

**Tactical Suppressor**
- silenced
- +3% ADS time

**OWC Light Suppressor**
- silenced
- -20% damage range

**Monolithic Suppressor**
- silenced
- +25% damage range
- +8% ADS time
- +20% aiming crosshair drift
- -35% lung refresher

**RTC Compensator**
- -15% vertical recoil
- -15% horizontal recoil
- -60% aiming crosshair drift
- +60% lung refresher
- -10% ADS time as displayed by the source

**RTC Light Muzzle Brake**
- -10% horizontal recoil
- -10% vertical recoil
- -5% ADS time
- +20% aiming crosshair drift
- -35% lung refresher

### Barrels

**MIP Light Barrel (Short)**
- -7% ADS time
- +5% movement speed
- +5% ADS movement speed
- +10% vertical recoil
- -20% damage range
- +20% hit flinch

**MIP Extended Light Barrel**
- +20% damage range
- -10% vertical recoil
- -25% hit flinch
- -10% horizontal recoil
- +8% ADS time

**OWC Marksman**
- +45% damage range
- -20% horizontal recoil
- -20% vertical recoil
- -45% hit flinch
- -6% movement speed
- -20% ADS movement speed
- +12% ADS time

### Stocks

**YKM Light Stock**
- +20% ADS movement speed
- +20% aiming crosshair drift
- +35% lung refresher
- +10% hit flinch
- source text also reports a small horizontal-recoil penalty

**OWC Skeleton Stock**
- +15% ADS movement speed
- +5% ADS time as displayed
- +20% hit flinch
- +8% horizontal recoil
- +8% vertical recoil
- +25% aiming crosshair drift

**RTC Steady Stock**
- -35% hit flinch
- -25% horizontal recoil
- -45% aiming crosshair drift
- +60% lung refresher
- +10% ADS time
- +10% ADS movement speed

### Laser

**OWC Laser - Tactical**
- -3% ADS time
- -1.5% sprint-to-fire delay
- visible laser

### Ammunition

**25x59mm Explosive Mag**
- +11.6 sprint-to-fire delay
- +25% ADS time
- +60% fire interval

### Rear grips

**Granulated Grip Tape**
- -25% hit flinch
- -4% ADS movement speed

**Rubberized Grip Tape**
- -7% vertical recoil
- +15% hit flinch

**Stippled Grip Tape**
- -5% ADS time
- -15% sprint-to-fire delay
- +15% hit flinch
- +4% horizontal recoil
- +4% vertical recoil

## Current DR-H example

Current third-party technical guide reports:

**OWC Ranger**
- -7.6% ADS bullet spread
- +20% damage range
- -3.2% horizontal recoil
- +12% ADS time

**No Stock**
- -12% ADS time
- +3% movement speed
- +10% ADS movement speed
- +9.6% bullet spread
- +15% hit flinch
- +10.8% vertical recoil

**Granulated Grip Tape**
- -11.6% ADS bullet spread
- -4% ADS movement speed

**Monolithic Suppressor**
- +25% damage range
- suppression

This differs from early "universal" attachment measurements, proving overrides/versioning are mandatory.

## Current BP50 example

Current technical guide reports:

**LEROY 438mm Rapid Barrel**
- body-part damage behavior change
- -15% fire interval
- +8% horizontal recoil
- +10% sprint-to-fire delay

**LEROY Custom Stock**
- -20% horizontal recoil
- -20% vertical recoil

**.30 Russian Short 60 Round Drums**
- +30 magazine capacity
- -8% horizontal recoil
- -8% vertical recoil
- +2% movement speed
- -8% damage range
- +5% bullet spread
- penetration penalty

This is also why "attachment combination evaluation" must recompute several independent systems, not one accuracy bar.

## Weapon-level unlock evidence

Current Call of Duty Wiki attachment pages expose per-weapon unlock levels and per-weapon effects.

Example: **YKM Combat Stock**:
- Type 25: Weapon Level 38 in the current reference
- M16: Weapon Level 37
- AK-47: Weapon Level 37
- values differ by weapon

The importer should therefore keep:

```text
{
  weaponId,
  attachmentId,
  unlockLevel,
  modifiers,
  observedAt,
  source
}
```

## Current qualitative slot catalog

A current Zilliongamer Gunsmith index (updated 2026-09-19) lists families across:

- muzzle
- barrel
- stock
- laser
- underbarrel
- ammunition
- rear grip
- optics
- perks/signature-specific slots depending weapon

Common recurring behavior dimensions:
- vertical recoil
- lateral/horizontal recoil
- ADS bullet spread
- hip spread
- ADS speed/time
- ADS movement
- movement
- sprint-to-fire
- flinch
- damage range
- bullet velocity
- penetration
- magazine
- suppression
- idle sway/crosshair drift

## Ingestion rule

Do not apply a generic attachment record to a weapon unless:
1. source explicitly says the values are universal for that patch, or
2. there is no weapon override and the title's actual rule is known to inherit it.

Prefer weapon-specific records whenever available.
