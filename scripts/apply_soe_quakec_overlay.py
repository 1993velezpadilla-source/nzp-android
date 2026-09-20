#!/usr/bin/env python3
"""Apply the Shadows of Evil QuakeC overlay to a pinned NZ:P QuakeC checkout."""

from pathlib import Path
import shutil
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: apply_soe_quakec_overlay.py <quakec-root>")

root = Path(sys.argv[1]).resolve()
overlay_root = Path(__file__).resolve().parents[1] / "overlay" / "quakec"

if not (root / "progs" / "ssqc.src").exists():
    raise SystemExit(f"not an NZ:P QuakeC checkout: {root}")

src = overlay_root / "source" / "server" / "maps" / "soe" / "soe_state.qc"
dst = root / "source" / "server" / "maps" / "soe" / "soe_state.qc"
dst.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(src, dst)

ssqc = root / "progs" / "ssqc.src"
text = ssqc.read_text(encoding="utf-8")
include_anchor = "dummies.qc\n"
include_line = "maps/soe/soe_state.qc\n"
if include_line not in text:
    if include_anchor not in text:
        raise SystemExit("ssqc include anchor changed; inspect pinned upstream")
    text = text.replace(include_anchor, include_anchor + include_line, 1)
    ssqc.write_text(text, encoding="utf-8")

main_qc = root / "source" / "server" / "main.qc"
text = main_qc.read_text(encoding="utf-8")
init_anchor = "\tGamemode_Init();\n"
init_call = "\tSoE_Init();\n"
if init_call not in text:
    if init_anchor not in text:
        raise SystemExit("worldspawn hook anchor changed; inspect pinned upstream")
    text = text.replace(init_anchor, init_call + init_anchor, 1)
    main_qc.write_text(text, encoding="utf-8")

rounds_qc = root / "source" / "server" / "rounds.qc"
text = rounds_qc.read_text(encoding="utf-8")
round_anchor = "void() NewRound =\n{\n"
round_call = "\tSoE_OnNewRound();\n"
if round_call not in text:
    if round_anchor not in text:
        raise SystemExit("NewRound hook anchor changed; inspect pinned upstream")
    text = text.replace(round_anchor, round_anchor + round_call, 1)
    rounds_qc.write_text(text, encoding="utf-8")

print("Shadows of Evil QuakeC overlay applied")
