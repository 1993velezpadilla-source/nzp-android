/*
    Shadows of Evil special-enemy runtime.

    Phase 1 uses stock NZ:P zombie geometry as a gameplay proxy so the
    mechanics can be tested before cleared Margwa/Parasite/Elemental models
    are available. The special state is isolated so model swaps do not alter
    quest/round logic.
*/

#define SOE_SPECIAL_NONE        0
#define SOE_SPECIAL_MARGWA      1
#define SOE_SPECIAL_PARASITE    2
#define SOE_SPECIAL_ELEMENTAL   3

.float soe_special_type;
.float soe_margwa_heads;
.float soe_margwa_head_health;
.float soe_margwa_head_health_max;
.float soe_margwa_mouth_open;
.float soe_margwa_mouth_change;
.float soe_margwa_purple;
.float soe_counts_round;
.float soe_attack_cooldown;
.float soe_spawn_at;
.vector soe_spawn_origin;

float(entity ent) SoE_IsCustomSpecialBody =
{
    return (
        ent.classname == "soe_parasite" ||
        ent.classname == "soe_elemental" ||
        ent.classname == "soe_elemental_warning"
    );
};

entity() getFreeZombieEnt;
void(entity where) spawn_a_zombieB;
entity(entity blarg) find_new_enemy;
entity(vector org, float counts_round) SoE_SpawnParasite;
void(entity victim, entity attacker, float damage, float d_style) DamageHandler;
void(entity who, float value, float impacted_by_2x_points) Player_ChangeScore;

void(entity ent) SoE_ClearSpecialState =
{
    ent.soe_special_type = SOE_SPECIAL_NONE;
    ent.soe_margwa_heads = 0;
    ent.soe_margwa_head_health = 0;
    ent.soe_margwa_head_health_max = 0;
    ent.soe_margwa_mouth_open = false;
    ent.soe_margwa_mouth_change = 0;
    ent.soe_margwa_purple = false;

    ent.scale = 1;
    if (ent.head != world)
        ent.head.scale = 1;
    if (ent.larm != world)
        ent.larm.scale = 1;
    if (ent.rarm != world)
        ent.rarm.scale = 1;
};

float(entity ent) SoE_IsNukeImmune =
{
    return (soe_active && ent.soe_special_type == SOE_SPECIAL_MARGWA);
};

entity(string marker_class) SoE_FindRandomMarker =
{
    entity marker = find(world, classname, marker_class);
    entity chosen = world;
    float seen = 0;

    while (marker != world) {
        seen = seen + 1;
        if (random() < (1 / seen))
            chosen = marker;

        marker = find(marker, classname, marker_class);
    }

    return chosen;
};

void() soe_spawn_margwa =
{
    self.solid = SOLID_NOT;
    self.movetype = MOVETYPE_NONE;
    setsize(self, '0 0 0', '0 0 0');
};

entity() SoE_MargwaFindTarget =
{
    entity target = find(world, classname, "player");
    entity chosen = world;
    float best_distance = 999999;

    while (target != world) {
        if (!target.downed && !target.is_spectator) {
            // Normal Margwas respect Beast invisibility. Purple finale Margwas
            // are allowed to see and attack Beast Mode.
            if (!target.soe_beast_active || soe_finale_active) {
                float distance = vlen(self.origin - target.origin);
                if (distance < best_distance) {
                    best_distance = distance;
                    chosen = target;
                }
            }
        }
        target = find(target, classname, "player");
    }

    return chosen;
};

void() SoE_MargwaMelee =
{
    if (self.enemy == world || !self.enemy.health)
        return;

    if (self.enemy.soe_beast_active && soe_finale_active) {
        // Finale Beast has infinite duration; incoming Margwa/corruption
        // damage is represented by draining the Beast meter budget.
        SoE_BeastDrain(self.enemy, 20);
        return;
    }

    // Canonical Margwa slam is lethal to a non-Jug player from full health.
    DamageHandler(self.enemy, self, 100, DMG_TYPE_ZOMBIESWIPE);
};

void(entity margwa) SoE_MargwaAdvanceMouthCycle =
{
    if (margwa.soe_margwa_mouth_change > time)
        return;

    if (margwa.soe_margwa_mouth_open) {
        margwa.soe_margwa_mouth_open = false;

        // Closed window gets shorter with only one head remaining.
        if (margwa.soe_margwa_heads <= 1)
            margwa.soe_margwa_mouth_change = time + 0.5 + (random() * 0.5);
        else
            margwa.soe_margwa_mouth_change = time + 1 + (random() * 2.5);
    } else {
        margwa.soe_margwa_mouth_open = true;
        margwa.soe_margwa_mouth_change = time + 3 + (random() * 2);
    }
};

void() SoE_UpdateSpecialAI =
{
    if (!soe_active || self.soe_special_type == SOE_SPECIAL_NONE)
        return;

    if (self.soe_special_type == SOE_SPECIAL_MARGWA) {
        SoE_MargwaAdvanceMouthCycle(self);

        // The stock pathfinder is reused, but target choice is SoE-specific.
        if (self.enemy == world || self.enemy.downed ||
            (self.enemy.soe_beast_active && !soe_finale_active)) {
            self.enemy = SoE_MargwaFindTarget();
            self.goalentity = self.enemy;
            self.chase_time = time + 5;
        }

        // Margwa becomes more aggressive as heads are removed.
        if (self.soe_margwa_heads >= 3)
            self.walktype = 3;
        else if (self.soe_margwa_heads == 2)
            self.walktype = 4;
        else
            self.walktype = 5;
    }
};

