# Interaction System

Everything from doors to revive to PaP depends on one reliable interaction layer.

## Open-source lesson

Der Koloss has a pure interaction line-clear test and explicit per-action hold durations.

nZombies/Open Zombies use interactable entities with economy/prerequisite checks.

Our engine should centralize this.

## Interactable contract

```text
Interactable
  id
  enabled
  prompt
  range
  holdDuration
  lineOfSightRequired
  prerequisites[]
  offers/actions[]
```

Examples:
- open door
- buy weapon
- buy ammo
- buy perk
- spin box
- take box weapon
- insert/take PaP weapon
- revive
- repair board
- activate trap
- pick quest item
- build part
- press quest button

## Request flow

Client sends:
```text
InteractRequest
  requestId
  targetId
  actionId
  clientStartedAt?
```

Authority validates:
- player/session identity
- player state
- distance
- LOS
- target enabled
- prerequisites
- cooldown
- economy/inventory
- current target revision

## Hold interactions

Authority should own completion.

Client can render predicted progress, but completion occurs only when:
- authority start accepted
- hold duration elapsed
- requirements remained true

Cancel if:
- moved out of range
- LOS broken
- downed/dead
- target disabled
- release input if required

## Prompt priority

Multiple nearby interactions need deterministic ranking.

Suggested:
1. revive teammate
2. quest-critical interact
3. weapon/item pickup
4. machine/box
5. door/trap
6. repair board

Then by:
- screen-center angle
- distance

Never rely on unordered entity iteration.

## Revisioning

Dynamic interactables need `revision`.

Example:
A Box result changes from CYCLING to READY.
An old client request targeting the prior revision is rejected rather than interpreted against the new state.

## Cost presentation

UI may display price, but server calculates final price.

Discounts/hacks/perks are authority-side.

## Accessibility

Support:
- tap vs hold option where gameplay allows
- larger prompt text
- color-independent state cues
- touch-safe interaction button
- optional auto-repair hold behavior

## Tests

1. interaction through wall rejected
2. exact range boundary deterministic
3. old revision cannot trigger new state
4. two players cannot consume one quest item
5. simultaneous door purchase debits once
6. revive priority beats nearby wall buy
7. hold cancels when target disabled
8. mobile tap/hold maps to same authority contract
