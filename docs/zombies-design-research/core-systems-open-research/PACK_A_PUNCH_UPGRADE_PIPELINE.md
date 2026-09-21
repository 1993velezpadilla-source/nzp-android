# Pack-a-Punch / Weapon Upgrade Pipeline

## Der Koloss — MIT

This is one of the strongest open-source references.

Observed gameplay contract:
- PaP has explicit busy state
- owner player ID
- weapon identity
- slot
- processing timer
- ready state
- process duration
- ready timeout
- pure helper validates that a delayed network PaP event still matches current owner + weapon
- disconnect cleanup tells peers before state reset so clients do not remain stuck in an “upgrading” presentation

This is exactly the failure mode our engine must prevent.

## IW4x behavior

Public implementation description matches classic lifecycle:
- insert weapon
- wait
- retrieve upgraded weapon
- new camo/effects
- weapon disappears if not retrieved in time

## Upgrade model

Do not encode PaP as “double damage.”

Weapon definitions should support:

```text
UpgradeTier
  displayName
  damage profile
  magazine/reserve
  fire mode
  fire rate
  projectile type
  penetration
  reload behavior
  attachment/alt-fire
  visuals
  audio
```

Der Koloss demonstrates this well: an upgraded pistol can change from hitscan to projectile/splash behavior.

## State machine

```text
IDLE
 -> ACCEPTING
 -> PROCESSING
 -> READY
    -> CLAIMED -> IDLE
    -> TIMEOUT -> DESTROY/RETURN_POLICY -> IDLE
```

Authority owns the machine.

## Upgrade transaction

When accepting weapon:

1. validate PaP unlocked/powered
2. validate machine not busy
3. validate player proximity/LOS
4. validate weapon upgradeability
5. reserve player weapon instance
6. debit points
7. remove/lock weapon from usable inventory
8. create `UpgradeJob`
9. broadcast processing state

Do not debit first and hope later steps succeed.

## UpgradeJob

```text
jobId
machineId
playerId
weaponInstanceId
sourceTier
targetTier
startedAt
readyAt
expiresAt
state
```

All network events include `jobId`.

## Disconnect policy

If owner disconnects while:
- PROCESSING
- READY

the host must choose deterministic policy:
- keep job for reconnect grace period
- return upgraded weapon on next spawn
- drop recoverable claim token
- cancel/refund

Whatever policy we choose, **all peers receive state termination**.

## Multi-tier PaP

A modern system may allow several tiers.

Use:
`targetTier = currentTier + 1`

Each tier may:
- reference authored weapon variant
- apply a generic multiplier table
- combine both

Avoid multiplying already-rounded stats repeatedly. Derive runtime stats from base + tier definition.

## Animation lock

PaP interaction must coordinate:
- hands/viewmodel
- input lock
- weapon switching
- downed state
- death/disconnect

If player goes down during insertion, the job either completed its authoritative accept transaction or it did not.

## Tests

1. two players cannot occupy one machine simultaneously
2. delayed READY packet cannot finish a later job
3. disconnect cleans presentation on every peer
4. timeout destroys/returns exactly one weapon
5. player cannot fire weapon while reserved by PaP
6. point debit and weapon reservation are atomic
7. tier stats derive deterministically
8. reset clears job and presentation
9. join-in-progress receives current machine state
10. PaP visual model never includes first-person arms/hands
