/*
    Shadows of Evil - local perk power + broken-bottle indicators.

    For the rotating trio, place three native NZ:P "perk_random" entities:
      spawnflags = 14  // Jugger-Nog (2) | Speed Cola (4) | Double Tap (8)

    NZ:P's native perk_random allocator guarantees each of the three appears
    once. Give each slot a targetname so its Beast power panel can reference
    the machine after the random assignment.

    soe_perk_bottle_indicator:
      place beside the corresponding district entrance in Junction
      `target` = randomized perk slot targetname (optional)
      model may supply 3 skins: 0 Jug red, 1 Speed green, 2 Double Tap orange
*/

.float soe_perk_kind;

void(entity who) Turn_PerkLight_On;

entity(entity panel) SoE_FindTargetedPerk =
{
    if (panel.target != "") {
        entity direct = find(world, targetname, panel.target);
        if (direct != world)
            return direct;
    }

    // Fallback: nearest supported perk machine to the panel.
    entity best = world;
    float best_distance = 384;

    entity machine = find(world, classname, "perk_juggernog");
    while (machine != world) {
        float distance = vlen(machine.origin - panel.origin);
        if (distance < best_distance) {
            best_distance = distance;
            best = machine;
        }
        machine = find(machine, classname, "perk_juggernog");
    }

    machine = find(world, classname, "perk_speed");
    while (machine != world) {
        float distance = vlen(machine.origin - panel.origin);
        if (distance < best_distance) {
            best_distance = distance;
            best = machine;
        }
        machine = find(machine, classname, "perk_speed");
    }

    machine = find(world, classname, "perk_double");
    while (machine != world) {
        float distance = vlen(machine.origin - panel.origin);
        if (distance < best_distance) {
            best_distance = distance;
            best = machine;
        }
        machine = find(machine, classname, "perk_double");
    }

    machine = find(world, classname, "perk_revive");
    while (machine != world) {
        float distance = vlen(machine.origin - panel.origin);
        if (distance < best_distance) {
            best_distance = distance;
            best = machine;
        }
        machine = find(machine, classname, "perk_revive");
    }

    machine = find(world, classname, "perk_staminup");
    while (machine != world) {
        float distance = vlen(machine.origin - panel.origin);
        if (distance < best_distance) {
            best_distance = distance;
            best = machine;
        }
        machine = find(machine, classname, "perk_staminup");
    }

    machine = find(world, classname, "perk_mule");
    while (machine != world) {
        float distance = vlen(machine.origin - panel.origin);
        if (distance < best_distance) {
            best_distance = distance;
            best = machine;
        }
        machine = find(machine, classname, "perk_mule");
    }

    return best;
};

void() SoE_PerkPowerPanelTouch =
{
    if (other.classname != "player" ||
        !other.soe_beast_active ||
        self.activated)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    entity machine = SoE_FindTargetedPerk(self);
    if (machine == world)
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;
    self.activated = true;

    machine.soe_perk_powered = true;
    Turn_PerkLight_On(machine);

    SoE_FireEntityTargets(self);
};

void() soe_perk_power_panel =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Power Perk";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_PerkPowerPanelTouch;
    self.activated = false;

    if (self.model != "")
        setmodel(self, self.model);
    else
        setsize(self, '-16 -10 -16', '16 10 22');
};

entity(entity indicator) SoE_IndicatorPerk =
{
    if (indicator.target != "") {
        entity direct = find(world, targetname, indicator.target);
        if (direct != world)
            return direct;
    }

    entity best = world;
    float best_distance = 999999;

    entity machine = find(world, classname, "perk_juggernog");
    while (machine != world) {
        float distance = vlen(machine.origin - indicator.oldorigin);
        if (distance < best_distance) {
            best_distance = distance;
            best = machine;
        }
        machine = find(machine, classname, "perk_juggernog");
    }

    machine = find(world, classname, "perk_speed");
    while (machine != world) {
        float distance = vlen(machine.origin - indicator.oldorigin);
        if (distance < best_distance) {
            best_distance = distance;
            best = machine;
        }
        machine = find(machine, classname, "perk_speed");
    }

    machine = find(world, classname, "perk_double");
    while (machine != world) {
        float distance = vlen(machine.origin - indicator.oldorigin);
        if (distance < best_distance) {
            best_distance = distance;
            best = machine;
        }
        machine = find(machine, classname, "perk_double");
    }

    return best;
};

void() SoE_PerkIndicatorResolve =
{
    entity machine = SoE_IndicatorPerk(self);

    if (machine == world) {
        self.nextthink = time + 0.25;
        return;
    }

    if (machine.classname == "perk_juggernog") {
        self.soe_perk_kind = 1;
        self.skin = 0;
        Light_Red(self, true);
    } else if (machine.classname == "perk_speed") {
        self.soe_perk_kind = 2;
        self.skin = 1;
        Light_Green(self, true);
    } else if (machine.classname == "perk_double") {
        self.soe_perk_kind = 3;
        self.skin = 2;
        Light_Orange(self, true);
    }

    self.think = SUB_Null;
    self.nextthink = 0;
};

void() soe_perk_bottle_indicator =
{
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_NOT;

    // If target is omitted, oldorigin is the approximate district perk slot
    // used by the nearest-machine fallback.
    self.oldorigin = self.origin;

    if (self.model != "")
        setmodel(self, self.model);

    self.think = SoE_PerkIndicatorResolve;
    self.nextthink = time + 3.25;
};
