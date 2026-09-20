/*
    Shadows of Evil - Apothicon Servant runtime.

    Weapon slot: W_CUSTOM1 (70)
    Temporary presentation: native Ray Gun view/ground model + fire sound.
    Gameplay is independent from that placeholder and uses a dedicated
    projectile/vortex implementation.
*/

float soe_servant_built;
float soe_servant_box_unlocked;
entity soe_servant_table_ent;

.float soe_vortex_until;
.float soe_vortex_next_tick;
.float soe_servant_projectile_expire;

void(float weapon_id, float weapon_mag, float weapon_reserve, float weapon_tier) Weapon_GiveWeapon;
float(entity player, float weapon, float match_pap) Weapon_PlayerHasWeapon;
void(entity victim, entity attacker, float damage, float d_style) DamageHandler;

float() SoE_AnyPlayerHasServant =
{
    entity player = find(world, classname, "player");

    while (player != world) {
        for (float i = 0; i < MAX_PLAYER_WEAPONS; i++) {
            if (player.weapons[i].weapon_id == W_CUSTOM1)
                return true;
        }

        player = find(player, classname, "player");
    }

    return false;
};

void(entity player) SoE_GiveServant =
{
    entity old_self = self;
    self = player;
    Weapon_GiveWeapon(W_CUSTOM1, 1, 9, 0);
    self = old_self;
};

float(entity user) SoE_MysteryBoxServantOverride =
{
    if (!soe_active || !soe_servant_box_unlocked)
        return W_NOWEP;

    if (SoE_AnyPlayerHasServant())
        return W_NOWEP;

    if (Weapon_PlayerHasWeapon(user, W_CUSTOM1, true))
        return W_NOWEP;

    // One additional entry among roughly the stock 28-entry box pool.
    if (random() < (1.0 / 29.0))
        return W_CUSTOM1;

    return W_NOWEP;
};

void() SoE_ServantBuildTableTouch =
{
    if (other.classname != "player" || other.downed || other.isBuying)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    // state 0: parts not assembled
    if (self.state == 0) {
        if (!soe_has_margwa_heart || !soe_has_xenomatter || !soe_has_margwa_tentacle)
            return;

        Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

        if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
            return;

        other.semi_actions |= SEMIACTION_USE;

        soe_has_margwa_heart = false;
        soe_has_xenomatter = false;
        soe_has_margwa_tentacle = false;

        soe_servant_built = true;
        soe_servant_box_unlocked = true;
        soe_servant_table_ent = self;

        self.state = 1;
        SoE_FireEntityTargets(self);
        return;
    }

    // state 1: the initially built copy is waiting on the table.
    if (self.state == 1) {
        if (SoE_AnyPlayerHasServant())
            return;

        Player_UseprintWithWait(other, self, self.useprint_index_2, 0);

        if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
            return;

        other.semi_actions |= SEMIACTION_USE;
        SoE_GiveServant(other);
        self.state = 2;
        SoE_FireEntityTargets(self);
    }
};

void() soe_servant_build_table =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Build Apothicon Servant";
    if (self.useprint_string_2 == "")
        self.useprint_string_2 = "Hold %b to Take Apothicon Servant";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.useprint_index_2 = Useprint_Register(self.useprint_string_2, self.useprint_color_2);

    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_ServantBuildTableTouch;
    self.state = 0;

    if (self.model != "")
        setmodel(self, self.model);
    else
        setsize(self, '-28 -28 -18', '28 28 28');

    // Temporary native presentation assets. Replace with cleared Servant
    // assets later without touching W_CUSTOM1 gameplay.
    precache_model("models/weapons/ray/g_ray.mdl");
    precache_model("models/weapons/ray/v_ray.mdl");
    precache_model("models/sprites/sprkle.spr");
    precache_sound("sounds/weapons/raygun/shoot.wav");
};

