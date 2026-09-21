#!/usr/bin/env python3
"""Static integration audit for generated full Morg City soe.map."""

from __future__ import annotations

import re
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAP = ROOT / "overlay" / "assets" / "source" / "maps" / "soe" / "soe.map"
text = MAP.read_text(encoding="utf-8")

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
    '"adjacent_zones" "easy_street, canal_entry, footlight_entry, waterfront_entry"',
    '"adjacent_zones" "junction, canal_lower"',
    '"adjacent_zones" "junction, footlight_main"',
    '"adjacent_zones" "junction, waterfront_lower"',
):
    if required not in text:
        raise SystemExit(f"cross-phase spawn-zone adjacency missing: {required}")

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
    "paired Rifts, complete Reborn+Flag quest geometry, global Tram/finale"
)
