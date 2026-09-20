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
    "maps/soe/soe_perks.qc\n",
    "maps/soe/soe_tram.qc\n",
    "maps/soe/soe_specials.qc\n",
    "maps/soe/soe_misc_secrets.qc\n",
    "maps/soe/soe_lore.qc\n",
    "maps/soe/soe_arnie.qc\n",
    "maps/soe/soe_sidequests.qc\n",
    "maps/soe/soe_chain_traps.qc\n",
    "maps/soe/soe_rituals.qc\n",
    "maps/soe/soe_special_movers.qc\n",
    "maps/soe/soe_harvest.qc\n",
    "maps/soe/soe_servant.qc\n",
    "maps/soe/soe_civil_protector.qc\n",
    "maps/soe/soe_shield.qc\n",
    "maps/soe/soe_sword.qc\n",
    "maps/soe/soe_special_rounds.qc\n",
    "maps/soe/soe_mainquest.qc\n",
    "maps/soe/soe_shadowman.qc\n",
    "maps/soe/soe_finale.qc\n",
    "maps/soe/soe_random_spawns.qc\n",
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
init_call = "\tSoE_Init();\n\tSoE_ResetTransportState();\n\tSoE_ResetSideQuests();\n\tSoE_ResetMiscSecrets();\n\tSoE_ResetArnie();\n\tSoE_ResetServant();\n\tSoE_ResetCivilProtector();\n\tSoE_ResetShield();\n\tSoE_ResetSword();\n\tSoE_ResetSpecialRoundSchedule();\n\tSoE_ResetMainQuest();\n\tSoE_ResetShadowman();\n\tSoE_ResetFinale();\n\tSoE_ResetRandomSpawns();\n"
if init_call not in text:
    if init_anchor not in text:
        raise SystemExit("worldspawn hook anchor changed; inspect pinned upstream")
    text = text.replace(init_anchor, init_call + init_anchor, 1)

# Per-frame Beast/grapple/finale runtime hook.
frame_anchor = "\tframecount = framecount + 1;\n"
frame_call = "\tSoE_RandomSpawnFrame();\n\tSoE_Frame();\n\tSoE_RitualFrame();\n\tSoE_ShieldFrame();\n\tSoE_MainQuestFrame();\n\tSoE_ShadowmanFrame();\n\tSoE_FinaleFrame();\n\tSoE_ProcessSpecialSpawns();\n"
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
special_ai_call = "void() Zombie_AI = {\n\tSoE_UpdateSpecialAI();\n\tif (SoE_ArnieOverrideZombieAI())\n\t\treturn;\n"
if special_ai_call not in text:
    if special_ai_anchor not in text:
        raise SystemExit("Zombie_AI hook anchor changed; inspect pinned upstream")
    text = text.replace(special_ai_anchor, special_ai_call, 1)
    ai_qc.write_text(text, encoding="utf-8")

# Special damage runs before generic zombie HP / Insta-Kill logic.
damage_qc = root / "source" / "server" / "damage.qc"
text = damage_qc.read_text(encoding="utf-8")
damage_anchor = "void(entity victim, entity attacker, float damage, float d_style) DamageHandler = {\n"
damage_call = damage_anchor + "\tif (SoE_HandleSpecialDamage(victim, attacker, damage, d_style))\n\t\treturn;\n\n\tif (SoE_ShieldAbsorbDamage(victim, attacker, damage, d_style))\n\t\treturn;\n\n"
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


# NZ:P's hit parser assumes every non-zombie damageable is a zombie limb.
# Teach it that SoE flying/rolling specials are full body entities.
weapon_qc = root / "source" / "server" / "weapons" / "weapon_core.qc"
text = weapon_qc.read_text(encoding="utf-8")
parse_anchor = '''\t\t\tif (ent.classname != "ai_zombie" && ent.classname != "ai_dog") //limb
\t\t\t\tbody_ent = ent.owner;
\t\t\telse
\t\t\t\tbody_ent = ent;
'''
parse_patch = '''\t\t\tif (SoE_IsCustomSpecialBody(ent))
\t\t\t\tbody_ent = ent;
\t\t\telse if (ent.classname != "ai_zombie" && ent.classname != "ai_dog") //limb
\t\t\t\tbody_ent = ent.owner;
\t\t\telse
\t\t\t\tbody_ent = ent;
'''
if "SoE_IsCustomSpecialBody(ent)" not in text:
    if parse_anchor not in text:
        raise SystemExit("Parse_Damage body classification anchor changed; inspect pinned upstream")
    text = text.replace(parse_anchor, parse_patch, 1)

