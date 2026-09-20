/*
    Shadows of Evil - ritual / Gateworm / fifth-ritual runtime.

    This closes the early-game progression spine:
      district ritual -> Keeper survival -> Gateworm
      -> four Sacred Place pedestals
      -> Summoning Key final ritual
      -> Pack-a-Punch unlock

    Mapper contract:
      soe_ritual_keeper_spawn style 1..5 = ritual id
      soe_gateworm_pedestal style 1,2,4,8 = one of the four Gateworms
      soe_final_ritual_altar = Sacred Place altar
*/

.float soe_ritual_id;
.float soe_keeper_next_attack;

float(float ritual_id) SoE_RitualBit =
{
    if (ritual_id == 1) return 1;
    if (ritual_id == 2) return 2;
    if (ritual_id == 3) return 4;
    if (ritual_id == 4) return 8;
    return 0;
};

entity(entity seeker) SoE_RitualFindPlayer =
{
    entity player = find(world, classname, "player");
    entity best = world;
    float best_distance = 999999;

    while (player != world) {
        if (!player.downed && !player.is_spectator) {
            float distance = vlen(player.origin - seeker.origin);
            if (distance < best_distance) {
                best_distance = distance;
                best = player;
            }
        }

        player = find(player, classname, "player");
    }

    return best;
};

void() SoE_KeeperThink =
{
    if (!soe_active ||
        soe_active_ritual_controller == world ||
        self.soe_ritual_id != soe_active_ritual_controller.style) {
        remove(self);
        return;
    }

    if (self.enemy == world || self.enemy.downed || self.enemy.is_spectator)
        self.enemy = SoE_RitualFindPlayer(self);

    if (self.enemy == world) {
        self.velocity = '0 0 0';
        self.nextthink = time + 0.1;
        return;
    }

    vector delta = self.enemy.origin - self.origin;
    vector planar = delta;
    planar_z = 0;
    float distance = vlen(planar);

    self.angles_y = vectoyaw(planar);

    if (distance > 54) {
        vector direction = normalize(planar);
        self.velocity_x = direction_x * 180;
        self.velocity_y = direction_y * 180;
    } else {
        self.velocity_x = 0;
        self.velocity_y = 0;

        if (self.soe_keeper_next_attack <= time) {
            DamageHandler(self.enemy, self, 30, DMG_TYPE_ZOMBIESWIPE);
            self.soe_keeper_next_attack = time + 0.9;
        }
    }

    self.nextthink = time + 0.05;
};

entity(vector org, float ritual_id) SoE_SpawnKeeper =
{
    entity keeper = spawn();
    keeper.classname = "soe_keeper";
    keeper.soe_special_type = SOE_SPECIAL_KEEPER;
    keeper.soe_ritual_id = ritual_id;
    keeper.movetype = MOVETYPE_STEP;
    keeper.solid = SOLID_SLIDEBOX;
    keeper.takedamage = DAMAGE_YES;
    keeper.flags = keeper.flags | FL_MONSTER;
    keeper.effects = EF_FULLBRIGHT;

    float hp = 80 + (rounds * 12);
    if (hp > 450)
        hp = 450;
    keeper.health = hp;

    // Placeholder until a cleared Keeper model/animation set is integrated.
    setmodel(keeper, "models/sprites/sprkle.spr");
    setsize(keeper, '-14 -14 -28', '14 14 34');
    setorigin(keeper, org);

    keeper.enemy = SoE_RitualFindPlayer(keeper);
    keeper.soe_keeper_next_attack = time + 0.4;
    keeper.think = SoE_KeeperThink;
    keeper.nextthink = time + 0.05;

    return keeper;
};

entity(float ritual_id) SoE_FindRitualSpawn =
{
    entity marker = find(world, classname, "soe_ritual_keeper_spawn");
    entity chosen = world;
    float seen = 0;

    while (marker != world) {
        if (marker.style == ritual_id) {
            seen = seen + 1;
            if (random() < (1 / seen))
                chosen = marker;
        }

        marker = find(marker, classname, "soe_ritual_keeper_spawn");
    }

    return chosen;
};

float(float ritual_id) SoE_CountRitualKeepers =
{
    float count = 0;
    entity keeper = find(world, classname, "soe_keeper");

    while (keeper != world) {
        if (keeper.soe_ritual_id == ritual_id)
            count = count + 1;

        keeper = find(keeper, classname, "soe_keeper");
    }

    return count;
};

void(float ritual_id) SoE_RemoveRitualKeepers =
{
    entity keeper = find(world, classname, "soe_keeper");

    while (keeper != world) {
        entity next = find(keeper, classname, "soe_keeper");

        if (keeper.soe_ritual_id == ritual_id)
            remove(keeper);

        keeper = next;
    }
};

void() soe_ritual_keeper_spawn =
{
    self.solid = SOLID_NOT;
    self.movetype = MOVETYPE_NONE;
    setsize(self, '0 0 0', '0 0 0');
};

