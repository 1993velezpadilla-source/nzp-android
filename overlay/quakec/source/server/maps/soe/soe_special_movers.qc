/*
    Shadows of Evil Parasite + Insanity Elemental movers.

    Gameplay-first placeholders. Final cleared models, animations and FX can
    replace these visuals without changing combat/scheduler code.
*/

.float soe_projectile_expire;
.float soe_spawn_counts_round;

entity(entity seeker, float allow_beast) SoE_FindSpecialTarget =
{
    entity target = find(world, classname, "player");
    entity chosen = world;
    float best_distance = 999999;

    while (target != world) {
        if (!target.downed && !target.is_spectator) {
            if (allow_beast || !target.soe_beast_active) {
                float distance = vlen(seeker.origin - target.origin);
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

void() SoE_SpecialVisualExpire =
{
    remove(self);
};

void() SoE_ParasiteProjectileTouch =
{
    if (other == self.owner)
        return;

    if (other.classname == "player") {
        if (!other.soe_beast_active)
            DamageHandler(other, self.owner, 30, DMG_TYPE_ZOMBIESWIPE);
    }

    remove(self);
};

void() SoE_ParasiteProjectileThink =
{
    if (self.soe_projectile_expire <= time) {
        remove(self);
        return;
    }

    self.nextthink = time + 0.1;
};

void(entity parasite, entity target) SoE_ParasiteFire =
{
    if (target == world)
        return;

    entity shot = spawn();
    shot.classname = "soe_parasite_projectile";
    shot.owner = parasite;
    shot.enemy = target;
    shot.movetype = MOVETYPE_FLYMISSILE;
    shot.solid = SOLID_BBOX;
    shot.touch = SoE_ParasiteProjectileTouch;
    shot.think = SoE_ParasiteProjectileThink;
    shot.nextthink = time + 0.1;
    shot.soe_projectile_expire = time + 3;

    setmodel(shot, "models/sprites/sprkle.spr");
    setsize(shot, '-2 -2 -2', '2 2 2');
    setorigin(shot, parasite.origin + '0 0 8');

    vector aim = (target.origin + target.view_ofs) - shot.origin;
    shot.velocity = normalize(aim) * 500;
    shot.effects = EF_FULLBRIGHT;
};

void() SoE_ParasiteThink =
{
    if (!soe_active) {
        remove(self);
        return;
    }

    if (self.enemy == world || self.enemy.downed || self.enemy.is_spectator ||
        self.enemy.soe_beast_active) {
        self.enemy = SoE_FindSpecialTarget(self, false);
    }

    if (self.enemy == world) {
        self.velocity = '0 0 0';
        self.nextthink = time + 0.1;
        return;
    }

    vector desired = (self.enemy.origin + '0 0 72') - self.origin;
    float distance = vlen(desired);

    // Hover/chase instead of walking the waypoint graph.
    if (distance > 220)
        self.velocity = normalize(desired) * 170;
    else if (distance < 110)
        self.velocity = normalize(self.origin - (self.enemy.origin + '0 0 48')) * 100;
    else
        self.velocity = self.velocity * 0.75;

    self.angles_y = vectoyaw(desired);

    if (distance < 700 && self.soe_attack_cooldown <= time) {
        SoE_ParasiteFire(self, self.enemy);
        self.soe_attack_cooldown = time + 1.4 + (random() * 0.9);
    }

    self.nextthink = time + 0.05;
};

float() SoE_SpecialEnemyHealth =
{
    float special_health = rounds * 50;

    if (special_health > 1600)
        special_health = 1600;
    if (special_health < 50)
        special_health = 50;

    return special_health;
};

entity(vector org, float counts_round) SoE_SpawnParasite =
{
    entity parasite = spawn();
    parasite.classname = "soe_parasite";
    parasite.soe_special_type = SOE_SPECIAL_PARASITE;
    parasite.soe_counts_round = counts_round;
    parasite.movetype = MOVETYPE_FLY;
    parasite.solid = SOLID_BBOX;
    parasite.takedamage = DAMAGE_YES;
    parasite.health = SoE_SpecialEnemyHealth();
    parasite.flags = parasite.flags | FL_MONSTER;
    parasite.effects = EF_FULLBRIGHT;

    setmodel(parasite, "models/sprites/sprkle.spr");
    setsize(parasite, '-10 -10 -8', '10 10 8');
    setorigin(parasite, org + '0 0 32');

    parasite.enemy = SoE_FindSpecialTarget(parasite, false);
    parasite.think = SoE_ParasiteThink;
    parasite.nextthink = time + 0.05;
    parasite.soe_attack_cooldown = time + 0.8 + random();

    if (counts_round)
        Current_Zombies = Current_Zombies + 1;

    return parasite;
};

void() SoE_ElementalExplode =
{
    entity target = findradius(self.origin, 72);

    while (target != world) {
        if (target.classname == "player" && !target.downed) {
            if (!target.soe_beast_active)
                DamageHandler(target, self, 50, DMG_TYPE_EXPLOSIVE);
        }

        target = target.chain;
    }

    entity flash = spawn();
    flash.movetype = MOVETYPE_NONE;
    flash.solid = SOLID_NOT;
    flash.think = SoE_SpecialVisualExpire;
    flash.nextthink = time + 0.45;
    flash.effects = EF_FULLBRIGHT;
    setmodel(flash, "models/sprites/explosion.spr");
    setorigin(flash, self.origin);

    if (self.soe_counts_round)
        SoE_OnCountedSpecialDeath(self.origin);

    remove(self);
};

void() SoE_ElementalTouch =
{
    if (other.classname == "player" && !other.downed)
        SoE_ElementalExplode();
};

void() SoE_ElementalThink =
{
    if (!soe_active) {
        remove(self);
        return;
    }

    if (self.enemy == world || self.enemy.downed || self.enemy.is_spectator ||
        self.enemy.soe_beast_active) {
        self.enemy = SoE_FindSpecialTarget(self, false);
    }

    if (self.enemy == world) {
        self.velocity = '0 0 0';
        self.nextthink = time + 0.1;
        return;
    }

    vector delta = self.enemy.origin - self.origin;
    vector planar = delta;
    planar_z = 0;

    if (vlen(planar) < 48) {
        SoE_ElementalExplode();
        return;
    }

    vector direction = normalize(planar);
    self.velocity_x = direction_x * 280;
    self.velocity_y = direction_y * 280;
    self.angles_y = vectoyaw(planar);

    self.nextthink = time + 0.05;
};

entity(vector org, entity target, float counts_round) SoE_SpawnElemental =
{
    entity elemental = spawn();
    elemental.classname = "soe_elemental";
    elemental.soe_special_type = SOE_SPECIAL_ELEMENTAL;
    elemental.soe_counts_round = counts_round;
    elemental.movetype = MOVETYPE_STEP;
    elemental.solid = SOLID_SLIDEBOX;
    elemental.takedamage = DAMAGE_YES;
    elemental.health = SoE_SpecialEnemyHealth();
    elemental.flags = elemental.flags | FL_MONSTER;
    elemental.effects = EF_FULLBRIGHT;

    setmodel(elemental, "models/sprites/sprkle.spr");
    setsize(elemental, '-12 -12 -12', '12 12 12');
    setorigin(elemental, org);

    if (target == world)
        target = SoE_FindSpecialTarget(elemental, false);

    elemental.enemy = target;
    elemental.touch = SoE_ElementalTouch;
    elemental.think = SoE_ElementalThink;
    elemental.nextthink = time + 0.05;

    if (counts_round)
        Current_Zombies = Current_Zombies + 1;

    return elemental;
};

void() SoE_ElementalWarningFinish =
{
    // If the warning survived the telegraph window, transfer the already
    // counted round slot to the actual Elemental without incrementing Current.
    entity elemental = SoE_SpawnElemental(self.soe_spawn_origin, self.enemy, false);
    elemental.soe_counts_round = self.soe_spawn_counts_round;
    remove(self);
};

entity(vector org, entity target, float counts_round) SoE_SpawnElementalWarning =
{
    entity warning = spawn();
    warning.classname = "soe_elemental_warning";
    warning.soe_special_type = SOE_SPECIAL_ELEMENTAL;
    warning.soe_counts_round = counts_round;
    warning.soe_spawn_counts_round = counts_round;
    warning.movetype = MOVETYPE_NONE;
    warning.solid = SOLID_BBOX;
    warning.takedamage = DAMAGE_YES;
    warning.health = 35;
    warning.enemy = target;
    warning.effects = EF_FULLBRIGHT;
    warning.soe_spawn_origin = org;

    // Temporary clean placeholder for the canonical red-mist telegraph.
    setmodel(warning, "models/sprites/sprkle.spr");
    setsize(warning, '-14 -14 -8', '14 14 24');
    setorigin(warning, org + '0 0 36');

    warning.think = SoE_ElementalWarningFinish;
    warning.nextthink = time + 0.8;

    return warning;
};


void() soe_spawn_air =
{
    self.solid = SOLID_NOT;
    self.movetype = MOVETYPE_NONE;
    setsize(self, '0 0 0', '0 0 0');
};