float(entity ent) SoE_ServantCanConsume =
{
    if (ent == world)
        return false;

    if (ent.classname == "ai_zombie") {
        if (ent.soe_special_type == SOE_SPECIAL_MARGWA)
            return false;
        return true;
    }

    if (ent.classname == "ai_dog")
        return true;

    if (ent.classname == "soe_parasite" || ent.classname == "soe_elemental")
        return true;

    return false;
};

void(entity victim, entity owner) SoE_ServantKill =
{
    if (!SoE_ServantCanConsume(victim))
        return;

    DamageHandler(victim, owner, 999999, DMG_TYPE_OTHER);
};

void() SoE_ServantVortexExplode =
{
    entity victim = findradius(self.origin, 285);

    while (victim != world) {
        entity next = victim.chain;

        if (SoE_ServantCanConsume(victim))
            SoE_ServantKill(victim, self.owner);

        victim = next;
    }

    // Reuse a clean native explosion sprite as placeholder FX.
    entity fx = spawn();
    fx.movetype = MOVETYPE_NONE;
    fx.solid = SOLID_NOT;
    fx.effects = EF_FULLBRIGHT;
    fx.think = SoE_SpecialVisualExpire;
    fx.nextthink = time + 0.45;
    setmodel(fx, "models/sprites/explosion.spr");
    setorigin(fx, self.origin);

    remove(self);
};

void() SoE_ServantVortexThink =
{
    if (self.soe_vortex_until <= time) {
        SoE_ServantVortexExplode();
        return;
    }

    entity victim = findradius(self.origin, 230);

    while (victim != world) {
        entity next = victim.chain;

        if (SoE_ServantCanConsume(victim)) {
            vector delta = self.origin - victim.origin;
            float distance = vlen(delta);

            if (distance < 52) {
                SoE_ServantKill(victim, self.owner);
            } else {
                // Pull harder as targets approach the singularity.
                float pull_speed = 220 + ((230 - distance) * 1.8);
                victim.velocity = normalize(delta) * pull_speed;
            }
        }

        victim = next;
    }

    self.angles_y = self.angles_y + 18;
    self.nextthink = time + 0.05;
};

void(entity projectile) SoE_ServantCreateVortex =
{
    entity vortex = spawn();
    vortex.classname = "soe_servant_vortex";
    vortex.owner = projectile.owner;
    vortex.movetype = MOVETYPE_NONE;
    vortex.solid = SOLID_NOT;
    vortex.effects = EF_FULLBRIGHT;
    vortex.scale = 1.6;

    setmodel(vortex, "models/sprites/sprkle.spr");
    setorigin(vortex, projectile.origin);

    vortex.soe_vortex_until = time + 4.25;
    vortex.think = SoE_ServantVortexThink;
    vortex.nextthink = time + 0.01;

    remove(projectile);
};

void() SoE_ServantProjectileTouch =
{
    if (other == self.owner)
        return;

    SoE_ServantCreateVortex(self);
};

void() SoE_ServantProjectileThink =
{
    if (self.soe_servant_projectile_expire <= time) {
        SoE_ServantCreateVortex(self);
        return;
    }

    self.nextthink = time + 0.05;
};

void(float side) SoE_FireApothiconServant =
{
    entity shot = spawn();
    shot.classname = "soe_servant_projectile";
    shot.owner = self;
    shot.movetype = MOVETYPE_FLYMISSILE;
    shot.solid = SOLID_BBOX;
    shot.effects = EF_FULLBRIGHT;
    shot.scale = 0.6;
    shot.touch = SoE_ServantProjectileTouch;
    shot.think = SoE_ServantProjectileThink;
    shot.nextthink = time + 0.05;
    shot.soe_servant_projectile_expire = time + 2.5;

    setmodel(shot, "models/sprites/sprkle.spr");
    setsize(shot, '-3 -3 -3', '3 3 3');

    makevectors(self.v_angle);
    setorigin(shot, self.origin + self.view_ofs + (v_forward * 18));
    shot.velocity = v_forward * 760;
};

void() SoE_ResetServant =
{
    soe_servant_built = false;
    soe_servant_box_unlocked = false;
    soe_servant_table_ent = world;
};
