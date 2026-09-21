# Source Manifest / Provenance

Research snapshot: 2026-09-21.

## Green — clearly licensed open-source

### Der Koloss Community Edition
Repository: `rishipr/der-koloss-ce`
Source license: MIT.
Assets: separate terms; inspect NOTICE.

Inspected blobs:
- `README.md` — `c689c70e3a9ad37bb085f8c43cb4ea3fa2f99554`
- `LICENSE` — `c13a2ac87ce6851229abeed8ac9626ab29061e23`
- `NOTICE.md` — `3468fe9bd195792dda42952ade8a7afbdc5ed228`
- `js/game.js` — `239694c3a47e7bbd83ef08cdf359a99b29b55c13`
- `js/zombies.js` — `4de58e475227551df666bc852268bfab75cb64ac`
- `js/gameplay-rules.js` — `1a238accc06682a0a5d4fba0af4d02ef8f308703`
- `js/multiplayer-contracts.js` — `0057cbd415a16a6cdd93a1f54bce94d30c5a1c65`
- `js/interaction-rules.js` — `aae4153f02db12d426f4cdefd5a5c4d7eebeee99`
- `js/weapons.js` — `a1dd4789f9447c79586089fd5b06714d88713e93`

### nZombies Unlimited
Repository: `Zet0rz/nZombies-Unlimited`
License: MIT.
License blob: `9aee9c66c6e687073f5804b9af354e4f8dda71e6`

Inspected blobs:
- round: `da462d66c36e141e8d25c567c90e48c3fc6c8055`
- powerups: `200cf2ee6c76dde9a17f28b07afb14efee052d0d`
- mystery box: `3a064f44fefcbed7dde315616312a3d2b098631b`
- revive: `683524b6fec70a81801853ed624ba2a15509827c`
- wall buys: `5c0aa9e958b59d5f43da616e53aea1c5fb50be38`
- barricades: `d6f36c15322a4a99b05bf5a5100b7c20c5a9a455`
- logic manager: `aa8e9b20ca3610a3a67ffd11d8148727d6ab3765`

### Open Zombies
Repository: `team-obsession/open-zombies-code`
License: GPLv3.
License blob: `9cecc1d4669ee8af2ca727a5d8cde10cd8b2d7cc`
Observed revision in search results: `8c7ca8953265f58bfa6acec27e830bf44bfe7639`

Useful paths:
- `Scripts/GameController.cs`
- `Objects/MysteryBox.cs`
- `Scripts/MysteryBoxScript.cs`
- `Objects/Door.cs`
- `Objects/WallWeapon.cs`
- `Objects/Player.cs`
- `Scripts/GunInstance.cs`

### Project Blue Bean
Repository: `ariesyous/projectbluebean`
License: MIT.
License blob: `5ff02fda98bf57b9e3d92bc3b8eb6e013e2847be`
README blob: `306bf4fa824f66ad9414978dc334a10c6b481b61`

Useful as a simpler Godot round/economy reference.

## Yellow — copyleft

### nZombies
Repository: `Zet0rz/nzombies`
License: GPLv3.
License blob previously inspected:
`ef7e7efc09c9d471c391f05b9567966928085840`

Direct code reuse carries GPL obligations.

## Reference only / licensing unclear or restrictive

### Zombie Survival — Full Game System
Repository: `Suleiman700/Zombie-Survival-Game-Showcase`
License: **All Rights Reserved**.
License blob:
`6673d7618a7e6db68c5d6ed4c5ba16dd1930e6a1`

README explicitly says source is not included.
Use only public design/architecture descriptions.

### IW4x Zombies
Repository: `AmethystTower/iw4x-zombies`
README calls IW4x edition open source, but a conventional root license was not resolved during prior audit.
Use behavioral reference unless exact terms are confirmed.

### BO Zombies Maps Maker
Repository: `shippuden1592/BO-Zombies-Maps-Maker`
No license resolved in this audit and content is intertwined with proprietary Call of Duty mod tools/assets.
Behavioral/reference only.

### Decompiled/generated proprietary GSC mirrors
Reference behavior only.
Do not import code/assets.

## Rule for future imports

Any direct code import must record:
- source repository
- revision
- source path
- license
- destination path
- modifications

Any asset import separately records:
- creator/source
- asset-specific license
- commercial-use rights
- attribution
- derivative restrictions

Never infer asset rights from the repository's code license.
