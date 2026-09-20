/*
    Shadows of Evil - Rocket Shield / Goddard Apparatus runtime.

    Mapper contract:
      soe_shield_part style 1 = Footlight visor
      soe_shield_part style 2 = Canals base
      soe_shield_part style 4 = Waterfront rockets
      exactly one randomized spawn per category should be activated by map logic
      soe_shield_build_table = chosen construction table

    Input:
      impulse 34 = Rocket Shield boost
      Android HUD can map its shield button directly to this impulse.
*/

#define SOE_SHIELD_PART_FOOTLIGHT   1
#define SOE_SHIELD_PART_CANALS      2
#define SOE_SHIELD_PART_WATERFRONT  4
#define SOE_SHIELD_PART_ALL         7

float soe_shield_part_mask;
float soe_shield_built;
entity soe_shield_table_ent;

.float soe_has_shield;
.float soe_shield_durability;
.float soe_shield_max_durability;
.float soe_shield_boosts;
.float soe_shield_boost_max;
.float soe_shield_boost_until;
.float soe_shield_boost_cooldown;
.float soe_shield_boost_kills;
.float soe_shield_strike_streak;
.float soe_shield_goddard_unlocked;

void(entity victim, entity attacker, float damage, float d_style) DamageHandler;

void() SoE_ResetShield =
{
    soe_shield_part_mask = 0;
    soe_shield_built = false;
    soe_shield_table_ent = world;
};

void(entity player) SoE_ShieldGive =
{
    player.soe_has_shield = true;

    if (player.soe_shield_goddard_unlocked) {
        player.soe_shield_max_durability = 24;
        player.soe_shield_boost_max = 4;
    } else {
        player.soe_shield_max_durability = 16;
        player.soe_shield_boost_max = 3;
    }

    player.soe_shield_durability = player.soe_shield_max_durability;
    player.soe_shield_boosts = player.soe_shield_boost_max;
    player.soe_shield_boost_until = 0;
    player.soe_shield_boost_cooldown = 0;
    player.soe_shield_boost_kills = 0;
};

void(entity player) SoE_ShieldBreak =
{
    player.soe_has_shield = false;
    player.soe_shield_durability = 0;
    player.soe_shield_boosts = 0;
    player.soe_shield_boost_until = 0;
    player.soe_shield_boost_cooldown = time + 0.25;
    player.soe_shield_boost_kills = 0;

    // Goddard challenge progress is intentionally NOT reset by shield break.
    // The 12 successful boosts may span multiple shield pickups.
};

float(entity victim, entity attacker, float damage, float d_style) SoE_ShieldAbsorbDamage =
{
    if (!soe_active || victim.classname != "player" || !victim.soe_has_shield)
        return false;

    if (victim.soe_shield_boost_until > time)
        return false;

    // The back plate primarily protects against zombie melee from behind.
    if (d_style != DMG_TYPE_ZOMBIESWIPE || attacker == world)
        return false;

    makevectors(victim.v_angle);

    vector to_attacker = attacker.origin - victim.origin;
    to_attacker_z = 0;

    if (vlen(to_attacker) <= 0)
        return false;

    to_attacker = normalize(to_attacker);

    // Negative dot = attack came from behind the player's view direction.
    float rear_dot = to_attacker * v_forward;
    if (rear_dot > -0.15)
        return false;

    victim.soe_shield_durability = victim.soe_shield_durability - 1;

    if (victim.soe_shield_durability <= 0)
        SoE_ShieldBreak(victim);

    return true;
};

void() SoE_ShieldPartTouch =
{
    if (other.classname != "player" || other.downed)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    float part_bit = self.style;
    if (part_bit != SOE_SHIELD_PART_FOOTLIGHT &&
        part_bit != SOE_SHIELD_PART_CANALS &&
        part_bit != SOE_SHIELD_PART_WATERFRONT)
        return;

    if (soe_shield_part_mask & part_bit)
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;
    soe_shield_part_mask = soe_shield_part_mask | part_bit;

    SoE_FireEntityTargets(self);
    self.solid = SOLID_NOT;
    self.touch = SUB_Null;

    if (self.model != "")
        setmodel(self, "");
};

void() soe_shield_part =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Pick Up Shield Part";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_ShieldPartTouch;

    if (self.model != "")
        setmodel(self, self.model);
    else {
        setmodel(self, "models/sprites/sprkle.spr");
        setsize(self, '-10 -10 -8', '10 10 12');
        self.effects = EF_FULLBRIGHT;
    }
};

