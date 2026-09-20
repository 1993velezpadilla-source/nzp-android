#!/usr/bin/env python3
"""Generate the provisional Shadows of Evil G1 blockout as a Valve 220 .map.

This is intentionally a gameplay/blockout generator, not a claim of canonical
BO3 coordinates. The source of truth is content/shadows_of_evil/g1_blockout.json.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC_PATH = ROOT / "content" / "shadows_of_evil" / "g1_blockout.json"
OUTPUT_PATH = ROOT / "overlay" / "assets" / "source" / "maps" / "soe_g1" / "soe_g1.map"

WORLD_WAD = "../../textures/wad/Example_02.wad"
FLOOR_TEX = "tiles_me"
WALL_TEX = "facility_wall_l"
CEILING_TEX = "ceilings_64"
BLOCK_TEX = "wall_plainr"
TRIGGER_TEX = "trigger"
NULL_TEX = "null"


def fmt(v):
    if isinstance(v, int) or float(v).is_integer():
        return str(int(v))
    return f"{v:.3f}".rstrip("0").rstrip(".")


def plane(a, b, c, tex, uaxis, vaxis):
    return (
        f"( {fmt(a[0])} {fmt(a[1])} {fmt(a[2])} ) "
        f"( {fmt(b[0])} {fmt(b[1])} {fmt(b[2])} ) "
        f"( {fmt(c[0])} {fmt(c[1])} {fmt(c[2])} ) "
        f"{tex} [ {uaxis} ] [ {vaxis} ] 0 1 1"
    )


def box_brush(mins, maxs, tex=BLOCK_TEX):
    x1, y1, z1 = mins
    x2, y2, z2 = maxs
    if not (x1 < x2 and y1 < y2 and z1 < z2):
        raise ValueError(f"invalid box {mins} -> {maxs}")
    p = []
    p.append(plane((x1,y1,z1), (x1,y1+1,z1), (x1,y1,z1+1), tex, "0 -1 0 0", "0 0 -1 0"))
    p.append(plane((x1,y1,z1), (x1,y1,z1+1), (x1+1,y1,z1), tex, "1 0 0 0", "0 0 -1 0"))
    p.append(plane((x1,y1,z1), (x1+1,y1,z1), (x1,y1+1,z1), tex, "1 0 0 0", "0 -1 0 0"))
    p.append(plane((x2,y2,z2), (x2,y2,z2+1), (x2,y2+1,z2), tex, "0 1 0 0", "0 0 -1 0"))
    p.append(plane((x2,y2,z2), (x2+1,y2,z2), (x2,y2,z2+1), tex, "-1 0 0 0", "0 0 -1 0"))
    p.append(plane((x2,y2,z2), (x2,y2+1,z2), (x2+1,y2,z2), tex, "1 0 0 0", "0 -1 0 0"))
    return "{\n" + "\n".join(p) + "\n}"


def point_entity(classname, origin, **keys):
    lines = ["{", f'"classname" "{classname}"']
    for key, value in keys.items():
        if value is None:
            continue
        if isinstance(value, (list, tuple)):
            value = " ".join(fmt(v) for v in value)
        lines.append(f'"{key}" "{value}"')
    lines.append(f'"origin" "{" ".join(fmt(v) for v in origin)}"')
    lines.append("}")
    return "\n".join(lines)


def brush_entity(classname, mins, maxs, texture=TRIGGER_TEX, **keys):
    lines = ["{", f'"classname" "{classname}"']
    for key, value in keys.items():
        if value is None:
            continue
        lines.append(f'"{key}" "{value}"')
    lines.append(box_brush(mins, maxs, texture))
    lines.append("}")
    return "\n".join(lines)


def stair_boxes(x0, y0, z0, count, step_run, step_rise, width, direction=1):
    out = []
    for i in range(count):
        if direction > 0:
            x1 = x0 + i * step_run
            x2 = x1 + step_run
        else:
            x2 = x0 - i * step_run
            x1 = x2 - step_run
        z2 = z0 + (i + 1) * step_rise
        out.append(((x1, y0, z0), (x2, y0 + width, z2)))
    return out


def generate(spec):
    entities = []
    world_brushes = []

    # Sealed test volume. All dimensions are provisional.
    world_brushes += [
        box_brush((-896,-576,-48), (768,576,0), FLOOR_TEX),
        box_brush((-896,-576,0), (-864,576,448), WALL_TEX),
        box_brush((736,-576,0), (768,576,448), WALL_TEX),
        box_brush((-896,-576,0), (768,-544,448), WALL_TEX),
        box_brush((-896,544,0), (768,576,448), WALL_TEX),
        box_brush((-896,-576,448), (768,576,480), CEILING_TEX),
    ]

    # Easy Street facade masses leave a central playable street.
    world_brushes += [
        box_brush((-832,224,0), (-112,304,224), WALL_TEX),
        box_brush((-832,-304,0), (-112,-224,224), WALL_TEX),
        box_brush((-832,-224,0), (-768,224,224), WALL_TEX),
        # Junction framing/building masses.
        box_brush((-48,240,0), (160,432,192), WALL_TEX),
        box_brush((-48,-432,0), (160,-240,192), WALL_TEX),
        box_brush((448,144,0), (624,432,192), WALL_TEX),
        box_brush((448,-432,0), (624,-144,192), WALL_TEX),
        # Stubs beyond the three district gates.
        box_brush((176,464,0), (464,528,160), BLOCK_TEX),
        box_brush((176,-528,0), (464,-464,160), BLOCK_TEX),
        box_brush((656,-144,0), (720,144,160), BLOCK_TEX),
    ]

    # Nero elevated landing + crude Beast-only visual platform.
    world_brushes += [
        box_brush((-432,208,144), (-256,304,160), BLOCK_TEX),
        box_brush((-288,224,160), (-240,288,224), WALL_TEX),
    ]

    # Junction tram crossing: thin visible rails, kept low enough to step over.
    world_brushes += [
        box_brush((-64,-46,0), (640,-38,8), BLOCK_TEX),
        box_brush((-64,38,0), (640,46,8), BLOCK_TEX),
    ]

    # Rift-approach visual stair marker. It is intentionally not a real Rift yet.
    for mins, maxs in stair_boxes(-32, -400, 0, 5, 28, 8, 96, direction=1):
        world_brushes.append(box_brush(mins, maxs, BLOCK_TEX))

    world = [
        "// Game: Nazi Zombies Portable",
        "// Format: Valve",
        "// AUTO-GENERATED by scripts/generate_soe_g1_blockout.py",
        "// G1 coordinates are provisional clean-room blockout dimensions.",
        "{",
        '"mapversion" "220"',
        f'"wad" "{WORLD_WAD}"',
        '"classname" "worldspawn"',
        '"chaptertitle" "Shadows of Evil - G1 Blockout"',
        '"location" "Morg City - Easy Street / Junction"',
        '"person" "NZ:P Android clean-room reconstruction"',
        '"light" "80"',
    ]
    for i, brush in enumerate(world_brushes):
        world += [f"// brush {i}", brush]
    world.append("}")
    entities.append("\n".join(world))

    # Player spawns.
    for p in spec["playerSpawns"]:
        entities.append(point_entity(
            p["class"], p["origin"], weapon=0, currentmag=0, currentammo=0, angle=p["angle"]
        ))

    # Four Easy Street windows with simple AI chains.
    for idx, w in enumerate(spec["windows"], start=1):
        path_name = f"soe_g1_path_{idx}"
        window_name = w["id"]
        entities.append(point_entity(
            "spawn_zombie", w["zombie"], spawnflags=2, angle=w["angle"],
            targetname="soe_g1_spawn", target=path_name
        ))
        entities.append(point_entity(
            "path_corner", w["path"], wait=0, spawnflags=0,
            targetname=path_name, target=window_name
        ))
        entities.append(point_entity(
            "item_barricade", w["origin"],
            model="models/misc/window.mdl", skin=0, health=6, health_delay=6,
            oldmodel="sounds/misc/barricade.wav",
            aistatus="sounds/misc/barricade_destroy.wav",
            spawnflags=0, angle=w["angle"], targetname=window_name
        ))

    # Junction perimeter spawns are open-area nodes for the G1 pursuit test.
    for j in spec.get("junctionSpawns", []):
        entities.append(point_entity(
            "spawn_zombie", j["origin"], spawnflags=7, angle=j["angle"],
            targetname="soe_g1_junction"
        ))

    # Zones use target groups so the stock NZ:P zone system can activate AI.
    for z in spec["zones"]:
        if z["id"] == "easy_street":
            adjacent = "junction"
            doorway_targets = "easy_to_junction"
        else:
            adjacent = "easy_street"
            doorway_targets = "easy_to_junction, junction_to_canal_stub, junction_to_waterfront_stub, junction_to_footlight_stub"
        keys = {
            "zone_name": z["id"],
            "zone_target": z["zoneTarget"],
            "adjacent_zones": adjacent,
            "door_way_targets": doorway_targets,
        }
        entities.append(brush_entity(
            "spawn_zone", z["mins"], z["maxs"], TRIGGER_TEX, **keys
        ))

    # Doorways. The three district doors are deliberate G1 dead-end stubs.
    for d in spec["doors"]:
        entities.append(brush_entity(
            "func_door_nzp", d["mins"], d["maxs"], NULL_TEX,
            targetname=d["id"], cost=d["cost"], speed=100, sounds=1,
            wait=4, lip=8, distance=96, dmg=0, health=0, spawnflags=0
        ))

    # SoE mapper-facing anchors.
    for a in spec["anchors"]:
        keys = {k:v for k,v in a.items() if k not in {"classname","origin"}}
        entities.append(point_entity(a["classname"], a["origin"], **keys))

    # Basic lighting to make blockout readable.
    for org, brightness in [
        ((-640,0,192),300),((-320,0,192),280),((64,0,192),300),
        ((320,0,208),320),((544,0,192),260),((240,320,176),220),((240,-320,176),220)
    ]:
        entities.append(point_entity("light", org, _light=brightness, wait=1, style=0))

    return "\n".join(entities) + "\n"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true",
                        help="fail if checked-in output differs from generated output")
    parser.add_argument("--stdout", action="store_true")
    args = parser.parse_args()

    spec = json.loads(SPEC_PATH.read_text(encoding="utf-8"))
    output = generate(spec)

    if args.stdout:
        print(output, end="")
        return

    if args.check:
        if not OUTPUT_PATH.exists():
            raise SystemExit(f"missing generated map: {OUTPUT_PATH}")
        current = OUTPUT_PATH.read_text(encoding="utf-8")
        if current != output:
            raise SystemExit(
                "G1 map is stale; run scripts/generate_soe_g1_blockout.py and commit the result"
            )
        print("SOE G1 generated map is deterministic and up to date")
        return

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(output, encoding="utf-8", newline="\n")
    print(f"wrote {OUTPUT_PATH.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
