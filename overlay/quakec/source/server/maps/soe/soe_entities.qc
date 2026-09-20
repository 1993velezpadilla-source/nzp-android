/*
    Shadows of Evil mapper-facing entities.

    These provide native NZ:P entity hooks so an approved/recreated Morg City
    .map can wire Beast interactions and ritual progression without hard-coded
    coordinates in QuakeC.
*/

void(entity who, entity active_ent, float useprint_index, float cost) Player_UseprintWithWait;
float(entity who, entity active_ent) Player_UseButtonPressed;
float(entity them, entity me) PlayerIsLooking;
void() SUB_UseTargets;

#define SOE_PICKUP_SUMMONING_KEY    1
#define SOE_PICKUP_LAWYERS_PEN      2
#define SOE_PICKUP_DETECTIVE_BADGE   3
#define SOE_PICKUP_TOUPEE            4
#define SOE_PICKUP_CHAMP_BELT        5

float soe_has_summoning_key;
float soe_has_lawyers_pen;
float soe_has_detective_badge;
float soe_has_toupee;
float soe_has_champ_belt;
float soe_ritual_active;

float(entity ent) SoE_PlayerCanUseEntity =
{
    if (!soe_active || other.classname != "player" || other.downed)
        return false;

    if (other.isBuying)
        return false;

    if (!PlayerIsLooking(other, ent))
        return false;

    return true;
};

void(entity ent) SoE_FireEntityTargets =
{
    entity old_self = self;
    entity old_activator = activator;

    self = ent;
    activator = other;
    SUB_UseTargets();

    self = old_self;
    activator = old_activator;
};

void() SoE_BeastPedestalTouch =
{
    if (!SoE_PlayerCanUseEntity(self))
        return;

    if (other.soe_beast_active || other.soe_beast_charges <= 0)
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (Player_UseButtonPressed(other, self) && !(other.semi_actions & SEMIACTION_USE)) {
        other.semi_actions |= SEMIACTION_USE;
        SoE_BeginBeast(other);
    }
};

void() soe_beast_pedestal =
{
    if (!self.useprint_string_1)
        self.useprint_string_1 = "Hold %b to Become the Beast";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_BeastPedestalTouch;

    if (self.model)
        setmodel(self, self.model);
    else
        setsize(self, '-24 -24 -16', '24 24 48');
};

void() SoE_BeastShockTouch =
{
    if (!SoE_PlayerCanUseEntity(self) || !other.soe_beast_active)
        return;

    if (self.activated && !(self.spawnflags & 1))
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (Player_UseButtonPressed(other, self) && !(other.semi_actions & SEMIACTION_USE)) {
        other.semi_actions |= SEMIACTION_USE;
        self.activated = true;
        SoE_FireEntityTargets(self);
    }
};

void() soe_beast_shock =
{
    if (!self.useprint_string_1)
        self.useprint_string_1 = "Hold %b to Shock";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_BeastShockTouch;

    if (self.model)
        setmodel(self, self.model);
    else
        setsize(self, '-20 -20 -20', '20 20 20');
};

void() SoE_BeastSmashTouch =
{
    if (!SoE_PlayerCanUseEntity(self) || !other.soe_beast_active)
        return;

    if (self.activated)
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (Player_UseButtonPressed(other, self) && !(other.semi_actions & SEMIACTION_USE)) {
        other.semi_actions |= SEMIACTION_USE;
        self.activated = true;
        SoE_BeastDrain(other, 3);
        SoE_FireEntityTargets(self);

        self.solid = SOLID_NOT;
        if (self.model)
            setmodel(self, "");
    }
};

void() soe_beast_smash =
{
    if (!self.useprint_string_1)
        self.useprint_string_1 = "Hold %b to Smash";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_BeastSmashTouch;

    if (self.model)
        setmodel(self, self.model);
    else
        setsize(self, '-24 -24 -24', '24 24 24');
};

void() SoE_BeastGrappleTouch =
{
    if (!SoE_PlayerCanUseEntity(self) || !other.soe_beast_active)
        return;

    entity destination = find(world, targetname, self.target);
    if (destination == world)
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (Player_UseButtonPressed(other, self) && !(other.semi_actions & SEMIACTION_USE)) {
        other.semi_actions |= SEMIACTION_USE;
        SoE_BeginGrapple(other, destination);
    }
};

void() soe_beast_grapple =
{
    if (!self.useprint_string_1)
        self.useprint_string_1 = "Hold %b to Grapple";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_BeastGrappleTouch;

    if (self.model)
        setmodel(self, self.model);
    else
        setsize(self, '-32 -32 -32', '32 32 32');
};

void() SoE_QuestPickupTouch =
{
    if (!SoE_PlayerCanUseEntity(self))
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;

    if (self.style == SOE_PICKUP_SUMMONING_KEY)
        soe_has_summoning_key = true;
    else if (self.style == SOE_PICKUP_LAWYERS_PEN)
        soe_has_lawyers_pen = true;
    else if (self.style == SOE_PICKUP_DETECTIVE_BADGE)
        soe_has_detective_badge = true;
    else if (self.style == SOE_PICKUP_TOUPEE)
        soe_has_toupee = true;
    else if (self.style == SOE_PICKUP_CHAMP_BELT)
        soe_has_champ_belt = true;

    SoE_FireEntityTargets(self);
    self.solid = SOLID_NOT;
    self.touch = SUB_Null;

    if (self.model)
        setmodel(self, "");
};

void() soe_quest_pickup =
{
    if (!self.useprint_string_1)
        self.useprint_string_1 = "Hold %b to Pick Up Quest Item";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_QuestPickupTouch;

    if (self.model)
        setmodel(self, self.model);
    else
        setsize(self, '-16 -16 -16', '16 16 16');
};

float(float ritual_id) SoE_RitualItemReady =
{
    if (!soe_has_summoning_key)
        return false;

    if (ritual_id == 1)
        return soe_has_lawyers_pen;
    if (ritual_id == 2)
        return soe_has_detective_badge;
    if (ritual_id == 3)
        return soe_has_toupee;
    if (ritual_id == 4)
        return soe_has_champ_belt;

    return false;
};

void() SoE_RitualComplete =
{
    soe_ritual_active = false;
    self.state = 2;

    if (self.style == 1)
        soe_ritual_nero = true;
    else if (self.style == 2)
        soe_ritual_jackie = true;
    else if (self.style == 3)
        soe_ritual_jessica = true;
    else if (self.style == 4)
        soe_ritual_floyd = true;

    SoE_MarkRitualComplete();

    // Completion targets can spawn a Gateworm pickup, alter arena doors,
    // stop Keeper spawners, play the completion FX, etc.
    SoE_FireEntityTargets(self);
};

void() SoE_RitualTouch =
{
    if (!SoE_PlayerCanUseEntity(self))
        return;

    if (self.state != 0 || soe_ritual_active)
        return;

    if (!SoE_RitualItemReady(self.style))
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (Player_UseButtonPressed(other, self) && !(other.semi_actions & SEMIACTION_USE)) {
        other.semi_actions |= SEMIACTION_USE;
        self.state = 1;
        soe_ritual_active = true;

        self.think = SoE_RitualComplete;
        self.nextthink = time + (self.wait > 0 ? self.wait : 15);
    }
};

void() soe_ritual_controller =
{
    if (!self.useprint_string_1)
        self.useprint_string_1 = "Hold %b to Begin Ritual";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_RitualTouch;
    self.state = 0;

    if (self.model)
        setmodel(self, self.model);
    else
        setsize(self, '-48 -48 -24', '48 48 48');
};
