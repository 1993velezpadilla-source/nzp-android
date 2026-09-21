#!/usr/bin/env python3
"""Cross-map validation for physical Shadows of Evil main-quest geometry."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = json.loads(
    (ROOT / "content" / "shadows_of_evil" / "mainquest_geometry.json")
    .read_text(encoding="utf-8")
)

MAPS = {
    "g1": ROOT / "overlay" / "assets" / "source" / "maps" / "soe_g1" / "soe_g1.map",
    "g2": ROOT / "overlay" / "assets" / "source" / "maps" / "soe_g2" / "soe_g2.map",
    "g3": ROOT / "overlay" / "assets" / "source" / "maps" / "soe_g3" / "soe_g3.map",
    "g4": ROOT / "overlay" / "assets" / "source" / "maps" / "soe_g4" / "soe_g4.map",
    "g5": ROOT / "overlay" / "assets" / "source" / "maps" / "soe_g5" / "soe_g5.map",
}

texts = {}
for phase, path in MAPS.items():
    if not path.exists():
        raise SystemExit(f"missing generated map for cross-quest audit: {path}")
    texts[phase] = path.read_text(encoding="utf-8")

all_text = "\n".join(texts.values())

expected_counts = {
    '"classname" "soe_mainquest_book"': 1,
    '"classname" "soe_flag_spawn"': 1,
    '"classname" "soe_flag_site"': 8,
    '"classname" "soe_flag_keeper"': 4,
    '"classname" "soe_reborn_keeper"': 4,
    '"classname" "soe_reborn_circle"': 4,
    '"classname" "soe_flag_shadowman_spawn"': 12,
}
for token, expected in expected_counts.items():
    actual = all_text.count(token)
    if actual != expected:
        raise SystemExit(f"{token}: expected {expected}, got {actual}")

if texts["g1"].count('"classname" "soe_mainquest_book"') != 1:
    raise SystemExit("Nero book must exist exactly once in G1")
if texts["g5"].count('"classname" "soe_flag_spawn"') != 1:
    raise SystemExit("Rift flag spawn must exist exactly once in G5")

# Reborn circle bits must be one each across the four surface maps.
for phase, bit in (("g1", 1), ("g2", 2), ("g3", 4), ("g4", 8)):
    if texts[phase].count('"classname" "soe_reborn_circle"') != 1:
        raise SystemExit(f"{phase} must contain exactly one Reborn circle")
    if f'"style" "{bit}"' not in texts[phase]:
        raise SystemExit(f"{phase} Reborn circle bit {bit} missing")

# Player-slot / character presentation Keeper mapping.
expected_keeper = {
    "g1": 1,  # Nero
    "g3": 2,  # Jessica
    "g4": 3,  # Floyd
    "g2": 4,  # Jackie
}
for phase, style in expected_keeper.items():
    if texts[phase].count('"classname" "soe_reborn_keeper"') != 1:
        raise SystemExit(f"{phase} must contain exactly one Reborn Keeper")
    if f'"style" "{style}"' not in texts[phase]:
        raise SystemExit(f"{phase} Reborn Keeper style {style} missing")

# Flag runtime IDs + site indices must be complete per surface district.
expected_district = {
    "g1": 1,
    "g3": 2,
    "g4": 3,
    "g2": 4,
}
for phase, district_id in expected_district.items():
    text = texts[phase]
    if text.count('"classname" "soe_flag_site"') != 2:
        raise SystemExit(f"{phase} must contain exactly two Flag sites")
    if text.count('"classname" "soe_flag_keeper"') != 1:
        raise SystemExit(f"{phase} must contain exactly one Flag Keeper")
    if text.count('"classname" "soe_flag_shadowman_spawn"') != 3:
        raise SystemExit(f"{phase} must contain exactly three Flag Shadowman markers")

    # Parse entity blocks to make sure site 1 and site 2 both carry the same district ID.
    blocks = [block for block in text.split("}\n") if '"classname" "soe_flag_site"' in block]
    found_indices = set()
    for block in blocks:
        if f'"style" "{district_id}"' not in block:
            raise SystemExit(f"{phase} Flag site has wrong runtime district ID")
        if '"health" "1"' in block:
            found_indices.add(1)
        if '"health" "2"' in block:
            found_indices.add(2)
    if found_indices != {1, 2}:
        raise SystemExit(f"{phase} Flag site indices broken: {found_indices}")

# Every JSON targetname must survive into generated map output.
for circle in DATA["rebornCircles"]:
    name = f"soe_mq_reborn_circle_{circle['district']}"
    if f'"targetname" "{name}"' not in texts[circle["phase"]]:
        raise SystemExit(f"generated Reborn circle missing: {name}")

for keeper in DATA["ritualKeepers"]:
    if f'"targetname" "{keeper["targetname"]}"' not in texts[keeper["phase"]]:
        raise SystemExit(f"generated Reborn Keeper missing: {keeper['targetname']}")

for district in DATA["districts"]:
    phase = district["phase"]
    for site in district["sites"]:
        if f'"targetname" "{site["targetname"]}"' not in texts[phase]:
            raise SystemExit(f"generated Flag site missing: {site['targetname']}")
    name = district["flagKeeper"]["targetname"]
    if f'"targetname" "{name}"' not in texts[phase]:
        raise SystemExit(f"generated Flag Keeper missing: {name}")

print(
    "SOE main-quest geometry OK: 1 book, 1 Rift flag spawn, 8 Flag sites, "
    "4 Flag Keepers, 12 harassment markers, 4 Reborn Keepers, 4 Reborn circles"
)
