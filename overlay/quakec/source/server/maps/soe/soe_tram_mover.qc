/*
    Shadows of Evil - physical Tram mover + symbol-window presentation.

    G7 uses a deterministic MOVETYPE_PUSH brush that always travels through
    Junction between stations. This keeps rider collision stable and gives the
    finale one exact crossing event for the giant Gateworm.
*/

void(vector tdest, float tspeed, void() func) SUB_CalcMove;

.float soe_tram_move_destination;
.vector soe_tram_model_mins;
.float soe_tram_symbol_value;

entity(float station_id) SoE_FindTramStationMarker =
{
    entity marker = find(world, classname, "soe_tram_station_marker");

    while (marker != world) {
        if (marker.style == station_id)
            return marker;

        marker = find(marker, classname, "soe_tram_station_marker");
    }

    return world;
};

entity() SoE_FindTramHubMarker =
{
    return find(world, classname, "soe_tram_hub_marker");
};

void() SoE_TramMoverArrived =
{
    float arrived = self.soe_tram_move_destination;
    entity marker = SoE_FindTramStationMarker(arrived);

    // A late SUB_CalcMove callback from an aborted/older ride must not
    // overwrite the logical station of a newer Tram cycle.
    if (!soe_tram_in_transit ||
        arrived <= 0 ||
        soe_tram_destination != arrived) {
        self.soe_tram_move_destination = 0;
        self.velocity = '0 0 0';
        return;
    }

    soe_tram_current_station = arrived;
    soe_tram_destination = 0;
    soe_tram_in_transit = false;
    self.soe_tram_move_destination = 0;
    self.velocity = '0 0 0';

    if (marker != world)
        SoE_FireEntityTargets(marker);
};

void() SoE_TramMoverAtHub =
{
    entity hub = SoE_FindTramHubMarker();

    if (hub != world)
        SoE_FireEntityTargets(hub);

    entity destination = SoE_FindTramStationMarker(self.soe_tram_move_destination);
    if (destination == world) {
        // The destination marker may disappear between departure and the hub.
        // Abort with the same complete cleanup used by pre-departure failure.
        soe_tram_in_transit = false;
        soe_tram_destination = 0;
        self.soe_tram_move_destination = 0;
        self.velocity = '0 0 0';
        return;
    }

    SUB_CalcMove(
        destination.origin - self.soe_tram_model_mins,
        self.speed,
        SoE_TramMoverArrived
    );
};

void() SoE_TramMoverUse =
{
    if (!soe_tram_in_transit ||
        soe_tram_destination <= 0 ||
        self.soe_tram_move_destination > 0)
        return;

    entity destination = SoE_FindTramStationMarker(soe_tram_destination);
    entity hub = SoE_FindTramHubMarker();

    if (destination == world || hub == world) {
        // A malformed/missing path marker must not leave the global Tram
        // state permanently locked in-transit. Abort this ride cleanly so a
        // corrected/alternate call can be attempted instead of soft-locking.
        soe_tram_in_transit = false;
        soe_tram_destination = 0;
        self.soe_tram_move_destination = 0;
        self.velocity = '0 0 0';
        return;
    }

    self.soe_tram_move_destination = soe_tram_destination;

    SUB_CalcMove(
        hub.origin - self.soe_tram_model_mins,
        self.speed,
        SoE_TramMoverAtHub
    );
};

void() SoE_TramMoverInit =
{
    entity marker = SoE_FindTramStationMarker(self.style);

    if (marker == world) {
        self.nextthink = time + 0.25;
        return;
    }

    setorigin(self, marker.origin - self.soe_tram_model_mins);
    soe_tram_current_station = self.style;
    soe_tram_destination = 0;
    soe_tram_in_transit = false;
    self.soe_tram_move_destination = 0;
    self.think = SUB_Null;
    self.nextthink = 0;
};

void() soe_tram_mover =
{
    // Vril's SV_HullForEntity requires SOLID_BSP entities to have
    // MOVETYPE_PUSH before any hull query can touch them. Keep the physical
    // tram non-solid while it is being initialized, then arm BSP collision
    // only after setmodel/setorigin has completed.
    self.movetype = MOVETYPE_PUSH;
    self.solid = SOLID_NOT;
    self.use = SoE_TramMoverUse;

    if (self.speed <= 0)
        self.speed = 240;

    if (self.model != "")
        setmodel(self, self.model);

    self.soe_tram_model_mins = self.mins;
    self.soe_tram_move_destination = 0;
    self.solid = SOLID_BSP;

    self.think = SoE_TramMoverInit;
    self.nextthink = time + 0.25;
};

void() soe_tram_station_marker =
{
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_NOT;
    setsize(self, '0 0 0', '0 0 0');
};

void() soe_tram_hub_marker =
{
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_NOT;
    setsize(self, '0 0 0', '0 0 0');
};

void() SoE_TramSymbolResolve =
{
    float symbol = -1;

    // style: 1 Canal, 2 Footlight, 3 Waterfront.
    if (self.style == 1)
        symbol = soe_tram_symbol_a;
    else if (self.style == 2)
        symbol = soe_tram_symbol_b;
    else if (self.style == 3)
        symbol = soe_tram_symbol_c;

    if (symbol < 0)
        return;

    self.soe_tram_symbol_value = symbol;

    // A future cleared nine-frame glyph sprite/model can expose the selected
    // glyph directly through frame. The fallback is a bright clean marker.
    if (self.model != "") {
        setmodel(self, self.model);
        self.frame = symbol;
    } else {
        setmodel(self, "models/sprites/sprkle.spr");
        self.frame = 0;
    }

    self.effects = EF_FULLBRIGHT;
    self.think = SUB_Null;
    self.nextthink = 0;
};

void() soe_tram_symbol_window =
{
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_NOT;
    self.soe_tram_symbol_value = -1;
    self.think = SoE_TramSymbolResolve;
    self.nextthink = time + 0.30;
};