entity(vector org, float ritual_id) SoE_SpawnGateworm =
{
    float worm_bit = SoE_RitualBit(ritual_id);
    if (worm_bit == 0)
        return world;

    entity worm = spawn();
    worm.classname = "soe_gateworm_pickup";
    worm.style = worm_bit;
    worm.movetype = MOVETYPE_NONE;
    worm.solid = SOLID_TRIGGER;
    worm.effects = EF_FULLBRIGHT;
    worm.useprint_string_1 = "Hold %b to Pick Up Gateworm";
    worm.useprint_index_1 = Useprint_Register(worm.useprint_string_1, '1 1 1');

    setmodel(worm, "models/sprites/sprkle.spr");
    setsize(worm, '-12 -12 -12', '12 12 18');
    setorigin(worm, org + '0 0 30');

    worm.touch = SoE_GatewormPickupTouch;
    return worm;
};

void() SoE_GatewormPickupTouch =
{
    if (other.classname != "player" || other.downed || other.isBuying)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    if (soe_gateworm_collected_mask & self.style)
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;
    soe_gateworm_collected_mask = soe_gateworm_collected_mask | self.style;

    SoE_FireEntityTargets(self);
    remove(self);
};

void(entity controller) SoE_RitualRuntimeStart =
{
    if (!soe_active || controller == world)
        return;

    soe_active_ritual_controller = controller;
    soe_ritual_keeper_next_spawn = time + 0.25;
};

void(entity controller) SoE_RitualRuntimeComplete =
{
    if (!soe_active || controller == world)
        return;

    float ritual_id = controller.style;
    SoE_RemoveRitualKeepers(ritual_id);

    if (ritual_id >= 1 && ritual_id <= 4)
        SoE_SpawnGateworm(controller.origin, ritual_id);

    soe_active_ritual_controller = world;
    soe_ritual_keeper_next_spawn = 0;
};

void() SoE_RitualFrame =
{
    if (!soe_active || soe_active_ritual_controller == world)
        return;

    float ritual_id = soe_active_ritual_controller.style;
    float cap = 4;

    if (ritual_id == 5)
        cap = 7;

    if (time < soe_ritual_keeper_next_spawn)
        return;

    if (SoE_CountRitualKeepers(ritual_id) >= cap) {
        soe_ritual_keeper_next_spawn = time + 0.25;
        return;
    }

    entity marker = SoE_FindRitualSpawn(ritual_id);
    vector org;

    if (marker != world) {
        org = marker.origin;
    } else {
        org = soe_active_ritual_controller.origin;
        org_x = org_x + ((random() * 240) - 120);
        org_y = org_y + ((random() * 240) - 120);
        org_z = org_z + 24;
    }

    SoE_SpawnKeeper(org, ritual_id);
    soe_ritual_keeper_next_spawn = time + 0.8;
};

void() SoE_GatewormPedestalTouch =
{
    if (other.classname != "player" || other.downed || other.isBuying)
        return;

    float worm_bit = self.style;
    if (worm_bit != 1 && worm_bit != 2 && worm_bit != 4 && worm_bit != 8)
        return;

    if (soe_gateworm_placed_mask & worm_bit)
        return;

    if (!(soe_gateworm_collected_mask & worm_bit))
        return;

    if (!PlayerIsLooking(other, self))
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;

    // This bit is known to be present, so subtraction is a portable clear.
    soe_gateworm_collected_mask = soe_gateworm_collected_mask - worm_bit;
    soe_gateworm_placed_mask = soe_gateworm_placed_mask | worm_bit;
    self.state = 1;

    SoE_FireEntityTargets(self);
};

void() soe_gateworm_pedestal =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Place Gateworm";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_GatewormPedestalTouch;
    self.state = 0;

    if (self.model != "")
        setmodel(self, self.model);
    else
        setsize(self, '-18 -18 -18', '18 18 26');
};

void() SoE_FinalRitualComplete =
{
    SoE_RitualRuntimeComplete(self);

    self.state = 2;
    soe_ritual_active = false;

    SoE_UnlockPackAPunch();

    // Detailed guides report a Margwa after the final ritual as well.
    soe_scripted_margwa_pending = soe_scripted_margwa_pending + 1;

    // Mapper targets drive the sky state, PaP portal reveal, Shadowman reveal,
    // room unlock and any clean replacement VO/FX.
    SoE_FireEntityTargets(self);
};

void() SoE_FinalRitualTouch =
{
    if (other.classname != "player" || other.downed || other.isBuying)
        return;

    if (self.state != 0 ||
        soe_ritual_active ||
        soe_gateworm_placed_mask != 15 ||
        !soe_has_summoning_key)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;

    self.state = 1;
    self.style = 5;
    soe_ritual_active = true;

    SoE_RitualRuntimeStart(self);

    self.think = SoE_FinalRitualComplete;
    self.nextthink = time + (self.wait > 0 ? self.wait : 20);
};

void() soe_final_ritual_altar =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Begin Final Ritual";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_FinalRitualTouch;
    self.state = 0;

    if (self.model != "")
        setmodel(self, self.model);
    else
        setsize(self, '-34 -34 -20', '34 34 30');
};
