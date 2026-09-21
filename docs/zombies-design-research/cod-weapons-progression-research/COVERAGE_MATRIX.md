# Weapon Research Coverage Matrix

Legend:
- COMPLETE = architecture/data snapshot captured
- PARTIAL = source identified, deeper values still being ingested
- NO-MIRROR = proprietary assets are reference-only

| Area | Classic IW era | Treyarch classic | COD Mobile | MW2019/WZ | MWII/MWIII/WZM | BO6/BO7 |
|---|---|---|---|---|---|---|
| Damage/range schema | COMPLETE | PARTIAL | COMPLETE schema / PARTIAL values | PARTIAL | PARTIAL | PARTIAL |
| RPM/fire interval | COMPLETE model | PARTIAL | PARTIAL current roster | PARTIAL | PARTIAL | PARTIAL |
| Hip spread | COMPLETE | PARTIAL | historical measured | PARTIAL | PARTIAL | PARTIAL |
| ADS spread | COMPLETE | PARTIAL | historical measured | PARTIAL | PARTIAL | official category confirmed |
| Vertical/horizontal recoil | COMPLETE model | PARTIAL | historical measured | PARTIAL | PARTIAL | official categories confirmed |
| View kick vs gun kick | COMPLETE | PARTIAL | PARTIAL | PARTIAL | PARTIAL | PARTIAL |
| ADS time | COMPLETE | PARTIAL | historical measured | PARTIAL | PARTIAL | official category confirmed |
| Sprint-to-fire | COMPLETE timing model | PARTIAL | historical measured | PARTIAL | PARTIAL | official category confirmed |
| Reload/empty reload | COMPLETE | PARTIAL | schema | PARTIAL | PARTIAL | official category confirmed |
| Move / ADS move | COMPLETE | PARTIAL | historical measured | PARTIAL | PARTIAL | official category confirmed |
| Bullet velocity | title-dependent | title-dependent | PARTIAL | modern source needed | modern source needed | official category confirmed |
| Penetration | COMPLETE model | PARTIAL | PARTIAL | PARTIAL | PARTIAL | PARTIAL |
| Progression model | MW2 challenge graph documented | WAW examples documented | official Gunsmith documented | official | official | official |
| Attachment exact deltas | PARTIAL | PARTIAL | historical subset COMPLETE | PARTIAL | qualitative MIT dataset COMPLETE | PARTIAL |
| Compatibility graph | PARTIAL | PARTIAL | PARTIAL | PARTIAL | 97 weapons / 1502 attachments snapshot | PARTIAL |
| Combination generator | COMPLETE generic | COMPLETE generic | COMPLETE generic | COMPLETE generic | COMPLETE generic | COMPLETE generic |
| Raw proprietary asset mirroring | NO-MIRROR | NO-MIRROR | NO-MIRROR | NO-MIRROR | NO-MIRROR | NO-MIRROR |
| Legal replacement audio/models | shared CC0 catalog | shared | shared | shared | shared | shared |

## Current concrete datasets in this repository

### MWII / early MWIII armory snapshot
Derived from the MIT-licensed codarmory.com repository:
- 97 weapons
- 1,502 attachments
- 135 attachment-stat labels
- 20 attachment categories
- 34 weapon platforms
- per-weapon combination-space counts

### COD Mobile historical Gunsmith test vectors
Early universal attachment measurements preserve exact vertical/horizontal recoil, ADS spread, hip spread, ADS-time, movement/range and other percentage deltas for a reusable modifier-engine test set.

## Next ingestion priority

1. current COD Mobile complete base-weapon roster: damage/RPM/mag/range/mode variants
2. current COD Mobile exact attachment deltas by weapon
3. MW2 (2009) complete numeric weapon-definition table from legally suitable public/open technical sources
4. BO1 / MW3 / BO2 complete numeric tables
5. MW2019 weapon + attachment data by patch
6. MWII/MWIII/WZM exact numeric deltas beyond qualitative pros/cons
7. BO6/BO7 current values
8. Zombies-specific base/rarity/Pack-a-Punch variants

Every live-service record must be versioned by date/patch.
