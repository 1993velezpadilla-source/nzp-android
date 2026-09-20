# NZ:P / QuakeC port map

Pinned QuakeC: `04bd544172e16193162277a7c356c827e9653b06`

## Reuse existing upstream systems
- Pack-a-Punch: `source/server/entities/pack_a_punch.qc`
- Perk machines: `source/server/entities/perk_a_cola.qc`
- Mystery Box: `source/server/entities/mystery_box.qc` and per-map `.mb2`
- Electric traps: `source/server/entities/traps.qc`
- Teleporters: `source/server/entities/teleporter.qc`
- Doors / waypoint opening: `source/server/entities/doors.qc`
- Zombie waypoint system: `source/server/ai/*/waypoints_*.qc`
- Boss-style AI reference: `source/server/ai/dog_core.qc`
- Round scheduler: `source/server/rounds.qc`

## New SoE modules
- `soe_state.qc`: quest state/reset.
- `soe_beast.qc`: transform, timer, grapple, shock/melee, finale.
- `soe_rituals.qc`: ritual inventory/arenas/Gateworms.
- `soe_tram.qc`: moving tram and glyph callbacks.
- `soe_sword.qc`: glyph puzzle, egg/statues, Arch-Ovum.
- `soe_margwa.qc`: three-head vulnerability, slam, drops.
- `soe_apothicon.qc`: Harvest Pods and Servant build.
- `soe_mainquest.qc`: book, flags, Shadowman, finale.
- `soe_sidequests.qc`: optional quests.
- `soe_civilprotector.qc`: fuses, panels, ally/revive.
- `soe_fx.qc`: ritual/portal/sky/mist states.

## Mobile constraints
- Bound particles by graphics preset.
- Baked/static lighting for normal city dressing; dynamic lights for ritual/portal/Beast events.
- Background skyline non-solid and aggressively culled.
- LOD props/zombies before reducing collision fidelity.
- Gameplay collision identical across presets.


## Android input bindings carried by the SoE overlay
- `impulse 34`: Rocket Shield boost. Requires its own shield action/button when the player has a shield.
- `impulse 35`: Li'l Arnie tactical throw. **Requires a dedicated Li'l Arnie HUD button**, not a weapon slot or generic grenade toggle.
- Both controls must participate in Custom HUD move/scale/opacity editing and expose current per-player state to the HUD.


### SoE secondary equipment presentation
- Trip Mine uses the existing secondary-equipment slot/count and `impulse 33` on Shadows of Evil.
- Android must swap the old Betty icon/name to **Trip Mine** whenever `soe_active && player.soe_has_tripmines`.
- Do not create a second Trip Mine button; the standard secondary-equipment control is reused.
