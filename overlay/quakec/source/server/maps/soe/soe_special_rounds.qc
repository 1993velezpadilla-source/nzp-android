/*
    Shadows of Evil special-round scheduler.

    Verified schedule:
      - round 5 or 6: Parasites
      - round 9 or 10: Insanity Elementals
      - round 14 or 15: mixed
      - later mixed rounds: 5-9 rounds apart

    Individual special-round spawn counts are based on current public
    reverse-engineering/community measurements. Mixed-round species split is
    isolated in one function because the exact internal BO3 split is not
    independently verified.
*/

#define SOE_SPECIAL_ROUND_NONE          0
#define SOE_SPECIAL_ROUND_PARASITES     1
#define SOE_SPECIAL_ROUND_ELEMENTALS    2
#define SOE_SPECIAL_ROUND_MIXED         3

float soe_special_round_active;
float soe_special_round_type;
float soe_special_round_phase;
float soe_next_special_round;
float soe_special_parasites_left;
float soe_special_elementals_left;
float soe_special_spawn_delay;

entity(vector org, float counts_round) SoE_SpawnParasite;
entity(vector org, entity target, float counts_round) SoE_SpawnElementalWarning;
entity(entity seeker, float allow_beast) SoE_FindSpecialTarget;
void(vector where, float type) Spawn_Powerup;

void() SoE_ResetSpecialRoundSchedule =
{
    if (!soe_active)
        return;

    soe_special_round_active = false;
    soe_special_round_type = SOE_SPECIAL_ROUND_NONE;
    soe_special_round_phase = 0;
    soe_next_special_round = 5 + floor(random() * 2);
    soe_special_parasites_left = 0;
    soe_special_elementals_left = 0;
    soe_special_spawn_delay = 0;
};

float() SoE_ParasiteRoundTotal =
{
    float players = SoE_PlayerCount();

    if (players <= 1)
        return 10;

    return floor(10 * players * 0.75);
};

float() SoE_ElementalRoundTotal =
{
    float players = SoE_PlayerCount();

    if (players <= 1)
        return 10;
    if (players == 2)
        return 18;
    if (players == 3)
        return 28;

    return 34;
};

void() SoE_ConfigureMixedRound =
{
    // Public measurements document the total population for pure Parasite
    // and pure Elemental rounds, but not a reliable BO3 mixed-species split.
    // Preserve a stable total using the larger pure-round population and
    // split it approximately 50/50 until direct capture confirms the ratio.
    float total = SoE_ElementalRoundTotal();

    soe_special_parasites_left = floor(total * 0.5);
    soe_special_elementals_left = total - soe_special_parasites_left;
};

void() SoE_AfterRoundIncrement =
{
    if (!soe_active)
        return;

    if (rounds != soe_next_special_round)
        return;

    soe_special_round_active = true;
    soe_special_spawn_delay = time + 1;

    if (soe_special_round_phase == 0) {
        soe_special_round_type = SOE_SPECIAL_ROUND_PARASITES;
        soe_special_parasites_left = SoE_ParasiteRoundTotal();
        soe_special_elementals_left = 0;

        soe_next_special_round = 9 + floor(random() * 2);
    } else if (soe_special_round_phase == 1) {
        soe_special_round_type = SOE_SPECIAL_ROUND_ELEMENTALS;
        soe_special_parasites_left = 0;
        soe_special_elementals_left = SoE_ElementalRoundTotal();

        soe_next_special_round = 14 + floor(random() * 2);
    } else {
        soe_special_round_type = SOE_SPECIAL_ROUND_MIXED;
        SoE_ConfigureMixedRound();

        soe_next_special_round = rounds + 5 + floor(random() * 5);
    }

    soe_special_round_phase = soe_special_round_phase + 1;

    // Distinguish from NZ:P's normal (1) and dog (2) rounds.
    roundtype = 3;
};

float(float fallback) SoE_AdjustRoundEnemyTotal =
{
    if (!soe_active || !soe_special_round_active)
        return fallback;

    return soe_special_parasites_left + soe_special_elementals_left;
};

float(string classname_to_count) SoE_CountEntities =
{
    float count = 0;
    entity ent = find(world, classname, classname_to_count);

    while (ent != world) {
        count = count + 1;
        ent = find(ent, classname, classname_to_count);
    }

    return count;
};

