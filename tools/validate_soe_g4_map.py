#!/usr/bin/env python3
"""Static checks for the generated Waterfront G4 Valve 220 map."""
from __future__ import annotations
import re
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
MAP=ROOT/"overlay"/"assets"/"source"/"maps"/"soe_g4"/"soe_g4.map"
text=MAP.read_text(encoding="utf-8")

if text.count("{") != text.count("}"): raise SystemExit("G4 braces unbalanced")
if '"mapversion" "220"' not in text: raise SystemExit("G4 is not Valve 220")
if '"wad" "../../textures/wad/Example_02.wad"' not in text: raise SystemExit("G4 WAD path wrong")

counts={
 '"classname" "worldspawn"':1,
 '"classname" "info_player_1_spawn"':1,'"classname" "info_player_2_spawn"':1,
 '"classname" "info_player_3_spawn"':1,'"classname" "info_player_4_spawn"':1,
 '"classname" "spawn_zone"':6,'"classname" "spawn_zombie"':10,
 '"classname" "soe_beast_pedestal"':3,'"classname" "soe_beast_grapple"':2,
 '"classname" "soe_beast_shock"':1,'"classname" "soe_beast_smash"':4,
 '"classname" "soe_quest_pickup"':1,'"classname" "soe_powered_door"':3,
 '"classname" "soe_ritual_controller"':1,'"classname" "soe_ritual_keeper_spawn"':4,
 '"classname" "perk_random"':1,'"classname" "soe_perk_power_panel"':1,
 '"classname" "soe_civil_call_panel"':1,'"classname" "soe_sword_statue"':1,
 '"classname" "soe_shield_part"':3,'"classname" "soe_civil_fuse"':3,
 '"classname" "soe_shield_build_table"':1,'"classname" "soe_servant_build_table"':1,
 '"classname" "mystery_box_tp_spot"':1,
 '"classname" "soe_chain_trap_volume"':1,'"classname" "soe_chain_trap_switch"':1,
 '"classname" "func_door_nzp"':1,
}
for token,want in counts.items():
    got=text.count(token)
    if got != want: raise SystemExit(f"{token}: expected {want}, got {got}")

if '"classname" "soe_rift_portal"' in text:
    raise SystemExit("G4 must keep Rift teleport inert until G5")
if '"cost" "1250"' not in text or '"targetname" "soe_g4_highstreet_side_gate"' not in text:
    raise SystemExit("Waterfront High Street side gate must retain documented 1250 cost")

for marker in (
 "soe_g4_belt_grapple_a","soe_g4_belt_grapple_dest_a","soe_g4_belt_grapple_b","soe_g4_belt_grapple_dest_b",
 "soe_g4_belt_smash","soe_g4_belt_pickup","soe_g4_anvil_smash","soe_g4_anvil_access","soe_g4_anvil_ritual",
 "soe_g4_waterfront_perk_slot","soe_g4_waterfront_perk_power","soe_g4_high_shortcut",
 "soe_g4_ovum_crate_smash","soe_g4_waterfront_ovum_statue","soe_g4_rift_smash"
):
    if f'"targetname" "{marker}"' not in text:
        raise SystemExit(f"missing Waterfront anchor: {marker}")

if text.count('"target" "soe_g4_belt_pickup"') != 1:
    raise SystemExit("Championship Belt must be enabled by exactly one smash")
if '"target" "soe_g4_anvil_access"' not in text:
    raise SystemExit("Anvil Beast smash no longer opens the gym")
if '"target" "soe_g4_waterfront_ovum_statue"' not in text:
    raise SystemExit("Waterfront Ovum crate smash no longer reveals its statue")
if text.count('"soe_random_group" "203"') != 3:
    raise SystemExit("Waterfront shield random group 203 must have 3 candidates")
if text.count('"soe_random_group" "303"') != 3:
    raise SystemExit("Waterfront fuse random group 303 must have 3 candidates")

planes=[ln for ln in text.splitlines() if ln.startswith("( ")]
plane_re=re.compile(
 r'^\( -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? \) '
 r'\( -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? \) '
 r'\( -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? \) '
)
if len(planes) < 220: raise SystemExit(f"G4 brush plane count too low: {len(planes)}")
for ln in planes:
    if not plane_re.match(ln): raise SystemExit(f"malformed plane: {ln}")

print("SOE G4 map OK: Waterfront lower/high routes, Belt chain, Anvil, 1250 gate, hidden statue, station, inert Rift")
