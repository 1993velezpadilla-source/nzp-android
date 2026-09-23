# Hayuya 3D / Hunyuan3D Workflow — Felix / Volnox

Within this project, **Hayuya 3D** means the Hunyuan3D-style image-to-3D workflow for producing a usable 3D asset, normally ending in GLB plus previews/validation.

Requests like "usa Hayuya", "haz este modelo con Hayuya 3D", "pasa esta imagen a 3D", or "haz el GLB" should use this workflow when an executable compatible runtime is available.

## Before generation
Verify that the active session really has an executable image-to-3D runtime. If not, do not pretend generation is running. Prepare the source images, prompts/config, dimensions/manifests and expected output paths and mark the job `PREPARED_NOT_EXECUTED`.

## Output structure
Use:
`collaborators/felix-volnox/models/hayuya/<asset-name>/`

Recommended:
- `source/`
- `raw/`
- `processed/`
- `textures/`
- `previews/`
- `measurements.json`
- `PROVENANCE.md`
- `STATUS.md`

## Blender finishing
When Blender execution is actually available, it may be used for scale normalization, cleanup, normals, UV/material repair, texture hookup, LOD/decimation, rigging, animation retarget/bake, pivots, collision/helper geometry, GLB export and review renders.

Blender sources/derived scripts stay under `collaborators/felix-volnox/blender/` or inside the asset package.

## Validation
Before calling an asset done, verify GLB import/open, scale, orientation, textures, silhouette/completeness, runtime usability, provenance and previews. Animated characters also require skeleton/armature and clip/retarget/bake status checks.