# Reset the local head-shot accumulator for every damage entity, not only once
# before the loop. This prevents a previous zombie head hit from leaking into
# a subsequent custom-special body processed during the same frame.
loop_anchor = '''\tent = findfloat (world, washit, 1);

\twhile (ent) {
'''
loop_patch = '''\tent = findfloat (world, washit, 1);

\twhile (ent) {
\t\thead_hit = 0;
'''
if "\twhile (ent) {\n\t\thead_hit = 0;\n" not in text:
    if loop_anchor not in text:
        raise SystemExit("Parse_Damage loop anchor changed; inspect pinned upstream")
    text = text.replace(loop_anchor, loop_patch, 1)

weapon_qc.write_text(text, encoding="utf-8")


# Convert selected SoE rounds into true Parasite/Elemental special rounds.
rounds_qc = root / "source" / "server" / "rounds.qc"
text = rounds_qc.read_text(encoding="utf-8")

increment_anchor = "\trounds = rounds + 1;\n"
increment_patch = "\trounds = rounds + 1;\n\tSoE_AfterRoundIncrement();\n\tSoE_HarvestPodsOnNewRound();\n\tSoE_MainQuestOnNewRound();\n"
if "\tSoE_AfterRoundIncrement();\n" not in text:
    if increment_anchor not in text:
        raise SystemExit("round increment anchor changed; inspect pinned upstream")
    text = text.replace(increment_anchor, increment_patch, 1)

spawn_anchor = '''\t// temporarily prevent spawning
\tif (nuke_powerup_spawndelay > time)
\t\treturn;

'''
spawn_patch = '''\t// temporarily prevent spawning
\tif (nuke_powerup_spawndelay > time)
\t\treturn;

\t// Apocalypse Averted finale owns combat through its endless purple
\t// Margwa scheduler; never fall through to stock wave spawns.
\tif (soe_finale_active)
\t\treturn;

\t// SoE special rounds own the spawn stream and never fall through to
\t// normal zombies/hellhounds while active.
\tif (SoE_SpawnSpecialRoundEnemy())
\t\treturn;

'''
if "SoE_SpawnSpecialRoundEnemy()" not in text:
    if spawn_anchor not in text:
        raise SystemExit("Spawn_Enemy anchor changed; inspect pinned upstream")
    text = text.replace(spawn_anchor, spawn_patch, 1)

total_anchor = '''\treturn count;
}

//
// Rounds_PlayTransition'''
total_patch = '''\tcount = SoE_AdjustRoundEnemyTotal(count);
\treturn count;
}

//
// Rounds_PlayTransition'''
if "SoE_AdjustRoundEnemyTotal(count)" not in text:
    if total_anchor not in text:
        raise SystemExit("getZombieTotal return anchor changed; inspect pinned upstream")
    text = text.replace(total_anchor, total_patch, 1)

rounds_qc.write_text(text, encoding="utf-8")


# Configure W_CUSTOM1 as the SoE Apothicon Servant. We deliberately reuse
# the Ray Gun presentation assets only as a temporary visual shell; firing is
# intercepted below and uses dedicated SoE singularity gameplay.
weapon_stats_qc = root / "source" / "shared" / "weapon_stats.qc"
text = weapon_stats_qc.read_text(encoding="utf-8")

def replace_once_or_die(source, old, new, label):
    if new in source:
        return source
    if old not in source:
        raise SystemExit(f"{label} anchor changed; inspect pinned upstream")
    return source.replace(old, new, 1)

