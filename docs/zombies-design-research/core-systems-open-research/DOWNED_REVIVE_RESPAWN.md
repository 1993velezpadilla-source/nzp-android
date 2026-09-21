# Downed / Revive / Bleedout / Respawn

## nZombies Unlimited — MIT

Strong concepts found in `gamemode/revive.lua`:

- explicit networked downed state
- configurable bleedout time
- down timestamp and bleedout deadline
- “promised revive” state
- round/game-over logic delays its check so other systems can promise a revive
- revive hooks/stat tracking

The inspected default bleedout function returns 45 seconds.

The most important concept is **promised revive**:
a player can be technically down but should not trigger game over if an authoritative revive action is already committed.

## Der Koloss — MIT

Useful production details:
- downed UI tracks bleedout
- solo can expose self-revive
- revive interaction has hold time
- a single revive-start message is enough to let clients estimate progress rather than streaming progress every frame
- timeout protects against dropped stop/cancel messages
- horde can become dormant if nobody is currently valid prey
- camera trauma is suppressed while down so effects do not “dump” onto the player when revived
- intermission can recover dead players according to mode rules

## Player lifecycle

Recommended states:

```text
ACTIVE
 -> DOWNED
    -> REVIVING
       -> ACTIVE
    -> BLEEDOUT
       -> DEAD
 -> DEAD
    -> RESPAWN_PENDING
       -> ACTIVE
```

Do not represent this with a handful of booleans.

## DownInstance

```text
downId
playerId
startedAt
bleedoutAt
reviveOwnerId?
reviveStartedAt?
reviveDuration
selfReviveAllowed
state
```

A new down gets a new `downId`.

Every revive packet references it so an old revive event cannot revive a later down.

## Revive reservation

Only one active reviver should own the canonical progress unless mode supports cooperative stacking.

```text
ReviveLease
  downId
  reviverId
  expiresAt
```

Cancel if:
- reviver moves too far
- loses line of sight
- gets downed
- releases interact
- target dies
- disconnect

## Promised revive / game-over check

Game over should be evaluated as:

```text
for every team member:
  active
  OR validDownWithRevivePath
  OR authoritativePromisedRevive
```

Then reevaluate after a short deterministic delay/event flush.

This avoids a frame-order bug where the last standing player goes down on the same tick another revive mechanic activates.

## Bleedout authority

Host/server owns absolute `bleedoutAt`.

Clients display:
`remaining = bleedoutAt - synchronizedTime`

Never decrement independent local timers.

## Self revive

Treat self-revive as a revive source:
- limited charges
- duration
- interrupt policy
- authority validation
- consumes charge at an explicit commit point

## Respawn policy

Separate:
- revive from down
- respawn after full death

Map/mode config decides:
- next-round respawn
- starting weapon
- points
- perk loss
- ammo state
- quest inventory
- persistent key items

Do not reset quest progression when a player respawns unless the quest explicitly says so.

## Zombies targeting downed players

Enemy archetypes need target filters.

Typical:
- normal zombies ignore fully dead
- behavior toward downed players configurable
- if no valid prey remains, horde enters safe dormant/game-over behavior

## Join / disconnect

If reviver disconnects:
- revoke lease
- notify target

If downed player disconnects:
- remove down instance
- reassess game over

If player reconnects:
- restore only if session policy preserves that player slot/state.

## Tests

1. old revive packet cannot revive a newer down
2. two players cannot both finish same revive
3. reviver disconnect releases target
4. promised revive blocks premature game over
5. failed promised revive triggers reevaluation
6. bleedout uses authority time
7. self-revive charge consumed once
8. respawn applies configured inventory/perk policy
9. camera/effects reset cleanly on revive
10. horde prey state changes immediately after revive/death
