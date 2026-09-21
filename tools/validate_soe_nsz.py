#!/usr/bin/env python3
"""Validate the generated NZ:P spawn-zone file exactly as runtime will consume it."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path

MAX_ZONES = 64
MAX_ZONE_BRUSHES = 8
MAX_ADJ_ZONE = 8
MAX_ZONE_WAY_TARGETS = 6


@dataclass
class Zone:
    name: str
    zone_id: int
    target: str
    fog: str
    adjacent_ids: list[int]
    brushes: list[tuple[tuple[float, float, float], tuple[float, float, float]]]
    way_targets: list[str]


def require_line(lines: list[str], index: int, label: str) -> tuple[str, int]:
    if index >= len(lines):
        raise SystemExit(f"truncated NSZ while reading {label}")
    return lines[index], index + 1


def parse_vec(value: str, label: str) -> tuple[float, float, float]:
    parts = value.split()
    if len(parts) != 3:
        raise SystemExit(f"{label} is not a 3-vector: {value}")
    try:
        return tuple(float(x) for x in parts)
    except ValueError as exc:
        raise SystemExit(f"{label} contains non-numeric data: {value}") from exc


def parse(path: Path) -> list[Zone]:
    lines = path.read_text(encoding="utf-8").splitlines()
    if len(lines) < 2:
        raise SystemExit("NSZ is empty/truncated")

    if lines[0] != "zone_file_version: 1.1.0":
        raise SystemExit(f"unexpected NSZ version header: {lines[0]}")

    prefix = "number_of_zones: "
    if not lines[1].startswith(prefix):
        raise SystemExit("NSZ zone count header missing")
    try:
        count = int(lines[1][len(prefix):])
    except ValueError as exc:
        raise SystemExit("NSZ zone count is not an integer") from exc

    if count <= 0 or count > MAX_ZONES:
        raise SystemExit(f"NSZ zone count {count} exceeds supported range 1..{MAX_ZONES}")

    zones: list[Zone] = []
    i = 2
    for zone_index in range(count):
        name, i = require_line(lines, i, f"zone {zone_index} name")
        zone_id_line, i = require_line(lines, i, f"zone {name} id")
        target, i = require_line(lines, i, f"zone {name} target")
        fog, i = require_line(lines, i, f"zone {name} fog")

        try:
            zone_id = int(zone_id_line)
        except ValueError as exc:
            raise SystemExit(f"zone {name} has invalid id: {zone_id_line}") from exc

        adj_count_line, i = require_line(lines, i, f"zone {name} adjacency count")
        try:
            adj_count = int(adj_count_line)
        except ValueError as exc:
            raise SystemExit(f"zone {name} has invalid adjacency count") from exc
        if not 0 <= adj_count <= MAX_ADJ_ZONE:
            raise SystemExit(f"zone {name} adjacency count {adj_count} exceeds {MAX_ADJ_ZONE}")

        adjacent_ids = []
        for _ in range(adj_count):
            value, i = require_line(lines, i, f"zone {name} adjacent id")
            try:
                adjacent_ids.append(int(value))
            except ValueError as exc:
                raise SystemExit(f"zone {name} has invalid adjacent id: {value}") from exc

        brush_count_line, i = require_line(lines, i, f"zone {name} brush count")
        try:
            brush_count = int(brush_count_line)
        except ValueError as exc:
            raise SystemExit(f"zone {name} has invalid brush count") from exc
        if not 1 <= brush_count <= MAX_ZONE_BRUSHES:
            raise SystemExit(
                f"zone {name} brush count {brush_count} outside supported 1..{MAX_ZONE_BRUSHES}"
            )

        brushes = []
        for brush_index in range(brush_count):
            mins_line, i = require_line(lines, i, f"zone {name} brush {brush_index} mins")
            maxs_line, i = require_line(lines, i, f"zone {name} brush {brush_index} maxs")
            mins = parse_vec(mins_line, f"zone {name} brush {brush_index} mins")
            maxs = parse_vec(maxs_line, f"zone {name} brush {brush_index} maxs")
            if any(mins[axis] >= maxs[axis] for axis in range(3)):
                raise SystemExit(f"zone {name} brush {brush_index} has invalid AABB")
            brushes.append((mins, maxs))

        way_count_line, i = require_line(lines, i, f"zone {name} way-target count")
        try:
            way_count = int(way_count_line)
        except ValueError as exc:
            raise SystemExit(f"zone {name} has invalid way-target count") from exc
        if not 0 <= way_count <= MAX_ZONE_WAY_TARGETS:
            raise SystemExit(
                f"zone {name} way-target count {way_count} exceeds {MAX_ZONE_WAY_TARGETS}"
            )

        way_targets = []
        for _ in range(way_count):
            value, i = require_line(lines, i, f"zone {name} way target")
            if not value:
                raise SystemExit(f"zone {name} contains an empty way target")
            way_targets.append(value)

        zones.append(
            Zone(
                name=name,
                zone_id=zone_id,
                target=target,
                fog=fog,
                adjacent_ids=adjacent_ids,
                brushes=brushes,
                way_targets=way_targets,
            )
        )

    if any(line.strip() for line in lines[i:]):
        raise SystemExit("NSZ contains unexpected trailing data")

    return zones


def validate(zones: list[Zone], expected_zones: int | None) -> None:
    if expected_zones is not None and len(zones) != expected_zones:
        raise SystemExit(f"expected {expected_zones} zones, got {len(zones)}")

    names = [z.name for z in zones]
    ids = [z.zone_id for z in zones]
    if len(names) != len(set(names)):
        raise SystemExit("NSZ contains duplicate zone names")
    if len(ids) != len(set(ids)):
        raise SystemExit("NSZ contains duplicate zone ids")
    if set(ids) != set(range(1, len(zones) + 1)):
        raise SystemExit(f"NSZ ids must be contiguous 1..{len(zones)}")

    by_id = {z.zone_id: z for z in zones}
    by_name = {z.name: z for z in zones}

    if "easy_street" not in by_name:
        raise SystemExit("NSZ playable root easy_street missing")

    for zone in zones:
        if not zone.target:
            raise SystemExit(f"zone {zone.name} has empty spawn target")
        if len(zone.adjacent_ids) != len(set(zone.adjacent_ids)):
            raise SystemExit(f"zone {zone.name} repeats an adjacent id")
        if len(zone.way_targets) != len(set(zone.way_targets)):
            raise SystemExit(f"zone {zone.name} repeats a way target")

        for adj_id in zone.adjacent_ids:
            if adj_id not in by_id:
                raise SystemExit(f"zone {zone.name} references unknown zone id {adj_id}")
            if adj_id == zone.zone_id:
                raise SystemExit(f"zone {zone.name} is adjacent to itself")
            other = by_id[adj_id]
            if zone.zone_id not in other.adjacent_ids:
                raise SystemExit(
                    f"NSZ adjacency not symmetric: {zone.name} -> {other.name}"
                )

    reachable: set[int] = set()
    frontier = [by_name["easy_street"].zone_id]
    while frontier:
        current = frontier.pop()
        if current in reachable:
            continue
        reachable.add(current)
        frontier.extend(
            adj for adj in by_id[current].adjacent_ids if adj not in reachable
        )

    if len(reachable) != len(zones):
        missing = sorted(by_id[z].name for z in set(by_id) - reachable)
        raise SystemExit(f"NSZ contains unreachable zone island(s): {missing}")

    print(
        f"SOE NSZ OK: version 1.1.0, {len(zones)} zones, "
        f"{sum(len(z.brushes) for z in zones)} brushes, "
        f"{sum(len(z.way_targets) for z in zones)} way targets"
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--file", required=True, type=Path)
    parser.add_argument("--expected-zones", type=int)
    args = parser.parse_args()
    validate(parse(args.file), args.expected_zones)


if __name__ == "__main__":
    main()
