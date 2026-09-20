# Shadows of Evil — completion research master

## Goal
Finish a mechanically complete, mobile-safe Shadows of Evil recreation for the NZ:P Android project without silently dropping map systems. Geometry fidelity and environmental dressing are tracked separately from gameplay fidelity so the map can become playable before the last decorative pass.

## Hard source status
The strongest fan-map base located so far is **Klevi Alushi's unfinished World at War remake**. The public mirror labels it *Unfinished*, 466.83 MB, T4M-required, and says the last public build does not even have a skybox. The download is a compiled installer; an editable Radiant `.map` source has not been located publicly.

That means the project must not pretend an editable base exists. Geometry work is gated on either author-approved source or a clean reconstruction. Gameplay systems are not gated and are specified below.

## Canonical area graph
Easy Street -> Junction -> three main districts:
- Canal District -> Ruby Rabbit -> Canal station -> Rift access
- Footlight District -> Black Lace Burlesque -> Footlight station -> Rift access
- Waterfront District -> Anvil Boxing Gym / docks -> Waterfront station -> Rift access
- Rift/Subway -> Sacred Place / Pack-a-Punch
- Tram links Canal, Footlight and Waterfront through the central Junction tracks.

## Core mechanics that must be present
- Beast Mode: shock, melee/smash, grapple, teammate revive, timed/charge behavior, extended finale variant.
- No global power switch. Individual perk/access panels are powered in Beast Mode.
- Ritual chain: Summoning Key, Pen, Badge, Toupee/Hair Piece, Belt, four rituals, four Gateworms, fifth ritual, PaP.
- Ritual #2 and #4 Margwa events.
- Tram: 500-point travel, proper route direction, sword glyph visibility, Bootlegger wallbuy.
- Apothicon Sword: three tram glyphs, Rift glyph wall, egg, four soul statues, sword pickup.
- Reborn Sword: character ghost, Arch-Ovum, four Margwa circles, one circle per player per round.
- Main quest after swords: book -> flag -> four district Keeper frees -> Shadowman boss -> infinite Margwa finale -> train strike -> three station shocks -> three Keeper shocks -> ending.
- Civil Protector fuses/master switch/call boxes.
- Rocket Shield, Goddard Apparatus.
- Fumigators, Harvest Pods and maturation.
- Apothicon Servant parts/build.
- Margwa, Parasites, Insanity Elementals, Keepers.
- Side Easter eggs tracked in `side_quests.json`.

## Canonical behavior already pinned
- Easy Street has four zombie windows, Quick Revive, RK5, Sheiva, a Fumigator spawn set and Beast pedestal.
- Easy Street -> Junction costs 500. Each main district gate costs 1000.
- Jugger-Nog, Speed Cola and Double Tap rotate between district positions each match; broken bottles in Junction communicate the assignment.
- Pack-a-Punch costs 5000.
- Civil Protector costs 2000 after all three fuses are installed.
- Tram costs 500.
- Margwas begin regular scheduling around round 8, with extra scripted spawns for rituals, sword upgrades and quest phases.
- Original final quest requires four players. Portable mode may optionally support a solo-compatible timing adaptation, while Classic Co-op preserves original synchronization.

## Environmental fidelity checklist
Audit district by district:
- sidewalk seams, street cracks, drains, curb cuts, potholes and road markings
- rails, sleepers, overhead tram infrastructure and stations
- every staircase, railing, ledge and rooftop route
- Beast grapple anchors, smashables and electrical boxes
- neon signs and lighting spill
- doors, windows, shutters and ritual-room dressing
- posters, awnings, crates, trash, tables, chairs, barrels and carts
- sewer/canal waterline and concrete damage
- skyline silhouettes and unreachable background buildings
- fog, sky color, apocalypse sky state and portal lighting
- bullet materials, decals, blood, destruction, ambience and reverb
- collision on stairs, railings, roofs, ledges, tram and props

## High-value geometry reference
The YouTube out-of-bounds walkthrough below explicitly timestamps Easy Street, Junction, Waterfront, Docks, Boxing Gym, Footlight, city streets, Burlesque, Canal, Ruby Rabbit, Metro, PaP and the giant Apothicon. It is useful for otherwise-hidden geometry and skyline reference:
https://www.youtube.com/watch?v=FYF03XFb0YE

## Research references
- Klevi release mirror: https://callofdutyrepo.com/2019/06/29/shadows-of-evil/
- Klevi portfolio: https://klevi.artstation.com/
- Steam complete guide, updated 2024: https://steamcommunity.com/sharedfiles/filedetails/?id=550319350
- Steam map overview: https://steamcommunity.com/sharedfiles/filedetails/?id=563005850
- CODZombie map: https://codzombie.com/maps/shadows-of-evil
- CODZombie atlas: https://codzombie.com/atlas/shadows-of-evil
- MargwaNetwork: https://margwa.net/shadows-of-evil
- UGX Margwa behavior reference: https://www.ugx-mods.com/forum/models/125/margwa-from-shadows-of-evil/23286/

## Implementation order
1. Obtain or recreate collision-complete Morg City shell.
2. Validate player traversal and zombie waypoint graph.
3. Beast Mode + all Beast interactions.
4. Four rituals + Rift + PaP.
5. Tram + sword.
6. Margwa/Parasite/Elemental enemy layer.
7. Reborn sword and flag/main-quest graph.
8. Shadowman boss/finale.
9. Buildables, Civil Protector and Harvest Pods.
10. Side Easter eggs.
11. Full environment/lighting/audio/FX pass.
12. Mobile perf pass with Low/Medium/High/Max presets.
