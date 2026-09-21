# Data Source Catalog

Research snapshot: 2026-09-21.

## Tier A — Official Call of Duty / Activision

Use official material first for progression systems, terminology, launch unlocks and explicitly published balance changes.

### Call of Duty: Mobile Gunsmith
Source: https://blog.activision.com/call-of-duty/2020-08/Call-of-Duty-Mobile-Gunsmith

Confirms nine attachment categories, a maximum of five equipped attachments, weapon-level unlocks and attachment pros/cons.

### Modern Warfare (2019)
Source: https://support.activision.com/modern-warfare/articles/progression-in-call-of-duty-modern-warfare

Confirms weapon XP and per-weapon attachment/perk/camo unlock progression.

### Black Ops Cold War
Official Gunsmith/loadout guides document weapon-specific XP, five normal attachment slots and Gunfighter expansion for primaries.

### Modern Warfare II
Official progression/Gunsmith guides document:
- Weapon Platforms
- Receivers
- platform-specific attachments
- universal attachments
- original launch Weapon Tuning progression

### Modern Warfare III
Official guides document:
- shared attachment unlocks
- Armory Unlocks
- Aftermarket Parts / Conversion Kits
- detailed Gunsmith numeric-stat view

### Warzone Mobile
Official material documents MWII/MWIII/Warzone cross-progression and Gunsmith modifications.

### Black Ops 6
Official material documents individual weapon leveling, roughly 40–50 levels for most primaries, class optics and Global Weapon Builds.

### Black Ops 7
Official material documents granular weapon-stat details and Weapon Prestige, including weapon-specific Prestige Attachments.

## Tier B — Clearly licensed technical/open-source sources

### IW4x Client
Repository: iw4x/iw4x-client
License: GPLv3.

Best for:
- MW2-era WeaponDef taxonomy
- recoil/view-kick separation
- spread/sway
- handling timing
- penetration
- classic engine behavior

### IW4x Rawfiles
Repository: iw4x/iw4x-rawfiles
Repository license: GPLv3.

Caution: a repository-level license does not automatically relicense embedded Activision-origin assets. Treat proprietary asset content separately.

### codarmory.com
Repository: tzurbaev/codarmory.com
License: MIT.
Inspected revision: 04408ef38fb8e64531503e8a1148b6676374e4b8

Database snapshot inspected:
- 97 weapons
- 1,502 attachments
- 135 attachment-stat labels
- 20 attachment categories
- 34 weapon platforms

This is a particularly useful structured source for MWII / early MWIII-era weapon-platform and attachment unlock relationships.

### Greyhound
Repository: Scobalula/Greyhound
License: GPLv3 for the extractor.

Its own README explicitly warns that extracted Call of Duty assets remain property of their respective owners.

### COD Mobile extract scripts
Repository: Willie169/call-of-duty-mobile-extract
License: MPL 2.0 for the scripts.

Useful for understanding CODM package/audio extraction workflow. Script license does not license extracted Activision resources.

### CSVWeaponStatReader
Repository: MakeCentsGaming/CSVWeaponStatReader
License: GPLv3.

Historical workflow for reading Call of Duty weapon-stat CSVs with Asset Manager/APE-style field names and exporting GDT data.

Input spreadsheet licensing/provenance must be checked separately.

## Tier C — Reproducible measurements / technical databases

### Den Kirson
https://denkirson.blogspot.com/

Strong historical source for classic Call of Duty terminology and measurements:
- fire interval/rate
- spread
- reload/empty/add timing
- raise/drop/sight time
- directional recoil
- movement multipliers

### Sym.gg / legacy Symthic
https://sym.gg/

Technical cross-title weapon/Gunsmith comparison source.

### Killstreaks
https://killstreaks.com/

Cross-title sourced catalog. Use as discovery/verification and preserve source/version metadata.

### TrueGameData
Modern TTK/DPS/recoil and attachment-comparison source, including COD Mobile coverage.

### CODMunity
https://codmunity.gg/database

Large modern weapon/attachment database useful for compatibility and current-content cross-checking.

### PlayAware COD Mobile weapons
https://playaware.gg/games/call-of-duty-mobile/wiki

Current snapshot inspected on 2026-09-21 reports 159 CODM weapon entries and exposes factual damage/RPM information for many weapons, including mode-specific MP/BR/Zombies values. Treat as community/reference data and date every import.

### Zilliongamer COD Mobile
https://zilliongamer.com/call-of-duty-mobile/page/weapons

Current page snapshot dated 2026-09-20. Useful as a second source for CODM weapon roster/basic stat-bar cross-checking.

### path.exe attachment measurements
Historical CODM research separates:
- sprint-to-fire
- ADS
- ADS bullet spread
- vertical recoil
- horizontal recoil
- hip spread
- mobility

### Somdev Sangwan Gunsmith helper
Source: https://gist.github.com/s0md3v/90637ef45d0ff23b9bfb86ec9b47fdd7
License noted in source: GPLv3.

Useful historical attachment modifier test vectors.

## Tier D — Dataset sources

### Kaggle: Call of Duty Mobile weapons and specification
A public dataset discovered in research is marked CC0/Public Domain by Kaggle. It is older, so it is useful for historical/backfill comparisons, not current live balance.

## Reliability hierarchy

For one numeric field prefer:

1. official detailed numeric patch/stat source
2. compatible open technical config/struct
3. reproducible measurement
4. sourced technical database
5. community wiki/database
6. unsourced guide

When two sources disagree, retain both with source date/patch instead of silently overwriting one.
