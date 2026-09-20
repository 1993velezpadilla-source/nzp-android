#!/usr/bin/env python3
"""Apply project-owned asset overlays onto a checked-out NZ:P assets tree."""

from __future__ import annotations

import argparse
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OVERLAY = ROOT / "overlay" / "assets"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--assets-root", required=True, type=Path)
    args = parser.parse_args()

    assets_root = args.assets_root.resolve()
    if not assets_root.exists():
        raise SystemExit(f"assets root does not exist: {assets_root}")

    if not OVERLAY.exists():
        raise SystemExit(f"asset overlay does not exist: {OVERLAY}")

    copied = 0
    for src in sorted(OVERLAY.rglob("*")):
        if not src.is_file():
            continue
        rel = src.relative_to(OVERLAY)
        dst = assets_root / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        copied += 1
        print(f"overlay: {rel}")

    print(f"applied {copied} asset overlay file(s)")


if __name__ == "__main__":
    main()
