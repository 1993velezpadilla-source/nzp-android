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

# Copy every SoE server module, not just the state file.
src_dir = overlay_root / "source" / "server" / "maps" / "soe"
dst_dir = root / "source" / "server" / "maps" / "soe"
dst_dir.mkdir(parents=True, exist_ok=True)
for src in sorted(src_dir.glob("*.qc")):
    shutil.copy2(src, dst_dir / src.name)

# Include the modules in dependency order before rounds/main are compiled.
ssqc = root / "progs" / "ssqc.src"
text = ssqc.read_text(encoding="utf-8")
include_anchor = "dummies.qc\n"
include_lines = [
    "maps/soe/soe_state.qc\n",
    "maps/soe/soe_beast.qc\n",
    "maps/soe/soe_entities.qc\n",
    "maps/soe/soe_tram.qc\n",
]
if not all(line in text for line in include_lines):
    if include_anchor not in text:
        raise SystemExit("ssqc include anchor changed; inspect pinned upstream")
    block = "".join(line for line in include_lines if line not in text)
    text = text.replace(include_anchor, include_anchor + block, 1)
    ssqc.write_text(text, encoding="utf-8")

main_qc = root / "source" / "server" / "main.qc"
text = main_qc.read_text(encoding="utf-8")

# Map initialization hook.
init_anchor = "\tGamemode_Init();\n"
init_call = "\tSoE_Init();\n\tSoE_ResetTransportState();\n"
if init_call not in text:
    if init_anchor not in text:
        raise SystemExit("worldspawn hook anchor changed; inspect pinned upstream")
    text = text.replace(init_anchor, init_call + init_anchor, 1)

# Per-frame Beast/grapple/finale runtime hook.
frame_anchor = "\tframecount = framecount + 1;\n"
frame_call = "\tSoE_Frame();\n"
if frame_call not in text:
    if frame_anchor not in text:
        raise SystemExit("StartFrame hook anchor changed; inspect pinned upstream")
    text = text.replace(frame_anchor, frame_anchor + "\n" + frame_call, 1)

main_qc.write_text(text, encoding="utf-8")

rounds_qc = root / "source" / "server" / "rounds.qc"
text = rounds_qc.read_text(encoding="utf-8")
round_anchor = "void() NewRound =\n{\n"
round_calls = "\tSoE_OnNewRound();\n\tSoE_ResetBeastCharges();\n"
if "\tSoE_ResetBeastCharges();\n" not in text:
    if round_anchor not in text:
        raise SystemExit("NewRound hook anchor changed; inspect pinned upstream")
    # Replace any earlier one-line overlay hook with the complete hook block.
    text = text.replace(round_anchor + "\tSoE_OnNewRound();\n", round_anchor + round_calls, 1)
    if "\tSoE_ResetBeastCharges();\n" not in text:
        text = text.replace(round_anchor, round_anchor + round_calls, 1)
    rounds_qc.write_text(text, encoding="utf-8")


# Normal NZ:P zombies/dogs must ignore a player while they are in Beast Mode.
ai_qc = root / "source" / "server" / "ai" / "ai_core.qc"
text = ai_qc.read_text(encoding="utf-8")
target_anchor = 'if (targets.downed == true || targets.is_spectator == true) {'
target_patch = 'if (targets.downed == true || targets.is_spectator == true || SoE_IsBeast(targets)) {'
if target_patch not in text:
    if target_anchor not in text:
        raise SystemExit("AI target filter anchor changed; inspect pinned upstream")
    text = text.replace(target_anchor, target_patch, 1)
    ai_qc.write_text(text, encoding="utf-8")

# Beast Mode revives are instant in Shadows of Evil and immediately end Beast.
last_stand_qc = root / "source" / "server" / "player" / "last_stand.qc"
text = last_stand_qc.read_text(encoding="utf-8")
revive_anchor = '''    // No one is actively reviving the downed team mate.
    if (self.owner.beingrevived == false) {
'''
revive_patch = '''    // Shadows of Evil: Beast Mode instantly revives a teammate, then ends Beast.
    if (SoE_IsBeast(other)) {
        entity downed_player = self.owner;
        Player_AddScore(other, downed_player.requirespower, false);
        downed_player.revives++;

        entity old_self = self;
        self = downed_player;
        GetUp();
        self = old_self;

        DisableReviveIcon(downed_player.playernum);
        SoE_EndBeast(other);
        remove(self);
        return;
    }

    // No one is actively being revived.
    if (self.owner.beingrevived == false) {
'''
if "Shadows of Evil: Beast Mode instantly revives" not in text:
    if revive_anchor not in text:
        raise SystemExit("revive hook anchor changed; inspect pinned upstream")
    text = text.replace(revive_anchor, revive_patch, 1)
    last_stand_qc.write_text(text, encoding="utf-8")

print("Shadows of Evil QuakeC overlay applied")
