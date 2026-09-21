# Weapon Field Evolution — IW3 / T4 / IW4 / T5 / IW5 / T6

Source: GPLv3 OpenAssetTools weapon field definitions.

This comparison gives us a clean, machine-readable picture of how Call of Duty weapon definitions became more expressive across:

- IW3 — Call of Duty 4
- T4 — World at War
- IW4 — Modern Warfare 2
- T5 — Black Ops
- IW5 — Modern Warfare 3
- T6 — Black Ops II

## Field counts

- IW3: 501 unique weapon fields
- T4: 562 unique weapon fields
- IW4: 671 unique weapon fields
- T5: 745 unique weapon fields
- IW5: 783 unique weapon fields
- T6: 1027 unique weapon fields

The point is not that every field controls ballistics. Many are animation/audio/model/AI fields. The important finding is that the *gameplay-relevant* vocabulary also grows substantially.

## Stable core across generations

A large classic core survives across many generations:

- damage / min damage / range
- fire timing
- reload timing
- ADS timing/FOV
- hip spread
- ADS spread
- gun kick
- view kick
- sway
- movement/ADS movement
- ammunition
- penetration
- projectile behavior
- hit-location multipliers
- animation and audio hooks

That validates our normalized schema.

## T6 / Black Ops II additions important to our engine

The T6 definition exposes richer behavior including:

- multiple damage values and range breakpoints (damage2..damage5 / range2..range5)
- burst-fire delay
- additional intro/last-fire timing
- quick reload timing
- crawling and sliding weapon animation/state timing
- more explicit attachment/attachment-unique representation
- recoil reduction / recoil return controls
- anti-quickscope controls
- barrel types
- more dual-wield/alternate weapon options
- camera shake
- gibbing controls
- richer shell/effect offsets
- additional sensor/tactical properties

## Superset design decision

Our engine should not model only:

`damage + RPM + recoil`

It should support optional layers for:

1. damage curve with N breakpoints
2. body-zone multipliers
3. fire-state timing
4. spread state
5. gun kick
6. camera/view kick
7. recoil recovery
8. sway
9. mobility
10. reload variants
11. stance-specific weapon states
12. projectile/penetration
13. attachment/conversion transforms
14. gameplay flags
15. presentation hooks

Then old games simply leave newer optional fields unset.

## Data file

See:

`data/openassettools/weapon-field-evolution.json`

It contains:
- all field names per engine generation
- source path and blob hash
- added/removed fields between adjacent generations
- a compact key-field presence matrix
