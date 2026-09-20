#!/usr/bin/env python3
"""Static checks for the generated Rift/Subway G5 Valve 220 map."""
from __future__ import annotations
import re
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
MAP=ROOT/"overlay"/"assets"/"source"/"maps"/"soe_g5"/"soe_g5.map"
text=MAP.read_text(encoding="utf-8")

if text.count("{") != text.count("}"):
    raise SystemExit("G5 braces unbalanced")
if '"mapversion" "220"' not in text:
    raise SystemExit("G5 is not Valve 220")
if '"wad" "../../textures/wad/Example_02.wad"' not in text:
    raise SystemExit("G5 WAD path wrong")

counts={
    '"classname" "worldspawn"':1,
    '"classname" "info_player_1_spawn"':1,
    '"classname" "info_player_2_spawn"':1,
    '"classname" "info_player_3_spawn"':1,
    '"classname" "info_player_4_spawn"':1,
    '"classname" "spawn_zone"':9,
    '"classname" "spawn_zombie"':10,
    '"classname" "soe_beast_pedestal"':1,
    '"classname" "soe_widows_wine_machine"':1,
    '"classname" "soe_beast_shock"':2,
    '"classname" "perk_mule"':1,
    '"classname" "soe_perk_power_panel"':1,
    '"classname" "soe_civil_fusebox"':1,
    '"classname" "soe_rift_destination"':3,
    '"classname" "soe_sword_wall_gate"':1,
    '"classname" "soe_sword_altar"':1,
    '"classname" "soe_beast_smash"':1,
    '"classname" "soe_sword_statue"':1,
    '"classname" "soe_rift_first_entry"':1,
    '"classname" "soe_rift_guard_spawn"':3,
    '"classname" "mystery_box_tp_spot"':1,
    '"classname" "soe_sword_glyph"':9,
    '"classname" "soe_powered_door"':2,
    '"classname" "soe_rift_portal"':3,
}
for token,want in counts.items():
    got=text.count(token)
    if got != want:
        raise SystemExit(f"{token}: expected {want}, got {got}")

for marker in (
    "soe_g5_arrival_canal","soe_g5_arrival_waterfront","soe_g5_arrival_footlight",
    "soe_g5_widows_machine","soe_g5_widows_power","soe_g5_mule_machine","soe_g5_mule_power",
    "soe_g5_junction_access","soe_g5_junction_shortcut_power","soe_g5_civil_fusebox",
    "soe_g5_sword_wall_gate","soe_g5_sword_wall","soe_g5_sword_altar",
    "soe_g5_rift_ovum_crate_smash","soe_g5_rift_ovum_statue",
    "soe_g5_first_entry","soe_g5_guard_a","soe_g5_guard_b","soe_g5_guard_c",
    "soe_g5_sacred_place_gate_anchor",
):
    if f'"targetname" "{marker}"' not in text:
        raise SystemExit(f"missing Rift anchor: {marker}")

if '"cost" "4000"' not in text:
    raise SystemExit("Widow's Wine 4000-point price missing")
if text.count('"target" "soe_g5_widows_machine"') != 1:
    raise SystemExit("Widow's Wine must have exactly one Beast power target")
if text.count('"target" "soe_g5_mule_machine"') != 1:
    raise SystemExit("Mule Kick must have exactly one Beast power target")
if text.count('"target" "soe_g5_sword_wall_gate"') != 9:
    raise SystemExit("all nine glyphs must route through the guarded wall gate")
if text.count('"target" "soe_g5_sword_wall"') != 1:
    raise SystemExit("only the guarded wall gate may target the physical Sword wall")
if text.count('"target" "soe_g5_rift_ovum_statue"') != 1:
    raise SystemExit("Rift Ovum statue must be revealed by exactly one Beast smash")

for glyph_id in range(9):
    if text.count(f'"style" "{glyph_id}"') < 1:
        raise SystemExit(f"Rift glyph style {glyph_id} missing")

# The three development portals must route to the three distinct counterpart destinations.
for target in ("soe_g5_arrival_canal","soe_g5_arrival_waterfront","soe_g5_arrival_footlight"):
    if text.count(f'"target2" "{target}"') != 1:
        raise SystemExit(f"Rift portal destination contract broken: {target}")

planes=[ln for ln in text.splitlines() if ln.startswith("( ")]
plane_re=re.compile(
    r'^\( -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? \) '
    r'\( -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? \) '
    r'\( -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? \) '
)
if len(planes) < 200:
    raise SystemExit(f"G5 brush plane count too low: {len(planes)}")
for ln in planes:
    if not plane_re.match(ln):
        raise SystemExit(f"malformed plane: {ln}")

print(
    "SOE G5 map OK: 3 Rift counterparts, Widow/Mule power, 3-Keeper first-entry markers, "
    "9 guarded glyphs, Sword altar/statue, Junction shortcut, Civil fusebox, sealed Sacred Place"
)
