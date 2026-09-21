# Classic Call of Duty Raw-Weapon Research Paths

## CoD4 weapon asset format

COD Engine Research documents the CoD4 weapon source format as raw text weapon files under raw/weapons/sp and raw/weapons/mp, using backslash-separated setting/value pairs.

This matches the parser implemented in:
tools/weapon-research/parse_iw_weapon.py

## World at War Mod Tools

A public reupload of the original World at War mod tools exposes weapon GDF definitions and source metadata.

The projectileweapon.gdf field schema includes categories such as:
- damage
- fire delay / fire time
- reload / raise / drop / sprint timing
- ADS transition/FOV
- hip spread min/max by stance
- spread decay/fire/move additions
- ADS spread
- sway
- magazine/ammo
- projectile speed/lifetime
- movement/ADS movement
- aim-assist ranges
- recoil/viewmodel controls

Licensing caution:
this is a reupload of official mod tools governed by their original tool/EULA terms, not a clean MIT/CC0 dataset.

Use as field/reference material unless a specific file's redistribution rights are established.

## IW4x

IW4x provides the cleanest open classic technical path currently in this research pack:
- GPLv3 client source
- GPLv3 rawfiles repository
- WeaponDef struct taxonomy
- raw weapon variants where available
- statstable / unlocktable / challenge relationships

Example raw variant inspected:
iw4x/iw4x_00/weapons/mp/p90_xmags_mp
blob:
24f708da0c9b6b994792ef6835e67034179e5d21

The effective variant record includes factual gameplay values such as:
- damage 30
- minDamage 20
- maxDamageRange 750
- minDamageRange 1000
- fireTime 0.064
- clipSize 75
- reloadTime 2.759
- reloadEmptyTime 3.5
- ADS transition 0.2
- ADS zoom FOV 55
- ADS gun/view kick fields
- stance-dependent hip spread
- sway
- movement scales
- hit-location multipliers

This illustrates why our parser compares **effective raw definitions** rather than assuming an attachment modifies only the stat advertised in the menu.

## MW2 2009 unlock relationships

IW4x statstable/unlock/challenge files expose:
- compatible attachment IDs
- weapon challenge relationships
- unlock entries
- challenge titles/icons

For example the MP5K statstable entry lists attachment families such as:
- rate of fire
- reflex
- silencer
- ACOG
- FMJ
- akimbo
- EOTech
- thermal
- extended magazines

This provides a machine-readable path to reconstructing classic challenge graphs.

## Black Ops II / T6

Public Plutonium T6 script mirrors generated from game scripts are useful for behavioral research (weapon stat tracking, class/perk logic and Zombies weapon handling), but generated/decompiled proprietary script provenance means they remain **reference-only** here.

Do not copy large proprietary script bodies into our engine.

## Extraction pipeline for classic raw weapon values

~~~text
raw weapon file
 -> parse key/value pairs
 -> keep gameplay scalar fields
 -> normalize units/names
 -> identify base/attachment variant
 -> diff fields
 -> save derived factual delta + provenance
~~~

No model/audio/animation blobs are required for this process.
