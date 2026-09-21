# COD Mobile — Current 2026 Research Snapshot

Snapshot date: 2026-09-21.

COD Mobile is a live-service title. Every numeric value in this file is timestamped and must not silently replace older records.

## Current roster-source observations

### PlayAware COD Mobile weapon catalog
Source:
https://playaware.gg/games/call-of-duty-mobile/wiki

The snapshot inspected reports **159 weapon entries** across its COD Mobile catalog and exposes damage/RPM text for many weapons, often separated by MP, Battle Royale and Zombies.

Examples present in the current snapshot:

- MP5:
  - base damage sequence: 25 / 23 / 17 / 15
  - 10mm sequence: 26 / 23 / 17 / 15
  - base: 833 RPM / 72 ms fire interval
  - 10mm: 758 RPM / 79.2 ms

- MP7:
  - damage: 23 / 21 / 19 / 14
  - base: 870 RPM / 69 ms
  - Enhanced Bolt: 1000 RPM / 60 ms

- AK-47:
  - MP base damage sequence: 33 / 26 / 23 / 21
  - 5.45-caliber MP sequence shown separately
  - base fire rate: 545 RPM

- Type 25:
  - MP: 24 / 22 / 19 / 16
  - BR variant shown separately
  - 857 RPM

- M4A1:
  - MP: 26 / 25 / 20 / 19
  - BR and Zombies variants shown separately
  - 682 RPM

- MG42:
  - mode-specific damage sequences
  - 1034 RPM

- MAC-10:
  - MP/BR damage sequence
  - 1200 RPM

This source is useful for **current roster discovery and factual cross-checking**, not as the sole authority for hidden recoil/spread/handling values.

## Current second-source cross-checks

### Zilliongamer
https://zilliongamer.com/call-of-duty-mobile/page/weapons

The page inspected was updated 2026-09-20 and publishes current weapon lists plus in-game-style Damage / Fire Rate / Accuracy numbers.

Use as a roster/basic-stat cross-check only because the game's UI bars are not the same as real engine values.

### MADS Mobile
https://madsmobile.com/en/codm/

Current snapshot contains modern season weapon entries and build recommendations with approximate RPM/TTK/ADS/recoil descriptors.

Useful for discovering current build combinations; exact values need independent verification.

## Why we preserve source disagreement

Different current sites can:
- count weapons differently
- include cut/unusable/wonder weapons
- use different game modes
- show raw damage vs UI stat bars
- lag one patch behind

Therefore the normalized importer must record:

~~~text
source
observedAt
mode
patch/season
weapon
stat
value
confidence
~~~

Never merge two sources simply because their weapon name matches.

## Current CODM ingestion target

For each playable weapon:

- class
- base magazine
- base damage curve
- body multipliers
- RPM / fire interval
- ADS time
- sprint-to-fire
- tactical reload / empty reload
- move speed
- ADS movement
- hip spread
- ADS bullet spread
- vertical recoil
- horizontal recoil
- recoil pattern
- bullet velocity when relevant
- flinch
- penetration
- compatible attachments
- weapon max level
- per-level attachment unlock
- MP / BR / Zombies override
- current season/patch provenance

## Status

The repository currently contains:
1. a normalized schema for all these values;
2. current-source catalog references;
3. historical exact CODM attachment delta vectors;
4. an attachment combination evaluator;
5. a planned/current-source ingestion path.

Current live values remain versioned instead of overwriting the historical test set.
