#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "content" / "shadows_of_evil"

FILES = {
    "manifest": "manifest.json",
    "quest": "quest_graph.json",
    "side": "side_quests.json",
    "audit": "port_audit.json",
    "lore": "lore_collectibles.json",
    "achievements": "achievements.json",
    "districts": "district_fidelity.json",
    "provenance": "provenance.json",
    "enemies": "enemies.json",
    "world": "world_objects.json",
    "beast": "beast_mode.json",
    "buildables": "buildables.json",
    "finale": "finale.json",
    "geometry": "geometry_reconstruction.json",
    "topology": "topology_graph.json",
    "g1": "g1_blockout.json",
    "g2": "g2_canal_blockout.json",
    "g3": "g3_footlight_blockout.json",
}

data = {}
for name, filename in FILES.items():
    path = BASE / filename
    if not path.exists():
        raise SystemExit(f"missing {path}")
    data[name] = json.loads(path.read_text(encoding="utf-8"))

if data["manifest"]["id"] != "soe":
    raise SystemExit("manifest id must be soe")

for name in ("quest", "side", "audit", "lore", "achievements", "districts", "enemies", "world", "beast", "buildables", "finale", "geometry", "topology", "g1", "g2", "g3"):
    if data[name].get("map") != "soe":
        raise SystemExit(f"{name} map id mismatch")

states = data["quest"]["states"]
ids = [state["id"] for state in states]
if len(ids) != len(set(ids)):
    raise SystemExit("duplicate quest state ids")
known = set(ids)
for state in states:
    for req in state.get("requires", []):
        if req not in known:
            raise SystemExit(f"{state['id']} requires unknown state {req}")

required_systems = {
    "Beast Mode",
    "ritual items and four district rituals",
    "Pack-a-Punch portal",
    "Tram and sword-symbol visibility",
    "Apothicon Sword and soul egg",
    "Shadowman main quest",
    "Civil Protector",
    "Rocket Shield / Goddard Apparatus",
    "Apothicon Servant",
    "Fumigator and Harvest Pods",
    "Margwa boss",
}
missing = sorted(required_systems - set(data["manifest"]["systems"]))
if missing:
    raise SystemExit("missing required systems: " + ", ".join(missing))

# Anti-regression counts for details that are easy to accidentally drop.
if data["lore"]["ciphers"]["count"] != 5 or len(data["lore"]["ciphers"]["entries"]) != 5:
    raise SystemExit("Shadows of Evil must track all five ciphers")
if data["lore"]["scrapMural"]["pieceCount"] != 10 or len(data["lore"]["scrapMural"]["pieces"]) != 10:
    raise SystemExit("Shadows of Evil must track all ten scrap-paper placements")
if data["lore"]["telephoneMessages"]["count"] != 12 or len(data["lore"]["telephoneMessages"]["entries"]) != 12:
    raise SystemExit("Shadows of Evil must track all twelve phone/portal messages")
if len(data["achievements"]["challenges"]) != 9:
    raise SystemExit("Shadows of Evil must track all nine map-specific launch achievements")
if len(data["districts"]["districts"]) < 8:
    raise SystemExit("world fidelity inventory lost one or more major map regions")

district_ids = {d["id"] for d in data["districts"]["districts"]}
for expected in {"easy_street", "junction", "canals", "footlight", "waterfront", "rift", "sacred_place", "tram"}:
    if expected not in district_ids:
        raise SystemExit(f"missing district fidelity inventory: {expected}")

enemy_ids = {enemy["id"] for enemy in data["enemies"]["types"]}
for expected in {"zombie", "keeper", "parasite", "insanity_elemental", "margwa", "shadowman"}:
    if expected not in enemy_ids:
        raise SystemExit(f"missing enemy behavior inventory: {expected}")

if len(data["world"]["wallWeapons"]) != 13:
    raise SystemExit("wall-weapon/equipment inventory must retain 13 SoE wall purchases")
if len(data["world"]["gobbleGumMachines"]) != 8:
    raise SystemExit("all eight SoE GobbleGum locations must remain tracked")
