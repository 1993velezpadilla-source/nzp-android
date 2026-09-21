# Zombies Core Systems — Open Research Pack

This pack extends the NZ:P gameplay-core and special-round research into the systems a complete round-based Zombies game needs beyond spawning and enemy AI.

## Why this exists

A convincing Zombies engine is not only:

`round -> spawn -> chase -> kill`

It is also:

`economy -> drops -> perks -> weapons -> box -> upgrades -> down/revive -> map progression -> traps -> quests -> multiplayer authority -> reset/recovery`

Most long-session bugs come from interactions between those systems, not from the basic zombie chase loop.

## Documents

- `POWERUPS_DROP_DIRECTOR.md`
- `WEAPON_ECONOMY_WALLBUYS.md`
- `MYSTERY_BOX_LOOT_DIRECTOR.md`
- `PACK_A_PUNCH_UPGRADE_PIPELINE.md`
- `PERKS_STATUS_EFFECTS.md`
- `DOWNED_REVIVE_RESPAWN.md`
- `QUEST_LOGIC_BUILDABLES.md`
- `TRAPS_WORLD_EVENTS.md`
- `COMBAT_CRAWLERS_DISMEMBERMENT.md`
- `MULTIPLAYER_AUTHORITY_SECURITY.md`
- `MAP_CONFIG_EDITOR_MODDING.md`
- `VALIDATION_TEST_MATRIX.md`
- `SOURCE_MANIFEST.md`

## Primary reusable references

### Der Koloss Community Edition
MIT source code. Strong modern reference for:
- host-authoritative co-op
- Mystery Box lifecycle
- Pack-a-Punch state
- perk drink timeline
- revive synchronization
- crawler-specific hitboxes
- interaction line-of-sight
- snapshot validation
- hot-path validators

### nZombies Unlimited
MIT. Strong modular reference for:
- power-up registration/drop cycle
- round ownership
- revive/bleedout
- wall buys
- barricades
- Mystery Box spawn-point reservation
- map logic graph
- configuration/modding architecture

### Open Zombies
GPLv3 Unity/C# project. Useful older clean-room-ish reference for:
- interactable base classes
- Mystery Box
- doors
- wall weapons
- points
- round controller
- player/zombie object separation

### Project Blue Bean
MIT Godot 4.6 project. Useful lightweight modern reference for:
- round survival
- economy
- doors
- wall refill/purchases
- data-driven weapons

## Reference-only sources

### Zombie Survival — Full Game System showcase
Public documentation, but repository is **All Rights Reserved** and states that source code is not included.

Useful only for architectural comparison:
- authoritative server
- seven zombie classes
- per-bone hitboxes
- PaP tiers
- 14 drop types
- map editor
- dismemberment/ragdoll
- EasterEggSystem
- down/revive/player lifecycle

No code or media from it should be copied.

### IW4x Zombies
Very useful behavioral documentation for:
- box pity logic
- power-up drop restrictions
- PaP timeout/loss
- perks
- teleporter rewards
- special grenades

Treat source as reference until exact redistribution terms are confirmed.

## Core design rule

Every system should expose a small gameplay contract and keep rendering/audio/network presentation behind it.

Example:

```text
PowerupDefinition
  id
  scope
  duration
  eligibility
  onActivate
  onExpire

PowerupDirector
  dropCycle
  perRoundCap
  droughtProtection
  spawnResolver
```

The RoundDirector should never need to know the details of Max Ammo, Mystery Box, PaP, a perk, or an Easter egg.
