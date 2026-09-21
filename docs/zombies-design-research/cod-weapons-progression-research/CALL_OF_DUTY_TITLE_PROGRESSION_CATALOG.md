# Call of Duty Title Progression Catalog

This catalog records the **progression family** and the best data source class for each era. It is not yet a claim that every numeric weapon has been ingested.

## Early / classic

| Title | Year | Weapon customization/progression model | Research priority |
|---|---:|---|---|
| Call of Duty | 2003 | fixed weapon definitions | raw stat/reference |
| Call of Duty 2 | 2005 | fixed weapon definitions | raw stat/reference |
| Call of Duty 3 | 2006 | limited/class weapon sets | behavior/reference |
| Call of Duty 4: Modern Warfare | 2007 | weapon challenge attachment unlocks | high |
| World at War | 2008 | Marksman kill challenges unlock attachments | high |
| Modern Warfare 2 | 2009 | branching weapon attachment challenges | very high |
| Black Ops | 2010 | rank + COD Points purchase/customization | high |
| Modern Warfare 3 | 2011 | weapon XP/levels + proficiencies | very high |
| Black Ops II | 2012 | weapon levels + Pick 10 customization | very high |
| Ghosts | 2013 | Squad Points flexible unlocks | medium |
| Advanced Warfare | 2014 | weapon/attachment progression + variants | medium |
| Black Ops III | 2015 | weapon levels + Gunsmith customization | high |
| Infinite Warfare | 2016 | progression + weapon variants | medium |
| WWII | 2017 | divisions/progression + weapon levels | medium |
| Black Ops 4 | 2018 | weapon levels, attachments, operator mods | high |

## Gunsmith / live-service generation

| Title | Year | Model | Research priority |
|---|---:|---|---|
| Modern Warfare | 2019 | deep Gunsmith, weapon XP | very high |
| Call of Duty: Mobile | 2019 | 9 slots / max 5, weapon XP, signature attachments | **highest** |
| Warzone | 2020 | shared Gunsmith/live balance | very high |
| Black Ops Cold War | 2020 | weapon XP, detailed stats, Gunfighter | high |
| Vanguard | 2021 | deep Gunsmith | medium-high |
| Modern Warfare II | 2022 | Weapon Platforms, Receivers, universal attachments, tuning | **highest** |
| Warzone 2.x | 2022 | shared modern platform | high |
| Modern Warfare III | 2023 | streamlined shared attachments + Aftermarket Parts | **highest** |
| Warzone Mobile | 2024 | MWII/MWIII/WZ cross-progression and Gunsmith | high |
| Black Ops 6 | 2024 | 40–50ish weapon levels for most primaries, global builds | **highest** |
| Black Ops 7 | 2025 | weapon levels + Weapon Prestige + Prestige Attachment | **highest** |

## Current/upcoming titles

Do not ingest unreleased weapon numbers as final data.
Store announced progression behavior separately from shipping values.

## Modes

One weapon may need separate profiles for:
- Campaign
- Multiplayer
- Zombies
- Warzone/BR
- COD Mobile MP
- COD Mobile BR

Never overwrite one mode with another.

## Zombies variants

Pack-a-Punch/rarity/upgrades should be another stat layer:

`base MP-like weapon -> Zombies mode override -> rarity/PaP -> attachments -> temporary buffs`

This keeps one canonical weapon family while preserving mode-specific behavior.
