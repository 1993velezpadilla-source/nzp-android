/*
    Shadows of Evil - Li'l Arnie tactical equipment.

    W_CUSTOM2 is used only as a Mystery Box presentation token. Taking that
    token grants tactical equipment (3/3 charges) and does NOT occupy a gun
    inventory slot.

    Input:
      impulse 35 = throw Li'l Arnie
      Android HUD can bind a dedicated tactical button to the same impulse.

    Upgrade:
      shared 100 Arnie kills + all four district rituals complete
      -> throw at Top Hat, Cane, Bow Tie
      -> throw at Black Lace ritual stage
      -> upgrade/refill every active Arnie owner
*/

float soe_arnie_kills;
float soe_arnie_item_mask;
float soe_arnie_upgraded_global;

.float soe_has_arnie;
.float soe_arnie_ammo;
.float soe_arnie_upgraded;

.float soe_arnie_activate_at;
.float soe_arnie_expire_at;
.float soe_arnie_next_kill;
.float soe_arnie_target_bit;

float(entity ent) SoE_ArnieCanConsume =
{
    if (ent == world)
        return false;

    if (ent.classname == "ai_zombie") {
        if (!ent.iszomb || ent.aistatus != "1")
            return false;
        if (ent.soe_special_type == SOE_SPECIAL_MARGWA)
            return false;
        return true;
    }

    if (ent.classname == "ai_dog")
        return ent.aistatus == "1";

    if (ent.classname == "soe_parasite" ||
        ent.classname == "soe_elemental")
        return ent.health > 0;

    return false;
};

entity(entity seeker) SoE_FindNearestActiveArnie =
{
    entity arnie = find(world, classname, "soe_arnie_active");
    entity best = world;
    float best_distance = 900;

    while (arnie != world) {
        float distance = vlen(arnie.origin - seeker.origin);

        if (distance < best_distance) {
            best_distance = distance;
            best = arnie;
        }

        arnie = find(arnie, classname, "soe_arnie_active");
    }

    return best;
};

float() SoE_ArnieOverrideZombieAI =
{
    if (!soe_active || self.classname != "ai_zombie" || self.aistatus != "1")
        return false;

    entity arnie = SoE_FindNearestActiveArnie(self);
    if (arnie == world)
        return false;

    vector delta = arnie.origin - self.origin;
    vector planar = delta;
    planar_z = 0;
    float distance = vlen(planar);

    // Margwas are distracted/held by the lure but cannot be killed by it.
    if (self.soe_special_type == SOE_SPECIAL_MARGWA) {
        self.velocity = '0 0 0';
        self.angles_y = vectoyaw(planar);
        return true;
    }

    if (distance > 34) {
        vector direction = normalize(planar);
        self.velocity_x = direction_x * 150;
        self.velocity_y = direction_y * 150;
        self.angles_y = vectoyaw(planar);
    } else {
        self.velocity = '0 0 0';
    }

    return true;
};

void(entity owner, entity victim) SoE_ArnieKillEnemy =
{
    if (!SoE_ArnieCanConsume(victim))
        return;

    // Count before DamageHandler returns pooled zombies to the free list.
    soe_arnie_kills = soe_arnie_kills + 1;
    DamageHandler(victim, owner, 999999, DMG_TYPE_OTHER);
};

void(entity arnie) SoE_ArnieConsumeNearby =
{
    if (arnie.soe_arnie_next_kill > time)
        return;

    entity victim = findradius(arnie.origin, 58);
    entity chosen = world;

    while (victim != world) {
        if (SoE_ArnieCanConsume(victim)) {
            chosen = victim;
            break;
        }

        victim = victim.chain;
    }

    if (chosen != world)
        SoE_ArnieKillEnemy(arnie.owner, chosen);

    if (arnie.owner.soe_arnie_upgraded)
        arnie.soe_arnie_next_kill = time + 0.10;
    else
        arnie.soe_arnie_next_kill = time + 0.18;
};

