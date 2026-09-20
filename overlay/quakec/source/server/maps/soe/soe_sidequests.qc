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
