#!/usr/bin/env python3
"""Shared Shadows of Evil main-quest geometry injection.

The JSON is the single source of truth for cross-phase quest anchors. Standalone
phase generators call append_phase_mainquest_entities() so Reborn Sword / Flag
entities cannot silently diverge between data and compiled .map output.
"""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA_PATH = ROOT / "content" / "shadows_of_evil" / "mainquest_geometry.json"


def load_mainquest_geometry():
    return json.loads(DATA_PATH.read_text(encoding="utf-8"))


def _append_point(entities, point_entity, classname, origin, **keys):
    entities.append(point_entity(classname, origin, **keys))


def append_phase_mainquest_entities(entities, phase, point_entity):
    """Append mapper entities belonging to one standalone geometry phase."""
    data = load_mainquest_geometry()

    # One Reborn/Arch-Ovum circle per major surface district.
    for circle in data["rebornCircles"]:
        if circle["phase"] != phase:
            continue
        _append_point(
            entities, point_entity, "soe_reborn_circle", circle["origin"],
            style=circle["style"],
            targetname=f"soe_mq_reborn_circle_{circle['district']}",
        )

    # Character/player-slot Keeper at each original ritual room.
    for keeper in data["ritualKeepers"]:
        if keeper["phase"] != phase:
            continue
        _append_point(
            entities, point_entity, keeper["classname"], keeper["origin"],
            style=keeper["style"], targetname=keeper["targetname"],
        )

    book = data["book"]
    if book["phase"] == phase:
        _append_point(
            entities, point_entity, book["classname"], book["origin"],
            targetname=book["targetname"],
        )

    flag_spawn = data["flagSpawn"]
    if flag_spawn["phase"] == phase:
        _append_point(
            entities, point_entity, flag_spawn["classname"], flag_spawn["origin"],
            targetname=flag_spawn["targetname"],
        )

    # Two flag defenses + delivery Keeper + Shadowman harassment markers per district.
    for district in data["districts"]:
        if district["phase"] != phase:
            continue

        district_id = district["runtimeId"]

        for site in district["sites"]:
            _append_point(
                entities, point_entity, "soe_flag_site", site["origin"],
                style=district_id, health=site["index"],
                targetname=site["targetname"],
            )

        keeper = district["flagKeeper"]
        _append_point(
            entities, point_entity, "soe_flag_keeper", keeper["origin"],
            style=district_id, targetname=keeper["targetname"],
        )

        for idx, origin in enumerate(district["shadowmanSpawns"], start=1):
            _append_point(
                entities, point_entity, "soe_flag_shadowman_spawn", origin,
                style=district_id,
                targetname=f"soe_mq_flag_shadow_{district['id']}_{idx}",
            )

    return entities