void(entity arnie) SoE_ArniePullCustomSpecials =
{
    entity ent = findradius(arnie.origin, 420);

    while (ent != world) {
        entity next = ent.chain;

        if (ent.classname == "soe_parasite" ||
            ent.classname == "soe_elemental") {
            vector delta = arnie.origin - ent.origin;
            float distance = vlen(delta);

            if (distance > 45)
                ent.velocity = normalize(delta) * 240;
            else if (SoE_ArnieCanConsume(ent))
                SoE_ArnieKillEnemy(arnie.owner, ent);
        }

        ent = next;
    }
};

void(entity arnie) SoE_ArnieCheckUpgradeProps =
{
    if (soe_arnie_kills < 100 || soe_gateworm_count < 4)
        return;

    entity prop = findradius(arnie.origin, 76);

    while (prop != world) {
        entity next = prop.chain;

        if (prop.classname == "soe_arnie_upgrade_prop") {
            float bit = prop.soe_arnie_target_bit;

            if (bit > 0 && !(soe_arnie_item_mask & bit)) {
                soe_arnie_item_mask = soe_arnie_item_mask | bit;
                prop.solid = SOLID_NOT;

                if (prop.model != "")
                    setmodel(prop, "");

                SoE_FireEntityTargets(prop);
            }
        }

        prop = next;
    }
};

void(entity arnie) SoE_ArnieTryFinishUpgrade =
{
    if (soe_arnie_upgraded_global ||
        soe_arnie_kills < 100 ||
        soe_arnie_item_mask != 7)
        return;

    entity stage = find(world, classname, "soe_arnie_upgrade_stage");
    while (stage != world) {
        if (vlen(stage.origin - arnie.origin) <= 90) {
            soe_arnie_upgraded_global = true;

            entity player = find(world, classname, "player");
            while (player != world) {
                if (player.soe_has_arnie) {
                    player.soe_arnie_upgraded = true;
                    player.soe_arnie_ammo = 3;
                }
                player = find(player, classname, "player");
            }

            entity old_self = self;
            entity old_other = other;
            self = stage;
            other = arnie.owner;
            SoE_FireEntityTargets(stage);
            self = old_self;
            other = old_other;
            return;
        }

        stage = find(stage, classname, "soe_arnie_upgrade_stage");
    }
};

void() SoE_ArnieActiveThink =
{
    if (self.soe_arnie_expire_at <= time) {
        // Final pulse. Margwas are deliberately excluded by SoE_ArnieCanConsume.
        entity victim = findradius(self.origin, 110);
        while (victim != world) {
            entity next = victim.chain;

            if (SoE_ArnieCanConsume(victim))
                SoE_ArnieKillEnemy(self.owner, victim);

            victim = next;
        }

        remove(self);
        return;
    }

    SoE_ArnieConsumeNearby(self);
    SoE_ArniePullCustomSpecials(self);

    self.angles_y = self.angles_y + 24;
    self.nextthink = time + 0.05;
};

void(entity projectile) SoE_ArnieActivate =
{
    SoE_ArnieCheckUpgradeProps(projectile);
    SoE_ArnieTryFinishUpgrade(projectile);

    entity active = spawn();
    active.classname = "soe_arnie_active";
    active.owner = projectile.owner;
    active.movetype = MOVETYPE_NONE;
    active.solid = SOLID_NOT;
    active.effects = EF_FULLBRIGHT;

    // Native grenade is a legal placeholder for the jar/squid presentation.
    setmodel(active, "models/weapons/grenade/g_grenade.mdl");
    setorigin(active, projectile.origin);

    if (projectile.owner.soe_arnie_upgraded) {
        active.soe_arnie_expire_at = time + 12;
        active.scale = 1.35;
    } else {
        active.soe_arnie_expire_at = time + 8;
        active.scale = 1.0;
    }

    active.soe_arnie_next_kill = time + 0.15;
    active.think = SoE_ArnieActiveThink;
    active.nextthink = time + 0.05;

    remove(projectile);
};

