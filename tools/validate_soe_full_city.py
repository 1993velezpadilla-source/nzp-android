#!/usr/bin/env python3
"""Static integration audit for generated full Morg City soe.map."""

from __future__ import annotations

import re
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAP = ROOT / "overlay" / "assets" / "source" / "maps" / "soe" / "soe.map"
text = MAP.read_text(encoding="utf-8")


def split_top_entities(source: str):
    blocks = []
    depth = 0
    start = None
    for i, ch in enumerate(source):
        if ch == "{":
            if depth == 0:
                start = i
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth < 0:
                raise SystemExit("negative brace depth in full-city map")
            if depth == 0 and start is not None:
                blocks.append(source[start:i + 1])
                start = None
    if depth != 0:
        raise SystemExit("unbalanced entity braces in full-city map")
    return blocks


def entity_keys(block: str):
    pairs = re.findall(r'"([^"]+)"[ \t]+"([^"]*)"', block)
    return dict(pairs)


def parse_origin(value: str):
    parts = value.split()
    if len(parts) != 3:
        raise SystemExit(f"invalid origin: {value}")
    return tuple(float(v) for v in parts)


def brush_aabb(block: str):
    coords = [
        tuple(float(v) for v in match)
        for match in re.findall(
            r'\(\s*(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)\s*\)',
            block,
        )
    ]
    if not coords:
        return None
    mins = tuple(min(p[i] for p in coords) for i in range(3))
    maxs = tuple(max(p[i] for p in coords) for i in range(3))
    return mins, maxs


def point_in_aabb(point, aabb, tolerance=0.01):
    mins, maxs = aabb
    return all(mins[i] - tolerance <= point[i] <= maxs[i] + tolerance for i in range(3))


entity_blocks = split_top_entities(text)
entity_props = [entity_keys(block) for block in entity_blocks]

if text.count("{") != text.count("}"):
    raise SystemExit("full soe.map braces are unbalanced")
if text.count('"classname" "worldspawn"') != 1:
    raise SystemExit("full city must contain exactly one worldspawn")
if '"mapversion" "220"' not in text:
    raise SystemExit("full city is not Valve 220")
if '"wad" "../../textures/wad/Example_02.wad"' not in text:
    raise SystemExit("full city WAD path wrong")

# Integrated blockout lights must be static so VHLT never burns the 32-slot
# switched-light budget before the visual pass.
for block in text.split("}\n"):
    m = re.search(r'"classname" "([^"]+)"', block)
    if not m or not m.group(1).startswith("light"):
        continue
    if '"targetname"' in block:
        raise SystemExit("full-city light retained targetname and would consume MAX_SWITCHED_LIGHTS")
    if '"style"' in block:
        raise SystemExit("full-city blockout light retained explicit style")

# SoE gameplay entities may legitimately use the generic style field for
# ritual/district/part IDs. In VHLT that key collides with texlight/lightstyle
# handling, so every styled SoE entity in the integrated map must opt out.
for block in text.split("}\n"):
    cls_match = re.search(r'"classname" "([^"]+)"', block)
    if not cls_match or not cls_match.group(1).startswith("soe_"):
        continue
    if re.search(r'^"style"\s+"[^"]+"', block, re.MULTILINE):
        if '"zhlt_usestyle" "null"' not in block:
            raise SystemExit(
                f"styled SoE entity missing VHLT lightstyle escape: {cls_match.group(1)}"
            )

# Runtime zoning integrity. NZ:P's stock MAX_ZONES is patched to 64 for
# this map; current integrated Morg City uses 32 and may grow during art/gameplay.
zone_props = [p for p in entity_props if p.get("classname") == "spawn_zone"]
if not (32 <= len(zone_props) <= 64):
    raise SystemExit(f"full-city zone count out of supported range: {len(zone_props)}")

zone_by_name = {}
for p in zone_props:
    name = p.get("zone_name", "")
    if not name:
        raise SystemExit("spawn_zone missing zone_name")
    if name in zone_by_name:
        raise SystemExit(f"duplicate spawn zone name: {name}")
    zone_by_name[name] = p

for name, p in zone_by_name.items():
    adjacent = [x.strip() for x in p.get("adjacent_zones", "").split(",") if x.strip()]
    if len(adjacent) > 8:
        raise SystemExit(f"{name} exceeds NZ:P MAX_ADJ_ZONE=8")
    for other in adjacent:
        if other not in zone_by_name:
            raise SystemExit(f"{name} references unknown adjacent zone: {other}")

