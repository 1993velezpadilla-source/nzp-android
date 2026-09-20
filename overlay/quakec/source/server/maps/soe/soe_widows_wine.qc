/*
    Shadows of Evil - Widow's Wine clean-room runtime.

    Phase 1 implements the core defensive behavior:
      - 4000 point powered machine
      - four web charges
      - zombie melee triggers a radial web burst and consumes one charge
      - web field repeatedly suppresses normal enemy movement
      - +2 charges at the start of a round (cap 4)
      - Max Ammo refills to 4

    Sticky thrown web grenades and melee-web application are intentionally
    isolated as follow-up weapon-pipeline work instead of faking them here.
*/

.float soe_has_widows_wine;
.float soe_widows_charges;
.float soe_widows_web_expire;

void(entity who, float value, float impacted_by_2x_points) Player_ChangeScore;

float(entity ent) SoE_WidowsCanWeb =
{
    if (ent == world)
        return false;

    if (ent.classname == "ai_zombie") {
        // Margwas trigger the player's web charge but are not immobilized.
        if (ent.soe_special_type == SOE_SPECIAL_MARGWA)
            return false;
        return ent.iszomb;
    }

    if (ent.classname == "ai_dog" ||
        ent.classname == "soe_parasite" ||
        ent.classname == "soe_elemental" ||
        ent.classname == "soe_keeper")
        return true;

    return false;
};

void() SoE_WidowsWebThink =
{
    if (!soe_active || time >= self.soe_widows_web_expire) {
        remove(self);
        return;
    }

    entity ent = findradius(self.origin, 176);
    while (ent != world) {
        if (SoE_WidowsCanWeb(ent)) {
            // AI may recompute velocity every frame. Re-applying this clamp
            // from the web field gives a stable slow/freeze without replacing
            // stock NZ:P pathfinding or monster think functions.
            ent.velocity_x = ent.velocity_x * 0.08;
            ent.velocity_y = ent.velocity_y * 0.08;
        }

        ent = ent.chain;
    }

    self.nextthink = time + 0.05;
};

void(vector origin) SoE_SpawnWidowsWeb =
{
    entity web = spawn();
    web.classname = "soe_widows_web";
    web.movetype = MOVETYPE_NONE;
    web.solid = SOLID_NOT;
    web.effects = EF_FULLBRIGHT;
    web.soe_widows_web_expire = time + 20;
    web.think = SoE_WidowsWebThink;
    web.nextthink = time + 0.01;

    // Clean placeholder until cleared Widow-specific web FX is integrated.
    setmodel(web, "models/sprites/sprkle.spr");
    setorigin(web, origin);
};

float(entity victim, entity attacker, float damage, float d_style) SoE_WidowsWineHandleHit =
{
    if (!soe_active ||
        victim.classname != "player" ||
        !victim.soe_has_widows_wine ||
        victim.soe_widows_charges <= 0)
        return false;

    if (d_style != DMG_TYPE_ZOMBIESWIPE || attacker == world)
        return false;

    if (attacker.classname != "ai_zombie" &&
        attacker.classname != "ai_dog" &&
        attacker.classname != "soe_keeper")
        return false;

    victim.soe_widows_charges = victim.soe_widows_charges - 1;
    SoE_SpawnWidowsWeb(victim.origin);

    // The triggering hit still lands. Returning false lets the stock damage
    // path continue after the defensive web burst has been created.
    return false;
};

void() SoE_WidowsMachineEnableUse =
{
    self.state = 1;
    self.use = SUB_Null;
};

void() SoE_WidowsMachineTouch =
{
    if (other.classname != "player" || other.downed || other.isBuying)
        return;

    if (self.state == 0 || other.soe_has_widows_wine)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    float price = self.cost;
    if (price <= 0)
        price = 4000;

    Player_UseprintWithWait(other, self, self.useprint_index_1, price);

    if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;

    if (other.points < price) {
        centerprint(other, STR_NOTENOUGHPOINTS);
        Sound_PlaySound(other, "sounds/misc/denybuy.wav", SOUND_TYPE_ENV_CHING, SOUND_PRIORITY_PLAYALWAYS);
        return;
    }

    Player_ChangeScore(other, -price, false);
    other.soe_has_widows_wine = true;
    other.soe_widows_charges = 4;

    SoE_FireEntityTargets(self);
};

void() soe_widows_wine_machine =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Buy Widow's Wine";

    if (self.cost <= 0)
        self.cost = 4000;

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_WidowsMachineTouch;
    self.use = SoE_WidowsMachineEnableUse;

    // spawnflag 1 exposes a powered machine for isolated testing.
    if (self.spawnflags & 1)
        self.state = 1;
    else
        self.state = 0;

    if (self.model != "")
        setmodel(self, self.model);
    else {
        setmodel(self, "models/sprites/sprkle.spr");
        setsize(self, '-20 -20 -28', '20 20 44');
        self.effects = EF_FULLBRIGHT;
    }
};

void() SoE_WidowsWineOnNewRound =
{
    if (!soe_active)
        return;

    entity player = find(world, classname, "player");
    while (player != world) {
        if (player.soe_has_widows_wine) {
            player.soe_widows_charges = player.soe_widows_charges + 2;
            if (player.soe_widows_charges > 4)
                player.soe_widows_charges = 4;
        }

        player = find(player, classname, "player");
    }
};

void(entity player) SoE_WidowsWineOnMaxAmmo =
{
    if (soe_active && player.soe_has_widows_wine)
        player.soe_widows_charges = 4;
};

void() SoE_ResetWidowsWine =
{
    entity player = find(world, classname, "player");
    while (player != world) {
        player.soe_has_widows_wine = false;
        player.soe_widows_charges = 0;
        player = find(player, classname, "player");
    }
};