void() SoE_ArnieProjectileThink =
{
    if (time >= self.soe_arnie_activate_at) {
        SoE_ArnieActivate(self);
        return;
    }

    self.nextthink = time + 0.05;
};

void() SoE_ArnieProjectileTouch =
{
    if (other == self.owner)
        return;

    // Let it bounce briefly before opening, preserving the thrown-tactical feel.
    if (time + 0.15 >= self.soe_arnie_activate_at)
        SoE_ArnieActivate(self);
};

void() SoE_ArnieThrowInput =
{
    if (!soe_active ||
        self.classname != "player" ||
        self.downed ||
        self.isBuying ||
        !self.soe_has_arnie ||
        self.soe_arnie_ammo <= 0)
        return;

    self.soe_arnie_ammo = self.soe_arnie_ammo - 1;

    entity projectile = spawn();
    projectile.classname = "soe_arnie_projectile";
    projectile.owner = self;
    projectile.movetype = MOVETYPE_BOUNCE;
    projectile.solid = SOLID_BBOX;
    projectile.touch = SoE_ArnieProjectileTouch;
    projectile.effects = EF_FULLBRIGHT;
    projectile.soe_arnie_activate_at = time + 0.75;
    projectile.think = SoE_ArnieProjectileThink;
    projectile.nextthink = time + 0.05;

    setmodel(projectile, "models/weapons/grenade/g_grenade.mdl");
    setsize(projectile, '-3 -3 -3', '3 3 3');

    makevectors(self.v_angle);
    setorigin(projectile, self.origin + self.view_ofs + (v_forward * 14));
    projectile.velocity = (v_forward * 520) + (v_up * 150);
    projectile.avelocity = '80 120 60';
};

float(entity user) SoE_CanReceiveLilArnie =
{
    if (!soe_active || user == world)
        return false;

    return !user.soe_has_arnie;
};

void(entity player) SoE_GiveLilArnie =
{
    if (!soe_active || player == world)
        return;

    player.soe_has_arnie = true;
    player.soe_arnie_ammo = 3;
    player.soe_arnie_upgraded = soe_arnie_upgraded_global;
};

void(entity player) SoE_ArnieOnMaxAmmo =
{
    if (soe_active && player.soe_has_arnie)
        player.soe_arnie_ammo = 3;
};

float(entity user) SoE_MysteryBoxArnieOverride =
{
    if (!SoE_CanReceiveLilArnie(user))
        return W_NOWEP;

    // Extra SoE-only tactical candidate alongside the normal box list.
    if (random() < (1.0 / 29.0))
        return W_CUSTOM2;

    return W_NOWEP;
};

void() soe_arnie_upgrade_prop =
{
    if (self.style == 1)
        self.soe_arnie_target_bit = 1; // Top Hat / Nero
    else if (self.style == 2)
        self.soe_arnie_target_bit = 2; // Cane / Ruby Rabbit
    else if (self.style == 3)
        self.soe_arnie_target_bit = 4; // Bow Tie / Boxing Gym
    else
        objerror("soe_arnie_upgrade_prop requires style 1..3\n");

    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;

    if (self.model != "")
        setmodel(self, self.model);
    else {
        setmodel(self, "models/sprites/sprkle.spr");
        setsize(self, '-8 -8 -8', '8 8 10');
        self.effects = EF_FULLBRIGHT;
    }
};

void() soe_arnie_upgrade_stage =
{
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;

    if (self.model != "")
        setmodel(self, self.model);
    else
        setsize(self, '-34 -28 -12', '34 28 20');
};

void() SoE_ResetArnie =
{
    soe_arnie_kills = 0;
    soe_arnie_item_mask = 0;
    soe_arnie_upgraded_global = false;
};
