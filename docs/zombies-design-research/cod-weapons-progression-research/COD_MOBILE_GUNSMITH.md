# Call of Duty: Mobile Gunsmith

## Official Gunsmith contract

Activision's 2020 COD Mobile Gunsmith introduction documents nine attachment categories:

- Optic
- Laser
- Muzzle
- Barrel
- Underbarrel
- Ammunition
- Rear Grip
- Stock
- Perk

Up to **five** unique attachments can be equipped at once.

Attachments are unlocked by weapon leveling and typically include both a benefit and a drawback.

This trade-off model is the direct inspiration for our attachment modifier system.

## Stat dimensions to preserve

CODM community measurement work distinguishes:

- damage
- damage range
- fire interval / RPM
- sprint-to-fire
- ADS time
- ADS movement speed
- ordinary movement speed
- ADS bullet spread
- hip-fire spread
- vertical recoil
- horizontal recoil
- flinch
- reload time
- magazine
- bullet behavior/velocity where applicable

The in-game summary bars are not enough for simulation.

## Historical measured Gunsmith data

A 2020 research post by path.exe describes a 3D angular method for recoil:
- vertical recoil
- horizontal recoil
- ADS bullet spread / aim shake
- hip spread
- sprint-to-fire
- ADS
- mobility

The measurement explicitly distinguishes angular recoil path from a simple wall grouping.

A GPLv3 2021 Gunsmith-helper proof of concept by Somdev Sangwan stores percentage-like modifiers for universal/common attachments. We preserve selected values in:
`CODM_ATTACHMENT_BASELINE_2020_2021.md`

That dataset is **historical**, not current 2026 balance.

## Current source strategy

COD Mobile is live-service. Any weapon record must store:
- season
- build/patch if known
- MP vs BR
- base weapon
- exact attachment set

Current qualitative attachment lists remain available from community databases, while exact measured stats should be versioned.

## Attachment incompatibility

CODM has attachments that:
- occupy one slot
- disable another slot
- are weapon-specific/signature attachments
- fundamentally alter weapon function

Schema:

```text
AttachmentDefinition
  id
  slot
  compatibleWeapons[]
  excludesSlots[]
  excludesAttachments[]
  modifiers[]
  conversion?
  unlock
```

## Signature attachments

A signature barrel/kit may combine several normal effects:
- suppression
- recoil changes
- ADS spread
- range
- mobility penalties

Treat these as one authored attachment containing many modifiers, not a special weapon type.

## Build system

```text
WeaponBuild
  weaponId
  attachments[0..5]
  optic?
  mode
  patch
```

Build validator:
1. <= 5 attachments
2. one per slot unless definition allows otherwise
3. attachment compatible with weapon
4. exclusions satisfied
5. unlock eligibility optional for sandbox/testing

## Multiplayer vs Battle Royale

Keep mode-specific balance overrides:
`StatLayer = base -> mode -> patch -> attachments -> perks/buffs`

Never assume MP and BR use identical damage/range/armor behavior.

## Testing

For every imported CODM weapon:
- verify naked base stats
- verify one attachment at a time
- verify 2-attachment composition
- verify 5-attachment build
- verify incompatible slots
- verify MP vs BR
- compare simulated recoil/spread against recorded test data when available
