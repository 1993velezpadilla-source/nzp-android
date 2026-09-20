/*
    Shadows of Evil Tram + Rift runtime foundations.

    Mapper-facing and source-clean. The actual Morg City brushwork/path
    corners still come from an approved or clean-room map source.
*/

void(entity who, float value, float impacted_by_2x_points) Player_ChangeScore;

float soe_tram_current_station;
float soe_tram_destination;
float soe_tram_in_transit;
float soe_tram_route_sequence;

void() SoE_ResetTransportState =
{
    soe_tram_current_station = 0;
    soe_tram_destination = 0;
    soe_tram_in_transit = false;
    soe_tram_route_sequence = 0;

    // Three unique glyphs are selected from the nine-symbol pool each match.
    soe_tram_symbol_a = floor(random() * 9);
    soe_tram_symbol_b = floor(random() * 9);
    while (soe_tram_symbol_b == soe_tram_symbol_a)
        soe_tram_symbol_b = floor(random() * 9);

    soe_tram_symbol_c = floor(random() * 9);
    while (soe_tram_symbol_c == soe_tram_symbol_a || soe_tram_symbol_c == soe_tram_symbol_b)
        soe_tram_symbol_c = floor(random() * 9);
};

void() SoE_TramControllerUse =
{
    // A mapper can target this entity from station buttons. It intentionally
    // owns no movement itself: the actual tram brush remains a stock func_train
    // following path_corners, while this tracks SoE quest/game state.
    soe_tram_in_transit = true;
    soe_tram_route_sequence = soe_tram_route_sequence + 1;
    SoE_FireEntityTargets(self);
};

void() soe_tram_controller =
{
    self.use = SoE_TramControllerUse;

    if (self.style > 0)
        soe_tram_current_station = self.style;
};

void() SoE_TramButtonTouch =
{
    if (!SoE_PlayerCanUseEntity(self))
        return;

    if (other.soe_beast_active)
        return;

    if (soe_tram_in_transit)
        return;

    // style = station where this button lives
    // count = requested destination station
    if (self.style > 0 && soe_tram_current_station > 0 && self.style != soe_tram_current_station)
        return;

    if (self.count <= 0 || self.count == soe_tram_current_station)
        return;

    float tram_cost = self.cost;
    if (tram_cost <= 0)
        tram_cost = 500;

    Player_UseprintWithWait(other, self, self.useprint_index_1, tram_cost);

    if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;

    if (other.points < tram_cost) {
        centerprint(other, STR_NOTENOUGHPOINTS);
        Sound_PlaySound(other, "sounds/misc/denybuy.wav", SOUND_TYPE_ENV_CHING, SOUND_PRIORITY_PLAYALWAYS);
        return;
    }

    Player_ChangeScore(other, -tram_cost, false);
    soe_tram_destination = self.count;
    soe_tram_in_transit = true;
    soe_tram_route_sequence = soe_tram_route_sequence + 1;

    SoE_FireEntityTargets(self);
};

void() soe_tram_button =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Call Tram";

    if (self.cost <= 0)
        self.cost = 500;

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_TramButtonTouch;

    if (self.model != "")
        setmodel(self, self.model);
    else
        setsize(self, '-24 -24 -24', '24 24 32');
};

void() SoE_TramArrivalUse =
{
    if (self.style <= 0)
        return;

    soe_tram_current_station = self.style;
    soe_tram_destination = 0;
    soe_tram_in_transit = false;

    SoE_FireEntityTargets(self);
};

void() soe_tram_arrival =
{
    self.use = SoE_TramArrivalUse;
    self.solid = SOLID_NOT;
    self.movetype = MOVETYPE_NONE;
    setsize(self, '0 0 0', '0 0 0');
};

void() SoE_RiftPortalEnableUse =
{
    if (self.state == 0)
        self.state = 1;
};

void() SoE_RiftPortalTouch =
{
    if (other.classname != "player" || other.downed)
        return;

    // 0 = hidden/blocked behind Beast-opened geometry
    // 1 = exposed but not yet activated by a human
    // 2 = active portal
    if (self.state == 0)
        return;

    if (self.state == 1) {
        if (other.soe_beast_active || other.isBuying || !PlayerIsLooking(other, self))
            return;

        Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

        if (Player_UseButtonPressed(other, self) && !(other.semi_actions & SEMIACTION_USE)) {
            other.semi_actions |= SEMIACTION_USE;
            self.state = 2;
            SoE_FireEntityTargets(self);
        }
        return;
    }

    if (other.soe_beast_active)
        return;

    entity destination = find(world, targetname, self.target2);
    if (destination == world)
        return;

    setorigin(other, destination.origin);
    other.velocity = '0 0 0';

    if (destination.angles != '0 0 0') {
        other.angles = destination.angles;
        other.v_angle = destination.angles;
    }
};

void() soe_rift_portal =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Open Rift";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_RiftPortalTouch;
    self.use = SoE_RiftPortalEnableUse;

    // Spawnflag 1 is useful for clean-room map development: the Rift may
    // start already exposed for isolated testing.
    if (self.spawnflags & 1)
        self.state = 1;
    else
        self.state = 0;

    if (self.model != "")
        setmodel(self, self.model);
    else
        setsize(self, '-28 -28 -40', '28 28 40');
};

void() soe_rift_destination =
{
    self.solid = SOLID_NOT;
    self.movetype = MOVETYPE_NONE;
    setsize(self, '0 0 0', '0 0 0');
};
