#!/usr/bin/env python3
"""Static checks for the generated Tram/finale G7 Valve 220 map."""
from __future__ import annotations
import re
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
MAP=ROOT/"overlay"/"assets"/"source"/"maps"/"soe_g7"/"soe_g7.map"
text=MAP.read_text(encoding="utf-8")

if text.count("{") != text.count("}"):
    raise SystemExit("G7 braces unbalanced")
if '"mapversion" "220"' not in text:
    raise SystemExit("G7 is not Valve 220")
if '"wad" "../../textures/wad/Example_02.wad"' not in text:
    raise SystemExit("G7 WAD path wrong")
if '"classname" "func_train"' in text:
    raise SystemExit("G7 must use the stoppable SoE Tram mover, not looping stock func_train")

counts={
    '"classname" "worldspawn"':1,
    '"classname" "info_player_1_spawn"':1,
    '"classname" "info_player_2_spawn"':1,
    '"classname" "info_player_3_spawn"':1,
    '"classname" "info_player_4_spawn"':1,
    '"classname" "spawn_zone"':4,
    '"classname" "spawn_zombie"':10,
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
    '"classname" "soe_finale_cleanse_wisp"':6,
}
for token,want in counts.items():
    got=text.count(token)
    if got != want:
        raise SystemExit(f"{token}: expected {want}, got {got}")

# Physical Tram contract.
if '"targetname" "soe_g7_tram"' not in text:
    raise SystemExit("G7 physical Tram target missing")
if '"speed" "170"' not in text:
    raise SystemExit("G7 Tram blockout speed changed unexpectedly")
if text.count('"cost" "500"') != 6:
    raise SystemExit("all six G7 route controls must cost exactly 500")

# Station controls: two unique destinations at every station.
expected_pairs={
    1:{2,3},
    2:{1,3},
    3:{1,2},
}
for station,dests in expected_pairs.items():
    # Each station style appears in two buttons plus other station entities,
    # so parse small entity blocks instead of relying on global style counts.
    blocks=text.split("}\n")
    found=set()
    for block in blocks:
        if '"classname" "soe_tram_button"' not in block:
            continue
        if f'"style" "{station}"' not in block:
            continue
        for dest in dests:
            if f'"soe_tram_to_station" "{dest}"' in block:
                found.add(dest)
    if found != dests:
        raise SystemExit(f"G7 station {station} destination controls broken: {found}")

# All rides must cross the Junction event marker.
if '"targetname" "soe_g7_junction_hub_marker"' not in text:
    raise SystemExit("Junction hub marker missing")
if text.count('"target" "soe_g7_train_hit"') != 1:
    raise SystemExit("Junction hub must invoke exactly one finale train-hit entity")

# Symbol views map one-to-one to the 3 route identities.
for district in ("canal","footlight","waterfront"):
    if f'"targetname" "soe_g7_symbol_{district}"' not in text:
        raise SystemExit(f"missing Tram symbol window: {district}")

# Finale wiring.
for district in ("canal","footlight","waterfront"):
    if f'"targetname" "soe_g7_finale_box_{district}"' not in text:
        raise SystemExit(f"missing finale station box: {district}")
if '"targetname" "soe_g7_train_hit"' not in text:
    raise SystemExit("finale train-hit entity missing")
if '"target" "soe_g7_gateworm_visual"' not in text:
    raise SystemExit("train hit must refresh/hide the giant Gateworm visual")
if '"targetname" "soe_g7_gateworm_visual"' not in text:
    raise SystemExit("giant Gateworm visual missing")
for style in (1,2,3):
    if f'"targetname" "soe_g7_finale_keeper_{style}"' not in text:
        raise SystemExit(f"Junction finale Keeper {style} missing")

planes=[ln for ln in text.splitlines() if ln.startswith("( ")]
plane_re=re.compile(
    r'^\( -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? \) '
    r'\( -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? \) '
    r'\( -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? \) '
)
if len(planes) < 120:
    raise SystemExit(f"G7 brush plane count too low: {len(planes)}")
for ln in planes:
    if not plane_re.match(ln):
        raise SystemExit(f"malformed plane: {ln}")

print(
    "SOE G7 map OK: stoppable physical Tram, 6 paid routes, Junction hub, "
    "3 symbol windows, 3 moving-tram finale boxes, Gateworm/Keeper finale"
)
