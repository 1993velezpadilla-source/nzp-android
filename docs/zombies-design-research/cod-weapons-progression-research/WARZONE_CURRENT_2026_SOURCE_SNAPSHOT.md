# Warzone — Current 2026 Technical Source Snapshot

Research snapshot: 2026-09-21.

## Current source

CODMunity Warzone Stats Comparator:
https://codmunity.gg/weapon-stats/warzone

The retrieved current page reports:

- Updated: 17/09/2026
- Season 6

It exposes or compares:

- damage profiles / TTK
- Bullet Velocity
- Hitscan Range
- Fire Rate
- movement
- crouch movement
- sprint
- ADS movement
- handling
- recoil Gun Kick
- Horizontal Recoil
- Vertical Recoil
- magazine
- hipfire metrics
- attachment builds

This is a community/current technical source, not an Activision official database.

## Example current records

### P890 — base/no attachments in retrieved comparator

```text
Bullet velocity: 250 m/s
Hitscan range: 12.5 m
Fire rate: 286 RPM
```

### VEL 46 — selected URL

The retrieved page reports base-state data while attachment statistics are loading:

```text
Bullet velocity: 540 m/s
Hitscan range: 27 m
Fire rate: 952 RPM
```

The requested URL contained five attachments, but the source explicitly warned that the values shown remained base weapon stats until attachment calculations loaded.

### REV-46 — retrieved selected-build page

Current source exposed recoil values in the loaded page context:

```text
Gun Kick: 36.81
Horizontal recoil: 3.72
Vertical recoil: 43.15
```

## Critical ingestion rule

Never assume:

`URL has attachment list => displayed stats include attachments`

Current comparator pages can say:

“Loading attachment statistics… values below are base weapon stats until they arrive.”

Therefore our importer needs:

```text
attachmentEvaluationState:
  base
  loaded
  loading
  unknown
```

Only `loaded` can be used to derive attachment deltas.

## Cross-generation source games

Warzone can contain weapons from multiple source-game generations.

Each record needs:

- source game
- Warzone season
- Warzone mode profile
- weapon ID/name
- attachment source generation
- current Warzone-specific override

Do not overwrite original MWII/MWIII/BO6/BO7 multiplayer stats with Warzone values.

## Layer model

```text
original game base weapon
 -> Warzone ruleset/balance override
 -> current-season patch
 -> attachment build
 -> temporary mode/event buffs
```

## Why this matters

A weapon name can survive through several titles and receive:
- different damage curves;
- different health/armor environment;
- different attachment pool;
- different velocity/recoil;
- conversion kits;
- current-season rebalance.

The normalized database therefore keys by `game + mode + patch + weapon`, not weapon name alone.