text = replace_once_or_die(
    text,
    '''\t\tcase W_RAY:
\t\t\tweapon_name = "Ray Gun";
\t\t\tbreak;''',
    '''\t\tcase W_CUSTOM1:
\t\t\tweapon_name = "Apothicon Servant";
\t\t\tbreak;
\t\tcase W_RAY:
\t\t\tweapon_name = "Ray Gun";
\t\t\tbreak;''',
    "Servant weapon name"
)

text = replace_once_or_die(
    text,
    '''\t\tcase W_RAY:
\t\tcase W_PORTER:
\t\t\treturn FIRETYPE_RAYBEAM;''',
    '''\t\tcase W_CUSTOM1:
\t\t\treturn FIRETYPE_RAYBEAM;
\t\tcase W_RAY:
\t\tcase W_PORTER:
\t\t\treturn FIRETYPE_RAYBEAM;''',
    "Servant firetype"
)

text = replace_once_or_die(
    text,
    '''\t\tcase W_RAY:
\t\t\treturn 20;''',
    '''\t\tcase W_CUSTOM1:
\t\t\treturn 1;
\t\tcase W_RAY:
\t\t\treturn 20;''',
    "Servant magazine"
)

text = replace_once_or_die(
    text,
    '''\t\tcase W_RAY:
\t\t\tweapon_ammo = 160;
\t\t\tbreak;''',
    '''\t\tcase W_CUSTOM1:
\t\t\tweapon_ammo = 10;
\t\t\tbreak;
\t\tcase W_RAY:
\t\t\tweapon_ammo = 160;
\t\t\tbreak;''',
    "Servant reserve ammo"
)

# Use zero generic bullet damage: all damage is owned by the dedicated
# singularity entity and is intentionally round-independent.
text = replace_once_or_die(
    text,
    '''\t\tcase W_RAY:
\t\tcase W_PORTER:
\t\t\tweapon_damage = 1000;
\t\t\tbreak;''',
    '''\t\tcase W_CUSTOM1:
\t\t\tweapon_damage = 0;
\t\t\tbreak;
\t\tcase W_RAY:
\t\tcase W_PORTER:
\t\t\tweapon_damage = 1000;
\t\t\tbreak;''',
    "Servant generic damage"
)

# Dedicated timing. 1-round magazine; reload is deliberately slower than
# fire cadence so the weapon cannot be spammed like a ray gun.
delay_anchor = '''\t\tcase W_RAY:
\t\tcase W_PORTER:
\t\t\tif (delaytype == RELOAD)
\t\t\t\treturn 2.75;'''
delay_patch = '''\t\tcase W_CUSTOM1:
\t\t\tif (delaytype == RELOAD)
\t\t\t\treturn 2.40;
\t\t\telse if (delaytype == FIRE)
\t\t\t\treturn 0.60;
\t\t\telse if (delaytype == PUTOUT)
\t\t\t\treturn 0.80;
\t\t\telse if (delaytype == TAKEOUT)
\t\t\t\treturn 0.40;
\t\tcase W_RAY:
\t\tcase W_PORTER:
\t\t\tif (delaytype == RELOAD)
\t\t\t\treturn 2.75;'''
text = replace_once_or_die(text, delay_anchor, delay_patch, "Servant delays")

# Temporary Ray Gun presentation shell.
model_anchor = '''\t\tcase W_RAY:
    \tcase W_PORTER:
\t\t\tif (gorvmodel)
\t\t\t\treturn ("models/weapons/ray/g_ray.mdl");
\t\t\telse
\t\t\t\treturn ("models/weapons/ray/v_ray.mdl");'''
model_patch = '''\t\tcase W_CUSTOM1:
\t\t\tif (gorvmodel)
\t\t\t\treturn ("models/weapons/ray/g_ray.mdl");
\t\t\telse
\t\t\t\treturn ("models/weapons/ray/v_ray.mdl");
\t\tcase W_RAY:
    \tcase W_PORTER:
\t\t\tif (gorvmodel)
\t\t\t\treturn ("models/weapons/ray/g_ray.mdl");
\t\t\telse
\t\t\t\treturn ("models/weapons/ray/v_ray.mdl");'''
text = replace_once_or_die(text, model_anchor, model_patch, "Servant temporary model")

