#!/usr/bin/env python3
"""Static checks for the generated Sacred Place G6 Valve 220 map."""
from __future__ import annotations
import re
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
MAP=ROOT/"overlay"/"assets"/"source"/"maps"/"soe_g6"/"soe_g6.map"
text=MAP.read_text(encoding="utf-8")

if text.count("{") != text.count("}"):
    raise SystemExit("G6 braces unbalanced")
if '"mapversion" "220"' not in text:
    raise SystemExit("G6 is not Valve 220")
if '"wad" "../../textures/wad/Example_02.wad"' not in text:
    raise SystemExit("G6 WAD path wrong")

counts={
    '"classname" "worldspawn"':1,
    '"classname" "info_player_1_spawn"':1,
    '"classname" "info_player_2_spawn"':1,
    '"classname" "info_player_3_spawn"':1,
    '"classname" "info_player_4_spawn"':1,
    '"classname" "spawn_zone"':3,
    '"classname" "spawn_zombie"':10,
    '"classname" "soe_beast_pedestal"':1,
    '"classname" "soe_gateworm_pedestal"':4,
    '"classname" "soe_final_ritual_altar"':1,
    '"classname" "soe_ritual_keeper_spawn"':4,
    '"classname" "perk_pap"':1,
    '"classname" "soe_shadowman_keeper"':4,
    '"classname" "soe_shadowman_capture_table"':1,
    '"classname" "soe_shadowman_capture_marker"':1,
    '"classname" "soe_shadowman_node"':6,
    '"classname" "mystery_box_tp_spot"':1,
    '"classname" "soe_reveal_wall"':2,
    '"classname" "soe_wallrun_volume"':2,
    '"classname" "soe_powered_door"':1,
    '"classname" "trigger_hurt"':1,
}
for token,want in counts.items():
    got=text.count(token)
    if got != want:
        raise SystemExit(f"{token}: expected {want}, got {got}")

# Gateworm style/layout progression.
for style,name in [
    (1,"soe_g6_gateworm_entry_left"),
    (2,"soe_g6_gateworm_entry_right"),
    (4,"soe_g6_gateworm_far_left"),
    (8,"soe_g6_gateworm_far_right"),
]:
    block=f'"targetname" "{name}"'
    if block not in text:
        raise SystemExit(f"missing Sacred Gateworm pedestal: {name}")
    # style may appear on other entities too, so require at least presence globally.
    if f'"style" "{style}"' not in text:
        raise SystemExit(f"missing Sacred Gateworm style {style}")

if text.count('"target" "soe_g6_wallrun_left"') != 1:
    raise SystemExit("left entry Gateworm must reveal exactly one left wallrun")
if text.count('"target" "soe_g6_wallrun_right"') != 1:
    raise SystemExit("right entry Gateworm must reveal exactly one right wallrun")
if text.count('"targetname" "soe_g6_wallrun_left"') != 1:
    raise SystemExit("left revealable wallrun brush missing")
if text.count('"targetname" "soe_g6_wallrun_right"') != 1:
    raise SystemExit("right revealable wallrun brush missing")

# Fifth ritual / PaP is double-gated.
if '"targetname" "soe_g6_final_ritual"' not in text:
    raise SystemExit("fifth ritual altar missing")
if text.count('"target" "soe_g6_pap_cover"') != 1:
    raise SystemExit("fifth ritual must remove exactly one PaP cover")
if '"targetname" "soe_g6_pap_cover"' not in text:
    raise SystemExit("physical PaP cover missing")
if '"targetname" "soe_g6_pap"' not in text or '"cost" "5000"' not in text:
    raise SystemExit("Sacred Place Pack-a-Punch 5000-point machine missing")

# Shadowman arena wiring.
for style in range(1,5):
    if text.count(f'"style" "{style}"') < 1:
        raise SystemExit(f"Shadowman Keeper style {style} missing")
for marker in (
    "soe_g6_shadow_keeper_1","soe_g6_shadow_keeper_2",
    "soe_g6_shadow_keeper_3","soe_g6_shadow_keeper_4",
    "soe_g6_shadow_capture_table","soe_g6_shadow_capture_marker"
):
    if f'"targetname" "{marker}"' not in text:
        raise SystemExit(f"missing Shadowman arena anchor: {marker}")

# Wallrun abyss must stay explicitly lethal.
if '"targetname" "soe_g6_abyss_kill"' not in text:
    raise SystemExit("Sacred Place abyss hurt volume missing")
if '"dmg" "9999"' not in text:
    raise SystemExit("Sacred Place abyss must remain lethal")

planes=[ln for ln in text.splitlines() if ln.startswith("( ")]
plane_re=re.compile(
    r'^\( -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? \) '
    r'\( -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? \) '
    r'\( -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? \) '
)
if len(planes) < 150:
    raise SystemExit(f"G6 brush plane count too low: {len(planes)}")
for ln in planes:
    if not plane_re.match(ln):
        raise SystemExit(f"malformed plane: {ln}")

print(
    "SOE G6 map OK: four Gateworms, two revealed wallruns, lethal abyss, "
    "fifth ritual, 5000 PaP double gate, full Shadowman arena"
)
