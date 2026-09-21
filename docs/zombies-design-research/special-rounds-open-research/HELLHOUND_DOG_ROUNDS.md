# Hellhound / Dog Rounds

## Shared pattern across implementations

Independent Zombies implementations repeatedly converge on the same structure:

1. A special wave is scheduled after several normal rounds.
2. Normal zombie composition is replaced by dogs for that wave.
3. Dogs spawn much closer/faster than ordinary window zombies.
4. Dogs prioritize direct player pursuit instead of barricade destruction.
5. Spawn cadence scales with player count or special-wave index.
6. Special visual/audio cue tells players the rules changed.
7. Last valid dog triggers a guaranteed ammo reward.
8. Later high rounds may inject dogs into normal rounds.

That repeated convergence is useful: it means these are gameplay contracts, not quirks of one codebase.

## NZ:P reference

NZ:P has separate dog spawning/round logic and special-round handling. It is already captured in the NZ:P gameplay-core pack.

Use it as the classic baseline.

## Der Koloss Community Edition — MIT source

Files:
- `js/config.js`
- `js/zombies.js`
- `js/game.js`
- `js/combat-rules.js`

Observed design:

### Schedule
- standard first dog wave anchored around round 5
- subsequent dog wave chosen 5–7 rounds after the previous
- when starting artificially at a later round, the game reanchors the next dog round a few rounds later instead of losing the schedule

### Count
A dedicated `dogCount(round, players)` function returns a player/round-scaled amount with an upper cap.

### Spawn domain
Hounds explicitly skip boarded windows.

The source explains why: a dog spawned outside a barrier it cannot legally traverse can permanently stall. Dog rounds therefore use in-room/ground-riser-style entry/fallback positions.

This is a strong engine lesson:

`EnemyArchetype.canUseWindows = false`

must affect spawn eligibility.

### Prewarm
Hellhound geometry is prewarmed during round transition before the first dog enters.

### Presentation
The implementation swaps:
- fog
- HUD/banner
- announcer/audio
- remaining-hound counter

### Reward
A pure helper checks:
- current round is a dog round
- killed victim is a dog
- dog remaining count is zero
- reward was not already spawned

Then authority marks reward consumed **before** generating the drop.

That is the correct shape for our guaranteed special-round reward gate.

## IW4x Zombies

Useful behavior documented by the project:
- dogs faster than regular zombies
- lower health/damage to compensate
- some dogs burn/explode
- dog-only special waves
- guaranteed Max Ammo after wave
- later normal rounds can substitute a small percentage of ordinary zombies with dogs

This gives us two modes for one archetype:

```text
SPECIAL_ROUND:
  composition = 100% hound

NORMAL_MIX:
  replace ordinary zombie with hound according to chance/cap
```

## BO1 Reimagined

Useful lessons:
- deliberately controls first dog-wave window
- separately tunes recurring dog-wave health
- later mid-round dogs have distinct rules
- fixed a bug where dogs spawned through another system could be killed before the actual dog-round population began and cause early completion

Our solution:
Every enemy carries `roundInstanceId`; only enemies owned by the current special-round instance decrement its completion counter.

## Suggested original dog archetypes

Instead of cloning one exact franchise dog:

### Ember Hound
- rush melee
- short death heat burst
- never uses windows
- spawn telegraph on ground

### Plague Hound
- rush melee
- death gas cloud
- cloud uses pooled area-effect entity
- immunity/weakness tags configurable

### Shock Hound
- leap + close-range electrical disruption
- lower raw damage
- can briefly interfere with traps/electronics if map allows

All can run from the same `RushQuadrupedController`.

## Tests

1. Special wave owns only dogs it spawned.
2. A normal-round injected dog cannot end a dog special wave.
3. Dog never chooses an incompatible window-only spawn.
4. Last dog reward can fire once only.
5. Simultaneous final hits still produce one reward.
6. Late-start/debug round schedules a future dog round correctly.
7. Round reset clears last/next dog schedule.
8. 1–4 player count scaling remains bounded.
9. Hound assets are prewarmed outside combat hot path.
10. Mid-round dog injection respects normal-round alive cap.
