# NZ:P Android — Zombies Portable Enhanced

Android/mobile overlay project for **Nazi Zombies: Portable**.

## Active map: Shadows of Evil

Branch: `feature/shadows-of-evil-completion`

The Shadows of Evil work is split into four independent tracks so none of them can hide behind the others:

1. **World fidelity** — Morg City geometry, collision, traversal, zombie navigation, props, decals, lighting, fog, audio zones and skyline.
2. **Gameplay fidelity** — Beast Mode, rituals, Rift/Pack-a-Punch, Tram, Apothicon Sword, Margwa/Parasites/Insanity Elementals, Civil Protector, buildables and round behavior.
3. **Quest fidelity** — full four-player main quest/finale plus tracked optional portable solo adaptation.
4. **Secrets/lore fidelity** — side Easter eggs, five ciphers, ten scrap pieces, twelve phone/portal messages, music-event hooks and the nine map-specific challenges.

The public Klevi Alushi World at War Shadows of Evil release is treated as a **reference/source candidate**, not as redistributable content. The public release is unfinished and an editable Radiant source has not been located. The preferred path is author-approved editable source; the fallback is clean-room geometry reconstruction from public visual references and measurements.

## Start here

- `docs/shadows-of-evil/MASTER_RESEARCH.md`
- `docs/shadows-of-evil/GEOMETRY_RECONSTRUCTION.md`
- `docs/shadows-of-evil/QUAKEC_PORT.md`
- `content/shadows_of_evil/manifest.json`
- `content/shadows_of_evil/quest_graph.json`
- `content/shadows_of_evil/district_fidelity.json`
- `content/shadows_of_evil/geometry_reconstruction.json`
- `content/shadows_of_evil/lore_collectibles.json`
- `content/shadows_of_evil/side_quests.json`
- `content/shadows_of_evil/enemies.json`
- `content/shadows_of_evil/provenance.json`

## Upstream pins

Runtime sources are pinned in `upstreams.lock.json`. Run `scripts/fetch_upstreams.sh` on a development machine to materialize them.

The project deliberately does **not** auto-package third-party/proprietary map assets whose redistribution rights have not been verified.


## Android HUD integration note

- **Li'l Arnie must have a dedicated mobile tactical button** mapped to `impulse 35`.
- It must be separately movable/resizable in Custom HUD, show remaining charges, and stay independent from firearm/grenade slots.
- Do not ship the Android HUD with Arnie accessible only through a generic Swap or grenade-cycle control.
