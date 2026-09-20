#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-.upstream}"
mkdir -p "$ROOT"

clone_pin () {
  local name="$1" url="$2" sha="$3"
  local dir="$ROOT/$name"
  if [ ! -d "$dir/.git" ]; then
    git clone --filter=blob:none --no-checkout "$url" "$dir"
  fi
  git -C "$dir" fetch --depth=1 origin "$sha"
  git -C "$dir" checkout --detach "$sha"
}

clone_pin nzportable https://github.com/nzp-team/nzportable.git db9dde64a781f1f6c237a81107caea5ec0f58b21
clone_pin quakec https://github.com/nzp-team/quakec.git 04bd544172e16193162277a7c356c827e9653b06
clone_pin vril-engine https://github.com/nzp-team/vril-engine.git fd345000547a1278b45d86c86b2ca130c592a83f

echo "Pinned runtime sources are ready under $ROOT"
echo "Assets are intentionally not auto-fetched into packaging until per-asset rights are audited."
