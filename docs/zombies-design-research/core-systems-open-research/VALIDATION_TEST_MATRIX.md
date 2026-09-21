# Validation / Test Matrix

Der Koloss Community Edition documents **27 headless validators** rather than relying only on manual playtests.

It validates invariants such as:
- control-key collisions
- camera spring stability
- allocation budgets in hot paths
- collision/particle allocation
- coplanar geometry
- spawn sources
- shot occlusion
- weapon model integrity
- host/guest combat agreement
- audio loudness manifest

This is a strong pattern for our portable engine.

## Test classes

### 1. Pure rule tests

No map/render needed.

Test:
- round count/health curves
- special scheduler
- Box Teddy/pity
- PaP state transitions
- powerup cycle
- perk eligibility
- point awards
- revive state
- purchase transactions

### 2. Map preflight tests

Load map data headlessly.

Test:
- IDs/references
- nav connectivity
- spawn legality
- zone/door graph
- quest graph
- required anchors
- collision overlaps

### 3. Deterministic simulation

Run 100+ rounds accelerated.

Assert:
- no hung round
- population conservation
- no stale leases
- bounded entity counts
- scheduler reproducible from seed

### 4. Multiplayer contract tests

Feed malformed/hostile packets.

Assert:
- NaN/Inf rejected
- oversized arrays rejected
- spoofed identity ignored
- duplicate transaction rejected
- client authority escalation rejected

### 5. Host/guest agreement

Simulate latency and snapshots.

Assert:
- same kill result
- same point presentation
- same perk/loadout ownership
- same round number
- no duplicate drops

### 6. Performance invariants

Instrument:
- allocations per audio frame
- allocations per AI tick
- nav path calculations/frame
- projectile pool size
- ragdoll/limb count
- dynamic lights
- draw calls by quality tier

Fail build if bounded paths regress badly.

### 7. Long-session soak

Automated:
- round progression
- open/close every door
- repeated Box spins
- repeated PaP
- down/revive cycles
- powerup overlap
- special/boss collisions
- map restart

Watch:
- memory
- entity count
- leases
- timers
- audio handles
- GPU resources

### 8. Audio validation

Manifest:
- sample peak/RMS/LUFS target band
- missing files
- loop seam metadata
- excessive duration
- duplicate IDs

No single regenerated sound should suddenly be dramatically louder.

### 9. Mobile validation

Test:
- touch controls
- UI safe areas
- app background/foreground
- audio focus
- low-memory recovery
- thermal throttling
- 30/60 FPS tiers
- pause/resume multiplayer handling

## Critical build gates

A release candidate fails if:

- any round stalls in deterministic simulation
- authoritative counters disagree
- duplicate guaranteed reward possible
- invalid packet can mutate state
- map preflight reports broken references
- reset leaves active timers/leases/entities
- hot-path allocation budget regresses beyond threshold
- mobile low tier exceeds configured entity/FX cap

## Debug counters to expose

```text
round
alive
pendingSpawns
activeLeases
activeDrops
activeTimedPowerups
activePaPJobs
activeRevives
questTimers
hazardVolumes
projectiles
ragdolls
pooledFX
navPathsThisFrame
allocBytesThisTick
```

This makes “something feels broken” diagnosable.