void() SoE_ShieldBuildTableTouch =
{
    if (other.classname != "player" || other.downed || other.isBuying)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    if (!soe_shield_built) {
        if (soe_shield_part_mask != SOE_SHIELD_PART_ALL)
            return;

        Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

        if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
            return;

        other.semi_actions |= SEMIACTION_USE;
        soe_shield_built = true;
        soe_shield_table_ent = self;
        self.state = 1;
        SoE_FireEntityTargets(self);
        return;
    }

    // Replacement shields remain available at the table where the build
    // occurred; each player carries at most one.
    if (soe_shield_table_ent != self || other.soe_has_shield)
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_2, 0);

    if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;
    SoE_ShieldGive(other);
    SoE_FireEntityTargets(self);
};

void() soe_shield_build_table =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Build Rocket Shield";
    if (self.useprint_string_2 == "")
        self.useprint_string_2 = "Hold %b to Take Rocket Shield";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.useprint_index_2 = Useprint_Register(self.useprint_string_2, self.useprint_color_2);

    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_ShieldBuildTableTouch;
    self.state = 0;

    if (self.model != "")
        setmodel(self, self.model);
    else
        setsize(self, '-28 -28 -18', '28 28 28');
};

float(entity ent) SoE_ShieldBoostCanKill =
{
    if (ent == world)
        return false;

    if (ent.classname != "ai_zombie")
        return false;

    if (!ent.iszomb)
        return false;

    if (ent.soe_special_type == SOE_SPECIAL_MARGWA)
        return false;

    return true;
};

void(entity player) SoE_ShieldFinishBoost =
{
    if (player.soe_shield_boost_until == 0)
        return;

    float kills = player.soe_shield_boost_kills;
    player.soe_shield_boost_until = 0;
    player.soe_shield_boost_kills = 0;

    if (kills >= 10) {
        player.soe_shield_strike_streak = player.soe_shield_strike_streak + 1;

        if (player.soe_shield_strike_streak >= 12 &&
            !player.soe_shield_goddard_unlocked) {
            player.soe_shield_goddard_unlocked = true;
            player.soe_shield_boost_max = 4;
            player.soe_shield_boosts = 4;
            player.soe_shield_max_durability = 24;
            player.soe_shield_durability = 24;

            centerprint(player, "Goddard Apparatus Unlocked");
        }
    } else {
        player.soe_shield_strike_streak = 0;
    }

    player.soe_shield_boost_cooldown = time + 0.35;
};

void(entity player) SoE_ShieldBoostTick =
{
    if (!player.soe_has_shield || player.soe_shield_boost_until <= 0)
        return;

    if (player.soe_shield_boost_until <= time) {
        SoE_ShieldFinishBoost(player);
        return;
    }

    makevectors(player.v_angle);
    player.velocity_x = v_forward_x * 620;
    player.velocity_y = v_forward_y * 620;

    entity ent = findradius(player.origin, 72);
    while (ent != world) {
        entity next = ent.chain;

        if (SoE_ShieldBoostCanKill(ent)) {
            player.soe_shield_boost_kills = player.soe_shield_boost_kills + 1;

            // Attribute the kill to the player and bypass round-scaled health.
            DamageHandler(ent, player, 999999, DMG_TYPE_OTHER);
        }

        ent = next;
    }
};

void() SoE_ShieldBoostInput =
{
    if (!soe_active || self.classname != "player")
        return;

    if (!self.soe_has_shield || self.downed || self.isBuying ||
        self.soe_shield_boost_cooldown > time ||
        self.soe_shield_boost_until > time)
        return;

    if (self.soe_shield_boosts <= 0)
        return;

    self.soe_shield_boosts = self.soe_shield_boosts - 1;
    self.soe_shield_boost_kills = 0;
    self.soe_shield_boost_until = time + 0.68;

    makevectors(self.v_angle);
    self.velocity = v_forward * 620;
};

void() SoE_ShieldFrame =
{
    if (!soe_active)
        return;

    entity player = find(world, classname, "player");
    while (player != world) {
        if (player.soe_shield_boost_until > 0)
            SoE_ShieldBoostTick(player);

        player = find(player, classname, "player");
    }
};
