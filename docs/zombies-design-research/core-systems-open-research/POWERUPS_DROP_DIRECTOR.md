# Power-ups / Drop Director

## Strong open-source findings

### nZombies Unlimited — MIT

The power-up system is data-driven.

Observed concepts:
- registered powerups
- droppable vs undroppable
- global vs player-based effects
- timed vs instant
- positive/negative IDs
- start function and end function
- cleanup when player leaves/unspawns
- full cleanup on game over
- drop list rebuilt from enabled powerups
- per-round drop count reset
- simple baseline kill chance: 1 in 50 (2%)
- baseline maximum: 4 random drops per round
- out-of-bounds nav areas are rejected before a drop is created

Built-in examples include:
- Max Ammo
- Carpenter
- Nuke
- Double Points
- Insta-Kill

Double Points is explicitly timed at 30 seconds in the inspected source.

### IW4x Zombies behavior

Its public documentation adds useful production rules:
- ordinary zombies use a general ~2% random drop chance
- drought protection can eventually guarantee a power-up
- zombies outside playable space do not drop one
- zombies dying during climb/jump transitions do not create inaccessible drops
- final special-round reward is relocated to a reachable/default node if its death location is unsafe
- powerup UI positions are dynamic
- supports global/green and personal/blue categories
- Fire Sale unlocks after box has moved at least once

These are excellent rules for our Drop Director.

## Proposed architecture

```text
PowerupDefinition
  id
  scope              // global, player, target-team
  activation         // instant, timed
  defaultDuration
  dropEligible
  rarityWeight
  incompatibilities[]
  onActivate()
  onExpire()
  presentationId
```

```text
DropDirector
  enabledDropPool
  dropsThisRound
  maxRandomDrops
  droughtMeter
  dropCycleState
  activeTimedEffects
  guaranteedRewardQueue
```

## Separate random drops from guaranteed/scripted rewards

Never use the random-drop cap for:
- final dog/special-round Max Ammo
- quest reward
- teleporter reward
- boss reward
- scripted map reward

Use:

```text
DropSource
  RandomKill
  SpecialRoundReward
  QuestReward
  MapInteraction
  BossReward
  Debug
```

Each source can have different cap/cycle rules.

## Drop spawn resolver

A drop must not be instantiated directly at the enemy death transform.

Resolve:

1. requested death position
2. playable-volume check
3. nav/reachability check
4. floor trace
5. hazard exclusion
6. moving-platform policy
7. fallback reward anchor

This covers:
- climbing zombies
- flying enemies
- enemies outside windows
- bosses dying off-navmesh

## Drought protection

Pure random chance can create long dry streaks.

Recommended design:

```text
onEligibleKill:
  droughtMeter += contribution
  chance = baseChance + droughtCurve(droughtMeter)
  if random < chance:
      spawn()
      droughtMeter = resetValue
```

Alternative:
Use a point/damage-based threshold as some classic systems do.

The key is deterministic bounded drought, not a specific copied formula.

## Drop-cycle fairness

Avoid repeatedly giving the same utility drop.

Maintain a shuffle-bag or weighted recent-history penalty.

Example:
- core group: Max Ammo / Nuke / Insta / Double
- don't repeat previous drop unless alternatives exhausted
- scripted drops bypass this cycle

## Timed effect authority

Server/host owns:
- start timestamp
- duration
- expiration
- stacking/extension rule

Client receives:
- effect ID
- authoritative expiry time

No client should extend Double Points by locally refreshing a HUD timer.

## Late join / reconnect

A joining player needs the current active timed effects:
- Insta-Kill
- Double Points
- Fire Sale
- other global buffs

For player-scoped powerups, restore only what the authority says belongs to that player.

## Required tests

1. random drop cap resets exactly once per round
2. guaranteed rewards ignore random cap
3. inaccessible death position resolves to reachable drop
4. simultaneous kills cannot exceed cap
5. active timed effect survives snapshot loss
6. reconnect receives correct remaining duration
7. game-over terminates every timed effect
8. personal effect cannot affect another player
9. drought protection eventually fires within configured bound
10. random cycle cannot deadlock when most drops disabled
