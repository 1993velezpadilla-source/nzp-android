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
    "maps/soe/soe_specials.qc\n",
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
frame_call = "\tSoE_Frame();\n\tSoE_ProcessSpecialSpawns();\n"
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

        entity soe_old_self = self;
        self = downed_player;
        GetUp();
        self = soe_old_self;

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


# Special-enemy AI update: keep stock pathfinding/movement, layer SoE state on top.
ai_qc = root / "source" / "server" / "ai" / "ai_core.qc"
text = ai_qc.read_text(encoding="utf-8")
special_ai_anchor = "void() Zombie_AI = {\n"
special_ai_call = "void() Zombie_AI = {\n\tSoE_UpdateSpecialAI();\n"
if special_ai_call not in text:
    if special_ai_anchor not in text:
        raise SystemExit("Zombie_AI hook anchor changed; inspect pinned upstream")
    text = text.replace(special_ai_anchor, special_ai_call, 1)
    ai_qc.write_text(text, encoding="utf-8")

# Special damage runs before generic zombie HP / Insta-Kill logic.
damage_qc = root / "source" / "server" / "damage.qc"
text = damage_qc.read_text(encoding="utf-8")
damage_anchor = "void(entity victim, entity attacker, float damage, float d_style) DamageHandler = {\n"
damage_call = damage_anchor + "\tif (SoE_HandleSpecialDamage(victim, attacker, damage, d_style))\n\t\treturn;\n\n"
if "SoE_HandleSpecialDamage(victim, attacker, damage, d_style)" not in text:
    if damage_anchor not in text:
        raise SystemExit("DamageHandler hook anchor changed; inspect pinned upstream")
    text = text.replace(damage_anchor, damage_call, 1)
    damage_qc.write_text(text, encoding="utf-8")

# Pooled zombie entities must never retain Margwa state when reused normally.
zombie_qc = root / "source" / "server" / "ai" / "zombie_core.qc"
text = zombie_qc.read_text(encoding="utf-8")
pool_anchor = '''\tszombie = getFreeZombieEnt();
\tif(szombie == world || zombie_spawn_timer > time)
'''
pool_patch = '''\tszombie = getFreeZombieEnt();
\tif (szombie != world)
\t\tSoE_ClearSpecialState(szombie);
\tif(szombie == world || zombie_spawn_timer > time)
'''
if "SoE_ClearSpecialState(szombie);" not in text:
    if pool_anchor not in text:
        raise SystemExit("zombie pool reset anchor changed; inspect pinned upstream")
    text = text.replace(pool_anchor, pool_patch, 1)
    zombie_qc.write_text(text, encoding="utf-8")

# Margwas are canonically immune to Nuke. Skip them in the Nuke watcher chain.
powerups_qc = root / "source" / "server" / "entities" / "powerups.qc"
text = powerups_qc.read_text(encoding="utf-8")
nuke_anchor = '''\t// play explosion effects
\tPU_NukeExplode(self.origin + '0 0 13');
'''
nuke_patch = '''\t// Shadows of Evil Margwas are immune to Nuke; advance without killing.
\tif (SoE_IsNukeImmune(self)) {
\t\tself = oldself;
\t\tself.goaldummy = findfloat(self.goaldummy, iszomb, 1);
\t\tself.nextthink = time + 0.01;
\t\treturn;
\t}

\t// play explosion effects
\tPU_NukeExplode(self.origin + '0 0 13');
'''
if "Shadows of Evil Margwas are immune to Nuke" not in text:
    if nuke_anchor not in text:
        raise SystemExit("Nuke hook anchor changed; inspect pinned upstream")
    text = text.replace(nuke_anchor, nuke_patch, 1)
    powerups_qc.write_text(text, encoding="utf-8")

print("Shadows of Evil QuakeC overlay applied")