for name, p in zone_by_name.items():
    adjacent = [x.strip() for x in p.get("adjacent_zones", "").split(",") if x.strip()]
    for other in adjacent:
        reverse = [
            x.strip() for x in zone_by_name[other].get("adjacent_zones", "").split(",")
            if x.strip()
        ]
        if name not in reverse:
            raise SystemExit(f"zone adjacency is not symmetric: {name} -> {other}")

# Every runtime zone must be connected to the playable graph rooted at Easy Street.
# This catches isolated NSZ islands even when all adjacency names are individually valid.
reachable = set()
frontier = ["easy_street"]
while frontier:
    current = frontier.pop()
    if current in reachable:
        continue
    reachable.add(current)
    current_prop = zone_by_name[current]
    for other in [
        x.strip() for x in current_prop.get("adjacent_zones", "").split(",")
        if x.strip()
    ]:
        if other not in reachable:
            frontier.append(other)

unreachable = sorted(set(zone_by_name) - reachable)
if unreachable:
    raise SystemExit(f"spawn-zone graph has unreachable island(s): {unreachable}")

# A correct targetname is not enough: transformed zombie spawns must stay
# physically near the spawn-zone volume that owns that target. Window/barricade
# spawns intentionally sit just outside the player zone, so allow a bounded
# 96-unit exterior apron while still catching broken transforms.
zone_blocks = [
    (entity_keys(block), block)
    for block in entity_blocks
    if entity_keys(block).get("classname") == "spawn_zone"
]
zones_by_target = {}
all_zone_aabbs = []
for p, block in zone_blocks:
    aabb = brush_aabb(block)
    if aabb is None:
        raise SystemExit(f"spawn zone has no brush geometry: {p.get('zone_name', '<unnamed>')}")
    all_zone_aabbs.append((p.get("zone_name", ""), aabb))
    target = p.get("zone_target", "")
    if target:
        zones_by_target.setdefault(target, []).append((p.get("zone_name", ""), aabb))

for p in entity_props:
    if p.get("classname") != "spawn_zombie":
        continue
    target = p.get("targetname", "")
    origin_value = p.get("origin", "")
    if not target or not origin_value:
        raise SystemExit("spawn_zombie missing targetname or origin")
    owners = zones_by_target.get(target, [])
    if len(owners) != 1:
        raise SystemExit(f"spawn target must resolve to exactly one zone: {target} -> {len(owners)}")
    zone_name_value, aabb = owners[0]
    origin = parse_origin(origin_value)
    if not point_in_aabb(origin, aabb, tolerance=96):
        raise SystemExit(
            f"zombie spawn {origin_value} target {target} is farther than the 96-unit "
            f"spawn apron for zone {zone_name_value} AABB {aabb}"
        )

# Match spawns also need to start inside the playable zone graph.
for p in entity_props:
    if not p.get("classname", "").startswith("info_player_"):
        continue
    origin_value = p.get("origin", "")
    if not origin_value:
        raise SystemExit(f"{p.get('classname')} missing origin")
    origin = parse_origin(origin_value)
    containing = [name for name, aabb in all_zone_aabbs if point_in_aabb(origin, aabb)]
    if not containing:
        raise SystemExit(f"player spawn {origin_value} is outside every runtime spawn zone")

zone_targets = {p.get("zone_target", "") for p in zone_props if p.get("zone_target")}
spawn_targets = {
    p.get("targetname", "") for p in entity_props
    if p.get("classname") == "spawn_zombie" and p.get("targetname")
}
orphan_spawns = sorted(spawn_targets - zone_targets)
if orphan_spawns:
    raise SystemExit(f"zombie spawn target not owned by any zone: {orphan_spawns[:8]}")

way_targets = {
    p.get("wayTarget", "") for p in entity_props
    if p.get("wayTarget")
}
for name, p in zone_by_name.items():
    doors = [x.strip() for x in p.get("door_way_targets", "").split(",") if x.strip()]
    if len(doors) > 6:
        raise SystemExit(f"{name} exceeds NZ:P MAX_ZONE_WAY_TARGETS=6")
    for door in doors:
        if door not in way_targets:
            raise SystemExit(f"{name} references missing door wayTarget: {door}")

