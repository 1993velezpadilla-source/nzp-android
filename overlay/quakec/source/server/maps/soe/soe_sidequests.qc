/*
    Shadows of Evil - side Easter egg runtime.

    Current systems:
      Margwa Mask / Margwa Head:
        1. kill six Margwas globally
        2. shoot six hidden heart targets only while riding the Tram
        3. complete all six within at most two Tram rides
        4. collect/equip the reusable mask pickup
        5. mask protects against the Margwa slam path

    The six target transforms and mask pickup candidates are mapper data so
    exact clean-room Morg City placement can be refined without changing code.
*/

entity soe_margwa_mask_pickup_ent;

float(float heart_id) SoE_MargwaMaskHeartBit =
{
    if (heart_id == 1) return 1;
    if (heart_id == 2) return 2;
    if (heart_id == 3) return 4;
    if (heart_id == 4) return 8;
    if (heart_id == 5) return 16;
    if (heart_id == 6) return 32;
    return 0;
};

void(entity heart) SoE_MargwaMaskShowHeart =
{
    if (heart == world)
        return;

    if (heart.oldmodel != "")
        setmodel(heart, heart.oldmodel);
    else
        setmodel(heart, "models/sprites/sprkle.spr");

    heart.solid = SOLID_BBOX;
    heart.takedamage = DAMAGE_YES;
    heart.effects = EF_FULLBRIGHT;
    heart.health = 1;
};

void(entity heart) SoE_MargwaMaskHideHeart =
{
    if (heart == world)
        return;

    heart.solid = SOLID_NOT;
    heart.takedamage = DAMAGE_NO;
    heart.effects = 0;
    setmodel(heart, "");
};

void() SoE_MargwaMaskResetHeartAttempt =
{
    soe_margwa_mask_heart_mask = 0;
    soe_margwa_mask_first_route = -1;

    entity heart = find(world, classname, "soe_margwa_mask_heart");
    while (heart != world) {
        SoE_MargwaMaskShowHeart(heart);
        heart = find(heart, classname, "soe_margwa_mask_heart");
    }
};

void() SoE_MargwaMaskEnableTargets =
{
    if (soe_margwa_mask_complete)
        return;

    soe_margwa_mask_targets_enabled = true;
    SoE_MargwaMaskResetHeartAttempt();
};

void(entity margwa) SoE_MargwaMaskOnMargwaKilled =
{
    if (!soe_active || soe_margwa_mask_complete)
        return;

    // soe_margwa_kills is incremented immediately before this callback.
    if (soe_margwa_kills >= 6 && !soe_margwa_mask_targets_enabled)
        SoE_MargwaMaskEnableTargets();
};

void() SoE_MargwaMaskOnTramRideStart =
{
    if (!soe_active ||
        !soe_margwa_mask_targets_enabled ||
        soe_margwa_mask_complete)
        return;

    // first_route is captured on the first successfully hit target. Starting
    // a third ride after that attempt restores all six targets.
    if (soe_margwa_mask_first_route >= 0 &&
        soe_tram_route_sequence > soe_margwa_mask_first_route + 1)
        SoE_MargwaMaskResetHeartAttempt();
};

float() SoE_AllActivePlayersHaveMargwaMask =
{
    entity player = find(world, classname, "player");
    float found = false;

    while (player != world) {
        if (!player.is_spectator) {
            found = true;

            if (!player.soe_has_margwa_mask)
                return false;
        }

        player = find(player, classname, "player");
    }

    return found;
};

void() SoE_MargwaMaskPickupTouch =
{
    if (other.classname != "player" ||
        other.downed ||
        other.isBuying ||
        other.soe_has_margwa_mask)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) ||
        (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;
    other.soe_has_margwa_mask = true;

    SoE_FireEntityTargets(self);

    // In co-op the same unlocked mask location remains usable until every
    // currently active player has equipped it.
    if (SoE_AllActivePlayersHaveMargwaMask()) {
        soe_margwa_mask_pickup_ent = world;
        remove(self);
    }
};

