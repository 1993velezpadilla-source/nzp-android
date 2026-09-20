# Shadows of Evil — clean-room geometry reconstruction plan

## Purpose

The gameplay/quest layer is already far ahead of the physical world. This document defines how to reconstruct a collision-complete, mobile-safe Morg City without pretending that a redistributable editable BO3/WaW source map exists.

The target is not a loose "inspired by" layout. The target is the same recognizable traversal graph, combat widths, ritual-room access, Beast routes, Rift topology, Tram route and finale spaces, while using original/open replacement art where proprietary source assets cannot be redistributed.

## Source tiers

### Tier A — public topology / gameplay references

Use these to establish adjacency, doors, route order and named sub-areas:

- Steam community map overview: https://steamcommunity.com/sharedfiles/filedetails/?id=563005850
- CODZombie Shadows of Evil atlas: https://codzombie.com/atlas/shadows-of-evil
- Zombified per-area layouts: https://codzombified.blogspot.com/2015/11/shadows-of-evil-map-layout-call-of-duty.html
- CODZombie map guide: https://www.codzombie.com/maps/shadows-of-evil

These sources are strong for topology but are not authoritative for exact scale.

### Tier B — visual/shape references

- Klevi Alushi's unfinished World at War recreation (compiled public build; reference only until source/permission exists)
- out-of-bounds / noclip walkthroughs of the original map
- player screenshots/video captured from a legitimately owned copy
- historical Project Nightmare WaW recreation references

Use these to solve height, facade silhouette, corridor width, stair/ramp relationships and background skyline.

### Tier C — prohibited as redistributable source

Do not package:

- original BO3 fastfiles/xpaks
- leaked official Radiant map/entity dumps
- extracted Treyarch geometry, models, textures, sounds or scripts unless redistribution rights are explicitly established

A widely circulated Radiant dump for BO3 Zombies is described as containing entities/triggers/spawners/models but no brushes. It is therefore not a usable clean geometry base anyway.

## Reconstruction coordinate strategy

Do not invent a single global scale from a screenshot.

Each district gets a local frame first:

1. choose a stable doorway/gate/platform edge as local origin;
2. build the walkable floor graph and height changes;
3. match human traversal timing and sightlines;
4. place gameplay-significant anchors;
5. only then lock the district into the global Morg City frame.

The global frame is solved from Junction + tram rail geometry after Easy Street/Junction are stable.

## Build order

### Phase G0 — topology lock

No art pass.

Deliverables:
- area adjacency graph
- door/gate graph and costs
- surface/Rift portal links
- tram-station order
- ritual-room links
- one-way drops and Beast-only shortcuts
- finale-only interaction graph

Acceptance:
- every route in the public map/atlas can be represented without contradiction
- no gameplay system requires an unrepresented room or connection

### Phase G1 — Easy Street + Junction vertical slice

Build:
- four spawn windows
- Quick Revive corner
- RK5 / Sheiva wall positions
- Summoning Key truck/crate
- Beast pedestal
- 500-point exit
- Nero grapple/landing route
- Junction central crossing
- three 1000-point district gates
- tram crossing geometry
- Rift stair approach
- Pen crane sightline
- central statue/flag/finale anchor spaces

Acceptance:
- spawn loop feels correct at walking/sprinting speed
- four-window defense works
- Beast can complete spawn/Junction interactions
- Margwa can traverse Junction without clipping
- rail crossing remains readable on mobile

### Phase G2 — Canal District

Build low-to-high:
- district gate
- lower canal/water edge
- bridges/stairs
- upper/high-street loop
- Ruby Rabbit interior/vertical access
- Canal station/platform
- Rift portal room
- Beast badge route
- ritual-room route
- part/fuse/perk/build-table anchor spaces

Acceptance:
- lower and upper loops connect exactly as documented
- drop-down shortcuts are preserved
- tram symbol sightline works from moving tram
- zombie nav can pursue player across every public route

### Phase G3 — Footlight District

Build:
- district entry bottleneck
- lower street/car-park combat space
- elevated walkways
- Black Lace Burlesque
- Footlight station
- Rift portal
- Toupee interaction route
- theatre/coffee-sign sightlines
- ritual room and build-table area

Acceptance:
- narrow-to-open combat rhythm is preserved
- Beast shortcut and Apothicon statue access work
- tram glyph is visible from the intended side/window

### Phase G4 — Waterfront District

Build:
- district gate
- docks / water edge
- warehouse street
- elevated high street
- Anvil Boxing Gym
- Waterfront station
- Rift portal
- Championship Belt route
- shield/fuse/perk/build-table spaces

Acceptance:
- dock edges and vertical routes have reliable collision
- Anvil interior supports ritual + Margwa encounter
- tram glyph sightline works

### Phase G5 — Rift / Subway

Build:
- three portal arrival points
- on-foot entrance
- central subway room
- Widow's Wine and Mule Kick anchor areas
- Civil Protector fuse/master-switch area
- sword glyph wall
- sword/egg altar
- subway-car collision
- Sacred Place approach

Acceptance:
- all three district portals remain spatially distinguishable
- no portal exit overlaps spawn/nav
- sword-glyph interaction works cleanly on touch controls

### Phase G6 — Sacred Place / Pack-a-Punch

Build:
- four Gateworm placements
- wall-run traversal
- fifth-ritual arena
- PaP portal position
- Shadowman/finale combat envelope
- Keeper positions
- fall/kill volumes
- final beam/capture anchors

Acceptance:
- wall-run cannot softlock player
- boss arena supports 1–4 players and Margwas
- finale interaction points remain reachable under pressure

### Phase G7 — Tram network

Build only after three surface districts are locked.

Requirements:
- Canal ↔ Footlight ↔ Waterfront station graph
- moving tram collision
- platform gaps
- symbol-view windows
- Bootlegger interior wallbuy
- route selector
- station shock boxes
- Junction giant-Gateworm hit envelope

Acceptance:
- no tunneling through players at mobile frame-rate dips
- symbols are visible for the intended observation window
- final rail-electrification/train strike sequence is deterministic

## Geometry fidelity rules

Gameplay-critical dimensions have priority over decorative fidelity:
- doorway width
- stair width/height
- lane width
- railing collision
- drop heights
- cover height
- sightline occlusion
- Margwa turning radius
- zombie window reach
- train-platform gap
- Beast grapple landing space
- wall-run surface length/angle

Decorative facades and skyline may use simplified depth/LOD if the silhouette and major sightlines remain convincing.

## Mobile performance partition

Treat the world as streamable cells:
- Easy Street
- Junction
- Canal lower
- Canal high/Ruby
- Footlight lower
- Footlight high/Burlesque
- Waterfront lower/docks
- Waterfront high/Anvil
- three tram stations
- Rift
- Sacred Place
- skyline/background clusters

Rules:
- gameplay collision stays loaded for adjacent cells before visual streaming completes
- zombie nav links across a gate become active before the player crosses it
- distant skyline uses non-colliding proxies
- portal destinations prewarm before activation
- Tram path + station collision remain resident while tram is active

## Reconstruction validation matrix

Every zone must pass all of:
- player traversal
- zombie traversal
- Margwa traversal
- Beast traversal
- collision sweep at crouch/walk/sprint/slide
- interaction reach on touch
- ritual spawn envelope
- enemy spawn line-of-sight test
- door open/closed nav state
- performance budget
- restart/reload determinism

## Current next action

Build **G0 topology lock**, then **G1 Easy Street + Junction blockout**.

Do not start decorative art until G1 traversal, Beast interactions, Margwa navigation and tram-crossing geometry are all stable.