for zone, expected_door in {
    "canal_entry": "junction_to_canal_stub",
    "footlight_entry": "junction_to_footlight_stub",
    "waterfront_entry": "junction_to_waterfront_stub",
    "junction": "soe_full_junction_rift_access",
    "rift_junction_shortcut": "soe_full_junction_rift_access",
    "rift_sacred_gate": "soe_full_sacred_access",
    "sacred_entry": "soe_full_sacred_access",
}.items():
    doors = {
        x.strip() for x in zone_by_name[zone].get("door_way_targets", "").split(",")
        if x.strip()
    }
    if expected_door not in doors:
        raise SystemExit(f"{zone} lost closed-door zoning gate {expected_door}")

for a, b in {
    ("junction", "rift_junction_shortcut"),
    ("rift_sacred_gate", "sacred_entry"),
}:
    aa = {x.strip() for x in zone_by_name[a].get("adjacent_zones", "").split(",") if x.strip()}
    bb = {x.strip() for x in zone_by_name[b].get("adjacent_zones", "").split(",") if x.strip()}
    if b not in aa or a not in bb:
        raise SystemExit(f"integrated physical zoning link missing: {a} <-> {b}")

# Only G1's actual match spawns survive the assembly.
for i in range(1,5):
    token=f'"classname" "info_player_{i}_spawn"'
    if text.count(token) != 1:
        raise SystemExit(f"full city requires exactly one {token}")
if text.count('"classname" "info_player_') != 4:
    raise SystemExit("standalone phase player spawns leaked into full city")

# Early ritual / sword / flag / boss quest geometry survives the merge.
counts = {
    '"classname" "soe_ritual_controller"': 4,
    '"classname" "soe_gateworm_pedestal"': 4,
    '"classname" "soe_final_ritual_altar"': 1,
    '"classname" "soe_mainquest_book"': 1,
    '"classname" "soe_flag_spawn"': 1,
    '"classname" "soe_flag_site"': 8,
    '"classname" "soe_flag_keeper"': 4,
    '"classname" "soe_flag_shadowman_spawn"': 12,
    '"classname" "soe_reborn_keeper"': 4,
    '"classname" "soe_reborn_circle"': 4,
    '"classname" "soe_shadowman_keeper"': 4,
    '"classname" "soe_shadowman_capture_table"': 1,
    '"classname" "soe_shadowman_capture_marker"': 1,
    '"classname" "perk_pap"': 1,
}
for token,want in counts.items():
    got=text.count(token)
    if got != want:
        raise SystemExit(f"{token}: expected {want}, got {got}")

# G1-G4 cross-zone surface integration.
for zone in (
    "easy_street","junction",
    "canal_entry","canal_lower","canal_high","ruby_rabbit","canal_station",
    "footlight_entry","footlight_main","footlight_high","black_lace","footlight_station",
    "waterfront_entry","waterfront_lower","waterfront_high","anvil_gym","waterfront_station",
):
    if f'"zone_name" "{zone}"' not in text:
        raise SystemExit(f"surface zone lost during merge: {zone}")

for required in (
    '"adjacent_zones" "easy_street, canal_entry, footlight_entry, waterfront_entry, rift_junction_shortcut"',
    '"adjacent_zones" "junction, canal_lower"',
    '"adjacent_zones" "junction, footlight_main"',
    '"adjacent_zones" "junction, waterfront_lower"',
):
    if required not in text:
        raise SystemExit(f"cross-phase spawn-zone adjacency missing: {required}")

# The integrated Rift -> Sacred Place route is physically sealed until the
# four district rituals complete; it is also an NZ:P zoning gate.
if '"targetname" "soe_full_sacred_access"' not in text:
    raise SystemExit("full-map Sacred Place ritual access gate missing")
if '"wayTarget" "soe_full_sacred_access"' not in text:
    raise SystemExit("Sacred Place access gate is not wired into NZ:P zoning")

# Junction -> Rift must be a real Beast-opened physical stair, not a teleport.
if '"targetname" "soe_g1_rift_access_power"' not in text:
    raise SystemExit("Junction Rift Beast shock missing")
if '"target" "soe_full_junction_rift_access"' not in text:
    raise SystemExit("Junction Rift Beast shock is not wired to full stair access")
if '"targetname" "soe_full_junction_rift_access"' not in text:
    raise SystemExit("full-map Junction Rift powered door missing")

# Standalone G5 development portals must never leak into shipping assembly.
if "soe_g5_test_portal_" in text:
    raise SystemExit("G5 standalone test portal leaked into full city")

# Full map adds 3 surface + 3 underground return Rift portals.
if text.count('"classname" "soe_rift_portal"') != 6:
    raise SystemExit("full city requires exactly six paired Rift portal entities")
