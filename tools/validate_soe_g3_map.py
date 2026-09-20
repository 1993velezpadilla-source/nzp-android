#!/usr/bin/env python3
"""Static checks for the generated Footlight G3 Valve 220 map."""
from __future__ import annotations
import re
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
MAP=ROOT/"overlay"/"assets"/"source"/"maps"/"soe_g3"/"soe_g3.map"
text=MAP.read_text(encoding="utf-8")

if text.count("{") != text.count("}"): raise SystemExit("G3 braces unbalanced")
if '"mapversion" "220"' not in text: raise SystemExit("G3 is not Valve 220")
if '"wad" "../../textures/wad/Example_02.wad"' not in text: raise SystemExit("G3 WAD path wrong")

counts={
 '"classname" "worldspawn"':1,
 '"classname" "info_player_1_spawn"':1,'"classname" "info_player_2_spawn"':1,
 '"classname" "info_player_3_spawn"':1,'"classname" "info_player_4_spawn"':1,
 '"classname" "spawn_zone"':6,'"classname" "spawn_zombie"':10,
 '"classname" "soe_beast_pedestal"':3,'"classname" "soe_beast_grapple"':2,
 '"classname" "soe_beast_shock"':1,'"classname" "soe_beast_smash"':2,
 '"classname" "soe_quest_pickup"':1,'"classname" "soe_powered_door"':2,
 '"classname" "soe_ritual_controller"':1,'"classname" "soe_ritual_keeper_spawn"':4,
 '"classname" "perk_random"':1,'"classname" "soe_perk_power_panel"':1,
 '"classname" "soe_civil_call_panel"':1,'"classname" "soe_sword_statue"':1,
 '"classname" "soe_shield_part"':3,'"classname" "soe_civil_fuse"':3,
 '"classname" "soe_shield_build_table"':1,'"classname" "soe_servant_build_table"':1,
 '"classname" "mystery_box_tp_spot"':2,
}
for token,want in counts.items():
    got=text.count(token)
    if got != want: raise SystemExit(f"{token}: expected {want}, got {got}")

if '"classname" "soe_rift_portal"' in text:
    raise SystemExit("G3 must keep Rift teleport inert until G5")

for marker in (
 "soe_g3_black_lace_grapple","soe_g3_black_lace_roof_dest","soe_g3_black_lace_power",
 "soe_g3_black_lace_access","soe_g3_black_lace_ritual",
 "soe_g3_toupee_grapple","soe_g3_toupee_grapple_dest","soe_g3_toupee_smash","soe_g3_toupee_pickup",
 "soe_g3_footlight_perk_slot","soe_g3_footlight_perk_power","soe_g3_rift_smash"
):
    if f'"targetname" "{marker}"' not in text:
        raise SystemExit(f"missing Footlight anchor: {marker}")

if text.count('"target" "soe_g3_toupee_pickup"') != 1:
    raise SystemExit("Toupee must be unlocked by exactly one Beast smash")
if '"target" "soe_g3_black_lace_access"' not in text:
    raise SystemExit("Black Lace power no longer opens its door")
if text.count('"soe_random_group" "202"') != 3:
    raise SystemExit("Footlight shield random group 202 must contain 3 candidates")
if text.count('"soe_random_group" "302"') != 3:
    raise SystemExit("Footlight fuse random group 302 must contain 3 candidates")

planes=[ln for ln in text.splitlines() if ln.startswith("( ")]
plane_re=re.compile(
 r'^\( -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? \) '
 r'\( -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? \) '
 r'\( -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? \) '
)
if len(planes) < 180: raise SystemExit(f"G3 brush plane count too low: {len(planes)}")
for ln in planes:
    if not plane_re.match(ln): raise SystemExit(f"malformed plane: {ln}")

print("SOE G3 map OK: Footlight lower/high routes, Black Lace access, Toupee route, station, inert Rift, randomized shield/fuse")