sound_anchor = '''\t\tcase W_RAY:
    \tcase W_PORTER:
\t\t\treturn "sounds/weapons/raygun/shoot.wav";'''
sound_patch = '''\t\tcase W_CUSTOM1:
\t\t\treturn "sounds/weapons/raygun/shoot.wav";
\t\tcase W_RAY:
    \tcase W_PORTER:
\t\t\treturn "sounds/weapons/raygun/shoot.wav";'''
text = replace_once_or_die(text, sound_anchor, sound_patch, "Servant temporary sound")

# Reuse Ray Gun animation frame ranges until a cleared Servant model exists.
frame_anchor = '''    \tcase W_RAY:
    \tcase W_PORTER:
\t\t\tswitch (frametype)'''
frame_patch = '''    \tcase W_CUSTOM1:
    \tcase W_RAY:
    \tcase W_PORTER:
\t\t\tswitch (frametype)'''
text = replace_once_or_die(text, frame_anchor, frame_patch, "Servant animation frames")

# W_CUSTOM2 is a Mystery Box presentation token for Li'l Arnie tactical equipment.
# It is never assigned as a firearm, so only name/model presentation is required.
arnie_name_anchor = '''\t\tcase W_CUSTOM1:
\t\t\tweapon_name = "Apothicon Servant";
\t\t\tbreak;'''
arnie_name_patch = '''\t\tcase W_CUSTOM1:
\t\t\tweapon_name = "Apothicon Servant";
\t\t\tbreak;
\t\tcase W_CUSTOM2:
\t\t\tweapon_name = "Li'l Arnie";
\t\t\tbreak;'''
text = replace_once_or_die(text, arnie_name_anchor, arnie_name_patch, "Arnie box name")

arnie_model_anchor = '''\t\tcase W_CUSTOM1:
\t\t\tif (gorvmodel)
\t\t\t\treturn ("models/weapons/ray/g_ray.mdl");
\t\t\telse
\t\t\t\treturn ("models/weapons/ray/v_ray.mdl");'''
arnie_model_patch = '''\t\tcase W_CUSTOM1:
\t\t\tif (gorvmodel)
\t\t\t\treturn ("models/weapons/ray/g_ray.mdl");
\t\t\telse
\t\t\t\treturn ("models/weapons/ray/v_ray.mdl");
\t\tcase W_CUSTOM2:
\t\t\treturn ("models/weapons/grenade/g_grenade.mdl");'''
text = replace_once_or_die(text, arnie_model_anchor, arnie_model_patch, "Arnie box model")

# Reuse the Ray Gun ADS transform for the placeholder model.
ads_section = text.find("vector GetWeaponADSOfs")
ads_ray = text.find("\t\tcase W_RAY:", ads_section)
if ads_section < 0 or ads_ray < 0:
    raise SystemExit("Servant ADS anchor changed; inspect pinned upstream")
if "\t\tcase W_CUSTOM1:\n\t\tcase W_RAY:" not in text[ads_section:ads_ray + 80]:
    text = text[:ads_ray] + "\t\tcase W_CUSTOM1:\n" + text[ads_ray:]

weapon_stats_qc.write_text(text, encoding="utf-8")

# Divert W_CUSTOM1 away from Ray Gun projectile logic.
weapon_core_qc = root / "source" / "server" / "weapons" / "weapon_core.qc"
text = weapon_core_qc.read_text(encoding="utf-8")
fire_anchor = '''\t\tcase FIRETYPE_RAYBEAM:
\t\t\tW_FireRay();
\t\t\tbreak;'''
fire_patch = '''\t\tcase FIRETYPE_RAYBEAM:
\t\t\tif (self.weapon == W_CUSTOM1)
\t\t\t\tSoE_FireApothiconServant(side);
\t\t\telse
\t\t\t\tW_FireRay();
\t\t\tbreak;'''
text = replace_once_or_die(text, fire_anchor, fire_patch, "Servant fire dispatch")
weapon_core_qc.write_text(text, encoding="utf-8")

