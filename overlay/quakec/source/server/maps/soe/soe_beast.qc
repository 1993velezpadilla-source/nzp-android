/*
    Shadows of Evil Beast Mode runtime foundation.

    Clean-room implementation targeting NZ:P. No commercial game code/assets.
*/

.float soe_beast_active;
.float soe_beast_until;
.float soe_beast_charges;
.float soe_beast_round;
.vector soe_beast_return_origin;
.float soe_grapple_active;
.entity soe_grapple_target;

entity(entity blarg) find_new_enemy;

float() SoE_PlayerCount =
{
    float count = 0;
    entity player = find(world, classname, "player");

    while (player != world) {
        if (!player.is_spectator)
            count = count + 1;
        player = find(player, classname, "player");
    }

    return count;
};

float(entity who) SoE_IsBeast =
{
    if (!soe_active)
        return false;

    return who.soe_beast_active;
};

void(entity who) SoE_ClearEnemyTargetsForBeast =
{
    entity ai = find(world, classname, "ai_zombie");
    while (ai != world) {
        if (ai.enemy == who)
            ai.enemy = find_new_enemy(ai);
        ai = find(ai, classname, "ai_zombie");
    }

    ai = find(world, classname, "ai_dog");
    while (ai != world) {
        if (ai.enemy == who)
            ai.enemy = find_new_enemy(ai);
        ai = find(ai, classname, "ai_dog");
    }
};

void(entity who) SoE_EndBeast =
{
    if (!who.soe_beast_active)
        return;

    who.soe_beast_active = false;
    who.soe_beast_until = 0;
    who.soe_finale_beast_meter = 0;
    who.soe_grapple_active = false;
    who.soe_grapple_target = world;

    // The original leaves the human body at the activation point.
    // Save the player's exact activation origin instead of relying on a
    // brush entity origin, which can be unreliable for trigger brushes.
    setorigin(who, who.soe_beast_return_origin);
    who.velocity = '0 0 0';
};

void(entity who) SoE_BeginBeast =
{
    if (!soe_active || who.classname != "player" || who.downed)
        return;

    if (who.soe_beast_active || who.soe_beast_charges <= 0)
        return;

    who.soe_beast_charges = who.soe_beast_charges - 1;
    who.soe_beast_active = true;
    who.soe_beast_until = time + 25;

    if (soe_finale_active)
        who.soe_finale_beast_meter = 100;
    else
        who.soe_finale_beast_meter = 0;
    who.soe_beast_return_origin = who.origin;
    who.soe_grapple_active = false;
    who.soe_grapple_target = world;

    SoE_ClearEnemyTargetsForBeast(who);
};

void(entity who, float percent) SoE_BeastDrain =
{
    if (!who.soe_beast_active)
        return;

    if (soe_finale_active) {
        who.soe_finale_beast_meter = who.soe_finale_beast_meter - percent;

        if (who.soe_finale_beast_meter <= 0)
            SoE_EndBeast(who);

        return;
    }

    float remaining = who.soe_beast_until - time;
    if (remaining <= 0)
        return;

    // A normal Beast transformation is 25 seconds. A canonical melee action
    // drains roughly three percent of the timer.
    remaining = remaining - (25 * (percent / 100));
    who.soe_beast_until = time + remaining;

    if (who.soe_beast_until <= time)
        SoE_EndBeast(who);
};

void(entity who, entity target) SoE_BeginGrapple =
{
    if (!who.soe_beast_active || target == world)
        return;

    who.soe_grapple_target = target;
    who.soe_grapple_active = true;
};

void() SoE_ResetBeastCharges =
{
    if (!soe_active)
        return;

    float soe_players = SoE_PlayerCount();
    float charges = 1;

    // Original solo allows up to three Beast uses in a round. Keep this
    // isolated here so edge-case recharge behavior can be tuned after
    // capture/validation without touching the entity code.
    if (soe_players <= 1)
        charges = 3;

    entity player = find(world, classname, "player");
    while (player != world) {
        player.soe_beast_charges = charges;
        player.soe_beast_round = rounds;
        player = find(player, classname, "player");
    }
};

void() SoE_Frame =
{
    if (!soe_active)
        return;

    entity player = find(world, classname, "player");
    while (player != world) {
        if (player.soe_beast_active) {
            if (!soe_finale_active && player.soe_beast_until <= time) {
                SoE_EndBeast(player);
            } else if (player.soe_grapple_active) {
                if (player.soe_grapple_target == world) {
                    player.soe_grapple_active = false;
                } else {
                    vector delta = player.soe_grapple_target.origin - player.origin;
                    float distance = vlen(delta);

                    if (distance <= 40) {
                        player.soe_grapple_active = false;
                        player.velocity = '0 0 0';
                    } else {
                        player.velocity = normalize(delta) * 700;
                    }
                }
            }
        }

        player = find(player, classname, "player");
    }
};
