/*
    Shadows of Evil - misc secret/event runtime.

    Includes:
      - opening Shadowman round skip (1 -> 5 -> 10 -> 15)
      - Icarus/Mob plane flyover after Pack-a-Punch
      - scoped ship-window Richtofen jumpscare trigger

    Presentation remains clean-room: mappers/client HUD may provide project-owned
    models/images/audio through targets without changing the server rules.
*/

float soe_round_skip_stage;
float soe_round_skip_hits;
float soe_round_skip_last_hit;
float soe_round_skip_locked;

float soe_icarus_flyover_done;
entity soe_icarus_plane_ent;

.float soe_jumpscare_seen;
.vector soe_misc_end_origin;
.float soe_misc_speed;

void() NewRound;
void(entity who, float value, float impacted_by_2x_points) Player_ChangeScore;

void() SoE_ResetMiscSecrets =
{
    soe_round_skip_stage = 0;
    soe_round_skip_hits = 0;
    soe_round_skip_last_hit = 0;
    soe_round_skip_locked = false;

    soe_icarus_flyover_done = false;
    soe_icarus_plane_ent = world;
};

void() SoE_RoundSkipRemoveLiveWave =
{
    entity next = world;
    entity old_self = world;
    entity ent = find(world, classname, "ai_zombie");

    while (ent != world) {
        next = find(ent, classname, "ai_zombie");

        if (ent.aistatus == "1") {
            old_self = self;
            self = ent;
            self.th_die();
            self = old_self;
        }

        ent = next;
    }

    ent = find(world, classname, "ai_dog");
    while (ent != world) {
        next = find(ent, classname, "ai_dog");

        if (ent.aistatus == "1") {
            old_self = self;
            self = ent;
            self.th_die();
            self = old_self;
        }

        ent = next;
    }

    Current_Zombies = 0;
    Remaining_Zombies = 0;
    Total_Zombies = 0;
    Delay_Time = 0;
    round_changetime = 0;
};

void(float target_round, float bonus_points) SoE_RoundSkipJump =
{
    SoE_RoundSkipRemoveLiveWave();

    // NewRound increments before calculating health/counts, so seed target-1.
    rounds = target_round - 1;
    roundtype = 1;
    NewRound();

    entity player = find(world, classname, "player");
    while (player != world) {
        if (!player.is_spectator)
            Player_ChangeScore(player, bonus_points, false);

        player = find(player, classname, "player");
    }
};

float(entity victim, entity attacker, float damage, float d_style) SoE_HandleRoundSkipDamage =
{
    if (!soe_active || victim.classname != "soe_round_skip_shadowman")
        return false;

    if (soe_round_skip_locked || rounds > 15)
        return true;

    if (attacker.classname != "player" || damage <= 0)
        return true;

    if (soe_round_skip_last_hit > 0 && time > soe_round_skip_last_hit + 5) {
        soe_round_skip_locked = true;
        victim.solid = SOLID_NOT;
        victim.takedamage = DAMAGE_NO;
        setmodel(victim, "");
        return true;
    }

    soe_round_skip_last_hit = time;
    soe_round_skip_hits = soe_round_skip_hits + 1;

    // Classic community-documented implementation: five hits per jump.
    if (soe_round_skip_hits < 5)
        return true;

    soe_round_skip_hits = 0;
    soe_round_skip_stage = soe_round_skip_stage + 1;

    if (soe_round_skip_stage == 1) {
        SoE_RoundSkipJump(5, 1000);
    } else if (soe_round_skip_stage == 2) {
        SoE_RoundSkipJump(10, 3000);
    } else if (soe_round_skip_stage == 3) {
        SoE_RoundSkipJump(15, 7000);
        soe_round_skip_locked = true;
        victim.solid = SOLID_NOT;
        victim.takedamage = DAMAGE_NO;
        setmodel(victim, "");
    }

    SoE_FireEntityTargets(victim);
    return true;
};

void() SoE_RoundSkipThink =
{
    if (soe_round_skip_locked || rounds > 15) {
        remove(self);
        return;
    }

    if (soe_round_skip_last_hit > 0 &&
        time > soe_round_skip_last_hit + 5) {
        soe_round_skip_locked = true;
        SoE_FireEntityTargets(self);
        remove(self);
        return;
    }

    self.nextthink = time + 0.1;
};

void() soe_round_skip_shadowman =
{
    self.classname = "soe_round_skip_shadowman";
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_BBOX;
    self.takedamage = DAMAGE_YES;
    self.health = 999999;
    self.effects = EF_FULLBRIGHT;

    if (self.model != "")
        setmodel(self, self.model);
    else
        setmodel(self, "models/sprites/sprkle.spr");

    setsize(self, '-14 -14 -28', '14 14 34');

    self.think = SoE_RoundSkipThink;
    self.nextthink = time + 0.1;
};

/* Icarus flyover */

void() SoE_IcarusPlaneThink =
{
    vector delta = self.soe_misc_end_origin - self.origin;
    float distance = vlen(delta);

    if (distance <= 24) {
        soe_icarus_plane_ent = world;
        SoE_FireEntityTargets(self);
        remove(self);
        return;
    }

    float speed = self.soe_misc_speed;
    if (speed <= 0)
        speed = 520;

    self.velocity = normalize(delta) * speed;
    self.angles_y = vectoyaw(delta);
    self.nextthink = time + 0.05;
};

void(entity trigger) SoE_StartIcarusFlyover =
{
    if (soe_icarus_flyover_done)
        return;

    entity start = find(world, targetname, trigger.target);
    entity finish = find(world, targetname, trigger.target2);

    if (start == world || finish == world)
        return;

    entity plane = spawn();
    plane.classname = "soe_icarus_plane";
    plane.movetype = MOVETYPE_FLY;
    plane.solid = SOLID_NOT;
    plane.effects = EF_FULLBRIGHT;
    plane.soe_misc_end_origin = finish.origin;
    plane.soe_misc_speed = trigger.speed;

    if (trigger.model != "")
        setmodel(plane, trigger.model);
    else
        setmodel(plane, "models/sprites/sprkle.spr");

    setorigin(plane, start.origin);
    plane.think = SoE_IcarusPlaneThink;
    plane.nextthink = time + 0.05;

    soe_icarus_plane_ent = plane;
    soe_icarus_flyover_done = true;

    SoE_FireEntityTargets(trigger);
};

void() SoE_IcarusTriggerTouch =
{
    if (other.classname != "player" ||
        !soe_pap_unlocked ||
        soe_icarus_flyover_done)
        return;

    SoE_StartIcarusFlyover(self);
};

void() soe_icarus_trigger =
{
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_IcarusTriggerTouch;

    if (self.model != "")
        setmodel(self, self.model);
    else
        setsize(self, '-64 -64 -32', '64 64 64');
};

void() soe_misc_marker =
{
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_NOT;
    setsize(self, '0 0 0', '0 0 0');
};

/* Scoped ship-window Richtofen jumpscare detector.
   Server side owns eligibility/one-shot detection. The target field should
   fire a client-side/project-owned visual/audio event; no Treyarch image is bundled. */

void() SoE_RichtofenJumpscareTouch =
{
    if (other.classname != "player" ||
        other.downed ||
        other.soe_jumpscare_seen ||
        !soe_pap_unlocked ||
        !other.zoom)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    other.soe_jumpscare_seen = true;
    SoE_FireEntityTargets(self);
};

void() soe_richtofen_jumpscare_target =
{
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_RichtofenJumpscareTouch;

    if (self.model != "")
        setmodel(self, self.model);
    else
        setsize(self, '-18 -18 -18', '18 18 18');
};