if len(data["world"]["riftPortals"]) != 3:
    raise SystemExit("all three district Rift portals must remain tracked")
if "bowie_knife" not in {w["id"] for w in data["world"]["wallWeapons"]}:
    raise SystemExit("Bowie Knife placement was dropped")
if data["beast"]["core"]["normalDurationSeconds"] != 25:
    raise SystemExit("Beast Mode canonical duration changed unexpectedly")
if len(data["finale"]["flagDefense"]["sites"]) != 4 or sum(len(v) for v in data["finale"]["flagDefense"]["sites"].values()) != 8:
    raise SystemExit("all eight flag-defense sites must remain tracked")
if data["finale"]["fourPlayerFinale"]["originalRequiresPlayers"] != 4:
    raise SystemExit("Classic finale must preserve four-player requirement")
if len(data["side"]["sideQuests"]) < 16:
    raise SystemExit("one or more tracked SoE side quests/events disappeared")

mask_quest = next((q for q in data["side"]["sideQuests"] if q["id"] == "margwa_head"), None)
if not mask_quest:
    raise SystemExit("Margwa Mask side quest is missing")
if mask_quest.get("requiredMargwaKills") != 6 or mask_quest.get("targetCount") != 6 or mask_quest.get("maxTramRides") != 2:
    raise SystemExit("Margwa Mask canonical 6-kill / 6-target / 2-ride rules changed")


# Geometry/topology anti-regression.
if data["geometry"].get("strategy") != "clean-room modular reconstruction":
    raise SystemExit("SoE geometry strategy must remain clean-room modular reconstruction")

nodes = {node["id"] for node in data["topology"]["nodes"]}
required_nodes = {
    "spawn_alley", "junction", "canal_lower", "footlight_lower", "waterfront_lower",
    "canal_station", "footlight_station", "waterfront_station", "rift", "sacred_place"
}
if not required_nodes.issubset(nodes):
    raise SystemExit("major Morg City topology node was dropped")

edge_pairs = {(edge["from"], edge["to"]) for edge in data["topology"]["edges"]}
for pair in {
    ("spawn_alley", "junction"),
    ("junction", "canal_gate"),
    ("junction", "footlight_gate"),
    ("junction", "waterfront_gate"),
    ("canal_rift_portal", "rift"),
    ("footlight_rift_portal", "rift"),
    ("waterfront_rift_portal", "rift"),
    ("rift", "sacred_place"),
}:
    if pair not in edge_pairs:
        raise SystemExit(f"major Morg City topology edge was dropped: {pair[0]} -> {pair[1]}")

tram_pairs = {(seg["from"], seg["to"]) for seg in data["topology"]["tramSegments"]}
for pair in {
    ("canal_station", "footlight_station"),
    ("footlight_station", "waterfront_station"),
    ("waterfront_station", "canal_station"),
}:
    if pair not in tram_pairs:
        raise SystemExit(f"tram topology segment missing: {pair[0]} -> {pair[1]}")


# G2 Canal blockout contract.
if data["g2"].get("phase") != "G2" or data["g2"].get("district") != "canals":
    raise SystemExit("Canal G2 blockout metadata changed unexpectedly")
anchors = data["g2"].get("gameplayAnchors", [])
by_name = {a.get("targetname"): a for a in anchors if a.get("targetname")}
for required in {
    "soe_g2_badge_smash", "soe_g2_badge_power", "soe_g2_badge_gate",
    "soe_g2_badge_pickup", "soe_g2_ruby_power", "soe_g2_ruby_ritual",
    "soe_g2_canal_perk_slot", "soe_g2_canal_perk_power"
}:
    if required not in by_name:
        raise SystemExit(f"Canal G2 anchor missing: {required}")
if by_name["soe_g2_badge_gate"].get("soe_required_hits") != 2:
    raise SystemExit("Detective Badge must require exactly two Beast actions")
if by_name["soe_g2_badge_power"].get("target") != "soe_g2_badge_gate" or by_name["soe_g2_badge_power"].get("target2") != "soe_g2_badge_grate":
    raise SystemExit("Canal Badge shock must drive both the counter and physical grate")
