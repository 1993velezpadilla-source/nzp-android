# Points / Economy

Primary upstream references:

- `source/server/player/player_core.qc`
- `source/server/damage.qc`
- `source/server/entities/window.qc`
- `source/server/entities/powerups.qc`
- `source/server/entities/triggers.qc`

## One score authority

NZ:P funnels score changes through a central `Player_ChangeScore` path and thin add/remove wrappers.

That design is worth preserving.

Our engine should expose only:

- `AddPoints(player, amount, flags)`
- `RemovePoints(player, amount, reason)`
- `CanAfford(player, cost)`

No weapon, door, perk, trap, quest, or map trigger should directly mutate the player's point field.

## Starting points

Upstream constants:

- normal start: **500**
- late/high-round start: **1500** when joining/spawning after the early rounds threshold used by NZ:P

Treat join-in-progress starting economy as a separate policy from normal game start.

## Double Points

NZ:P's central score function doubles a positive score award only when the caller marks that award as eligible and Double Points is active.

Upstream Double Points duration: **30 s**.

This is important: purchase refunds, score restoration, or internal accounting can bypass Double Points.

Use score flags such as:

- `AffectedByDoublePoints`
- `CountsTowardPowerupThreshold`
- `CountsTowardEndgameScore`
- `MiscScore`
- `Refund`

## Damage points

Normal non-lethal damage to a zombie awards **10 points** when eligible.

That happens before health is reduced and only while the zombie survives the hit.

Mode callbacks can modify/suppress this value.

## Kill points

Upstream base kill awards:

- headshot: **100**
- melee: **130**
- upper torso: **60**
- lower torso: **50**
- grenade: **50**
- explosive weapon: **60**
- Tesla/electric special path: generally **50**
- PhD Flopper: **50**

A harder difficulty path reduces kill score to roughly 75%, rounded down to a 10-point step.

Then the gamemode callback can modify/suppress the award.

## Barrier rebuild

- **10 points per repaired board**
- eligible for Double Points
- only while miscellaneous scoring is enabled
- per-player round cap:
  - `min(50 * round, 500)`

Physical rebuild must remain possible after the score cap is exhausted.

## Carpenter

Carpenter completion awards **200 points to each player**, through the same central score path, and is Double-Points-eligible in the upstream implementation.

It also repairs windows separately from this reward.

## Purchases

Upstream purchase systems call score removal rather than directly subtracting points. Examples include:

- doors
- wall weapons/ammo
- perks
- mystery box
- Pack-a-Punch
- traps
- teleporter
- generic `trigger_interact`

Generic interaction flow:

1. Calculate cost (including modifier/multiplier).
2. Show interaction text and cost.
3. On use, reject if player lacks points.
4. Play deny feedback if unaffordable.
5. Remove points.
6. Fire the entity's target/action.
7. Disable/re-arm interaction according to entity rules.

## Downed-player rule

The upstream score service refuses to mutate points while a player is in Last Stand/downed state.

Whether we keep that exact behavior is a design choice, but it must be **centralized and explicit** rather than scattered through purchase code.

## Power-up threshold coupling

Positive point awards also feed a global power-up score threshold/accounting value in NZ:P.

That means score is used both as player currency and as an input to drop pacing.

For our engine, split these concepts internally:

- `walletPoints`
- `lifetimeScore`
- `powerupProgress`

Then define which score event increments which counters.

This prevents refunds or quest grants from accidentally manipulating drop rates.

## Event model recommended for our engine

Every score mutation should emit:

`ScoreEvent { player, delta, source, damageType, flags, worldPosition, timestamp }`

Sources should include:

- hit
- kill
- headshot
- melee
- rebuild
- carpenter
- nuke
- quest
- purchase
- refund
- revive
- script/map trigger

This makes HUD feedback, analytics, balancing and anti-cheat much easier.

## Tests

1. 500 starting points on standard game start.
2. Non-lethal eligible hit grants 10.
3. Kill reward matches damage/kill type.
4. Hit + kill awards stack exactly once.
5. Double Points doubles eligible awards only.
6. Purchase removal is never doubled.
7. Insufficient points blocks purchase atomically.
8. Rebuild reward cap resets according to round policy.
9. Carpenter rewards all valid players.
10. Downed-player policy is deterministic.
11. Refund does not increase power-up progress unless explicitly intended.
12. Server rejects client-forged score mutations.
