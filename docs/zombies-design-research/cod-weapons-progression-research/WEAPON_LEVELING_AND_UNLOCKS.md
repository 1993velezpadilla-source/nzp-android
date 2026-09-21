# Weapon Leveling / Attachment Unlock Evolution

Call of Duty has used several distinct progression models. We should support all of them as data.

## Challenge-unlock era

### Call of Duty 4 / World at War style

Attachments are tied to weapon-specific Marksman/challenge milestones rather than a modern weapon-XP tree.

World at War examples documented by community reference:
- 25-kill Marksman milestones can unlock suppressor/flash hider/bipod/bayonet/grip depending weapon
- later kill milestones unlock aperture/telescopic sights, magazines, rifle grenades, etc.

This is:

```text
UnlockRequirement:
  type = weaponChallenge
  metric = kills/headshots/attachmentKills
  threshold
```

### Modern Warfare 2 (2009)

Weapon attachment progression forms a dependency graph of challenges.

Assault-rifle example pattern:
- kills unlock Grenade Launcher
- more kills unlock Red Dot
- then Silencer
- ACOG
- FMJ
- secondary challenge branches unlock Shotgun/Holographic/Heartbeat/Thermal/Extended Mags

This is not a simple linear weapon level.

Use:
`unlockNode.requires = challengeId/attachmentId`

## Currency/token era

### Black Ops
Player progression plus COD Points purchasing.

### Ghosts
Squad Points can directly unlock weapons, attachments, perks and equipment in user-chosen order.

Schema needs:
```text
unlockCurrency
cost
prerequisites
```

## Weapon-level era

### Modern Warfare 3
Weapon XP/levels unlock attachments plus Weapon Proficiencies.

### Black Ops II / later Treyarch
Weapon level progression becomes a standard mechanism; attachments unlock at specific weapon levels.

## Gunsmith era

### Modern Warfare (2019)

Activision documents:
- kills/enemy defeats give weapon XP
- each weapon level unlocks an attachment, weapon perk or camo
- Gunsmith consumes those unlocks

### Call of Duty: Mobile

Officially:
- 9 attachment categories
- maximum 5 attached
- level weapon to unlock attachments

### Black Ops Cold War

Officially:
- each weapon has its own progression path
- weapon XP unlocks attachments
- normally max five attachments
- Gunfighter can allow eight primary attachments

### Modern Warfare II

Introduces Weapon Platforms:
- platform-specific attachments
- universal attachments
- Receivers unlock new weapons
- maxing weapon/platform spreads unlocks across compatible weapons
- max weapon level originally unlocked Weapon Tuning

### Modern Warfare III

Keeps shared attachment progression and adds:
- Armory Unlocks
- Aftermarket Parts / Conversion Kits after max-level + challenge
- attachment unlocked once can become available on other compatible weapons

### Black Ops 6

Officially:
- every weapon has an individual leveling journey
- most primaries around 40–50 levels
- each level commonly unlocks an attachment
- class optics can be shared
- global weapon builds across MP/Zombies/Warzone

### Black Ops 7

Officially adds Weapon Prestige:
- level weapon to max
- optional Prestige resets weapon level and relocks earned attachments
- optics stay permanently unlocked
- prestige grants a weapon-unique Prestige Attachment
- one permanent attachment unlock can bypass relock
- additional prestige/mastery progression continues

## Our progression schema

```text
ProgressionDefinition
  model:
    challengeGraph
    playerRankPlusCurrency
    weaponLevels
    platformTree
    armoryChallenges
    weaponPrestige
  maxLevel?
  xpCurve?
  unlockNodes[]
  prestige?
```

## Design for our Zombies game

We can combine successful ideas without copying one title exactly:

- weapon use earns Weapon XP
- levels unlock functional attachment categories gradually
- special attachment at mastery
- optional prestige after mastery
- optics can become account/class-wide
- quest/boss attachments can use challenge unlock nodes
- attachments remain gameplay trade-offs, not pure upgrades