# Once built, inject the Servant as an extra Mystery Box candidate. This
# avoids expanding NZ:P's legacy fixed 28-entry .mbox parser.
mbox_qc = root / "source" / "server" / "entities" / "mystery_box.qc"
text = mbox_qc.read_text(encoding="utf-8")
mbox_anchor = '''float(entity user) MBOX_GetRandomBoxWeapon =
{
    float weapon_index = rint((random() * (MAX_BOX_WEAPONS - 1)));'''
mbox_patch = '''float(entity user) MBOX_GetRandomBoxWeapon =
{
    float soe_servant_roll = SoE_MysteryBoxServantOverride(user);
    if (soe_servant_roll != W_NOWEP)
        return soe_servant_roll;

    float soe_arnie_roll = SoE_MysteryBoxArnieOverride(user);
    if (soe_arnie_roll != W_NOWEP)
        return soe_arnie_roll;

    float weapon_index = rint((random() * (MAX_BOX_WEAPONS - 1)));'''
text = replace_once_or_die(text, mbox_anchor, mbox_patch, "Servant mystery-box injection")

arnie_pickup_anchor = '''\t\t\t\tWeapon_GiveWeapon(tempe.boxweapon.weapon, 0, 0, 0);
\t\t\t\tself = tempe;'''
arnie_pickup_patch = '''\t\t\t\tif (tempe.boxweapon.weapon == W_CUSTOM2)
\t\t\t\t\tSoE_GiveLilArnie(self);
\t\t\t\telse
\t\t\t\t\tWeapon_GiveWeapon(tempe.boxweapon.weapon, 0, 0, 0);
\t\t\t\tself = tempe;'''
text = replace_once_or_die(text, arnie_pickup_anchor, arnie_pickup_patch, "Arnie Mystery Box pickup conversion")
mbox_qc.write_text(text, encoding="utf-8")


# Rocket Shield boost uses an unused gameplay impulse. Android/mobile HUD can
# bind its dedicated Shield button to impulse 34 without stealing grenade/melee.
weapon_core_qc = root / "source" / "server" / "weapons" / "weapon_core.qc"
text = weapon_core_qc.read_text(encoding="utf-8")
shield_impulse_anchor = '''\t\tcase 33:
\t\t\tW_PrimeBetty();
\t\t\tbreak;'''
shield_impulse_patch = '''\t\tcase 33:
\t\t\tW_PrimeBetty();
\t\t\tbreak;
\t\tcase 34:
\t\t\tSoE_ShieldBoostInput();
\t\t\tbreak;
\t\tcase 35:
\t\t\tSoE_ArnieThrowInput();
\t\t\tbreak;'''
if "SoE_ShieldBoostInput();" not in text:
    if shield_impulse_anchor not in text:
        raise SystemExit("Shield impulse anchor changed; inspect pinned upstream")
    text = text.replace(shield_impulse_anchor, shield_impulse_patch, 1)
    weapon_core_qc.write_text(text, encoding="utf-8")


# Max Ammo refills Li'l Arnie tactical charges for owners.
powerups_qc = root / "source" / "server" / "entities" / "powerups.qc"
text = powerups_qc.read_text(encoding="utf-8")
arnie_maxammo_anchor = '''\t\t\t// Give Grenades
\t\t\tplayers.primary_grenades = 4;
\t\t\t// Give Betties'''
arnie_maxammo_patch = '''\t\t\t// Give Grenades
\t\t\tplayers.primary_grenades = 4;
\t\t\tSoE_ArnieOnMaxAmmo(players);
\t\t\t// Give Betties'''
if "SoE_ArnieOnMaxAmmo(players);" not in text:
    if arnie_maxammo_anchor not in text:
        raise SystemExit("Arnie Max Ammo anchor changed; inspect pinned upstream")
    text = text.replace(arnie_maxammo_anchor, arnie_maxammo_patch, 1)
    powerups_qc.write_text(text, encoding="utf-8")


