/*
    Shadows of Evil - Civil Protector runtime.

    Flow:
      1. collect one fuse in each main district
      2. install all three at the Rift fuse box
      3. summon from Junction/Canal/Footlight/Waterfront call panels
      4. only one Protector may be active at once

    Presentation is intentionally placeholder-only until a cleared robot model
    and audio set are available. Gameplay/quest state is independent of art.
*/

#define SOE_CIVIL_FUSE_CANAL       1
#define SOE_CIVIL_FUSE_FOOTLIGHT   2
#define SOE_CIVIL_FUSE_WATERFRONT  4
#define SOE_CIVIL_FUSE_ALL         7

float soe_civil_fuse_mask;
float soe_civil_powered;
entity soe_civil_active_ent;

.float soe_civil_call_mask;
.float soe_civil_expire_round;
.float soe_civil_lifetime_rounds;
.float soe_civil_next_attack;
.float soe_civil_next_retarget;
.float soe_civil_panel_id;

void(entity client) LastStand_RemoveReviveTriggers;
void(entity client) LastStand_UnlinkRevivee;
void(float playernum) DisableReviveIcon;
void(entity who, float value, float impacted_by_2x_points) Player_ChangeScore;
void(entity victim, entity attacker, float damage, float d_style) DamageHandler;

void() SoE_ResetCivilProtector =
{
    soe_civil_fuse_mask = 0;
    soe_civil_powered = false;
    soe_civil_active_ent = world;
};

void() SoE_CivilFusePickupTouch =
{
    if (other.classname != "player" || other.downed)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    float fuse_bit = self.style;
    if (fuse_bit != SOE_CIVIL_FUSE_CANAL &&
        fuse_bit != SOE_CIVIL_FUSE_FOOTLIGHT &&
        fuse_bit != SOE_CIVIL_FUSE_WATERFRONT)
        return;

    if (soe_civil_fuse_mask & fuse_bit)
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;
    soe_civil_fuse_mask = soe_civil_fuse_mask | fuse_bit;

    SoE_FireEntityTargets(self);
    self.solid = SOLID_NOT;
    self.touch = SUB_Null;

    if (self.model != "")
        setmodel(self, "");
};

void() soe_civil_fuse =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Pick Up Fuse";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_CivilFusePickupTouch;

    if (self.model != "")
        setmodel(self, self.model);
    else {
        setmodel(self, "models/sprites/sprkle.spr");
        setsize(self, '-8 -8 -6', '8 8 10');
        self.effects = EF_FULLBRIGHT;
    }
};

void() SoE_CivilFuseBoxTouch =
{
    if (other.classname != "player" || other.downed || soe_civil_powered)
        return;

    if (soe_civil_fuse_mask != SOE_CIVIL_FUSE_ALL)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;
    soe_civil_powered = true;
    self.state = 1;
    SoE_FireEntityTargets(self);
};

void() soe_civil_fusebox =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Install Fuses";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_CivilFuseBoxTouch;
    self.state = 0;

    if (self.model != "")
        setmodel(self, self.model);
    else
        setsize(self, '-20 -12 -20', '20 12 30');
};

float(entity ent) SoE_CivilCanAttack =
{
    if (ent == world)
        return false;

    if (ent.classname == "ai_zombie")
        return ent.iszomb;

    if (ent.classname == "ai_dog")
        return ent.aistatus == "1";

    if (ent.classname == "soe_parasite" || ent.classname == "soe_elemental")
        return ent.health > 0;

    return false;
};

entity(entity protector) SoE_CivilFindEnemy =
{
    entity best = world;
    float best_distance = 1600;
    float distance = 0;

    entity ent = find(world, classname, "ai_zombie");
    while (ent != world) {
        if (SoE_CivilCanAttack(ent)) {
            distance = vlen(ent.origin - protector.origin);
            if (distance < best_distance) {
                best_distance = distance;
                best = ent;
            }
        }
        ent = find(ent, classname, "ai_zombie");
    }

    ent = find(world, classname, "ai_dog");
    while (ent != world) {
        if (SoE_CivilCanAttack(ent)) {
            distance = vlen(ent.origin - protector.origin);
            if (distance < best_distance) {
                best_distance = distance;
                best = ent;
            }
        }
        ent = find(ent, classname, "ai_dog");
    }

    ent = find(world, classname, "soe_parasite");
    while (ent != world) {
        if (SoE_CivilCanAttack(ent)) {
            distance = vlen(ent.origin - protector.origin);
            if (distance < best_distance) {
                best_distance = distance;
                best = ent;
            }
        }
        ent = find(ent, classname, "soe_parasite");
    }

    ent = find(world, classname, "soe_elemental");
    while (ent != world) {
        if (SoE_CivilCanAttack(ent)) {
            distance = vlen(ent.origin - protector.origin);
            if (distance < best_distance) {
                best_distance = distance;
                best = ent;
            }
        }
        ent = find(ent, classname, "soe_elemental");
    }

    return best;
};

entity(entity protector) SoE_CivilFindDownedPlayer =
{
    entity best = world;
    float best_distance = 1400;

    entity player = find(world, classname, "player");
    while (player != world) {
        if (player.downed && !player.is_spectator) {
            float distance = vlen(player.origin - protector.origin);
            if (distance < best_distance) {
                best_distance = distance;
                best = player;
            }
        }

        player = find(player, classname, "player");
    }

    return best;
};

void(entity protector, entity player) SoE_CivilRevivePlayer =
{
    if (player == world || !player.downed)
        return;

    if (player.beingrevived)
        LastStand_UnlinkRevivee(player);

    entity old_self = self;
    self = player;
    GetUp();
    self = old_self;

    LastStand_RemoveReviveTriggers(player);
    DisableReviveIcon(player.playernum);
};