entity() SoE_FindRandomMargwaMaskSpawn =
{
    entity marker = find(world, classname, "soe_margwa_mask_spawn");
    entity chosen = world;
    float seen = 0;

    while (marker != world) {
        seen = seen + 1;

        if (random() < (1 / seen))
            chosen = marker;

        marker = find(marker, classname, "soe_margwa_mask_spawn");
    }

    return chosen;
};

void() SoE_SpawnMargwaMaskPickup =
{
    if (soe_margwa_mask_pickup_ent != world)
        return;

    entity marker = SoE_FindRandomMargwaMaskSpawn();
    if (marker == world)
        return;

    entity pickup = spawn();
    pickup.classname = "soe_margwa_mask_pickup";
    pickup.movetype = MOVETYPE_NONE;
    pickup.solid = SOLID_TRIGGER;
    pickup.touch = SoE_MargwaMaskPickupTouch;
    pickup.effects = EF_FULLBRIGHT;
    pickup.useprint_string_1 = "Hold %b to Equip Margwa Mask";
    pickup.useprint_index_1 = Useprint_Register(pickup.useprint_string_1, '1 1 1');

    // Legal/native placeholder until a cleared original mask prop is used.
    setmodel(pickup, "models/sprites/sprkle.spr");
    setsize(pickup, '-12 -12 -14', '12 12 18');
    setorigin(pickup, marker.origin + '0 0 16');

    soe_margwa_mask_pickup_ent = pickup;
};

float(entity victim, entity attacker, float damage, float d_style) SoE_HandleMargwaMaskHeartDamage =
{
    if (!soe_active || victim.classname != "soe_margwa_mask_heart")
        return false;

    // Heart targets can only be completed from a moving Tram by a player.
    if (!soe_margwa_mask_targets_enabled ||
        soe_margwa_mask_complete ||
        !soe_tram_in_transit ||
        attacker.classname != "player" ||
        damage <= 0)
        return true;

    float heart_bit = SoE_MargwaMaskHeartBit(victim.style);
    if (heart_bit == 0 || (soe_margwa_mask_heart_mask & heart_bit))
        return true;

    if (soe_margwa_mask_first_route < 0)
        soe_margwa_mask_first_route = soe_tram_route_sequence;

    // Defensive guard if a mapper or alternate tram path somehow bypassed the
    // ride-start callback.
    if (soe_tram_route_sequence > soe_margwa_mask_first_route + 1) {
        SoE_MargwaMaskResetHeartAttempt();
        soe_margwa_mask_first_route = soe_tram_route_sequence;
    }

    soe_margwa_mask_heart_mask = soe_margwa_mask_heart_mask | heart_bit;
    SoE_MargwaMaskHideHeart(victim);

    if (soe_margwa_mask_heart_mask == 63) {
        soe_margwa_mask_complete = true;
        soe_margwa_mask_targets_enabled = false;
        SoE_SpawnMargwaMaskPickup();
    }

    return true;
};

void() soe_margwa_mask_heart =
{
    if (self.style < 1 || self.style > 6)
        objerror("soe_margwa_mask_heart requires style 1..6\n");

    if (self.model != "") {
        self.oldmodel = self.model;
        precache_model(self.model);
    } else {
        self.oldmodel = "models/sprites/sprkle.spr";
        precache_model(self.oldmodel);
    }

    self.classname = "soe_margwa_mask_heart";
    self.movetype = MOVETYPE_NONE;
    setsize(self, '-12 -8 -12', '12 8 12');

    if (soe_margwa_mask_targets_enabled)
        SoE_MargwaMaskShowHeart(self);
    else
        SoE_MargwaMaskHideHeart(self);
};

void() soe_margwa_mask_spawn =
{
    self.solid = SOLID_NOT;
    self.movetype = MOVETYPE_NONE;
    setsize(self, '0 0 0', '0 0 0');
};


/* -------------------------------------------------------------------------
   Shared sidequest state
   ------------------------------------------------------------------------- */

float soe_sal_ticket_revealed;
float soe_sal_ticket_claimed;

float soe_snakeskin_clock_mask;
float soe_snakeskin_activated;
float soe_snakeskin_instrumental;