# Charge active Ovum statues from normal zombie deaths.
zombie_qc = root / "source" / "server" / "ai" / "zombie_core.qc"
text = zombie_qc.read_text(encoding="utf-8")
sword_soul_anchor = '''\tent.health = 0;
\tent.respawn_iterator = 0;
\tent.skin = 0;
\tRemaining_Zombies = Remaining_Zombies - 1;'''
sword_soul_patch = '''\tent.health = 0;
\tent.respawn_iterator = 0;
\tent.skin = 0;

\tSoE_SwordOnEnemyDeath(ent);

\tRemaining_Zombies = Remaining_Zombies - 1;'''
if "SoE_SwordOnEnemyDeath(ent);" not in text:
    if sword_soul_anchor not in text:
        raise SystemExit("Sword soul hook anchor changed; inspect pinned upstream")
    text = text.replace(sword_soul_anchor, sword_soul_patch, 1)
    zombie_qc.write_text(text, encoding="utf-8")


# Shadows of Evil exposes Pack-a-Punch only after the fifth ritual.
pap_qc = root / "source" / "server" / "entities" / "pack_a_punch.qc"
text = pap_qc.read_text(encoding="utf-8")
pap_touch_anchor = '''void() PAP_Touch =
{
\tif (other.classname != "player" || other.downed || !PlayerIsLooking(other, self) || game_modifier_can_packapunch == false) {
'''
pap_touch_patch = '''void() PAP_Touch =
{
\tif (soe_active && !soe_pap_unlocked) {
\t\tif (other.classname == "player" && !other.downed && PlayerIsLooking(other, self))
\t\t\tcenterprint(other, "Complete the Sacred Place Ritual");
\t\treturn;
\t}

\tif (other.classname != "player" || other.downed || !PlayerIsLooking(other, self) || game_modifier_can_packapunch == false) {
'''
if "Complete the Sacred Place Ritual" not in text:
    if pap_touch_anchor not in text:
        raise SystemExit("Pack-a-Punch SoE gate anchor changed; inspect pinned upstream")
    text = text.replace(pap_touch_anchor, pap_touch_patch, 1)
    pap_qc.write_text(text, encoding="utf-8")


# Shadows of Evil has no global power switch: every perk machine is powered
# by its own Beast-shocked panel.
perk_qc = root / "source" / "server" / "entities" / "perk_a_cola.qc"
text = perk_qc.read_text(encoding="utf-8")

touch_anchor = '''void() touch_perk =
{  
\tif (other.classname != "player" || other.downed || other.isBuying == true || !PlayerIsLooking(other, self))
\t\treturn;
'''
touch_patch = '''void() touch_perk =
{  
\tif (other.classname != "player" || other.downed || other.isBuying == true || !PlayerIsLooking(other, self))
\t\treturn;

\t// Shadows of Evil powers each perk locally in Beast Mode.
\tif (soe_active && !self.soe_perk_powered) {
\t\tuseprint(other, self.useprint_index_4, 0);
\t\treturn;
\t}
'''
if "Shadows of Evil powers each perk locally in Beast Mode." not in text:
    if touch_anchor not in text:
        raise SystemExit("SoE perk touch anchor changed; inspect pinned upstream")
    text = text.replace(touch_anchor, touch_patch, 1)

light_anchor = '''void(entity who) Turn_PerkLight_On =
{
\tif (cvar("sv_magic") == 0)
\t\treturn;
'''
light_patch = '''void(entity who) Turn_PerkLight_On =
{
\tif (cvar("sv_magic") == 0)
\t\treturn;

\tif (soe_active && !who.soe_perk_powered)
\t\treturn;
'''
if "if (soe_active && !who.soe_perk_powered)" not in text:
    if light_anchor not in text:
        raise SystemExit("SoE perk light anchor changed; inspect pinned upstream")
    text = text.replace(light_anchor, light_patch, 1)

perk_qc.write_text(text, encoding="utf-8")

print("Shadows of Evil QuakeC overlay applied")