if by_name["soe_g2_badge_smash"].get("target") != "soe_g2_badge_gate":
    raise SystemExit("Canal Badge smash must feed the same two-hit counter")
if by_name["soe_g2_badge_pickup"].get("spawnflags") != 1:
    raise SystemExit("Detective Badge must start dormant")
ruby_grapple_z = by_name["soe_g2_ruby_grapple_dest"]["origin"][2]
ruby_ritual_z = by_name["soe_g2_ruby_ritual"]["origin"][2]
ruby_power_z = by_name["soe_g2_ruby_power"]["origin"][2]
if not (ruby_grapple_z > ruby_ritual_z > ruby_power_z):
    raise SystemExit("Ruby Rabbit vertical contract must be grapple top floor -> ritual second floor -> power ground floor")
if set(data["g2"].get("rubyRabbitFloorContract", {})) != {"groundFloor", "secondFloor", "thirdFloor", "sourceStatus"}:
    raise SystemExit("Ruby Rabbit three-floor contract metadata is incomplete")
random_groups = {r["group"]: len(r["candidates"]) for r in data["g2"].get("randomized", [])}
if random_groups != {103: 2, 201: 3, 301: 3}:
    raise SystemExit("Canal randomized spawn groups changed unexpectedly")

# G3 Footlight blockout contract.
if data["g3"].get("phase") != "G3" or data["g3"].get("district") != "footlight":
    raise SystemExit("Footlight G3 blockout metadata changed unexpectedly")
g3_anchors = data["g3"].get("gameplayAnchors", [])
g3_by_name = {a.get("targetname"): a for a in g3_anchors if a.get("targetname")}
for required in {
    "soe_g3_black_lace_grapple", "soe_g3_black_lace_power", "soe_g3_black_lace_ritual",
    "soe_g3_toupee_grapple", "soe_g3_toupee_smash", "soe_g3_toupee_pickup",
    "soe_g3_footlight_perk_slot", "soe_g3_footlight_perk_power", "soe_g3_rift_smash"
}:
    if required not in g3_by_name:
        raise SystemExit(f"Footlight G3 anchor missing: {required}")
if g3_by_name["soe_g3_toupee_pickup"].get("spawnflags") != 1:
    raise SystemExit("Footlight Toupee must start dormant")
if g3_by_name["soe_g3_toupee_smash"].get("target") != "soe_g3_toupee_pickup":
    raise SystemExit("Footlight Toupee smash must enable the dormant pickup")
if g3_by_name["soe_g3_black_lace_power"].get("target") != "soe_g3_black_lace_access":
    raise SystemExit("Black Lace Beast shock must open human access")
g3_random = {r["group"]: len(r["candidates"]) for r in data["g3"].get("randomized", [])}
if g3_random != {202: 3, 302: 3}:
    raise SystemExit("Footlight shield/fuse randomized groups changed unexpectedly")
if data["g3"].get("uncertain", [{}])[0].get("status") != "do_not_invent":
    raise SystemExit("Footlight Fumigator uncertainty guard was removed")

# Runtime coverage anti-regression: documented critical systems must have
# mapper-facing/runtime implementations, not just JSON descriptions.
overlay_dir = ROOT / "overlay" / "quakec" / "source" / "server" / "maps" / "soe"
if not overlay_dir.exists():
    raise SystemExit("SoE QuakeC overlay directory is missing")

qc_files = sorted(overlay_dir.glob("*.qc"))
qc_text = "\n".join(path.read_text(encoding="utf-8") for path in qc_files)

