#!/usr/bin/env python3
"""Evaluate reported attachment deltas without pretending unknown source semantics.

For historical CODM research, the source publishes percentage-like changes.
This tool sums those reported deltas per stat so builds can be compared.
It deliberately does NOT convert them into exact final engine values unless
the caller supplies a dataset whose operation semantics are explicitly known.
"""
from __future__ import annotations
import argparse, itertools, json
from pathlib import Path

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--data",type=Path,required=True)
    ap.add_argument("--attachments",nargs="*",default=[])
    ap.add_argument("--enumerate",type=int,metavar="N",help="enumerate all N-attachment builds")
    ap.add_argument("--sort-stat",help="sort enumeration by reported delta for this stat")
    ap.add_argument("--limit",type=int,default=50)
    args=ap.parse_args()
    doc=json.loads(args.data.read_text(encoding="utf-8"))
    items=doc["attachments"]
    by_id={x["id"]:x for x in items}

    def evaluate(chosen):
        totals={}
        for item in chosen:
            for stat,value in item.get("d",{}).items():
                totals[stat]=round(totals.get(stat,0.0)+float(value),6)
        return {
            "attachments":[x["id"] for x in chosen],
            "names":[x["name"] for x in chosen],
            "reported_deltas":totals,
            "unresolved":[{"attachment":x["id"],**x["unresolved"]} for x in chosen if x.get("unresolved")]
        }

    if args.enumerate:
        n=args.enumerate
        builds=[]
        for combo in itertools.combinations(items,n):
            slots=[x["slot"] for x in combo]
            if len(slots)!=len(set(slots)):
                continue
            builds.append(evaluate(combo))
        if args.sort_stat:
            builds.sort(key=lambda b:b["reported_deltas"].get(args.sort_stat,0.0))
        print(json.dumps({
            "count":len(builds),
            "note":"Reported source deltas; not asserted as exact final runtime percentages.",
            "builds":builds[:args.limit] if args.limit>0 else builds
        },indent=2))
        return

    missing=[x for x in args.attachments if x not in by_id]
    if missing:
        raise SystemExit("unknown attachment ids: "+", ".join(missing))
    chosen=[by_id[x] for x in args.attachments]
    slots=[x["slot"] for x in chosen]
    if len(slots)!=len(set(slots)):
        raise SystemExit("invalid build: more than one attachment occupies the same slot")
    print(json.dumps(evaluate(chosen),indent=2))

if __name__=="__main__":
    main()
