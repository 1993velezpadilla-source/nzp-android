/*
    Shadows of Evil - Chain Trap runtime.

    Mapper:
      soe_chain_trap_volume targetname = unique volume name
      optional target = marker on far side for Margwa bypass
      soe_chain_trap_switch target = that volume targetname
*/

.float soe_chain_active;
.float soe_chain_extended;
.float soe_chain_until;
.float soe_chain_next_cycle;
.float soe_chain_cooldown_until;

void(entity victim, entity attacker, float damage, float d_style) DamageHandler;
void(entity who, float value, float impacted_by_2x_points) Player_ChangeScore;

void() SoE_ChainTrapVolumeThink =
{
    if (!self.soe_chain_active)
        return;

    if (time >= self.soe_chain_until) {
        self.soe_chain_active = false;
        self.soe_chain_extended = false;
        self.effects = 0;
        self.think = SUB_Null;
        self.nextthink = 0;
        return;
    }

    self.soe_chain_extended = !self.soe_chain_extended;

    if (self.soe_chain_extended) {
        self.effects = EF_FULLBRIGHT;
        self.nextthink = time + 1.75;
    } else {
        self.effects = 0;
        self.nextthink = time + 0.55;
    }

    self.think = SoE_ChainTrapVolumeThink;
};

void() SoE_ChainTrapTouch =
{
    if (!self.soe_chain_active || !self.soe_chain_extended)
        return;

    if (other.classname == "ai_zombie") {
        if (other.soe_special_type == SOE_SPECIAL_MARGWA) {
            entity exit_marker = world;
            if (self.target != "")
                exit_marker = find(world, targetname, self.target);

            if (exit_marker != world) {
                setorigin(other, exit_marker.origin);
                other.velocity = '0 0 0';
            }

            return;
        }

        if (other.aistatus == "1")
            DamageHandler(other, world, 999999, DMG_TYPE_OTHER);

        return;
    }

    if (other.classname == "ai_dog" ||
        other.classname == "soe_parasite" ||
        other.classname == "soe_elemental" ||
        other.classname == "soe_keeper") {
        DamageHandler(other, world, 999999, DMG_TYPE_OTHER);
    }
};

void() SoE_ChainTrapUse =
{
    if (self.soe_chain_active)
        return;

    self.soe_chain_active = true;
    self.soe_chain_extended = true;
    self.soe_chain_until = time + 30;
    self.soe_chain_next_cycle = time + 1.75;
    self.effects = EF_FULLBRIGHT;
    self.think = SoE_ChainTrapVolumeThink;
    self.nextthink = self.soe_chain_next_cycle;
};

void() soe_chain_trap_volume =
{
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_ChainTrapTouch;
    self.use = SoE_ChainTrapUse;
    self.soe_chain_active = false;
    self.soe_chain_extended = false;

    if (self.model != "")
        setmodel(self, self.model);
    else
        setsize(self, '-48 -12 -28', '48 12 36');
};

void() SoE_ChainTrapSwitchTouch =
{
    if (other.classname != "player" || other.downed || other.isBuying)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    entity volume = world;
    if (self.target != "")
        volume = find(world, targetname, self.target);

    if (volume == world || volume.classname != "soe_chain_trap_volume")
        return;

    if (volume.soe_chain_active || self.soe_chain_cooldown_until > time)
        return;

    float price = self.cost;
    if (price <= 0)
        price = 1000;

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

    entity old_self = self;
    self = volume;
    SoE_ChainTrapUse();
    self = old_self;

    float cooldown = self.wait;
    if (cooldown <= 0)
        cooldown = 30;
    self.soe_chain_cooldown_until = time + 30 + cooldown;

    SoE_FireEntityTargets(self);
};

void() soe_chain_trap_switch =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Activate Chain Trap";

    if (self.cost <= 0)
        self.cost = 1000;

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_ChainTrapSwitchTouch;

    if (self.model != "")
        setmodel(self, self.model);
    else
        setsize(self, '-16 -12 -18', '16 12 22');
};