required_runtime_symbols = {
    "soe_beast_pedestal": "Beast pedestal",
    "soe_beast_shock": "Beast shock interaction",
    "soe_beast_smash": "Beast smash interaction",
    "soe_beast_grapple": "Beast grapple interaction",
    "soe_target_counter": "multi-action map target counter",
    "soe_powered_door": "Beast-powered geometry door",
    "soe_ritual_controller": "district ritual controller",
    "soe_ritual_keeper_spawn": "ritual Keeper spawns",
    "soe_gateworm_pedestal": "Sacred Place Gateworm pedestal",
    "soe_final_ritual_altar": "fifth ritual altar",
    "soe_tram_button": "tram purchase/control",
    "soe_rift_portal": "Rift portal",
    "soe_harvest_pod": "Harvest Pod",
    "soe_servant_build_table": "Apothicon Servant build table",
    "soe_civil_fuse": "Civil Protector fuse",
    "soe_civil_fusebox": "Civil Protector Rift fuse box",
    "soe_civil_call_panel": "Civil Protector call panel",
    "soe_shield_part": "Rocket Shield part",
    "soe_shield_build_table": "Rocket Shield build table",
    "soe_sword_glyph": "Sword glyph wall",
    "soe_sword_altar": "Sword/Ovum altar",
    "soe_sword_statue": "Sword soul statue",
    "soe_reborn_keeper": "Arch-Ovum Keeper",
    "soe_reborn_circle": "Arch-Ovum Margwa circle",
    "soe_mainquest_book": "Nero quest book",
    "soe_flag_site": "flag defense site",
    "soe_flag_keeper": "district flag Keeper",
    "soe_flag_shadowman_spawn": "flag-defense Shadowman spawn",
    "soe_shadowman_keeper": "Shadowman Keeper activation",
    "soe_shadowman_capture_table": "Shadowman capture table",
    "soe_finale_beast_torch": "finale Beast torch",
    "soe_finale_station_box": "finale station shock box",
    "soe_finale_train_hit": "finale tram/Gateworm event",
    "soe_finale_keeper": "finale central Keeper",
    "soe_margwa_mask_heart": "Margwa Mask Tram heart target",
    "soe_margwa_mask_spawn": "Margwa Mask pickup spawn",
    "soe_sal_laundry_trigger": "Sal DeLuca laundry grenade trigger",
    "soe_sal_ticket_spawn": "Sal DeLuca ticket spawn",
    "soe_snakeskin_clock": "Snakeskin Boots wooden clock",
    "soe_snakeskin_relay": "Snakeskin Boots clean-audio relay",
    "soe_cold_cash_part": "Cold Hard Cash equipment part",
    "soe_cold_cash_stage": "Cold Hard Cash Burlesque stage interaction",
    "soe_arnie_upgrade_prop": "Lil Arnie upgrade prop",
    "soe_arnie_upgrade_stage": "Lil Arnie Burlesque upgrade stage",
    "soe_round_skip_shadowman": "opening Shadowman round-skip target",
    "soe_icarus_trigger": "post-PaP Icarus flyover trigger",
    "soe_richtofen_jumpscare_target": "scoped ship-window jumpscare target",
    "soe_scrap_piece": "ten-piece scrap mural discovery",
    "soe_cipher": "five cipher discovery/reveal",
    "soe_lore_device": "twelve telephone/portal lore devices",
    "soe_shadowman_sighting": "Shadowman sighting challenge",
    "soe_noir_portrait": "shootable Noir portrait toggle",
    "soe_tripmine_wallbuy": "SoE Trip Mine equipment wallbuy",
    "soe_tripmine_cart": "pastry-cart Trip Mine upgrade target",
}
for symbol, description in required_runtime_symbols.items():
    if symbol not in qc_text:
        raise SystemExit(f"missing runtime coverage: {description} ({symbol})")

if 'mapname == "soe_g1"' not in qc_text:
    raise SystemExit("SoE G1 blockout must activate the Shadows runtime")
if 'mapname == "soe_g2"' not in qc_text:
    raise SystemExit("SoE G2 blockout must activate the Shadows runtime")
if 'mapname == "soe_g3"' not in qc_text:
    raise SystemExit("SoE G3 blockout must activate the Shadows runtime")