void(entity victim) SoE_SpawnMargwaHeart =
{
    if (soe_has_margwa_heart)
        return;

    entity drop = spawn();
    drop.style = SOE_PICKUP_MARGWA_HEART;
    drop.useprint_string_1 = "Hold %b to Pick Up Margwa Heart";

    entity old_self = self;
    self = drop;
    soe_quest_pickup();
    self = old_self;

    setorigin(drop, victim.origin + '0 0 16');
};

void(entity victim, entity attacker) SoE_DestroyMargwaHead =
{
    victim.soe_margwa_heads = victim.soe_margwa_heads - 1;

    // Every destroyed Margwa head releases one Parasite at the boss location.
    // These head-release Parasites are additive and do not own the round budget.
    SoE_SpawnParasite(victim.origin, false);

    if (attacker.classname == "player")
        Player_ChangeScore(attacker, 500, false);

    if (victim.soe_margwa_heads > 0) {
        victim.soe_margwa_head_health = victim.soe_margwa_head_health_max;
        victim.soe_margwa_mouth_open = false;
        victim.soe_margwa_mouth_change = time + 0.75;
        return;
    }

    soe_margwa_kills = soe_margwa_kills + 1;

    if (!soe_has_margwa_heart)
        SoE_SpawnMargwaHeart(victim);

    // Let NZ:P's normal death cleanup return the pooled zombie entity.
    entity old_self = self;
    self = victim;
    self.th_die();
    self = old_self;
};

float(entity victim, entity attacker, float damage, float d_style) SoE_HandleSpecialDamage =
{
    if (!soe_active || victim.soe_special_type == SOE_SPECIAL_NONE)
        return false;

    if (victim.soe_special_type == SOE_SPECIAL_MARGWA) {
        // Margwa body and closed mouths are invulnerable. Because NZ:P's
        // hitscan pipeline already collapses a limb/head hit into a headshot
        // damage style on the body entity, HEADSHOT is our clean weak-point
        // signal until final three-mouth hitboxes are available.
        if (d_style != DMG_TYPE_HEADSHOT || !victim.soe_margwa_mouth_open)
            return true;

        victim.soe_margwa_head_health = victim.soe_margwa_head_health - damage;

        if (victim.soe_margwa_head_health <= 0)
            SoE_DestroyMargwaHead(victim, attacker);

        // Returning true bypasses generic zombie HP and Insta-Kill handling.
        return true;
    }

    if (SoE_IsCustomSpecialBody(victim)) {
        victim.health = victim.health - damage;

        if (attacker.classname == "player" && damage > 0)
            Player_ChangeScore(attacker, 10, false);

        if (victim.health <= 0 || instakill_finished > time) {
            if (attacker.classname == "player") {
                attacker.kills = attacker.kills + 1;
                Player_ChangeScore(attacker, 50, true);
            }

            if (victim.soe_counts_round) {
                Remaining_Zombies = Remaining_Zombies - 1;
                Current_Zombies = Current_Zombies - 1;
            }

            remove(victim);
        }

        return true;
    }

    return false;
};

float() SoE_SpawnMargwaProxy =
{
    entity marker = SoE_FindRandomMarker("soe_spawn_margwa");
    if (marker == world)
        marker = SoE_FindRandomMarker("spawn_zombie");

    if (marker == world)
        return false;

    entity slot = getFreeZombieEnt();
    if (slot == world)
        return false;

    // Respect the pooled spawner's safety delay. The request stays queued.
    if (zombie_spawn_timer > time)
        return false;

    spawn_a_zombieB(marker);

    if (slot.classname != "ai_zombie")
        return false;

    slot.soe_special_type = SOE_SPECIAL_MARGWA;
    slot.soe_margwa_heads = 3;
    slot.soe_margwa_purple = soe_finale_active;

    slot.soe_margwa_head_health_max = z_health * 0.75;
    if (slot.soe_margwa_head_health_max < 600)
        slot.soe_margwa_head_health_max = 600;
    slot.soe_margwa_head_health = slot.soe_margwa_head_health_max;

    slot.soe_margwa_mouth_open = false;
    slot.soe_margwa_mouth_change = time + 1;

    // Keep generic HP out of the way; the three-mouth handler owns damage.
    slot.health = 999999;
    slot.head.health = 999999;
    slot.larm.health = 999999;
    slot.rarm.health = 999999;

    slot.scale = 1.55;
    slot.head.scale = 1.55;
    slot.larm.scale = 1.55;
    slot.rarm.scale = 1.55;

    slot.th_melee = SoE_MargwaMelee;
    slot.outside = false;
    slot.enemy = SoE_MargwaFindTarget();
    slot.goalentity = slot.enemy;

    // This enemy is in addition to the normal round budget.
    Total_Zombies = Total_Zombies + 1;
    Current_Zombies = Current_Zombies + 1;
    Remaining_Zombies = Remaining_Zombies + 1;

    return true;
};

void() SoE_ProcessSpecialSpawns =
{
    if (!soe_active || !roundinit || z_health <= 0)
        return;

    if (soe_scripted_margwa_pending > 0) {
        if (SoE_SpawnMargwaProxy()) {
            soe_scripted_margwa_pending = soe_scripted_margwa_pending - 1;

            // Only a natural scheduled spawn advances the next natural boss
            // round. Ritual/quest spawns leave this calendar untouched.
            if (soe_next_regular_margwa_round == rounds)
                soe_next_regular_margwa_round = rounds + 5 + floor(random() * 2);
        }
    }

    // Parasite and Insanity Elemental gameplay proxies are intentionally not
    // faked as ground zombies. Their pending count is preserved until the
    // dedicated flying/rolling movers are connected.
};
