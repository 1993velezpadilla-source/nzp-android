# Felix / Volnox Full Toolbox Policy

Felix / Volnox may read, inspect, learn from, invoke when permitted, and reuse the project's technical toolbox while keeping all collaborator-created output isolated in this workspace.

## Reusable project capabilities
- 3D model generation and GLB/FBX/OBJ assets
- character bases, rigs, armatures, measurements
- animation, retargeting, baking and runtime conversion
- Blender modeling, cleanup, UV/materials, rigging, animation, rendering and export
- Hayuya 3D / Hunyuan3D-style image-to-3D generation
- VFX/effects/particles/shaders/lighting
- textures/materials/masks/reference-image workflows
- audio/ambient/sound-effect pipelines
- maps, environments and scene composition
- exporters, build helpers, CI/workflows, runtime/Android validation and optimization
- scripts, research, documentation and future project tools unless explicitly restricted

## Mandatory isolation
Anything Felix creates, modifies, derives, generates, renders, exports, retargets, bakes, converts or downloads for project work must land under:
`collaborators/felix-volnox/`

Suggested destinations:
- `models/`
- `animations/`
- `vfx/`
- `textures/`
- `blender/`
- `audio/`
- `maps/`
- `assets/`
- `tools/`
- `experiments/`
- `research/`
- `audits/`
- `proposals/`
- `handoff/`

## Copy/wrap rule
Owner files outside this workspace are reference/reusable inputs. If a tool or script must be changed, copy the required logic or create a wrapper inside Felix's workspace and record the source path/commit.

## Runtime truth
Repository access is not execution access. Verify the active environment before claiming a tool ran. If unavailable, prepare the job and mark it `PREPARED_NOT_EXECUTED`.

## Secrets / paid services
Never reveal or commit secrets/API keys. Paid/external services must follow the project's authorization/budget rules.

## Promotion
The repository owner remains the final approval/merge gate.
