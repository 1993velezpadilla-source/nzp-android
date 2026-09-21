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
void(entity ent) SoE_FireEntityTargets;

#define SOE_PICKUP_SUMMONING_KEY    1
#define SOE_PICKUP_LAWYERS_PEN      2
#define SOE_PICKUP_DETECTIVE_BADGE   3
#define SOE_PICKUP_TOUPEE            4
#define SOE_PICKUP_CHAMP_BELT        5
#define SOE_PICKUP_MARGWA_HEART       6
#define SOE_PICKUP_XENOMATTER          7
#define SOE_PICKUP_MARGWA_TENTACLE     8

void() SoE_PoweredDoorUse =
{
    if (self.activated)
        return;

    self.activated = true;
    self.state = STATE_TOP;
    self.solid = SOLID_NOT;
    self.use = SUB_Null;

    if (self.model != "")
        setmodel(self, "");

    // Custom SoE blockers may also be used as NZ:P zoning gates. Once the
    // physical blocker opens, immediately refresh adjacent-zone spawn state.
    if (self.wayTarget != "")
        Zoning_UpdateAllZones(true);

    SoE_FireEntityTargets(self);
};

void() soe_powered_door =
{
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_BSP;
    self.use = SoE_PoweredDoorUse;
    self.activated = false;
    self.state = STATE_BOTTOM;

    if (self.model != "")
        setmodel(self, self.model);
};

.string soe_reveal_brush_model;

void() SoE_RevealBrushUse =
{
    if (self.activated)
        return;

    self.activated = true;
    self.solid = SOLID_BSP;

    if (self.soe_reveal_brush_model != "")
        setmodel(self, self.soe_reveal_brush_model);

    SoE_FireEntityTargets(self);
};

void() soe_reveal_wall =
{
    self.movetype = MOVETYPE_NONE;
    self.activated = false;
    self.use = SoE_RevealBrushUse;

    // Brush entities enter QuakeC with their generated *N model string.
    // Cache it before hiding the geometry so it can be restored by Gateworm
    // progression without spawning/reallocating geometry at runtime.
    self.soe_reveal_brush_model = self.model;
    self.solid = SOLID_NOT;
    setmodel(self, "");
};

void() SoE_WallrunTouch =
{
    if (other.classname != "player" || other.downed || other.soe_beast_active)
        return;

    makevectors(self.angles);

    // The player must already be committing to the intended direction.
    float along = other.velocity * v_forward;
    if (along < 35)
        return;

    float run_speed = self.speed;
    if (run_speed <= 0)
        run_speed = 420;

    float lift = self.wait;
    if (lift <= 0)
        lift = 28;

    other.velocity_x = v_forward_x * run_speed;
    other.velocity_y = v_forward_y * run_speed;

    if (other.velocity_z < lift)
        other.velocity_z = lift;
};

void() soe_wallrun_volume =
{
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_WallrunTouch;

    if (self.model != "")
        setmodel(self, self.model);
};

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

    // During the finale, Beast Mode is re-enabled only through Margwa-relit
    // curse torches, not these normal pedestals.
    if (soe_finale_active)
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
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Become the Beast";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_BeastPedestalTouch;

    if (self.model != "")
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
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Shock";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_BeastShockTouch;

    if (self.model != "")
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
        if (self.model != "")
            setmodel(self, "");
    }
};

void() soe_beast_smash =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Smash";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_BeastSmashTouch;

    if (self.model != "")
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
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Grapple";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_BeastGrappleTouch;

    if (self.model != "")
        setmodel(self, self.model);
    else
        setsize(self, '-32 -32 -32', '32 32 32');
};

.float soe_required_hits;
.float soe_target_hits;

void() SoE_TargetCounterUse =
{
    if (!soe_active || self.soe_target_hits >= self.soe_required_hits)
        return;

    self.soe_target_hits = self.soe_target_hits + 1;

    if (self.soe_target_hits < self.soe_required_hits)
        return;

    SoE_FireEntityTargets(self);
    self.use = SUB_Null;
};

void() soe_target_counter =
{
    if (self.soe_required_hits <= 0)
        self.soe_required_hits = 2;

    self.soe_target_hits = 0;
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_NOT;
    self.use = SoE_TargetCounterUse;
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
    else if (self.style == SOE_PICKUP_MARGWA_HEART)
        soe_has_margwa_heart = true;
    else if (self.style == SOE_PICKUP_XENOMATTER) {
        soe_has_xenomatter = true;
        soe_xenomatter_drop_active = false;
    }
    else if (self.style == SOE_PICKUP_MARGWA_TENTACLE)
        soe_has_margwa_tentacle = true;

    SoE_FireEntityTargets(self);
    self.solid = SOLID_NOT;
    self.touch = SUB_Null;

    if (self.model != "")
        setmodel(self, "");
};

void() SoE_QuestPickupEnableUse =
{
    // Mapper contract: spawnflag 1 means the pickup starts dormant and only
    // becomes collectible after another entity targets it (for example the
    // Summoning Key truck/crate Beast smash).
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_QuestPickupTouch;
    self.use = SUB_Null;
};

void() soe_quest_pickup =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Pick Up Quest Item";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;

    if (self.model != "")
        setmodel(self, self.model);
    else
        setsize(self, '-16 -16 -16', '16 16 16');

    if (self.spawnflags & 1) {
        self.solid = SOLID_NOT;
        self.touch = SUB_Null;
        self.use = SoE_QuestPickupEnableUse;
    } else {
        self.solid = SOLID_TRIGGER;
        self.touch = SoE_QuestPickupTouch;
    }
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

    if (self.style == 1) {
        soe_ritual_nero = true;
        soe_has_lawyers_pen = false;
    }
    else if (self.style == 2) {
        soe_ritual_jackie = true;
        soe_has_detective_badge = false;
    }
    else if (self.style == 3) {
        soe_ritual_jessica = true;
        soe_has_toupee = false;
    }
    else if (self.style == 4) {
        soe_ritual_floyd = true;
        soe_has_champ_belt = false;
    }

    SoE_RitualRuntimeComplete(self);
    SoE_MarkRitualComplete();

    // The integrated Sacred Place entrance is physically and zonally sealed
    // until all four district rituals have completed.
    if (soe_gateworm_count == 4) {
        entity sacred_gate = find(world, targetname, "soe_full_sacred_access");
        if (sacred_gate != world && sacred_gate.use) {
            entity old_self = self;
            self = sacred_gate;
            self.use();
            self = old_self;
        }
    }

    // Completion targets alter arena doors / sacrifice FX / room state.
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

        SoE_RitualRuntimeStart(self);

        self.think = SoE_RitualComplete;
        self.nextthink = time + (self.wait > 0 ? self.wait : 20);
    }
};

void() soe_ritual_controller =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Begin Ritual";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_RitualTouch;
    self.state = 0;

    if (self.model != "")
        setmodel(self, self.model);
    else
        setsize(self, '-48 -48 -24', '48 48 48');
};