void(entity protector, entity victim) SoE_CivilAttack =
{
    if (!SoE_CivilCanAttack(victim))
        return;

    float damage = 240;

    // Let an upgraded/gold Protector stay useful at high rounds.
    if (soe_quest_stage == SOE_QUEST_COMPLETE)
        damage = 420;

    // Margwa proxy uses its own headshot gate; normal body enemies route
    // through generic damage.
    if (victim.soe_special_type == SOE_SPECIAL_MARGWA)
        DamageHandler(victim, protector, damage, DMG_TYPE_HEADSHOT);
    else
        DamageHandler(victim, protector, damage, DMG_TYPE_UPPERTORSO);
};

void() SoE_CivilProtectorThink =
{
    if (!soe_active || self != soe_civil_active_ent) {
        remove(self);
        return;
    }

    if (rounds >= self.soe_civil_expire_round) {
        soe_civil_active_ent = world;
        SoE_FireEntityTargets(self);
        remove(self);
        return;
    }

    entity revive_target = SoE_CivilFindDownedPlayer(self);
    entity target = world;

    if (revive_target != world)
        target = revive_target;
    else {
        if (self.enemy == world || !SoE_CivilCanAttack(self.enemy) ||
            self.soe_civil_next_retarget <= time) {
            self.enemy = SoE_CivilFindEnemy(self);
            self.soe_civil_next_retarget = time + 0.4;
        }

        target = self.enemy;
    }

    if (target == world) {
        self.velocity = self.velocity * 0.5;
        self.nextthink = time + 0.05;
        return;
    }

    vector delta = target.origin - self.origin;
    vector planar = delta;
    planar_z = 0;
    float distance = vlen(planar);

    self.angles_y = vectoyaw(planar);

    if (distance > 74) {
        vector direction = normalize(planar);
        self.velocity_x = direction_x * 210;
        self.velocity_y = direction_y * 210;
    } else {
        self.velocity_x = 0;
        self.velocity_y = 0;

        if (target.classname == "player" && target.downed) {
            SoE_CivilRevivePlayer(self, target);
        } else if (self.soe_civil_next_attack <= time) {
            SoE_CivilAttack(self, target);
            self.soe_civil_next_attack = time + 0.35;
        }
    }

    self.nextthink = time + 0.05;
};

entity(vector org, float lifetime_rounds) SoE_SpawnCivilProtector =
{
    if (soe_civil_active_ent != world)
        return world;

    entity protector = spawn();
    protector.classname = "soe_civil_protector";
    protector.movetype = MOVETYPE_STEP;
    protector.solid = SOLID_SLIDEBOX;
    protector.takedamage = DAMAGE_NO;
    protector.flags = protector.flags | FL_MONSTER;
    protector.effects = EF_FULLBRIGHT;
    protector.enemy = world;

    if (lifetime_rounds <= 0)
        lifetime_rounds = 3;

    protector.soe_civil_expire_round = rounds + lifetime_rounds;
    protector.soe_civil_next_retarget = time;
    protector.soe_civil_next_attack = time;

    // Placeholder until a cleared Civil Protector model is integrated.
    setmodel(protector, "models/sprites/sprkle.spr");
    setsize(protector, '-16 -16 -32', '16 16 40');
    setorigin(protector, org + '0 0 36');

    protector.think = SoE_CivilProtectorThink;
    protector.nextthink = time + 0.05;

    soe_civil_active_ent = protector;
    return protector;
};

void() SoE_CivilCallPanelTouch =
{
    if (other.classname != "player" || other.downed || other.isBuying)
        return;

    if (!soe_civil_powered || soe_civil_active_ent != world)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    float price = self.cost;
    if (price <= 0)
        price = 2000;

    Player_UseprintWithWait(other, self, self.useprint_index_1, price);

    if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;

    if (other.points < price) {
        centerprint(other, STR_NOTENOUGHPOINTS);
        Sound_PlaySound(other, "sounds/misc/denybuy.wav", SOUND_TYPE_ENV_CHING, SOUND_PRIORITY_PLAYALWAYS);
        return;
    }

    Player_ChangeScore(other, -price, false);

    float lifetime = self.soe_civil_lifetime_rounds;
    if (lifetime <= 0)
        lifetime = 3;

    entity protector = SoE_SpawnCivilProtector(self.origin, lifetime);
    if (protector == world) {
        // Defensive refund if another panel won a same-frame summon race.
        Player_ChangeScore(other, price, false);
        return;
    }

    if (self.soe_civil_panel_id == 1)
        other.soe_civil_call_mask = other.soe_civil_call_mask | 1;
    else if (self.soe_civil_panel_id == 2)
        other.soe_civil_call_mask = other.soe_civil_call_mask | 2;
    else if (self.soe_civil_panel_id == 3)
        other.soe_civil_call_mask = other.soe_civil_call_mask | 4;
    else if (self.soe_civil_panel_id == 4)
        other.soe_civil_call_mask = other.soe_civil_call_mask | 8;

    SoE_FireEntityTargets(self);
};

void() soe_civil_call_panel =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Call Civil Protector";

    if (self.cost <= 0)
        self.cost = 2000;

    if (self.soe_civil_lifetime_rounds <= 0)
        self.soe_civil_lifetime_rounds = 3;

    self.soe_civil_panel_id = self.style;
    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_CivilCallPanelTouch;

    if (self.model != "")
        setmodel(self, self.model);
    else
        setsize(self, '-18 -10 -20', '18 10 28');
};
