#!/usr/bin/env python3
"""Enumerate or count valid attachment combinations for a weapon.

Designed for the normalized codarmory snapshot in:
docs/zombies-design-research/cod-weapons-progression-research/data/codarmory-mw2-mw3/

The source snapshot lists attachment compatibility and category. This tool
enforces at most one attachment from each category. Special in-game exclusions
or conversion-kit slot mutations need explicit rules before they can be applied.
"""

from __future__ import annotations
import argparse
import itertools
import json
from pathlib import Path
from typing import Dict, Iterable, List


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def compatible_groups(weapon: dict, attachments_by_id: Dict[str, dict]):
    groups: Dict[str, List[dict]] = {}
    for attachment_id in weapon.get("attachment_ids", []):
        attachment = attachments_by_id.get(attachment_id)
        if not attachment:
            continue
        groups.setdefault(attachment.get("category_id", "unknown"), []).append(attachment)
    return groups


def count_combinations(groups: Dict[str, List[dict]], max_size: int) -> List[int]:
    # Coefficient DP for product over categories: product(1 + n_category*x).
    coeff = [1] + [0] * max_size
    for values in groups.values():
        n = len(values)
        previous = coeff[:]
        for k in range(1, max_size + 1):
            coeff[k] = previous[k] + previous[k - 1] * n
    return coeff


def enumerate_combinations(groups: Dict[str, List[dict]], max_size: int, exact_size: int | None):
    categories = sorted(groups)
    sizes: Iterable[int]
    if exact_size is not None:
        sizes = [exact_size]
    else:
        sizes = range(1, min(max_size, len(categories)) + 1)

    for size in sizes:
        for category_subset in itertools.combinations(categories, size):
            pools = [groups[category] for category in category_subset]
            for selected in itertools.product(*pools):
                yield {
                    "attachments": [
                        {
                            "id": item["id"],
                            "name": item["name"],
                            "category_id": item["category_id"],
                            "pros": item.get("pros", []),
                            "cons": item.get("cons", []),
                        }
                        for item in selected
                    ],
                    "pros": sorted({p for item in selected for p in item.get("pros", [])}),
                    "cons": sorted({c for item in selected for c in item.get("cons", [])}),
                }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--weapons", type=Path, required=True)
    parser.add_argument("--attachments", type=Path, required=True)
    parser.add_argument("--weapon", required=True, help="weapon id or exact case-insensitive name")
    parser.add_argument("--max-size", type=int, default=5)
    parser.add_argument("--exact-size", type=int)
    parser.add_argument("--count-only", action="store_true")
    parser.add_argument("--max-results", type=int, default=100000)
    parser.add_argument("--all", action="store_true", help="disable max-results safety limit")
    parser.add_argument("--out", type=Path, help="NDJSON output; stdout when omitted")
    args = parser.parse_args()

    weapons_doc = load_json(args.weapons)
    attachments_doc = load_json(args.attachments)
    weapons = weapons_doc.get("weapons", weapons_doc)
    attachments = attachments_doc.get("attachments", attachments_doc)
    attachments_by_id = {item["id"]: item for item in attachments}

    needle = args.weapon.casefold()
    weapon = next(
        (w for w in weapons if w.get("id", "").casefold() == needle or w.get("name", "").casefold() == needle),
        None,
    )
    if not weapon:
        raise SystemExit(f"weapon not found: {args.weapon}")

    groups = compatible_groups(weapon, attachments_by_id)
    max_size = max(0, min(args.max_size, 5))
    counts = count_combinations(groups, max_size)
    summary = {
        "weapon_id": weapon["id"],
        "name": weapon["name"],
        "compatible_attachment_count": sum(len(v) for v in groups.values()),
        "category_counts": {k: len(v) for k, v in sorted(groups.items())},
        "combinations_by_size": counts,
        "combinations_1_to_max": sum(counts[1:]),
    }

    if args.count_only:
        print(json.dumps(summary, indent=2))
        return

    target = args.out.open("w", encoding="utf-8") if args.out else None
    emitted = 0
    try:
        header = json.dumps({"type": "summary", **summary})
        (target.write(header + "\n") if target else print(header))
        for combo in enumerate_combinations(groups, max_size, args.exact_size):
            if not args.all and emitted >= args.max_results:
                warning = json.dumps({
                    "type": "truncated",
                    "emitted": emitted,
                    "hint": "pass --all or increase --max-results to enumerate the full space",
                })
                (target.write(warning + "\n") if target else print(warning))
                break
            row = json.dumps({"type": "build", "weapon_id": weapon["id"], **combo}, ensure_ascii=False)
            (target.write(row + "\n") if target else print(row))
            emitted += 1
    finally:
        if target:
            target.close()


if __name__ == "__main__":
    main()
