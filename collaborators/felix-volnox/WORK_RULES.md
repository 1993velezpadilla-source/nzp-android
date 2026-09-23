# Workspace Isolation Rules — Felix / Volnox

## Allowed
- Read and audit repository content.
- Reuse project models, rigs, animation research, VFX/effects knowledge, textures/materials, audio, maps, Blender/model-generation pipelines, exporters, tools, scripts, workflows and documentation.
- Invoke existing tools where the active runtime/credential actually permits execution.
- Create collaborator-owned work under `collaborators/felix-volnox/`.
- Commit Felix work only to `collab/felix-volnox-sandbox`.
- Prepare PRs/diffs for owner review.

## Copy/wrap
If an owner file outside the workspace needs modification, copy the needed logic or create a wrapper in Felix's workspace and preserve source-path/commit provenance.

## Not allowed without explicit owner approval
- modify `main` or owner branches
- edit owner project files outside Felix's workspace
- merge PRs
- force-push/rewrite owner history
- delete branches/tags/releases/project assets
- change repository security/access/secrets/release configuration
- move sandbox work into production paths

## Runtime truth
Never claim a tool ran unless execution is actually available. Otherwise prepare the job and mark it `PREPARED_NOT_EXECUTED`.

## Owner gate
The repository owner is the final promotion/merge authority.
