# Special-Round Engine Implementation Checklist

## Phase SR-0 — data contracts

- [ ] `EnemyArchetypeRegistry`
- [ ] `SpecialRoundDefinition`
- [ ] `BossDefinition`
- [ ] schedule policy
- [ ] weighted composition
- [ ] count/alive-cap/delay curves
- [ ] reward definition
- [ ] normal-round mutation definition

## Phase SR-1 — generic scheduler

- [ ] first-special range
- [ ] recurring random/fixed interval
- [ ] explicit scripted rounds
- [ ] prerequisites
- [ ] boss/special conflict resolution
- [ ] deferred event
- [ ] deterministic RNG seed
- [ ] save/reset behavior

## Phase SR-2 — round ownership

- [ ] unique round instance ID
- [ ] spawn ticket IDs
- [ ] spawned/alive/dead/pending counters
- [ ] external enemy cannot decrement special counter
- [ ] despawn/replacement transfers ticket safely
- [ ] final reward one-shot token

## Phase SR-3 — spawn domains

- [ ] ground/nav spawns
- [ ] window exterior spawns
- [ ] ground risers
- [ ] air volumes
- [ ] ceiling drops
- [ ] scripted teleport spawns
- [ ] boss spawns
- [ ] per-domain collision validation

## Phase SR-4 — first archetypes

- [ ] Rush Hound
- [ ] Flying Spitter
- [ ] Spider/Crawler
- [ ] Suicide Charger
- [ ] Weakpoint Drone
- [ ] Objective Attacker
- [ ] Thief encounter
- [ ] Heavy Miniboss

## Phase SR-5 — reusable abilities

- [ ] melee
- [ ] leap
- [ ] short teleport
- [ ] projectile
- [ ] splash projectile
- [ ] death explosion
- [ ] gas cloud
- [ ] slow/web
- [ ] armor/weakpoint
- [ ] self-destruct
- [ ] target world objective
- [ ] steal resource
- [ ] summon adds

## Phase SR-6 — presentation

- [ ] intro announcer
- [ ] round-specific fog/grade
- [ ] special HUD label
- [ ] remaining count
- [ ] music/ambience override
- [ ] spawn FX
- [ ] end cue
- [ ] accessibility options for intense flashes/colors

## Phase SR-7 — rewards/challenges

- [ ] guaranteed end reward
- [ ] reachable-ground placement
- [ ] flawless-objective challenge
- [ ] accuracy challenge
- [ ] time challenge
- [ ] no-damage challenge
- [ ] bonus perk/item hook

## Phase SR-8 — multiplayer

- [ ] server chooses special round
- [ ] server chooses composition
- [ ] server owns damage and death
- [ ] clients cannot forge reward
- [ ] join-in-progress receives round definition/state
- [ ] reliable round start/end events
- [ ] snapshots include enemy archetype/state
- [ ] reconnection cannot duplicate enemies/rewards

## Phase SR-9 — Android performance

- [ ] enemy pooling
- [ ] projectile pooling
- [ ] FX pooling
- [ ] LODs
- [ ] animation update tiers
- [ ] staggered AI ticks
- [ ] spatial hash for flyers
- [ ] bounded dynamic lights
- [ ] prewarm special assets during intermission
- [ ] no hot-path allocations

# First acceptance scenarios

### A. Hellhound wave
- scheduled
- all dogs spawn from legal dog locations
- no window deadlock
- final dog gives exactly one reward

### B. Flying bug wave
- 1–4 player scaling
- air alive cap
- ranged attack
- no out-of-world spawn
- final reward lands on reachable ground

### C. Mixed wave
- two+ weighted enemy archetypes
- each belongs to same round instance
- max elite cap holds

### D. Objective wave
- enemies attack objective
- objective damage replicated
- flawless bonus tracked

### E. Boss collision
- boss and special due same round
- priority system selects one
- other event deferred, not lost

# “special-round system ready” gate

Do not call it ready until:

1. 100 simulated rounds run without scheduler deadlock.
2. Random schedule is reproducible from seed.
3. Final reward never duplicates under simultaneous deaths.
4. Spawn ticket counters return to zero after every wave.
5. Flying and ground enemies coexist without shared-nav corruption.
6. Map restart clears every special/boss state.
7. Host/client agree on round type, alive count and rewards.
8. Android stress test holds frame/audio stability at configured max alive cap.
