# Free / Commercially Usable Audio Catalog

Goal: build an original sound identity without shipping ripped Call of Duty audio.

## CC0 / easiest to ship

### OpenGameArt — The Free Firearm Sound Library
https://opengameart.org/content/the-free-firearm-sound-library

License: CC0.
Useful raw source for firearm reports and weapon-family layers.

### OpenGameArt — Gunshot Sounds
https://opengameart.org/content/gunshot-sounds

License: CC0.
Includes firearm recordings such as CZ-52, Mosin Nagant, SKS and shotgun material.

### OpenGameArt — Gun Reload Sound Effects
https://opengameart.org/content/gun-reload-sound-effects

License: CC0.
Useful for magazine/round handling layers.

### OpenGameArt — Gun Reload Sounds
https://opengameart.org/content/gun-reload-sounds

License: CC0.
Useful for rifle/pistol/shotgun action layers.

### OpenGameArt — Zombies Sound Pack
https://opengameart.org/content/zombies-sound-pack

License: CC0.
Contains 24 zombie WAV sounds.

### OpenGameArt — Zomby SFX Pack
https://opengameart.org/content/zomby-sfx-pack

License: CC0.

### OpenGameArt — Zombie noises and moans
https://opengameart.org/content/zombie-noises-and-moans

License: CC0.

### OpenGameArt — Footsteps
https://opengameart.org/content/footsteps-0

License: CC0.

### OpenGameArt — Explosions
https://opengameart.org/content/explosions-4

License: CC0.

### OpenGameArt — Residue SFX
https://opengameart.org/content/residue-sfx

License: CC0.
Includes gun/explosion-style material.

### Kenney — Impact Sounds
https://kenney.nl/assets/impact-sounds

License: CC0. Approximately 130 files.
Good for bullet impacts, debris and physical hits.

### Kenney — RPG Audio
https://kenney.nl/assets/rpg-audio

License: CC0.
Useful for footsteps, weapon Foley and generic world interactions.

### Kenney — UI Audio
https://kenney.nl/assets/ui-audio

License: CC0.

### Kenney — Interface Sounds
https://kenney.nl/assets/interface-sounds

License: CC0.

### Kenney — Digital Audio
https://kenney.nl/assets/digital-audio

License: CC0.
Potential layers for traps, powerups and quest machinery.

Kenney's support/license guidance states asset-page content is CC0 and can be used commercially without required attribution.

## Royalty-free for finished games, but do not redistribute raw

### Sonniss #GameAudioGDC
Archive: https://sonniss.com/gameaudiogdc/
Current bundle: https://gdc.sonniss.com/
License: https://sonniss.com/gdc-bundle-license/

The current license permits use and modification in commercial projects without attribution, but does not permit redistributing the sounds as a raw/re-designed standalone sound library, asset pack or SDK.

Repository rule:
- use in a finished game: yes
- edit/layer in a finished game: yes
- commit raw Sonniss bundles to public GitHub: no
- commit filename/source/license metadata: yes

The current 2026 license also contains an AI/ML-training restriction.

## AAA-style gunshot construction

One gunshot should be assembled from semantic layers:

~~~text
weapon shot =
  mechanical transient
  + muzzle crack
  + low-frequency body
  + environment tail
  + distant report
  + optional suppressor layer
~~~

Separate assets for:
- indoor report
- outdoor report
- distant report
- suppressed report
- bolt/action
- magazine
- charging handle
- casing by material
- dry fire

## Non-gun sound categories we need

- zombie vocalizations
- dog/special enemy vocals
- insects/flying enemies
- melee impacts
- blood/gore
- debris/wood/glass/metal
- doors and barricades
- electricity/traps
- fire
- rain/thunder/wind
- footsteps by surface
- cloth/gear movement
- powerup stingers
- perk-machine/quest machinery
- UI
- ambience
- horror drones
- explosions
- vehicle/machinery

## Metadata required for every imported asset

~~~text
id
sourceUrl
originalFilename
creator
license
licenseVersion
downloadDate
commercialUse
redistributionAllowed
attributionText
category
weaponFamily?
duration
sampleRate
channels
editedFrom[]
~~~

Never use a file only because the download page says "free". Record the exact asset-level license.
