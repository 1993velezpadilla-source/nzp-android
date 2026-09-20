/*
    Shadows of Evil - Rift first-entry guard encounter.

    The three district portals converge on the underground subway. The first
    human arrival creates a short Keeper encounter. This is separate from
    ritual Keepers so it cannot mutate ritual ownership/progression.
*/

float soe_rift_first_entry_fired;
.float soe_rift_guard_next_attack;

void(entity victim, entity attacker, float damage, float d_style) DamageHandler;

entity(entity seeker) SoE_RiftGuardFindPlayer =
{
    entity player = find(world, classname, "player");
    entity best = world;
    float best_distance = 999999;

    while (player != world) {
        if (!player.downed && !player.is_spectator && !player.soe_beast_active) {
            float distance = vlen(player.origin - seeker.origin);
            if (distance < best_distance) {
                best_distance = distance;
                best = player;
            }
        }

        player = find(player, classname, "player");
    }

    return best;
};

void() SoE_RiftGuardThink =
{
    if (!soe_active) {
        remove(self);
        return;
    }

    if (self.enemy == world || self.enemy.downed || self.enemy.is_spectator ||
        self.enemy.soe_beast_active)
        self.enemy = SoE_RiftGuardFindPlayer(self);

    if (self.enemy == world) {
        self.velocity = '0 0 0';
        self.nextthink = time + 0.1;
        return;
    }

    vector delta = self.enemy.origin - self.origin;
    vector planar = delta;
    planar_z = 0;
    float distance = vlen(planar);

    self.angles_y = vectoyaw(planar);

    if (distance > 54) {
        vector direction = normalize(planar);
        self.velocity_x = direction_x * 185;
        self.velocity_y = direction_y * 185;
    } else {
        self.velocity_x = 0;
        self.velocity_y = 0;

        if (self.soe_rift_guard_next_attack <= time) {
            DamageHandler(self.enemy, self, 30, DMG_TYPE_ZOMBIESWIPE);
            self.soe_rift_guard_next_attack = time + 0.9;
        }
    }

    self.nextthink = time + 0.05;
};

entity(vector org) SoE_SpawnRiftGuard =
{
    entity keeper = spawn();
    keeper.classname = "soe_keeper";
    keeper.soe_special_type = SOE_SPECIAL_KEEPER;
    keeper.movetype = MOVETYPE_STEP;
    keeper.solid = SOLID_SLIDEBOX;
    keeper.takedamage = DAMAGE_YES;
    keeper.flags = keeper.flags | FL_MONSTER;
    keeper.effects = EF_FULLBRIGHT;
    keeper.health = 180 + (rounds * 10);
    if (keeper.health > 520)
        keeper.health = 520;

    // Clean placeholder until a cleared Keeper mesh/animation set lands.
    setmodel(keeper, "models/sprites/sprkle.spr");
    setsize(keeper, '-14 -14 -28', '14 14 34');
    setorigin(keeper, org);

    keeper.enemy = SoE_RiftGuardFindPlayer(keeper);
    keeper.soe_rift_guard_next_attack = time + 0.4;
    keeper.think = SoE_RiftGuardThink;
    keeper.nextthink = time + 0.05;

    return keeper;
};

void() soe_rift_guard_spawn =
{
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_NOT;
    setsize(self, '0 0 0', '0 0 0');
};

void() SoE_RiftFirstEntryTouch =
{
    if (soe_rift_first_entry_fired ||
        other.classname != "player" ||
        other.downed ||
        other.soe_beast_active)
        return;

    soe_rift_first_entry_fired = true;

    entity marker = find(world, classname, "soe_rift_guard_spawn");
    float spawned = 0;
    while (marker != world && spawned < 3) {
        SoE_SpawnRiftGuard(marker.origin);
        spawned = spawned + 1;
        marker = find(marker, classname, "soe_rift_guard_spawn");
    }

    self.solid = SOLID_NOT;
    self.touch = SUB_Null;
    SoE_FireEntityTargets(self);
};

void() soe_rift_first_entry =
{
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_RiftFirstEntryTouch;

    if (self.model != "")
        setmodel(self, self.model);
    else
        setsize(self, '-96 -96 -32', '96 96 72');
};

void() SoE_ResetRiftEncounter =
{
    soe_rift_first_entry_fired = false;
};
