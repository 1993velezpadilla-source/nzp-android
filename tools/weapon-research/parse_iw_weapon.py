#!/usr/bin/env python3
"""Parse classic IW raw weapon key/value text and compare two definitions.

Many IW raw weapon files encode gameplay fields as backslash-delimited
key/value pairs. This utility extracts factual scalar fields into JSON and can
diff a base file against an attachment/variant file.

It does not ship or download proprietary assets.
"""
from __future__ import annotations
import argparse, json, re
from pathlib import Path

INTERESTING={
 "damage","playerDamage","minDamage","minPlayerDamage","maxDamageRange","minDamageRange",
 "fireTime","fireDelay","clipSize","startAmmo","maxAmmo","reloadTime","reloadEmptyTime",
 "reloadAddTime","dropTime","raiseTime","quickDropTime","quickRaiseTime","sprintInTime","sprintOutTime",
 "adsTransInTime","adsTransOutTime","adsZoomFov","adsMoveSpeedScale","moveSpeedScale",
 "adsSpread","hipSpreadStandMin","hipSpreadDuckedMin","hipSpreadProneMin","hipSpreadMax",
 "hipSpreadDuckedMax","hipSpreadProneMax","hipSpreadDecayRate","hipSpreadFireAdd","hipSpreadMoveAdd",
 "adsGunKickPitchMin","adsGunKickPitchMax","adsGunKickYawMin","adsGunKickYawMax",
 "adsGunKickSpeedMax","adsGunKickSpeedDecay","adsGunKickStaticDecay",
 "adsViewKickPitchMin","adsViewKickPitchMax","adsViewKickYawMin","adsViewKickYawMax","adsViewKickCenterSpeed",
 "hipGunKickPitchMin","hipGunKickPitchMax","hipGunKickYawMin","hipGunKickYawMax",
 "hipGunKickSpeedMax","hipGunKickSpeedDecay","hipGunKickStaticDecay",
 "hipViewKickPitchMin","hipViewKickPitchMax","hipViewKickYawMin","hipViewKickYawMax","hipViewKickCenterSpeed",
 "swayMaxAngle","swayLerpSpeed","adsSwayMaxAngle","adsSwayLerpSpeed",
 "penetrateType","penetrateMultiplier","silenced","fireType","weaponClass","projectileSpeed",
 "locHelmet","locHead","locNeck","locTorsoUpper","locTorsoLower"
}

def scalar(v):
    try:
        if re.fullmatch(r"-?\d+",v): return int(v)
        if re.fullmatch(r"-?(?:\d+\.\d*|\d*\.\d+)",v): return float(v)
    except Exception:
        pass
    return v

def parse(path:Path):
    text=path.read_text(encoding="utf-8",errors="replace")
    # Locate backslash key/value stream; split preserves empty values.
    parts=text.split("\\")
    out={}
    for i in range(len(parts)-1):
        key=parts[i].strip().splitlines()[-1].strip()
        if key in INTERESTING:
            out[key]=scalar(parts[i+1].splitlines()[0].strip())
    return out

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("base",type=Path)
    ap.add_argument("variant",type=Path,nargs="?")
    ap.add_argument("--all-fields",action="store_true")
    args=ap.parse_args()
    a=parse(args.base)
    if not args.variant:
        print(json.dumps(a,indent=2,sort_keys=True)); return
    b=parse(args.variant)
    keys=sorted(set(a)|set(b))
    diff={}
    for k in keys:
        if a.get(k)!=b.get(k):
            row={"base":a.get(k),"variant":b.get(k)}
            if isinstance(a.get(k),(int,float)) and isinstance(b.get(k),(int,float)):
                row["delta"]=b[k]-a[k]
                if a[k] != 0: row["percent_delta"]=(b[k]/a[k]-1)*100
            diff[k]=row
    print(json.dumps({"base":str(args.base),"variant":str(args.variant),"changed_fields":diff},indent=2))

if __name__=="__main__":
    main()
