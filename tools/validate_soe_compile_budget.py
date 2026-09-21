#!/usr/bin/env python3
"""Fail CI when the integrated Morg City blockout exceeds its smoke-build budgets."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

BUDGETS = {
    "faces": 8000,
    "clipnodes": 6000,
    "planes": 1600,
    "portalleafs": 1000,
    "light_styles": 8,
}


def last_int(pattern: str, text: str, label: str) -> int:
    matches = re.findall(pattern, text, re.MULTILINE)
    if not matches:
        raise SystemExit(f"compile budget parser could not find {label}")
    value = matches[-1]
    if isinstance(value, tuple):
        value = value[-1]
    return int(value)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--log", required=True, type=Path)
    args = parser.parse_args()

    text = args.log.read_text(encoding="utf-8", errors="replace")

    metrics = {
        "faces": last_int(r"^\s*(\d+) faces\s*$", text, "faces"),
        "clipnodes": last_int(
            r"^Reduced\s+\d+\s+clipnodes\s+to\s+(\d+)\s*$",
            text,
            "reduced clipnodes",
        ),
        "planes": last_int(
            r"^Reduced\s+\d+\s+planes\s+to\s+(\d+)\s*$",
            text,
            "reduced planes",
        ),
        "portalleafs": last_int(r"^\s*(\d+) portalleafs\s*$", text, "portalleafs"),
        "light_styles": last_int(r"^\s*(\d+) light styles\s*$", text, "light styles"),
    }

    failures = []
    for name, value in metrics.items():
        budget = BUDGETS[name]
        if value > budget:
            failures.append(f"{name} {value} > budget {budget}")

    summary = ", ".join(
        f"{name}={metrics[name]}/{BUDGETS[name]}" for name in BUDGETS
    )

    if failures:
        raise SystemExit("SOE compile budget exceeded: " + "; ".join(failures))

    print("SOE compile budget OK: " + summary)


if __name__ == "__main__":
    main()
