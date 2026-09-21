# Call of Duty Weapon / Progression / Asset Research

Research snapshot: 2026-09-21.

Purpose: build a legal, normalized technical reference for weapon handling, progression and customization patterns across the Call of Duty franchise, with a special deep dive into Call of Duty: Mobile.

## Important boundary

We store:
- derived numeric/stat tables
- public/official progression rules
- open-source engine field taxonomies
- attachment modifiers
- measured community data with provenance
- source paths/hashes
- schemas and ingestion rules
- links/licensing for legally reusable audio/models

We do **not** mirror proprietary Call of Duty models, sounds, textures or raw extracted game files into this repository.

Extraction tools can still be documented as research tools. Extracted Activision assets remain Activision/rights-holder property unless a separate license explicitly says otherwise.

## Documents

- `CALL_OF_DUTY_TITLE_PROGRESSION_CATALOG.md`
- `WEAPON_STAT_SCHEMA.md`
- `IW_ENGINE_WEAPONDEF_FIELD_TAXONOMY.md`
- `COD_MOBILE_GUNSMITH.md`
- `CODM_ATTACHMENT_BASELINE_2020_2021.md`
- `ATTACHMENT_MODIFIER_COMPOSITION.md`
- `RECOIL_SPREAD_BALLISTICS.md`
- `WEAPON_LEVELING_AND_UNLOCKS.md`
- `DATA_SOURCE_CATALOG.md`
- `FREE_AUDIO_ASSET_CATALOG.md`
- `FREE_MODEL_MATERIAL_ASSET_CATALOG.md`
- `EXTRACTION_AND_LICENSING_POLICY.md`
- `COVERAGE_MATRIX.md`

## Engine goal

One normalized weapon record should be able to describe:
- CoD4/MW2-style hitscan weapons
- Black Ops/MW3 weapon-level progression
- MW2019/CODM Gunsmith
- MWII weapon platforms
- MWIII Aftermarket Parts
- BO6 weapon-specific progression
- BO7 Weapon Prestige
- projectile/ballistic weapons
- Zombies-specific upgraded variants

The schema should preserve source-game behavior without forcing every title into the same simplified stat bars.