float soe_cold_cash_part_mask;
float soe_cold_cash_activated;

.float soe_side_interactions;

void(entity who, float value, float impacted_by_2x_points) Player_ChangeScore;

void() SoE_ResetSideQuests =
{
    soe_margwa_mask_pickup_ent = world;

    soe_sal_ticket_revealed = false;
    soe_sal_ticket_claimed = false;

    soe_snakeskin_clock_mask = 0;
    soe_snakeskin_activated = false;
    soe_snakeskin_instrumental = false;

    soe_cold_cash_part_mask = 0;
    soe_cold_cash_activated = false;
};

/* -------------------------------------------------------------------------
   Sal DeLuca / Chang's Laundry free 500 points
   ------------------------------------------------------------------------- */

void() SoE_SalTicketTouch =
{
    if (other.classname != "player" ||
        other.downed ||
        other.isBuying ||
        soe_sal_ticket_claimed)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) ||
        (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;
    soe_sal_ticket_claimed = true;

    Player_ChangeScore(other, 500, false);
    SoE_FireEntityTargets(self);
    remove(self);
};

entity() SoE_FindSalTicketSpawn =
{
    return find(world, classname, "soe_sal_ticket_spawn");
};

void() SoE_RevealSalTicket =
{
    if (soe_sal_ticket_revealed || soe_sal_ticket_claimed)
        return;

    entity marker = SoE_FindSalTicketSpawn();
    if (marker == world)
        return;

    entity ticket = spawn();
    ticket.classname = "soe_sal_ticket";
    ticket.movetype = MOVETYPE_NONE;
    ticket.solid = SOLID_TRIGGER;
    ticket.touch = SoE_SalTicketTouch;
    ticket.effects = EF_FULLBRIGHT;
    ticket.useprint_string_1 = "Hold %b to Collect Laundry Ticket";
    ticket.useprint_index_1 = Useprint_Register(ticket.useprint_string_1, '1 1 1');

    setmodel(ticket, "models/sprites/sprkle.spr");
    setsize(ticket, '-8 -8 -4', '8 8 8');
    setorigin(ticket, marker.origin);

    soe_sal_ticket_revealed = true;
};

void() SoE_SalLaundryTriggerTouch =
{
    if (soe_sal_ticket_revealed || soe_sal_ticket_claimed)
        return;

    // NZ:P's hand-thrown frag uses projectile_grenade. A future Widow's Wine
    // grenade can call SoE_RevealSalTicket directly from its detonation hook.
    if (other.classname == "projectile_grenade")
        SoE_RevealSalTicket();
};

void() soe_sal_laundry_trigger =
{
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_SalLaundryTriggerTouch;

    if (self.model != "")
        setmodel(self, self.model);
    else
        setsize(self, '-36 -16 -30', '36 16 30');
};

void() soe_sal_ticket_spawn =
{
    self.solid = SOLID_NOT;
    self.movetype = MOVETYPE_NONE;
    setsize(self, '0 0 0', '0 0 0');
};

/* -------------------------------------------------------------------------
   Snakeskin Boots - three wooden clock/speaker interactions.

   No copyrighted Treyarch/Jack Wall audio is bundled here. Completing the
   interaction fires mapper targets for a cleared/project-owned music event.
   ------------------------------------------------------------------------- */

float(float clock_id) SoE_SnakeskinClockBit =
{
    if (clock_id == 1) return 1;
    if (clock_id == 2) return 2;
    if (clock_id == 3) return 4;
    return 0;
};

void(entity relay, entity player) SoE_SnakeskinFireRelay =
{
    if (relay == world)
        return;

    string saved_target = relay.target;

    if (soe_snakeskin_instrumental && relay.target2 != "")
        relay.target = relay.target2;

    entity old_self = self;
    entity old_other = other;

    self = relay;
    other = player;
    SoE_FireEntityTargets(relay);

    self = old_self;
    other = old_other;
    relay.target = saved_target;
};

