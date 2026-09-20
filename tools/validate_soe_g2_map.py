#!/usr/bin/env python3
"""Static anti-regression checks for the generated SoE Canal G2 Valve 220 map."""
from __future__ import annotations
import json, re
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
SPEC=ROOT/"content"/"shadows_of_evil"/"g2_canal_blockout.json"
MAP=ROOT/"overlay"/"assets"/"source"/"maps"/"soe_g2"/"soe_g2.map"

spec=json.loads(SPEC.read_text(encoding="utf-8"))
text=MAP.read_text(encoding="utf-8")

if text.count("{") != text.count("}"):
    raise SystemExit("G2 .map braces are unbalanced")
if '"mapversion" "220"' not in text:
    raise SystemExit("G2 map is not Valve 220")
if '"classname" "worldspawn"' not in text:
    raise SystemExit("G2 worldspawn missing")
if '"wad" "../../textures/wad/Example_02.wad"' not in text:
    raise SystemExit("G2 must use the generated Example_02 WAD with a forward-slash path")

counts={
    '"classname" "info_player_1_spawn"':1,
    '"classname" "info_player_2_spawn"':1,
    '"classname" "info_player_3_spawn"':1,
    '"classname" "info_player_4_spawn"':1,
    '"classname" "spawn_zone"':6,
    '"classname" "spawn_zombie"':10,
    '"classname" "soe_beast_pedestal"':3,
    '"classname" "soe_beast_shock"':2,
    '"classname" "soe_beast_smash"':2,
    '"classname" "soe_target_counter"':1,
    '"classname" "soe_quest_pickup"':1,
    '"classname" "soe_powered_door"':3,
    '"classname" "soe_ritual_controller"':1,
    '"classname" "soe_ritual_keeper_spawn"':4,
    '"classname" "perk_random"':1,
    '"classname" "soe_perk_power_panel"':1,
    '"classname" "soe_civil_call_panel"':1,
    '"classname" "soe_sword_statue"':1,
    '"classname" "soe_shield_build_table"':1,
    '"classname" "soe_servant_build_table"':1,
    '"classname" "soe_chain_trap_volume"':1,
    '"classname" "soe_chain_trap_switch"':1,
    '"classname" "soe_fumigator_pickup"':2,
    '"classname" "soe_shield_part"':3,
    '"classname" "soe_civil_fuse"':3,
}
for token,want in counts.items():
    got=text.count(token)
    if got != want:
        raise SystemExit(f"{token}: expected {want}, got {got}")

# Badge is deliberately a two-action unlock, never a duplicate-shock shortcut.
if text.count('"targetname" "soe_g2_badge_power"') != 1:
    raise SystemExit("Canal must contain exactly one Badge power shock")
if text.count('"targetname" "soe_g2_badge_smash"') != 1:
    raise SystemExit("Canal must contain exactly one Badge crate smash")
if '"target" "soe_g2_badge_gate"' not in text:
    raise SystemExit("Badge interactions no longer feed their two-hit counter")
if '"target2" "soe_g2_badge_grate"' not in text:
    raise SystemExit("Badge shock no longer opens the physical grate")
if '"soe_required_hits" "2"' not in text:
    raise SystemExit("Badge counter must require two actions")
if '"targetname" "soe_g2_badge_pickup"' not in text or '"spawnflags" "1"' not in text:
    raise SystemExit("Detective Badge must remain a dormant pickup")

# G2 shows the Rift pocket but may not teleport until the underground G5 exists.
if '"classname" "soe_rift_portal"' in text:
    raise SystemExit("G2 must not create an active Rift portal before G5")

# Ruby Rabbit is explicitly a three-floor vertical route.
for marker in ("soe_g2_ruby_grapple_dest","soe_g2_ruby_power","soe_g2_ruby_ritual"):
    if f'"targetname" "{marker}"' not in text:
        raise SystemExit(f"Ruby Rabbit anchor missing: {marker}")

# Randomized clean-room groups must match the data contract.
for group,want in ((103,2),(201,3),(301,3)):
    got=text.count(f'"soe_random_group" "{group}"')
    if got != want:
        raise SystemExit(f"random group {group}: expected {want}, got {got}")

# Canal sword/Ovum statue should be present but hidden until its later quest reveal.
if '"targetname" "soe_g2_canal_ovum_statue"' not in text:
    raise SystemExit("Canal Ovum statue anchor missing")

plane_re=re.compile(
    r'^\( -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? \) '
    r'\( -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? \) '
    r'\( -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? -?\d+(?:\.\d+)? \) '
)
planes=[ln for ln in text.splitlines() if ln.startswith("( ")]
if len(planes) < 250:
    raise SystemExit(f"G2 brush plane count unexpectedly low: {len(planes)}")
for ln in planes:
    if not plane_re.match(ln):
        raise SystemExit(f"malformed Valve 220 plane line: {ln}")

print(
    "SOE G2 map OK: "
    f"{len(planes)} brush planes, 6 zones, 10 AI spawns, "
    "3-floor Ruby Rabbit, 2-action Badge unlock, inert Rift pocket, "
    "random groups 103/201/301"
)
