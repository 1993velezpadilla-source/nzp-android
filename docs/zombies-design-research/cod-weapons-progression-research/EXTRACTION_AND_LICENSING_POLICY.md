# Extraction / Reverse Engineering / Licensing Policy

## Tool license is not asset license

This distinction is mandatory.

### Greyhound
Greyhound source is GPLv3.

Its README explicitly states extracted Call of Duty assets remain property of their respective owners.

Therefore:
- extractor source/tool: GPLv3
- extracted Call of Duty model/sound/texture: not automatically GPL

### COD Mobile extraction scripts
The Willie169 extraction scripts are MPL 2.0.

Output obtained from an Activision/Tencent/Garena game install does not become MPL merely because the extractor is MPL.

## What this repository should store

### Yes
- open-source engine field taxonomies
- our normalized schemas
- derived/observed numeric facts
- public progression rules
- attachment modifier tables with provenance
- hashes and source paths
- source URLs / patch notes / dates
- original import/conversion tooling
- legally reusable assets according to their exact licenses

### No
- full proprietary retail weapon-definition dumps copied wholesale
- ripped Call of Duty gun models
- ripped Call of Duty audio
- proprietary textures/animations
- large decompiled proprietary scripts
- commercial sound libraries whose license forbids raw redistribution

## Research workflow for proprietary game facts

1. Work from a legally obtained game copy, official source, or public reproducible measurement.
2. Extract only technical facts needed for comparison/implementation.
3. Normalize those facts into our schema.
4. Record title, mode, patch/build and source.
5. Avoid copying expressive code/assets when a factual record is sufficient.
6. Implement our own runtime mechanics and use original/licensed replacement art/audio.

## Example clean record

~~~text
weaponId: example_smg
sourceGame: CODM
mode: MP
patch: 2026-09
rpm:
  value: 833
  sourceType: community_reference
  source: ...
~~~

Store the fact and provenance, not the retail package that contained it.

## Asset substitution strategy

For a proprietary reference asset we like:

~~~text
reference intent:
  fast suppressed SMG report with sharp mechanical action

replacement:
  CC0/royalty-free firearm layers
  original mix
  original/CC0 weapon model
~~~

## Folder discipline

Recommended separation:

~~~text
docs/.../cod-weapons-progression-research/
  data/
  source-manifests/

tools/weapon-research/
  importers/
  generators/

assets/
  cc0/
  authored/
  third-party-licensed/
~~~

Do not mix unlicensed extracted franchise content into a folder that later looks safe to ship.

## Commercial future

Keeping this boundary now preserves the option to evolve the engine/maps into an original commercial product later.