void() SoE_SnakeskinClockTouch =
{
    if (soe_snakeskin_activated ||
        other.classname != "player" ||
        other.downed ||
        other.isBuying)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    float clock_bit = SoE_SnakeskinClockBit(self.style);
    if (clock_bit == 0)
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) ||
        (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;
    self.soe_side_interactions = self.soe_side_interactions + 1;

    // Community documentation describes an instrumental variant when one
    // clock is interacted with twice before the three-unique-clock completion.
    if ((soe_snakeskin_clock_mask & clock_bit) &&
        self.soe_side_interactions >= 2)
        soe_snakeskin_instrumental = true;

    soe_snakeskin_clock_mask = soe_snakeskin_clock_mask | clock_bit;

    if (soe_snakeskin_clock_mask == 7) {
        soe_snakeskin_activated = true;

        entity relay = find(world, classname, "soe_snakeskin_relay");
        SoE_SnakeskinFireRelay(relay, other);
    }
};

void() soe_snakeskin_clock =
{
    if (self.style < 1 || self.style > 3)
        objerror("soe_snakeskin_clock requires style 1..3\n");

    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Interact";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_SnakeskinClockTouch;
    self.soe_side_interactions = 0;

    if (self.model != "")
        setmodel(self, self.model);
    else
        setsize(self, '-8 -8 -6', '8 8 10');
};

void() soe_snakeskin_relay =
{
    self.solid = SOLID_NOT;
    self.movetype = MOVETYPE_NONE;
    setsize(self, '0 0 0', '0 0 0');
};

/* -------------------------------------------------------------------------
   Cold Hard Cash - three stage-equipment pickups + Burlesque stage trigger.

   target on soe_cold_cash_stage should point at project-owned/cleared audio
   or another presentation event.
   ------------------------------------------------------------------------- */

float(float part_id) SoE_ColdCashPartBit =
{
    if (part_id == 1) return 1; // microphone stand / Nero
    if (part_id == 2) return 2; // cable / Canals
    if (part_id == 3) return 4; // microphone / Underground
    return 0;
};

void() SoE_ColdCashRevealStage =
{
    entity stage = find(world, classname, "soe_cold_cash_stage");

    while (stage != world) {
        stage.solid = SOLID_TRIGGER;

        if (stage.oldmodel != "")
            setmodel(stage, stage.oldmodel);

        stage = find(stage, classname, "soe_cold_cash_stage");
    }
};

void() SoE_ColdCashPartTouch =
{
    if (other.classname != "player" ||
        other.downed ||
        other.isBuying ||
        soe_cold_cash_activated)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    float part_bit = SoE_ColdCashPartBit(self.style);
    if (part_bit == 0 || (soe_cold_cash_part_mask & part_bit))
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) ||
        (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;
    soe_cold_cash_part_mask = soe_cold_cash_part_mask | part_bit;

    self.solid = SOLID_NOT;
    self.touch = SUB_Null;
    if (self.model != "")
        setmodel(self, "");

    SoE_FireEntityTargets(self);

    if (soe_cold_cash_part_mask == 7)
        SoE_ColdCashRevealStage();
};

void() soe_cold_cash_part =
{
    if (self.style < 1 || self.style > 3)
        objerror("soe_cold_cash_part requires style 1..3\n");

    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Pick Up Stage Equipment";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_ColdCashPartTouch;

    if (self.model != "")
        setmodel(self, self.model);
    else {
        setmodel(self, "models/sprites/sprkle.spr");
        setsize(self, '-8 -8 -8', '8 8 10');
        self.effects = EF_FULLBRIGHT;
    }
};

void() SoE_ColdCashStageTouch =
{
    if (soe_cold_cash_activated ||
        soe_cold_cash_part_mask != 7 ||
        other.classname != "player" ||
        other.downed ||
        other.isBuying)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) ||
        (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;
    soe_cold_cash_activated = true;
    SoE_FireEntityTargets(self);
};

void() soe_cold_cash_stage =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Use Microphone";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.touch = SoE_ColdCashStageTouch;

    if (self.model != "") {
        self.oldmodel = self.model;
        setmodel(self, "");
    }

    self.solid = SOLID_NOT;

    if (self.model == "" && self.oldmodel == "")
        setsize(self, '-16 -16 -18', '16 16 24');
};