patcher = (ROOT / "scripts" / "apply_soe_quakec_overlay.py").read_text(encoding="utf-8")
for hook in {
    "SoE_RitualFrame();",
    "SoE_MainQuestFrame();",
    "SoE_ShadowmanFrame();",
    "SoE_FinaleFrame();",
    "SoE_ProcessSpecialSpawns();",
    "SoE_RandomSpawnFrame();",
    "SoE_ResetSideQuests();",
    "SoE_ArnieOnMaxAmmo(players);",
    "SoE_ArnieThrowInput();",
    "SoE_ArnieOverrideZombieAI()",
    "SoE_ResetArnie();",
    "SoE_ResetMiscSecrets();",
    "Complete the Sacred Place Ritual",
}:
    if hook not in patcher:
        raise SystemExit(f"missing NZ:P integration hook: {hook}")

if data["quest"]["modes"]["portableSolo"]["finaleSynchronizationWindowSeconds"] != 30:
    raise SystemExit("portable finale sync window must match 30-second rail runtime")

quest_by_id = {state["id"]: state for state in states}
if quest_by_id["station_shocks"]["requires"] != ["infinite_margwa_phase"]:
    raise SystemExit("station shocks must precede the tram Gateworm hit")
if quest_by_id["train_gateworm_hit"]["requires"] != ["station_shocks"]:
    raise SystemExit("tram Gateworm hit must require electrified station rails")



for quest_id in ("free_500", "snakeskin_boots", "cold_hard_cash"):
    quest = next((q for q in data["side"]["sideQuests"] if q["id"] == quest_id), None)
    if not quest or not quest.get("runtimeEntities"):
        raise SystemExit(f"{quest_id} must retain runtime entity coverage")


if "immediate retry" not in data["finale"]["flagDefense"]["failRule"]:
    raise SystemExit("flag failure must preserve the immediate Underground retry behavior")
if not data["finale"]["flagDefense"].get("shadowmanBehavior"):
    raise SystemExit("flag defense lost Shadowman harassment behavior")


round_skip = next((q for q in data["side"]["sideQuests"] if q["id"] == "round_skip"), None)
if not round_skip or round_skip.get("hitsPerJump") != 5 or round_skip.get("timeoutSeconds") != 5:
    raise SystemExit("round-skip hit/timeout contract changed")
for quest_id in ("mob_plane_flyover", "richtofen_jumpscare"):
    quest = next((q for q in data["side"]["sideQuests"] if q["id"] == quest_id), None)
    if not quest:
        raise SystemExit(f"missing side quest metadata: {quest_id}")


tripmine = next((q for q in data["side"]["sideQuests"] if q["id"] == "tripmine_upgrade"), None)
if not tripmine or tripmine.get("baseCharges") != 2 or tripmine.get("inputImpulse") != 33:
    raise SystemExit("Trip Mine equipment contract changed")
routes = tripmine.get("routes", {})
if routes.get("helpHolly", {}).get("requiredCartCount") != 4:
    raise SystemExit("Holly route must retain four Devil-O-Donuts carts")
if routes.get("helpDevil", {}).get("requiredCartCount") != 3:
    raise SystemExit("Devil route must retain three Holly's Cream Cakes carts")

# Make sure the project never silently switches to bundling the unfinished binary.
source = data["manifest"]["sourceGeometry"]
if source.get("redistribution") != "do_not_bundle_without_permission":
    raise SystemExit("source geometry redistribution guard was removed")

lock = json.loads((ROOT / "upstreams.lock.json").read_text(encoding="utf-8"))
if len(lock.get("repositories", [])) < 3:
    raise SystemExit("upstream lock file is incomplete")

print(
    "SOE data OK: "
    f"{len(states)} quest states, "
    f"{len(data['side']['sideQuests'])} side quests, "
    f"{data['lore']['ciphers']['count']} ciphers, "
    f"{data['lore']['scrapMural']['pieceCount']} scrap placements, "
    f"{data['lore']['telephoneMessages']['count']} phone/portal messages, "
    f"{len(data['achievements']['challenges'])} challenges, "
    f"{len(data['districts']['districts'])} world regions, "
    f"{len(data['world']['wallWeapons'])} wall purchases"
)
