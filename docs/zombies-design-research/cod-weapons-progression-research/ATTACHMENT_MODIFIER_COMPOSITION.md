# Attachment Modifier Composition

## Problem

A five-attachment build is not just a list of icons.

It is a transformation:

`Base Weapon -> Mode/Patch Layer -> Attachment 1..N -> Perks/Temporary Buffs -> Final Runtime Stats`

The engine must preserve the individual trade-offs.

## Modifier

```text
StatModifier
  stat
  operation
    addAbsolute
    addPercent
    multiply
    replace
    clampMin
    clampMax
  value
  condition?
  sourceAttachmentId
```

## Order

Recommended deterministic order:

1. base weapon definition
2. source-game/mode override
3. current patch
4. conversion kit / receiver replacement
5. authored attachment replacements
6. additive absolute modifiers
7. percentage/multiplicative modifiers
8. perk/player modifiers
9. temporary gameplay buffs
10. final clamps

Store the order explicitly.

## Why “just add all percentages” can be wrong

Different games can implement attachment values differently:
- additive percentage points
- multiplicative percent
- replacement curves
- changing range breakpoints rather than range scalar
- changing recoil parameters rather than final recoil magnitude

Therefore imported data must include `operation` and, when unknown, `operation=sourceUnknown`.

Do not fabricate exact final stats from UI percentages.

## Compatibility

```text
Attachment:
  slot
  weaponWhitelist?
  weaponBlacklist?
  requires[]
  excludes[]
  disablesSlots[]
  conversionGroup?
```

Examples:
- integral suppressor barrel may disable Muzzle
- grip barrel may disable Underbarrel
- conversion kit can change available slots
- akimbo may disable optic/underbarrel depending game

## Recoil composition

An attachment can modify:
- vertical gun kick
- horizontal gun kick
- view kick
- recoil center speed
- first-N-shot reduction
- deterministic pattern bias
- random scatter

These are not equivalent.

## Spread composition

Separate modifiers:
- hip min
- hip max
- ADS bullet spread
- bloom per shot
- recovery
- moving ADS spread

A “recoil control” attachment should not automatically improve spread unless source data says it does.

## Example historical CODM trade-off

Early measured No Stock data:
- faster ADS
- faster movement
- worse ADS spread
- worse flinch
- worse vertical recoil

That should be represented as five modifiers attached to one item.

## Build evaluator output

```text
EvaluatedBuild
  base
  final
  deltas
  warnings[]
  incompatibilities[]
  provenance[]
```

Display both:
- final numbers
- which attachment caused each change

## Combination enumeration

For a weapon with compatible attachments, enumerate combinations by:
- choose 0..attachmentLimit
- at most one per occupied slot
- obey exclusions
- obey conversion-kit slot mutations

Do not persist millions of redundant build rows.
Persist weapon + attachment definitions and generate valid builds on demand.

A small generator is stored in:
`tools/weapon-research/build_combinations.py`
