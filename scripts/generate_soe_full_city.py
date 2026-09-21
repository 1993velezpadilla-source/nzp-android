#!/usr/bin/env python3
"""Assemble the clean-room Shadows of Evil phase maps into one Valve 220 map.

The standalone G1-G6 maps remain small compile/test harnesses. This assembler:
- regenerates them from source data;
- strips their standalone outer hulls/test spawns;
- preserves gameplay brush + point entities;
- translates Rift/Sacred Place underground;
- reconnects cross-phase spawn zones;
- adds the real three-pair Rift links and actual-district Tram runtime;
- emits one integrated overlay/assets/source/maps/soe/soe.map.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

import generate_soe_g1_blockout as g1
import generate_soe_g2_canal as g2
import generate_soe_g3_footlight as g3
import generate_soe_g4_waterfront as g4
import generate_soe_g5_rift as g5
import generate_soe_g6_sacred_place as g6

from generate_soe_g1_blockout import (
    box_brush, brush_entity, point_entity, fmt,
    FLOOR_TEX, WALL_TEX, CEILING_TEX, BLOCK_TEX, TRIGGER_TEX, NULL_TEX,
)

ROOT = Path(__file__).resolve().parents[1]
ASSEMBLY_PATH = ROOT / "content" / "shadows_of_evil" / "full_city_assembly.json"
OUTPUT_PATH = ROOT / "overlay" / "assets" / "source" / "maps" / "soe" / "soe.map"
WORLD_WAD = "../../textures/wad/Example_02.wad"

NUMBER = r"-?\d+(?:\.\d+)?"
POINT_RE = re.compile(
    rf"\(\s*({NUMBER})\s+({NUMBER})\s+({NUMBER})\s*\)"
)
ORIGIN_RE = re.compile(
    rf'("origin"\s+")({NUMBER})\s+({NUMBER})\s+({NUMBER})(")'
)
CLASS_RE = re.compile(r'"classname"\s+"([^"]+)"')
TARGETNAME_RE = re.compile(r'"targetname"\s+"([^"]+)"')
ZONE_NAME_RE = re.compile(r'"zone_name"\s+"([^"]+)"')


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def phase_outputs():
    return {
        "g1": g1.generate(load_json(g1.SPEC_PATH)),
        "g2": g2.gen(load_json(g2.SPEC_PATH)),
        "g3": g3.gen(load_json(g3.SPEC_PATH)),
        "g4": g4.gen(load_json(g4.SPEC_PATH)),
        "g5": g5.gen(load_json(g5.SPEC_PATH)),
        "g6": g6.gen(load_json(g6.SPEC_PATH)),
    }


def split_top_entities(text: str):
    blocks = []
    depth = 0
    start = None

    for i, ch in enumerate(text):
        if ch == "{":
            if depth == 0:
                start = i
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth < 0:
                raise ValueError("negative brace depth while parsing .map")
            if depth == 0 and start is not None:
                blocks.append(text[start:i + 1])
                start = None

    if depth != 0:
        raise ValueError("unbalanced map braces")
    return blocks


def world_brushes(world_entity: str):
    brushes = []
    depth = 0
    start = None

    for i, ch in enumerate(world_entity):
        if ch == "{":
            depth += 1
            if depth == 2:
                start = i
        elif ch == "}":
            if depth == 2 and start is not None:
                brushes.append(world_entity[start:i + 1])
                start = None
            depth -= 1

    return brushes


def classname(entity: str):
    match = CLASS_RE.search(entity)
    return match.group(1) if match else ""


def targetname(entity: str):
    match = TARGETNAME_RE.search(entity)
    return match.group(1) if match else ""


def zone_name(entity: str):
    match = ZONE_NAME_RE.search(entity)
    return match.group(1) if match else ""


def add_delta(values, delta):
    return tuple(float(values[i]) + float(delta[i]) for i in range(3))


def transform_brush(brush: str, delta):
    if tuple(delta) == (0, 0, 0):
        return brush

    def repl(match):
        xyz = add_delta(
            (match.group(1), match.group(2), match.group(3)),
            delta,
        )
        return f"( {fmt(xyz[0])} {fmt(xyz[1])} {fmt(xyz[2])} )"

    return POINT_RE.sub(repl, brush)


def transform_entity(entity: str, delta):
    transformed = transform_brush(entity, delta)

    if tuple(delta) == (0, 0, 0):
        return transformed

    def origin_repl(match):
        xyz = add_delta(
            (match.group(2), match.group(3), match.group(4)),
            delta,
        )
        return (
            match.group(1)
            + " ".join(fmt(v) for v in xyz)
            + match.group(5)
        )

    return ORIGIN_RE.sub(origin_repl, transformed)


def set_entity_key(entity: str, key: str, value: str):
    pattern = re.compile(rf'"{re.escape(key)}"\s+"[^"]*"')
    replacement = f'"{key}" "{value}"'

    if pattern.search(entity):
        return pattern.sub(replacement, entity, count=1)

    class_match = CLASS_RE.search(entity)
    if not class_match:
        return entity

    line_end = entity.find("\n", class_match.end())
    if line_end < 0:
        line_end = class_match.end()

    return entity[:line_end + 1] + replacement + "\n" + entity[line_end + 1:]



def remove_entity_key(entity: str, key: str):
    # Match a complete Valve .map key/value line. Keep the escapes single here:
    # this is a regex raw string, so \\s would match a literal backslash+s and
    # silently fail to remove the key.
    pattern = re.compile(rf'^"{re.escape(key)}"\s+"[^"]*"\n?', re.MULTILINE)
    return pattern.sub("", entity, count=1)

def patch_zone_adjacency(entity: str):
    if classname(entity) != "spawn_zone":
        return entity

    zone = zone_name(entity)
    overrides = {
        "junction": "easy_street, canal_entry, footlight_entry, waterfront_entry",
        "canal_entry": "junction, canal_lower",
        "footlight_entry": "junction, footlight_main",
        "waterfront_entry": "junction, waterfront_lower",
        "rift_junction_shortcut": "rift_upper, junction",
    }

    if zone in overrides:
        entity = set_entity_key(entity, "adjacent_zones", overrides[zone])

    return entity


def phase_map_parts(phase: str, text: str, cfg):
    blocks = split_top_entities(text)
    if not blocks or classname(blocks[0]) != "worldspawn":
        raise ValueError(f"{phase}: first entity is not worldspawn")

    delta = cfg.get("transform", [0, 0, 0])
    brushes = world_brushes(blocks[0])

    drop = set(range(cfg.get("dropFirstWorldBrushes", 0)))
    drop.update(cfg.get("dropWorldBrushIndices", []))

    last = cfg.get("dropLastWorldBrushes", 0)
    if last:
        drop.update(range(max(0, len(brushes) - last), len(brushes)))

    kept_brushes = [
        transform_brush(brush, delta)
        for idx, brush in enumerate(brushes)
        if idx not in drop
    ]

    keep_players = cfg.get("keepPlayerSpawns", False)
    drop_prefixes = tuple(cfg.get("dropTargetnamePrefixes", []))
    entities = []

    for raw in blocks[1:]:
        cls = classname(raw)
        name = targetname(raw)

        if cls.startswith("info_player_") and cls.endswith("_spawn") and not keep_players:
            continue
        if drop_prefixes and name.startswith(drop_prefixes):
            continue

        ent = transform_entity(raw, delta)
        ent = patch_zone_adjacency(ent)

        # Full-city blockout lighting is intentionally static. GoldSrc/VHLT
        # assigns switched-light styles to any classname beginning with "light"
        # that carries a targetname; 32 unique targets exhaust
        # MAX_SWITCHED_LIGHTS. Strip both explicit style and targetname here.
        # Final art lighting may reintroduce a small, budgeted set of switched
        # lights deliberately.
        if cls.startswith("light"):
            ent = remove_entity_key(ent, "style")
            ent = remove_entity_key(ent, "targetname")

        # VHLT reserves the generic "style" key for lightstyles/texlights, but
        # SoE mapper entities also use it for ritual IDs, district IDs, symbol
        # IDs, part bits, etc. In a merged map that otherwise makes dozens of
        # ordinary gameplay entities consume the 32 switched-light slots.
        # zhlt_usestyle=null is VHLT's explicit escape hatch: keep the runtime
        # style value intact while telling HLCSG not to reinterpret targetname
        # as a switchable-light style.
        if cls.startswith("soe_") and re.search(r'^"style"\s+"[^"]+"', ent, re.MULTILINE):
            ent = set_entity_key(ent, "zhlt_usestyle", "null")

        entities.append(ent)

    return kept_brushes, entities


def add_global_shell(world_brushes_out, bounds):
    x1, y1, z1 = bounds["mins"]
    x2, y2, z2 = bounds["maxs"]
    thickness = 32

    world_brushes_out += [
        box_brush((x1,y1,z1),(x2,y2,z1 + thickness),FLOOR_TEX),
        box_brush((x1,y1,z1),(x1 + thickness,y2,z2),WALL_TEX),
        box_brush((x2 - thickness,y1,z1),(x2,y2,z2),WALL_TEX),
        box_brush((x1,y1,z1),(x2,y1 + thickness,z2),WALL_TEX),
        box_brush((x1,y2 - thickness,z1),(x2,y2,z2),WALL_TEX),
        box_brush((x1,y1,z2 - thickness),(x2,y2,z2),CEILING_TEX),
    ]


def add_split_g1_ground(world_brushes_out):
    # Replaces G1's one-piece test floor. The opening allows a real stair
    # descent into the transformed G5 Rift instead of a fake teleport.
    z1, z2 = -48, 0
    world_brushes_out += [
        box_brush((-896,-576,z1),(80,576,z2),FLOOR_TEX),
        box_brush((240,-576,z1),(768,576,z2),FLOOR_TEX),
        box_brush((80,-576,z1),(240,-400,z2),FLOOR_TEX),
        box_brush((80,-256,z1),(240,576,z2),FLOOR_TEX),
    ]


def add_junction_rift_stairs(world_brushes_out, entities):
    # Open shaft from Junction surface down to transformed G5 upper concourse.
    x1, x2 = 96, 224
    base_z = -608

    # First steep run clears the underside of the split G1 floor.
    for i in range(6):
        y1 = -400 + i * 24
        y2 = y1 + 24
        top = -24 * (i + 1)
        world_brushes_out.append(
            box_brush((x1,y1,base_z),(x2,y2,top),BLOCK_TEX)
        )

    # Long protected descent under Junction, ending at G5 floor height.
    for i in range(27):
        y1 = -256 + i * 24
        y2 = y1 + 24
        top = -144 - 16 * (i + 1)
        world_brushes_out.append(
            box_brush((x1,y1,base_z),(x2,y2,top),BLOCK_TEX)
        )

    world_brushes_out += [
        box_brush((x1,392,-608),(x2,560,-576),BLOCK_TEX),
        box_brush((64,-400,-608),(96,560,0),WALL_TEX),
        box_brush((224,-400,-608),(256,560,0),WALL_TEX),
    ]

    entities.append(
        brush_entity(
            "soe_powered_door",
            (80,-408,-144),(240,-392,96),
            NULL_TEX,
            targetname="soe_full_junction_rift_access",
        )
    )


def add_underground_connector(world_brushes_out, assembly):
    connector = assembly["undergroundConnector"]
    for stair in connector["stairSurfaces"]:
        world_brushes_out.append(
            box_brush(tuple(stair["mins"]), tuple(stair["maxs"]), BLOCK_TEX)
        )
    for wall in connector["sideWalls"]:
        world_brushes_out.append(
            box_brush(tuple(wall["mins"]), tuple(wall["maxs"]), WALL_TEX)
        )


def add_rift_pairs(entities, assembly):
    g5_delta = assembly["phases"]["g5"]["transform"]

    for rift in assembly["rifts"]:
        rid = rift["id"]
        surface_dest_name = f"soe_full_surface_{rid}_dest"
        underground_return_name = f"soe_full_rift_return_{rid}"

        entities.append(point_entity(
            "soe_rift_destination",
            rift["surfaceDestination"],
            targetname=surface_dest_name,
            angles="0 0 0",
        ))

        entities.append(point_entity(
            "soe_rift_portal",
            rift["surfaceOrigin"],
            spawnflags=1,
            targetname=f"soe_full_rift_surface_{rid}",
            target2=rift["undergroundTarget"],
            useprint_string_1="Hold %b to Open Rift",
        ))

        underground_origin = [
            rift["undergroundPortalLocal"][i] + g5_delta[i]
            for i in range(3)
        ]
        entities.append(point_entity(
            "soe_rift_portal",
            underground_origin,
            spawnflags=1,
            targetname=underground_return_name,
            target2=surface_dest_name,
            useprint_string_1="Hold %b to Open Rift",
        ))


def add_full_tram(entities, assembly):
    tram = assembly["tram"]
    size = tram["size"]
    initial = next(s for s in tram["stations"] if s["style"] == tram["initialStation"])
    mins = initial["min"]
    maxs = [mins[i] + size[i] for i in range(3)]

    entities.append(brush_entity(
        tram["runtime"],
        mins,
        maxs,
        BLOCK_TEX,
        targetname="soe_full_tram",
        style=tram["initialStation"],
        speed=tram["speed"],
    ))

    for station in tram["stations"]:
        sid = station["id"]
        entities.append(point_entity(
            "soe_tram_station_marker",
            station["min"],
            style=station["style"],
            targetname=f"soe_full_tram_station_{sid}",
        ))

        for idx, destination in enumerate(station["destinations"]):
            entities.append(point_entity(
                "soe_tram_button",
                station["buttons"][idx],
                style=station["style"],
                soe_tram_to_station=destination,
                cost=tram["cost"],
                target="soe_full_tram",
                targetname=f"soe_full_tram_button_{sid}_{destination}",
            ))

    entities.append(point_entity(
        "soe_tram_hub_marker",
        tram["junctionHubMin"],
        target="soe_full_train_hit",
        targetname="soe_full_tram_junction_hub",
    ))

    for window in tram["symbolWindows"]:
        entities.append(point_entity(
            "soe_tram_symbol_window",
            window["origin"],
            style=window["style"],
            targetname=f"soe_full_symbol_{window['district']}",
        ))

    finale = tram["finale"]

    for box in finale["stationBoxes"]:
        entities.append(point_entity(
            "soe_finale_station_box",
            box["origin"],
            style=box["style"],
            targetname=f"soe_full_finale_box_{box['district']}",
        ))

    entities.append(point_entity(
        "soe_finale_train_hit",
        finale["trainHitOrigin"],
        targetname="soe_full_train_hit",
        target="soe_full_gateworm_visual",
    ))
    entities.append(point_entity(
        "soe_finale_gateworm_visual",
        finale["gatewormOrigin"],
        targetname="soe_full_gateworm_visual",
    ))

    for keeper in finale["keepers"]:
        entities.append(point_entity(
            "soe_finale_keeper",
            keeper["origin"],
            style=keeper["style"],
            targetname=f"soe_full_finale_keeper_{keeper['style']}",
        ))

    for idx, origin in enumerate(finale["torches"], start=1):
        entities.append(point_entity(
            "soe_finale_beast_torch",
            origin,
            targetname=f"soe_full_finale_torch_{idx}",
        ))

    for idx, origin in enumerate(finale["cleanseWisps"], start=1):
        entities.append(point_entity(
            "soe_finale_cleanse_wisp",
            origin,
            targetname=f"soe_full_cleanse_{idx}",
        ))


def generate():
    assembly = load_json(ASSEMBLY_PATH)
    generated = phase_outputs()

    brushes = []
    entities = []

    add_global_shell(brushes, assembly["worldBounds"])
    add_split_g1_ground(brushes)

    for phase in ("g1","g2","g3","g4","g5","g6"):
        phase_brushes, phase_entities = phase_map_parts(
            phase, generated[phase], assembly["phases"][phase]
        )
        brushes.extend(phase_brushes)
        entities.extend(phase_entities)

    add_junction_rift_stairs(brushes, entities)
    add_underground_connector(brushes, assembly)
    add_rift_pairs(entities, assembly)
    add_full_tram(entities, assembly)

    world = [
        "// Game: Nazi Zombies Portable",
        "// Format: Valve",
        "// AUTO-GENERATED by scripts/generate_soe_full_city.py",
        "// Integrated clean-room Morg City blockout.",
        "{",
        '"mapversion" "220"',
        f'"wad" "{WORLD_WAD}"',
        '"classname" "worldspawn"',
        '"chaptertitle" "Shadows of Evil - Integrated Morg City Blockout"',
        '"location" "Morg City / The Rift / Sacred Place"',
        '"person" "NZ:P Android clean-room reconstruction"',
        '"light" "64"',
    ]
    for idx, brush in enumerate(brushes):
        world += [f"// full brush {idx}", brush]
    world.append("}")

    return "\n".join(["\n".join(world)] + entities) + "\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()

    output = generate()

    if args.check:
        if not OUTPUT_PATH.exists():
            raise SystemExit(f"missing integrated map: {OUTPUT_PATH}")
        if OUTPUT_PATH.read_text(encoding="utf-8") != output:
            raise SystemExit("integrated soe.map is stale; regenerate it")
        print("SOE full-city map is deterministic and up to date")
        return

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(output, encoding="utf-8", newline="\n")
    print(f"wrote {OUTPUT_PATH.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
