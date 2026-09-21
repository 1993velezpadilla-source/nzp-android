# Black Ops 7 — Weapon Progression / Current Stat Snapshot

Research snapshot: 2026-09-21.

## Official stat vocabulary

The official Black Ops 7 weapon briefing exposes a granular set very close to the normalized schema we designed.

### Firepower
- fire rate
- damage
- range
- firing ping on Mini-Map

### Accuracy
- minimum Hip Fire Spread
- maximum Hip Fire Spread
- Recoil Gun Kick
- Horizontal Recoil
- Vertical Recoil
- Bullet Velocity
- Flinch Resistance

### Mobility
- crouch movement
- normal movement
- sprint movement
- ADS movement

### Handling
- reload quickness with rounds remaining
- empty reload quickness
- ADS speed
- Sprint-to-Fire
- Weapon Swap speed

Official source:
https://www.callofduty.com/blog/2025/11/call-of-duty-black-ops-7-ready-for-launch-weapons-equipment

This is strong evidence that our schema must preserve gun kick, horizontal recoil and vertical recoil separately.

## Attachments

The official source says Primary weapons and Pistols accept attachments and that attachments can affect one or more of the four major stat categories.

Black Ops 7 current builds can use more attachment slots than the five-slot CODM/MWII pattern in certain systems/loadouts, so our generic build object must keep `attachmentLimit` data-driven.

## Weapon Prestige

Official BO7 progression adds a weapon-specific prestige loop.

Source:
https://www.callofduty.com/blog/2025/11/call-of-duty-black-ops-7-ready-for-launch-progression-prestige

### Base leveling
Level the weapon to its maximum level and unlock its normal attachments.

The official example MXR-17 has Max Weapon Level 47.

### Weapon Prestige 1
When chosen:

- weapon returns to Level 1;
- earned attachments relock;
- Optics stay permanently unlocked;
- customization/camos/reticles/charms/decals/stickers remain;
- one unique **Prestige Attachment** for that weapon becomes permanently unlocked;
- one chosen normal attachment can be permanently unlocked;
- a prestige build/camo/icon is granted.

Official example Prestige Attachment:
MXR-17 MFS Semi-Auto Fast Mag, changing the rifle into a semi-auto behavior with faster aiming/reload and reworked recoil but more damage falloff.

### Weapon Prestige 2
Another reset/relevel cycle:
- another permanent attachment unlock;
- second prestige camo;
- weapon-specific charm.

### Weapon Prestige Master
After the prestige cycles:
- weapon continues to Master Level 250;
- normal Weapon Progression attachments become permanently unlocked;
- additional mastery cosmetics unlock on the path.

## Schema

```text
WeaponProgression:
  baseMaxLevel
  prestigeStages[]
    resetsLevel
    relocksAttachments
    preservedCategories[]
    permanentUnlockCount
    uniqueAttachment?
  masteryMaxLevel
```

## Current technical data

Current CODMunity BO7 comparator:
https://codmunity.gg/weapon-stats/bo7

Observed source state:
- updated 17/09/2026
- Season 5 in the retrieved snapshot

The comparator exposes:

- damage/TTK
- bullet velocity
- RPM
- gun kick
- horizontal recoil
- vertical recoil
- mobility/handling
- magazine and hipfire metrics
- builds with as many as eight attachments in the displayed BO7 loadout context

The current source should be stored as **community_current**, never confused with official balance tables.

## Import rule

Every BO7 record requires:

```text
sourceGame=BO7
season
observedAt
mode
weapon
attachments[]
source
loadingState
stats{}
```

because current live balance and attachment calculations can change.