if text.count('"classname" "soe_rift_destination"') != 6:
    raise SystemExit("full city requires three underground + three surface Rift destinations")
for rid in ("canal","footlight","waterfront"):
    if f'"targetname" "soe_full_rift_surface_{rid}"' not in text:
        raise SystemExit(f"surface Rift missing: {rid}")
    if f'"targetname" "soe_full_rift_return_{rid}"' not in text:
        raise SystemExit(f"underground return Rift missing: {rid}")
    if f'"targetname" "soe_full_surface_{rid}_dest"' not in text:
        raise SystemExit(f"surface return destination missing: {rid}")

# Layering audit: transformed underground landmarks must remain well below surface.
def entity_block_for_target(name):
    for block in text.split("}\n"):
        if f'"targetname" "{name}"' in block:
            return block
    return ""

origin_re=re.compile(r'"origin" "(-?\d+(?:\.\d+)?) (-?\d+(?:\.\d+)?) (-?\d+(?:\.\d+)?)"')
for name in ("soe_g5_arrival_canal","soe_g5_arrival_waterfront","soe_g5_arrival_footlight"):
    block=entity_block_for_target(name)
    m=origin_re.search(block)
    if not m or float(m.group(3)) > -400:
        raise SystemExit(f"Rift destination is not underground after assembly: {name}")
for name in ("soe_g6_final_ritual","soe_g6_pap"):
    block=entity_block_for_target(name)
    m=origin_re.search(block)
    if not m or float(m.group(3)) > -400:
        raise SystemExit(f"Sacred Place landmark is not underground after assembly: {name}")

# Global Tram / finale uses actual surface station envelopes, not G7 harness geometry.
tram_counts = {
    '"classname" "soe_tram_mover"':1,
    '"classname" "soe_tram_station_marker"':3,
    '"classname" "soe_tram_hub_marker"':1,
    '"classname" "soe_tram_button"':6,
    '"classname" "soe_tram_symbol_window"':3,
    '"classname" "soe_finale_station_box"':3,
    '"classname" "soe_finale_train_hit"':1,
    '"classname" "soe_finale_gateworm_visual"':1,
    '"classname" "soe_finale_keeper"':3,
    '"classname" "soe_finale_beast_torch"':3,
    '"classname" "soe_finale_cleanse_wisp"':4,
}
for token,want in tram_counts.items():
    got=text.count(token)
    if got != want:
        raise SystemExit(f"{token}: expected {want}, got {got}")
if text.count('"cost" "500"') < 6:
    raise SystemExit("full-city Tram controls lost 500-point price")
if '"targetname" "soe_full_tram_junction_hub"' not in text:
    raise SystemExit("full-city Junction Tram hub missing")
if '"target" "soe_full_train_hit"' not in text:
    raise SystemExit("full-city Junction hub no longer fires finale train collision")

# Resolve mapper target graph before runtime. Every SoE target/target2 must
# resolve to at least one entity targetname in the assembled map. This catches
# cross-phase links that BSP/NSZ compilation cannot validate.
all_targetnames = {
    p.get("targetname", "") for p in entity_props if p.get("targetname")
}
unresolved_targets = []
for p in entity_props:
    cls = p.get("classname", "")
    if not cls.startswith("soe_"):
        continue
    for key in ("target", "target2"):
        value = p.get(key, "")
        if value and value not in all_targetnames:
            unresolved_targets.append((cls, key, value, p.get("targetname", "")))
if unresolved_targets:
    sample = ", ".join(
        f"{cls}.{key}->{value}" for cls, key, value, _ in unresolved_targets[:12]
    )
    raise SystemExit(f"unresolved SoE target graph edge(s): {sample}")

# All generated main-quest/full-map targetnames are unique.
names=re.findall(r'"targetname" "(soe_(?:mq|full)_[^"]+)"', text)
dupes=[name for name,count in Counter(names).items() if count != 1]
if dupes:
    raise SystemExit(f"duplicate generated quest/full targetnames: {dupes[:12]}")

# Ensure the large integrated blockout actually contains substantial world geometry.
planes=[line for line in text.splitlines() if line.startswith("( ")]
if len(planes) < 1100:
    raise SystemExit(f"integrated world brush plane count suspiciously low: {len(planes)}")

print(
    "SOE full city OK: one worldspawn/4 players, G1-G6 merged, physical Junction-Rift descent, "
    "paired Rifts, complete Reborn+Flag quest geometry, global Tram/finale, "
    f"{len(zone_props)} validated spawn zones"
)
