#!/usr/bin/env python3
"""Cross-check the documented Shadows of Evil quest graph against runtime code."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "content" / "shadows_of_evil"
QC = ROOT / "overlay" / "quakec" / "source" / "server" / "maps" / "soe"

quest = json.loads((BASE / "quest_graph.json").read_text(encoding="utf-8"))
states = quest["states"]
by_id = {state["id"]: state for state in states}

if len(by_id) != len(states):
    raise SystemExit("quest graph contains duplicate state ids")


def require_dependency(state: str, expected: list[str]) -> None:
    got = by_id[state].get("requires", [])
    if got != expected:
        raise SystemExit(f"{state} dependency mismatch: expected {expected}, got {got}")


# The main progression must remain a valid DAG.
visiting: set[str] = set()
visited: set[str] = set()


def visit(state_id: str) -> None:
    if state_id in visited:
        return
    if state_id in visiting:
        raise SystemExit(f"quest graph cycle detected at {state_id}")

    visiting.add(state_id)
    for dependency in by_id[state_id].get("requires", []):
        if dependency not in by_id:
            raise SystemExit(f"{state_id} requires unknown state {dependency}")
        visit(dependency)
    visiting.remove(state_id)
    visited.add(state_id)


for state_id in by_id:
    visit(state_id)


# High-value documented progression edges. Sword-symbol discovery is intentionally
# parallel to the four district rituals, but the Book requires both PaP and
# upgraded/Reborn Swords at runtime.
require_dependency("summoning_key", ["spawn"])
for ritual in ("nero_ritual", "jackie_ritual", "jessica_ritual", "floyd_ritual"):
    require_dependency(ritual, ["summoning_key"])
require_dependency(
    "four_rituals_complete",
    ["nero_ritual", "jackie_ritual", "jessica_ritual", "floyd_ritual"],
)
require_dependency("fifth_ritual", ["four_rituals_complete"])
require_dependency("sword_symbols", ["summoning_key"])
require_dependency("sword_wall", ["sword_symbols"])
require_dependency("apothicon_egg", ["sword_wall"])
require_dependency("apothicon_sword", ["apothicon_egg"])
require_dependency("arch_ovum", ["apothicon_sword"])
require_dependency("reborn_sword", ["arch_ovum"])
require_dependency("book_trigger", ["reborn_sword", "fifth_ritual"])
for flag_state in ("flag_nero", "flag_jackie", "flag_jessica", "flag_floyd"):
    require_dependency(flag_state, ["book_trigger"])
require_dependency(
    "keepers_ready",
    ["flag_nero", "flag_jackie", "flag_jessica", "flag_floyd"],
)
require_dependency("shadowman_boss", ["keepers_ready"])
require_dependency("infinite_margwa_phase", ["shadowman_boss"])
require_dependency("station_shocks", ["infinite_margwa_phase"])
require_dependency("train_gateworm_hit", ["station_shocks"])
require_dependency("keeper_shocks", ["train_gateworm_hit"])
require_dependency("apocalypse_averted", ["keeper_shocks"])

state_qc = (QC / "soe_state.qc").read_text(encoding="utf-8")
ritual_qc = (QC / "soe_rituals.qc").read_text(encoding="utf-8")
entities_qc = (QC / "soe_entities.qc").read_text(encoding="utf-8")
sword_qc = (QC / "soe_sword.qc").read_text(encoding="utf-8")
main_qc = (QC / "soe_mainquest.qc").read_text(encoding="utf-8")
shadow_qc = (QC / "soe_shadowman.qc").read_text(encoding="utf-8")
finale_qc = (QC / "soe_finale.qc").read_text(encoding="utf-8")
tram_qc = (QC / "soe_tram.qc").read_text(encoding="utf-8")
tram_mover_qc = (QC / "soe_tram_mover.qc").read_text(encoding="utf-8")

runtime_guards = {
    "state initializes rituals": (
        state_qc,
        "soe_quest_stage = SOE_QUEST_RITUALS;",
    ),
    "PaP unlock preserves a more advanced parallel stage": (
        state_qc,
        "if (soe_quest_stage < SOE_QUEST_PAP_OPEN)",
    ),
    "PaP unlock can advance the ritual-only path": (
        state_qc,
        "soe_quest_stage = SOE_QUEST_PAP_OPEN;",
    ),
    "quest reset clears finale subsystem state": (
        state_qc,
        "SoE_ResetFinale();",
    ),
    "quest reset clears Tram subsystem state": (
        state_qc,
        "SoE_ResetTransportState();",
    ),
    "finale start advances stage": (
        state_qc,
        "soe_quest_stage = SOE_QUEST_FINALE;",
    ),
    "quest completion advances stage": (
        state_qc,
        "soe_quest_stage = SOE_QUEST_COMPLETE;",
    ),
    "fifth ritual requires four Gateworms": (
        ritual_qc,
        "soe_gateworm_placed_mask != 15",
    ),
    "four district rituals open integrated Sacred Place access": (
        entities_qc,
        'find(world, targetname, "soe_full_sacred_access")',
    ),
    "SoE zoning gate starts closed": (
        entities_qc,
        "self.state = STATE_BOTTOM;",
    ),
    "SoE zoning gate reports open state": (
        entities_qc,
        "self.state = STATE_TOP;",
    ),
    "SoE zoning gate refreshes active spawns": (
        entities_qc,
        "Zoning_UpdateAllZones(true);",
    ),
    "fifth ritual unlocks Pack-a-Punch": (
        ritual_qc,
        "SoE_UnlockPackAPunch();",
    ),
    "sword wall advances sword stage": (
        sword_qc,
        "soe_quest_stage = SOE_QUEST_SWORDS;",
    ),
    "all active Sword owners gate Reborn completion": (
        sword_qc,
        "SoE_AllActiveSwordOwnersUpgraded()",
    ),
    "Reborn completion advances stage": (
        sword_qc,
        "soe_quest_stage = SOE_QUEST_REBORN_SWORDS;",
    ),
    "Book requires Pack-a-Punch": (
        main_qc,
        "if (soe_book_used || !soe_pap_unlocked)",
    ),
    "Book requires Reborn Sword stage": (
        main_qc,
        "soe_quest_stage < SOE_QUEST_REBORN_SWORDS",
    ),
    "Book starts Flag stage": (
        main_qc,
        "soe_quest_stage = SOE_QUEST_FLAGS;",
    ),
    "successful flag delivery blocks another district that round": (
        main_qc,
        "if (soe_flag_last_completed_round == rounds)",
    ),
    "flag failure returns immediately to the Rift": (
        main_qc,
        "SoE_SpawnQuestFlagAtRift();",
    ),
    "all district Flags start Shadowman": (
        main_qc,
        "soe_flag_completed_district_mask == 15",
    ),
    "Flags advance Shadowman stage": (
        main_qc,
        "soe_quest_stage = SOE_QUEST_SHADOWMAN;",
    ),
    "Shadowman capture requires Summoning Key": (
        shadow_qc,
        "!soe_has_summoning_key",
    ),
    "Shadowman capture starts finale": (
        shadow_qc,
        "SoE_StartFinale();",
    ),
    "classic finale requires four players unless portable override": (
        shadow_qc,
        'SoE_PlayerCount() >= 4 || cvar("soe_solo_finale") != 0',
    ),
    "finale converts surviving Margwas to purple": (
        finale_qc,
        "zombie.soe_margwa_purple = true;",
    ),
    "finale clears normal zombies through NZP death cleanup": (
        finale_qc,
        "Zombie_Death_Cleanup(zombie);",
    ),
    "finale immediately returns cleared zombies to the pool": (
        finale_qc,
        "removeZombie();",
    ),
    "finale population transition runs before combat freeze": (
        finale_qc,
        "SoE_FinaleTransitionPopulation();",
    ),
    "finale rail timeout recovery uses one reset path": (
        finale_qc,
        "SoE_FinaleResetRailCycle();",
    ),
    "finale Gateworm Tram hit is idempotent": (
        finale_qc,
        "!soe_finale_gateworm_present",
    ),
    "finale corruption can arm while a player is downed": (
        finale_qc,
        "!player.is_spectator && !player.soe_finale_corrupted",
    ),
    "finale downed corruption remains armed until cleanse or revive": (
        finale_qc,
        "} else if (!player.downed) {",
    ),
    "all finale corruption cleanup routes through the shared reset helper": (
        finale_qc,
        "SoE_FinaleClearPlayerCorruption(other);",
    ),
    "finale reset clears per-player corruption state": (
        finale_qc,
        "SoE_FinaleClearPlayerCorruption(player);",
    ),
    "finale exposes a corruption reset for full bleed-out respawn": (
        finale_qc,
        "SoE_FinaleClearPlayerCorruption",
    ),
    "Tram clears stale infection before spectator respawn": (
        tram_qc,
        "SoE_FinaleClearPlayerCorruption(who);",
    ),
    "finale corruption minimum cadence is 30 seconds": (
        finale_qc,
        "#define SOE_FINALE_CORRUPTION_MIN_SECONDS 30",
    ),
    "finale corruption maximum cadence is 45 seconds": (
        finale_qc,
        "#define SOE_FINALE_CORRUPTION_MAX_SECONDS 45",
    ),
    "finale corruption cleanse deadline is 15 seconds": (
        finale_qc,
        "#define SOE_FINALE_CLEANSE_DEADLINE_SECONDS 15",
    ),
    "finale corruption drains 40 Beast meter": (
        finale_qc,
        "#define SOE_FINALE_BEAST_CORRUPTION_DRAIN 40",
    ),
    "duplicate station shocks cannot refresh the rail window": (
        finale_qc,
        "if (soe_finale_station_mask & station_bit)",
    ),
    "rail coordination timer starts only once per cycle": (
        finale_qc,
        "if (soe_finale_rail_window_until <= time)",
    ),
    "station shocks require moving Tram in classic": (
        finale_qc,
        "!soe_tram_in_transit && cvar(\"soe_solo_finale\") == 0",
    ),
    "Tram arrival ignores stale callbacks": (
        tram_qc,
        "if (!soe_tram_in_transit)\n        return;",
    ),
    "Tram arrival rejects destination mismatch": (
        tram_qc,
        "if (soe_tram_destination > 0 && self.style != soe_tram_destination)",
    ),
    "Tram controller ignores duplicate ride starts": (
        tram_qc,
        "if (soe_tram_in_transit)\n        return;",
    ),
    "physical Tram arrival rejects stale callbacks": (
        tram_mover_qc,
        "soe_tram_destination != arrived",
    ),
    "Tram mid-route failure fully stops mover velocity": (
        tram_mover_qc,
        "self.velocity = '0 0 0';",
    ),
    "Tram mover recovers from missing route markers": (
        tram_mover_qc,
        "if (destination == world || hub == world) {",
    ),
    "finale Tram respawn is finale-only": (
        tram_qc,
        "if (!soe_finale_active)",
    ),
    "finale Tram respawns spectator clients": (
        tram_qc,
        'find(world, classname, "spectator")',
    ),
    "finale Tram uses stock NZP player respawn": (
        tram_qc,
        "PlayerSpawn();",
    ),
    "finale Tram call invokes spectator respawn": (
        tram_qc,
        "SoE_TramRespawnFinaleSpectators();",
    ),
    "train hit requires all station shocks": (
        finale_qc,
        "soe_finale_station_mask != 7",
    ),
    "train hit removes Gateworm": (
        finale_qc,
        "soe_finale_gateworm_present = false;",
    ),
    "Keeper shocks require absent Gateworm": (
        finale_qc,
        "if (soe_finale_gateworm_present ||",
    ),
    "duplicate Keeper shocks do not advance finale": (
        finale_qc,
        "if (soe_finale_keeper_mask & keeper_bit)",
    ),
    "all three Keepers finish finale": (
        finale_qc,
        "if (soe_finale_keeper_mask == 7)",
    ),
    "finale completion keeps Gateworm removed": (
        finale_qc,
        "soe_finale_gateworm_present = false;",
    ),
    "finale completion retires rail-cycle state": (
        finale_qc,
        "SoE_FinaleResetRailCycle();",
    ),
    "finale completion retires Gateworm absence timer": (
        finale_qc,
        "soe_finale_gateworm_absent_until = 0;",
    ),
    "finale calls global completion": (
        finale_qc,
        "SoE_CompleteQuest();",
    ),
}

for label, (source, token) in runtime_guards.items():
    if token not in source:
        raise SystemExit(f"missing quest runtime contract: {label}")

transition_call = finale_qc.index("SoE_FinaleTransitionPopulation();")
combat_freeze = finale_qc.index("Remaining_Zombies = 9999;")
if transition_call > combat_freeze:
    raise SystemExit("finale population transition must run before the synthetic combat counter is installed")

tram_clear = tram_qc.index("SoE_FinaleClearPlayerCorruption(who);")
tram_spawn = tram_qc.index("PlayerSpawn();")
if tram_clear > tram_spawn:
    raise SystemExit("Tram respawn must clear stale finale corruption before PlayerSpawn")

# Verify every global quest stage is both defined and used by progression code.
stages = [
    "SOE_QUEST_NONE",
    "SOE_QUEST_RITUALS",
    "SOE_QUEST_PAP_OPEN",
    "SOE_QUEST_SWORDS",
    "SOE_QUEST_REBORN_SWORDS",
    "SOE_QUEST_FLAGS",
    "SOE_QUEST_SHADOWMAN",
    "SOE_QUEST_FINALE",
    "SOE_QUEST_COMPLETE",
]
all_qc = "\n".join([state_qc, ritual_qc, entities_qc, sword_qc, main_qc, shadow_qc, finale_qc, tram_qc, tram_mover_qc])
for stage in stages:
    if stage not in state_qc:
        raise SystemExit(f"quest stage definition missing: {stage}")
    if all_qc.count(stage) < 2 and stage != "SOE_QUEST_NONE":
        raise SystemExit(f"quest stage appears defined but not consumed: {stage}")

print(
    "SOE quest/runtime OK: DAG valid; rituals -> PaP -> Sword/Reborn -> "
    "Book/Flags -> Shadowman -> Tram finale contracts present"
)
