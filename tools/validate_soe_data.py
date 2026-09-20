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
}

data = {}
for name, filename in FILES.items():
    path = BASE / filename
    if not path.exists():
        raise SystemExit(f"missing {path}")
    data[name] = json.loads(path.read_text(encoding="utf-8"))

if data["manifest"]["id"] != "soe":
    raise SystemExit("manifest id must be soe")

for name in ("quest", "side", "audit", "lore", "achievements", "districts", "enemies"):
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
    f"{len(data['districts']['districts'])} world regions"
)