entity(string marker_class) SoE_SpecialRoundMarker =
{
    entity marker = SoE_FindRandomMarker(marker_class);

    if (marker != world)
        return marker;

    return world;
};

vector(entity target) SoE_FallbackSpecialSpawn =
{
    if (target == world)
        return '0 0 96';

    float xoff = (random() * 240) - 120;
    float yoff = (random() * 240) - 120;

    vector result = target.origin;
    result_x = result_x + xoff;
    result_y = result_y + yoff;
    result_z = result_z + 96;
    return result;
};

float() SoE_TrySpawnRoundParasite =
{
    if (soe_special_parasites_left <= 0)
        return false;

    float players = SoE_PlayerCount();
    float alive_cap = players * 5;
    if (alive_cap > 16)
        alive_cap = 16;
    if (alive_cap < 5)
        alive_cap = 5;

    if (SoE_CountEntities("soe_parasite") >= alive_cap)
        return false;

    entity marker = SoE_SpecialRoundMarker("soe_spawn_air");
    entity target = SoE_FindSpecialTarget(world, false);
    vector org;

    if (marker != world)
        org = marker.origin;
    else
        org = SoE_FallbackSpecialSpawn(target);

    SoE_SpawnParasite(org, true);
    soe_special_parasites_left = soe_special_parasites_left - 1;
    return true;
};

float() SoE_TrySpawnRoundElemental =
{
    if (soe_special_elementals_left <= 0)
        return false;

    float players = SoE_PlayerCount();
    float alive_cap = players * 4;
    if (alive_cap > 13)
        alive_cap = 13;
    if (alive_cap < 4)
        alive_cap = 4;

    float alive = SoE_CountEntities("soe_elemental") + SoE_CountEntities("soe_elemental_warning");
    if (alive >= alive_cap)
        return false;

    entity target = SoE_FindSpecialTarget(world, false);
    entity marker = SoE_SpecialRoundMarker("soe_spawn_elemental");
    vector org;

    if (marker != world)
        org = marker.origin;
    else
        org = SoE_FallbackSpecialSpawn(target);

    // Count the round slot now. The warning transfers ownership of that slot
    // to the Elemental if it survives the pre-spawn telegraph.
    SoE_SpawnElementalWarning(org, target, true);
    Current_Zombies = Current_Zombies + 1;

    soe_special_elementals_left = soe_special_elementals_left - 1;
    return true;
};

float() SoE_SpawnSpecialRoundEnemy =
{
    if (!soe_active || !soe_special_round_active)
        return false;

    // Returning true means "this is a SoE special round; never fall through
    // to the stock normal/dog spawner", even when concurrency caps are full.
    if (soe_special_spawn_delay > time)
        return true;

    float did_spawn = false;

    if (soe_special_round_type == SOE_SPECIAL_ROUND_PARASITES) {
        did_spawn = SoE_TrySpawnRoundParasite();
    } else if (soe_special_round_type == SOE_SPECIAL_ROUND_ELEMENTALS) {
        did_spawn = SoE_TrySpawnRoundElemental();
    } else {
        // Alternate preference stochastically so mixed waves don't arrive in
        // two artificial blocks.
        if (random() < 0.5) {
            did_spawn = SoE_TrySpawnRoundParasite();
            if (!did_spawn)
                did_spawn = SoE_TrySpawnRoundElemental();
        } else {
            did_spawn = SoE_TrySpawnRoundElemental();
            if (!did_spawn)
                did_spawn = SoE_TrySpawnRoundParasite();
        }
    }

    if (did_spawn)
        soe_special_spawn_delay = time + 0.18;

    return true;
};

void(vector death_origin) SoE_OnCountedSpecialDeath =
{
    Remaining_Zombies = Remaining_Zombies - 1;

    if (Remaining_Zombies < 0)
        Remaining_Zombies = 0;

    if (soe_special_round_active && Remaining_Zombies == 0) {
        Spawn_Powerup(death_origin, PU_MAXAMMO);
        soe_special_round_active = false;
        soe_special_round_type = SOE_SPECIAL_ROUND_NONE;
        roundtype = 1;
    }
};

void() soe_spawn_elemental =
{
    self.solid = SOLID_NOT;
    self.movetype = MOVETYPE_NONE;
    setsize(self, '0 0 0', '0 0 0');
};
