#!/usr/bin/env python3
"""Static anti-regression checks for the generated SoE G1 Valve 220 map."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = ROOT / "content" / "shadows_of_evil" / "g1_blockout.json"
MAP = ROOT / "overlay" / "assets" / "source" / "maps" / "soe_g1" / "soe_g1.map"

spec = json.loads(SPEC.read_text(encoding="utf-8"))
text = MAP.read_text(encoding="utf-8")

if text.count("{") != text.count("}"):
    raise SystemExit("G1 .map braces are unbalanced")

if '"mapversion" "220"' not in text:
    raise SystemExit("G1 map is not Valve 220")

wad_lines = [line for line in text.splitlines() if line.startswith('"wad"')]
if len(wad_lines) != 1 or "\\" in wad_lines[0]:
    raise SystemExit("G1 WAD path must exist once and use forward slashes")

required_counts = {
    '"classname" "worldspawn"': 1,
    '"classname" "info_player_1_spawn"': 1,
    '"classname" "info_player_2_spawn"': 1,
    '"classname" "info_player_3_spawn"': 1,
    '"classname" "info_player_4_spawn"': 1,
    '"classname" "item_barricade"': 4,
    '"classname" "path_corner"': 4,
    '"classname" "spawn_zone"': 2,
    '"classname" "func_door_nzp"': 4,
    '"classname" "soe_beast_pedestal"': 2,
    '"classname" "soe_beast_smash"': 2,
    '"classname" "soe_quest_pickup"': 2,
    '"classname" "soe_beast_grapple"': 1,
    '"classname" "soe_beast_shock"': 3,
    '"classname" "perk_revive"': 1,
    '"classname" "perk_staminup"': 1,
    '"classname" "soe_perk_power_panel"': 2,
    '"classname" "soe_civil_call_panel"': 1,
    '"classname" "soe_fumigator_pickup"': 7,
    '"classname" "func_door"': 2,
    '"classname" "soe_ritual_controller"': 1,
    '"classname" "soe_ritual_keeper_spawn"': 4,
}
for token, count in required_counts.items():
    actual = text.count(token)
    if actual != count:
        raise SystemExit(f"{token} expected {count}, got {actual}")

if text.count('"classname" "spawn_zombie"') != 8:
    raise SystemExit("G1 must retain four Easy Street and four Junction zombie spawns")

if text.count('"targetname" "soe_g1_spawn"') != 4:
    raise SystemExit("all four Easy Street zombie spawns must remain in the Easy Street zone target group")

if text.count('"targetname" "soe_g1_junction"') != 4:
    raise SystemExit("all four Junction perimeter zombie spawns must remain in the Junction zone target group")

for window in spec["windows"]:
    if f'"targetname" "{window["id"]}"' not in text:
        raise SystemExit(f'missing Easy Street barricade target: {window["id"]}')

for door in spec["doors"]:
    if f'"targetname" "{door["id"]}"' not in text:
        raise SystemExit(f'missing G1 door: {door["id"]}')
    if f'"cost" "{door["cost"]}"' not in text:
        raise SystemExit(f'G1 door cost missing from map: {door["id"]} -> {door["cost"]}')

if '"targetname" "soe_g1_summoning_key"' not in text or '"spawnflags" "1"' not in text:
    raise SystemExit("Summoning Key must remain dormant until the Beast smash target enables it")

if '"target" "soe_g1_summoning_key"' not in text:
    raise SystemExit("Summoning Key crate smash no longer targets the dormant pickup")


for target in (
    "soe_g1_quick_revive",
    "soe_g1_quick_revive_power",
    "soe_g1_staminup",
    "soe_g1_staminup_power",
    "soe_g1_beast_junction",
    "soe_g1_civil_panel_junction",
    "soe_g1_pen_pickup",
    "soe_g1_rk5_wallbuy_anchor",
    "soe_g1_sheiva_wallbuy_anchor",
    "soe_g1_lcar9_wallbuy_anchor",
    "soe_g1_krm262_wallbuy_anchor",
):
    if f'"targetname" "{target}"' not in text:
        raise SystemExit(f"missing canonical G1 gameplay anchor: {target}")

if text.count('"soe_random_group" "101"') != 3:
    raise SystemExit("Spawn Fumigator group 101 must retain exactly three candidates")
if text.count('"soe_random_group" "102"') != 4:
    raise SystemExit("Junction Fumigator group 102 must retain exactly four candidates")

if '"targetname" "soe_g1_pen_crane_power"\n"target" "soe_g1_pen_pickup"' not in text:
    raise SystemExit("Junction crane shock must enable the dormant Lawyer's Pen")

if '"targetname" "soe_g1_nero_power"\n"target" "soe_g1_nero_stair_blocker"' not in text:
    raise SystemExit("Nero power shock must open the human-access stair blocker")

if '"targetname" "soe_g1_nero_room_smash"\n"target" "soe_g1_nero_room_blocker"' not in text:
    raise SystemExit("Nero Beast smash must open the ritual-room blocker")

for target in (
    "soe_g1_nero_stair_blocker",
    "soe_g1_nero_room_blocker",
    "soe_g1_nero_ritual",
    "soe_g1_nero_keeper_a",
    "soe_g1_nero_keeper_b",
    "soe_g1_nero_keeper_c",
    "soe_g1_nero_keeper_d",
):
    if f'"targetname" "{target}"' not in text:
        raise SystemExit(f"missing Nero G1 ritual/access anchor: {target}")

plane_re = re.compile(
    r'^\( -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? \) '
    r'\( -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? \) '
    r'\( -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? \) '
)
plane_lines = [line for line in text.splitlines() if line.startswith("( ")]
if len(plane_lines) < 180:
    raise SystemExit(f"G1 brush plane count unexpectedly low: {len(plane_lines)}")
for line in plane_lines:
    if not plane_re.match(line):
        raise SystemExit(f"malformed Valve 220 plane line: {line}")

mins = spec["bounds"]["mins"]
maxs = spec["bounds"]["maxs"]
for match in re.finditer(r'^"origin" "(-?\d+(?:\.\d+)?) (-?\d+(?:\.\d+)?) (-?\d+(?:\.\d+)?)"$', text, re.MULTILINE):
    origin = [float(match.group(i)) for i in range(1, 4)]
    for axis in range(3):
        if origin[axis] < mins[axis] - 64 or origin[axis] > maxs[axis] + 64:
            raise SystemExit(f"entity origin outside G1 safety envelope: {origin}")

print(
    "SOE G1 map OK: "
    f"{text.count(chr(34) + 'classname' + chr(34))} entities/classes, "
    f"{len(plane_lines)} brush planes, "
    "4 Easy Street windows, 4 Junction perimeter spawns, 4 buyable doors"
)
