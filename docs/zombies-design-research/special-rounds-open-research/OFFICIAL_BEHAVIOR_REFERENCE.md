# Official Zombies Behavior Reference

This file captures **publicly documented gameplay behavior only**. It is not a source-code or asset import list.

The purpose is to answer:
“What kinds of special rounds have already proven interesting, and what engine capabilities do they require?”

## Hellhound

Pattern:
- recurring replacement special wave
- very fast melee enemies
- distinctive spawn/presentation cue
- guaranteed ammo reward at completion
- in some maps later mixes into ordinary rounds

Engine requirements:
- scheduler
- alternate spawn profile
- melee rush AI
- guaranteed reward gate
- optional normal-round mutation

## Jumping Jack

Pattern:
- replaces dog-style wave on its map
- leaping/short teleport behavior
- limited number alive per player
- guaranteed ammo reward
- **performance challenge** can grant extra reward for perfect accuracy

Engine requirements:
- teleporter/leaper controller
- per-player alive cap
- round-scoped accuracy tracker
- challenge reward independent of normal reward

## Space Monkey

Pattern:
- special enemies prioritize **perk machines/world objectives**
- players must defend owned perks
- flawless defense grants bonus perk reward
- normal completion still produces the standard special-round reward

Engine requirements:
- world-object target priorities
- destructible/protected objective state
- flawless objective tracker
- conditional reward

This is a major design lesson: not every wave should just chase players.

## Pentagon Thief

Pattern:
- one unusual enemy replaces a normal horde
- targets one player/resource at a time
- steals the active weapon rather than simply downing the player
- can escape
- reward depends on whether theft happened

Engine requirements:
- resource stealing transaction
- per-player target sequence
- escape state
- outcome-dependent rewards
- stolen-item restoration

This requires encounter outcomes beyond `allEnemiesKilled`.

## Parasite / flying bug

Pattern:
- true flying ranged special
- fires projectile while maintaining air movement
- swarm-focused
- special visual filter/fog
- guaranteed end reward
- later can appear outside dedicated special waves

Engine requirements:
- air spawn volumes
- air steering
- ranged projectiles
- independent alive cap
- reward-ground resolver

## Insanity Elemental / rolling-suicide archetype

Pattern:
- fast swarm enemy
- enters from unusual spawn method
- aggressively closes distance
- explodes near/contact with player
- can share later special rounds with flying enemies

Engine requirements:
- suicide controller
- proximity fuse
- explosion budget
- mixed-wave composition

## Spider

Pattern:
- dedicated special waves
- fast, small targets
- bite and/or ranged web behavior
- later normal-round mixing

Engine requirements:
- small-body navigation
- optional surface traversal
- web projectile/status
- normal-round mutator

## Valkyrie-style Drone

Pattern:
- flying mechanical special
- dedicated special wave
- destructible components/weakpoint behavior
- damaging arms/components changes final behavior
- can self-destruct/charge
- later mixes with normal enemies
- guaranteed end reward

Engine requirements:
- flying navigation
- damageable parts
- weakpoint state machine
- self-destruct transition
- special-wave + normal-mix support

## Exploding Clown

Pattern:
- fast rush enemy
- spawns close to player
- explodes
- can despawn/recycle if it cannot reach target
- dedicated recurring special wave
- later normal-round appearances

Engine requirements:
- close spawn policy
- unreachable-target watchdog
- despawn/respawn ticket
- explosion safety
- guaranteed reward

## Modern special-round catalog

Public special-round references across the franchise include many families beyond the classic ones, such as:
- hound variants
- Parasites
- Vermin
- spiders
- drones
- tigers
- electrical/jolting variants
- toxic enemies
- tormentor/ravager-style variants
- other map-specific special creatures

We should treat new names as **archetype data**, not reasons to expand RoundDirector.

## General patterns extracted

### 1. Special wave + guaranteed utility reward
Keeps ammunition economy from collapsing after an atypical round.

### 2. Special enemy later joins normal waves
Reuses content and raises late-round complexity.

### 3. Round performance challenge
Accuracy / flawless defense / speed can award bonus.

### 4. Objective special
Enemy attacks map systems instead of players.

### 5. Single-entity encounter
The special “round” can be one thief/boss rather than a horde.

### 6. Mixed special
Two or more complementary enemy families appear together.

These six patterns should all be expressible in our engine without special-case round code.
