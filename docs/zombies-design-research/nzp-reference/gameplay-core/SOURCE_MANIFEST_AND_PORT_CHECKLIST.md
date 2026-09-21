# Source Manifest + Port Checklist

## Source snapshot inspected

### nzp-team/quakec

Relevant current blobs inspected during extraction:

- `source/server/entities/window.qc` — blob `95d0d38d68c2dc3086ee81dab5e8b3358686af95`
- `source/server/rounds.qc` — blob `a60c948a7cd0a387c0ca46eddc22b95567c0de3d`
- `source/server/player/player_core.qc` — blob `4094f687a55cd98b631822ec9b631951e44332e5`
- `source/server/damage.qc` — blob `97deafb9770af3b549a428008634ed4ae044ab0c`
- `source/server/ai/zombie_core.qc` — blob `69bff4c1a1bbf09274d8306c36826e652139b2a5`
- `source/server/ai/ai_core.qc` — blob `59d62ef41eeb89ce5d6b88ac21ac98b17a18eecc`
- `source/server/ai/zoning_core.qc` — blob `3943084f4efb584557e438d4575385471f65f017`
- `source/server/entities/powerups.qc` — blob `39ae62f790dbdc1746130117185fe59f8b025870`
- `source/server/gamemodes/core.qc` — blob `a0a98267f8cfadeb063045ef6fc46e41e8362e70`
- `source/server/entities/triggers.qc` — inspected from upstream main
- `source/server/defs/custom.qc`
- `source/shared/shared_defs.qc`

Code license file inspected:
- `LICENSE` — GNU GPL Version 2 text
- license blob: `bf963773fa83cbdd98cf0739194594cb38f08f9e`

### nzp-team/assets

Mapper definition inspected:
- `source/maps/fgd/hl-nzp.fgd` — blob `a19cbf414c3238773a2b80a764288cc24b15341d`
- `source/maps/fgd/tb-nzp.fgd`
- `source/maps/template.map`
- production map sources found using `item_barricade` and `spawn_zombie`

Assets license inspected:
- `LICENSE.md` — CC BY-SA 4.0
- license blob: `a39d2f5a8794696e1ae0a75c77d47584c5b405ac`

## Important licensing rule

This reference pack describes behavior and source provenance.

If we directly copy/modify GPL QuakeC code into a distributed derivative, GPL obligations apply to that derivative/code path. Asset/map material is governed separately by CC BY-SA 4.0 and requires attribution/share-alike where applicable.

Keep provenance metadata attached to any imported asset or direct code port.

## Core implementation checklist

### RoundDirector
- [ ] round state machine
- [ ] normal/special round type
- [ ] total/remaining/alive/unspawned counters
- [ ] count formula policy
- [ ] health formula policy
- [ ] spawn cadence
- [ ] round transition timer/audio hooks
- [ ] round-end trigger event
- [ ] mode override hooks

### SpawnDirector
- [ ] active spawn container
- [ ] zone-aware enable/disable
- [ ] safe random/weighted selection
- [ ] max alive budget
- [ ] spawn style flags
- [ ] nav/collision validation
- [ ] deterministic server authority
- [ ] debug visualization toggle

### BarricadeController
- [ ] current/max boards
- [ ] destroy transition
- [ ] rebuild transition
- [ ] player use interaction
- [ ] per-player rebuild reward cap
- [ ] 3 zombie reservations + wait queue
- [ ] crossing landing point
- [ ] Speed Cola repair modifier
- [ ] Carpenter repair integration
- [ ] state replication

### ZombieController
- [ ] spawn/rise/inside initialization
- [ ] exterior path
- [ ] window target acquisition
- [ ] reservation acquire/release
- [ ] board attack
- [ ] crossing
- [ ] interior target chase
- [ ] player attack
- [ ] death cleanup
- [ ] crawler/special state compatibility

### ScoreService
- [ ] single score mutation authority
- [ ] wallet/lifetime/drop-progress split
- [ ] damage points
- [ ] kill points by type
- [ ] Double Points eligibility
- [ ] rebuild score cap
- [ ] Carpenter reward
- [ ] purchases/refunds
- [ ] network anti-cheat validation
- [ ] event feed for HUD/analytics

### MapEntityLayer
- [ ] spawn entity schema
- [ ] window schema
- [ ] path graph
- [ ] zones
- [ ] doors as zone edges
- [ ] trigger interactions
- [ ] activation groups
- [ ] load-time validation report

## “Ready for first custom map” gate

Do not declare the engine ready for the first custom Zombies map until all of these pass:

1. A test room can run 20 consecutive rounds without spawn deadlock.
2. Zombies correctly use at least two different windows.
3. Four+ zombies queue at one window without overlap or permanent stall.
4. Players can destroy/rebuild the same window loop repeatedly.
5. Points remain correct across hit/kill/rebuild/purchase/Double Points.
6. Door opening changes active zombie spawn zones.
7. Save/restart/map reload clears all window reservations and round state.
8. Host/client multiplayer produces identical authoritative score/round/window state.
9. Android touch interaction can rebuild/open/buy without duplicate use events.
10. No per-frame heap churn is introduced by spawning or barricade queues.
11. Debug overlays can show zones, spawn points, window reservations and active AI goals.
12. All imported direct source/assets retain correct provenance/license records.

Once this gate is green, the engine has the gameplay foundation needed to begin authoring the first Nacht-sized original map without faking core Zombies behavior.
