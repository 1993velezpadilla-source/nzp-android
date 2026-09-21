# Audio / Feedback Director

Sound is gameplay in Zombies:
players react to spawn cues, round transitions, dog howls, reloads, nearby enemies, perk jingles and power-up expiration warnings.

## Der Koloss — MIT source

Its public README/source architecture documents:
- room-based convolution/reverb
- geometry-derived occlusion
- cached/throttled occlusion checks
- distance rolloff and air-absorption filtering
- layered weapon shots
- master compression/limiting
- voice/explosion ducking
- concussion ring
- low-health tinnitus/heartbeat
- surface-aware footsteps
- ambience intensity scaling with round/threat
- audio loudness manifest + validator

This is an excellent model for a portable audio layer.

## Audio event contract

Gameplay emits semantic events:

```text
EnemySpawned(type, position)
EnemyDied(type, position)
RoundStarted(type)
PowerupSpawned(id)
PowerupActivated(id)
PowerupExpiring(id)
DoorOpened(id)
TrapActivated(id)
PerkPurchased(id)
PaPStarted
PaPReady
PlayerDowned
PlayerRevived
```

AudioDirector maps these to assets/mix.

Gameplay code should not hard-code file paths.

## AudioBank

```text
AudioCue
  id
  variants[]
  bus
  spatial
  minDistance
  maxDistance
  priority
  cooldown
  concurrencyLimit
```

## Concurrency

Critical for mobile.

Examples:
- max zombie groans nearby
- max impact sounds/frame
- max simultaneous explosions
- old/quiet instances culled first

## Occlusion

Use simplified geometry queries at a throttled rate.

Do not raycast every emitter every audio frame.

Cache by:
- emitter/listener zone
- time
- significant movement threshold

## Room/zone reverb

Zone can specify:
- reverb preset/IR
- ambience
- low-pass behavior
- outdoor flag

Crossfade when player changes zone.

## Threat mix

Audio mix can react to:
- health
- nearby enemy count
- special round
- boss
- downed state

Keep response subtle and bounded.

## Powerup warnings

Timed effects should emit warning cues based on authoritative expiry.

Example:
- 5 seconds remaining -> warning sequence

Client display/audio uses synchronized time.

## Loudness validation

Generate a manifest containing:
- file duration
- peak
- RMS/LUFS approximation
- loop metadata

CI fails obvious outliers.

This prevents one replacement asset from being dramatically louder than the rest.

## Tests

1. missing cue falls back safely
2. concurrency cap bounded in 100-zombie stress
3. occlusion query budget bounded
4. zone reverb crossfade never allocates in audio callback
5. expiry warning synchronized with gameplay timer
6. game reset stops all looping special cues
7. low-health mix clears immediately after revive
8. loudness manifest catches extreme outlier
