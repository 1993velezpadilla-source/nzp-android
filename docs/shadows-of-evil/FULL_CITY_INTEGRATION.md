# Shadows of Evil — Full City Integration

This document defines the integrated clean-room Morg City blockout generated as
`overlay/assets/source/maps/soe/soe.map`.

The standalone G1–G7 maps remain focused test harnesses. They are not intended
to be concatenated literally. The full-city generator rebuilds G1–G6 from their
source data, strips harness-only shells/spawns, translates the underground
layers, reconnects spawn zones, and instantiates the global Rift/Tram systems.

## Surface layout

G1–G4 intentionally share one coordinate frame:

- **G1**: Easy Street + Junction at the origin.
- **G2**: Canal District directly north of Junction.
- **G3**: Footlight District directly east of Junction.
- **G4**: Waterfront District directly south of Junction.

The three G1 district dead-end test stubs are removed in the integrated map.
The existing 1000-point district doors remain and meet the district entry
floors already authored in G2/G3/G4.

The one-piece G1 harness floor is also replaced by split slabs so Junction can
contain a real Beast-opened stair descent into the Rift.

## Underground layers

G5 is translated by `[224, 0, -704]`.

G6 is translated by `[224, -320, -704]`.

This keeps the Rift and Sacred Place below all current surface blockout
geometry while preserving their internal entity/target relationships.

The standalone G5 Sacred Place test seal is removed. A short physical stair
connector rises from the Rift floor into the G6 entry ledge.

### Junction -> Rift

The Junction Beast shock now targets `soe_full_junction_rift_access`.

The integrated generator creates:

1. a hole in the rebuilt Junction floor;
2. a powered entrance blocker;
3. a steep initial stair segment that clears the underside of the surface;
4. a protected long descent;
5. a landing aligned to the transformed G5 upper concourse.

This is physical traversal, not an invisible teleport.

## Rift pairs

The three district Rift pockets become real portal pairs in the integrated map:

- Canals <-> Canal Rift counterpart;
- Footlight <-> Footlight Rift counterpart;
- Waterfront <-> Waterfront Rift counterpart.

G5's standalone development portals are removed. The integrated map adds one
surface and one underground-return portal per district plus three surface
return destinations.

## Main quest geometry

`content/shadows_of_evil/mainquest_geometry.json` is the cross-phase source of
truth for the geometry required after the Sword step.

The generated map contains:

- Nero's main-quest book;
- the Rift Flag spawn;
- 8 Flag defense sites (2 per district);
- 4 Flag-delivery Keepers;
- 12 Flag Shadowman harassment markers;
- 4 Reborn Sword Keepers;
- 4 Arch-Ovum ritual circles.

The shared injector is used by G1–G5 so standalone tests and the integrated map
consume the same coordinates and runtime IDs.

## Sacred Place

G6 supplies:

- four Gateworm pedestals;
- two Gateworm-revealed wall-run surfaces;
- explicit wall-run trigger volumes;
- a lethal abyss;
- the fifth ritual;
- physical + logical Pack-a-Punch gating;
- four Shadowman Keepers;
- six Shadowman movement nodes;
- capture marker/table.

Pack-a-Punch remains hard-locked in QuakeC until `soe_pap_unlocked`, even if a
geometry bug somehow exposes the machine early.

## Global Tram and finale

The integrated map does **not** paste the G7 harness coordinates.

It instantiates `soe_tram_mover` at the actual G2 Canal station envelope and
uses the actual surface station envelopes for Footlight and Waterfront. Every
paid route costs 500 and passes the Junction hub before stopping at its
destination.

The integrated finale contains:

- 3 randomized-symbol viewing entities;
- 3 station rail-shock boxes;
- Junction train-hit hook;
- self-restoring giant Gateworm presentation;
- 3 finale Keepers;
- Beast torches;
- cleanse wisps.

Classic rail shocks require the Tram to be moving. The explicit
`soe_solo_finale` adaptation may perform the synchronization sequentially.

## Compilation and validation

The following are independent guards:

- phase workflows G1–G7;
- `validate-soe-mainquest-geometry.yml`;
- `validate-soe-full-city.yml`;
- QuakeC overlay compile workflow.

The full-city workflow regenerates `soe.map`, validates deterministic output,
runs an integration audit, builds NZ:P WADs, compiles with the pinned VHLT
pipeline, and requires a non-empty `soe.bsp`.

## Current calibration status

The blockout topology and gameplay contracts are deliberate. Exact BO3 world
coordinates are **not claimed**.

Still requiring live first-person calibration before a visual fidelity pass:

- lane widths and turn radii for Margwa navigation;
- exact stair/ledge heights;
- Rift/Sacred traversal timing;
- Tram ride speed and collision envelopes;
- Flag defense sightlines;
- Shadowman arena firing positions;
- wall-run feel on mobile touch controls;
- final lighting, fog, decals, reflections, rain/wetness and particle budgets.

Those are calibration/art tasks. They must not replace or bypass the already
validated gameplay topology.
