# Weapon Economy / Wall Buys

## nZombies Unlimited — MIT

Its wall-buy entity cleanly distinguishes:

- buying the weapon
- buying ammo if the player already owns it

The inspected implementation uses half the weapon purchase price for ammo refill.

The important design idea is not the exact price — it is the transaction contract.

## Open Zombies — GPLv3

Its older Unity code separates:
- `WallWeapon`
- weapon cost
- ammo cost
- player points

Its hit processing also awards hit points through the Player object.

This supports the same conclusion:
**economy belongs in a centralized transaction system, not inside UI/interactable code.**

## Proposed purchase API

```text
PurchaseRequest
  playerId
  interactableId
  offerId
  expectedRevision
```

```text
PurchaseResult
  accepted
  rejectReason
  pricePaid
  grantedItem
  newBalance
  inventoryRevision
```

Authority validates:
1. player exists/alive/eligible
2. interaction distance
3. line of sight
4. object is enabled
5. offer still exists
6. player has funds
7. inventory can accept result
8. transaction is not a replay

Then debit and grant as one atomic action.

## Wall-buy offers

A wall-buy should expose dynamic offers:

```text
if player lacks weapon:
  BUY_WEAPON

if player owns base weapon:
  BUY_BASE_AMMO

if player owns upgraded weapon:
  BUY_UPGRADED_AMMO
```

Maps/perks/hacker-style mechanics can override:
- price
- upgraded version
- ammo quantity
- temporary discount

without replacing the wall-buy entity.

## Inventory slots

Do not tie interaction logic to “weapon 1 / weapon 2”.

Use:
- primary slots
- special/melee slot
- throwable slots
- perk-added slot capacity

Mule-Kick-style extra-slot behavior then becomes inventory capacity data.

## Ammo model

Per weapon:
- magazine
- reserve
- max reserve
- ammo family
- reload policy

Max Ammo should call an inventory-level refill function, not manually know every gun.

Wall ammo should call:
`RefillWeapon(weaponInstanceId, policy)`

## Pack-a-Punch identity

A PaP weapon should remain the same inventory instance with a new upgrade state, or be atomically swapped while preserving an authoritative lineage ID.

Needed for:
- weapon theft/restoration
- box ownership limits
- PaP retrieval
- disconnect recovery
- stat tracking

## Ownership-limited weapons

IW4x documents limited wonder weapons that only one player can hold.

Implement through:

```text
UniqueItemLease
  itemFamilyId
  holderPlayerId?
  sourceReservation?
```

The Box queries this lease before selecting the item.

Release on:
- valid replacement
- player leaves permanently
- item destroyed/lost according to map rules

Do not infer uniqueness by searching rendered weapon entities.

## Tests

1. simultaneous purchase cannot double-spend points
2. transaction replay is rejected
3. wall ammo detects upgraded/base state correctly
4. extra weapon slot loss has deterministic policy
5. disconnect during purchase cannot lose points without item
6. unique wonder-weapon lease cannot duplicate
7. Max Ammo fills only legal reserves
8. UI hint updates after ownership change
