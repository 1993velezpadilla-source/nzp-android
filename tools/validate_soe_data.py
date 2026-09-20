#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "content" / "shadows_of_evil"
paths = {n: BASE / f for n, f in {
    "manifest":"manifest.json","quest":"quest_graph.json","side":"side_quests.json","audit":"port_audit.json"
}.items()}
data={}
for name,path in paths.items():
    if not path.exists():
        raise SystemExit(f"missing {path}")
    data[name]=json.loads(path.read_text(encoding="utf-8"))
if data["manifest"]["id"]!="soe" or data["quest"]["map"]!="soe" or data["side"]["map"]!="soe":
    raise SystemExit("SOE map id mismatch")
ids=[s["id"] for s in data["quest"]["states"]]
if len(ids)!=len(set(ids)):
    raise SystemExit("duplicate quest state ids")
known=set(ids)
for state in data["quest"]["states"]:
    for req in state.get("requires",[]):
        if req not in known:
            raise SystemExit(f"{state['id']} requires unknown state {req}")
required={"Beast Mode","ritual items and four district rituals","Pack-a-Punch portal","Tram and sword-symbol visibility","Apothicon Sword and soul egg","Shadowman main quest","Civil Protector","Rocket Shield / Goddard Apparatus","Apothicon Servant","Fumigator and Harvest Pods","Margwa boss"}
missing=sorted(required-set(data["manifest"]["systems"]))
if missing:
    raise SystemExit("missing required systems: "+", ".join(missing))
print(f"SOE data OK: {len(ids)} quest states, {len(data['side']['sideQuests'])} side quests")
