/*
    Shadows of Evil Fumigator + Harvest Pod runtime.

    Public references consistently describe:
      green/yellow -> red -> purple over "a couple of rounds"
      harvested pods regrow green after "a couple of rounds"
      purple is the only tier that can award Margwa Tentacle

    The exact BO3 internal timing/probabilities are not publicly verified, so
    growth timing and reward weights are intentionally centralized/tunable.
*/

#define SOE_POD_DORMANT     0
#define SOE_POD_GREEN       1
#define SOE_POD_RED         2
#define SOE_POD_PURPLE      3

.float soe_has_fumigator;
.float soe_pod_stage;
.float soe_pod_next_growth_round;
.float soe_pod_growth_rounds;
.float soe_pod_regrow_rounds;
.float soe_reward_expire;
.float soe_reward_kind;

#define SOE_POD_REWARD_NONE         0
#define SOE_POD_REWARD_POINTS       1
#define SOE_POD_REWARD_POWERUP      2
#define SOE_POD_REWARD_WEAPON       3
#define SOE_POD_REWARD_PARASITE     4
#define SOE_POD_REWARD_LIVE_GRENADE 5
#define SOE_POD_REWARD_TENTACLE     6

void(vector where, float type) Spawn_Powerup;
void(entity who, float value, float impacted_by_2x_points) Player_ChangeScore;
string(float wep, float gorvmodel) GetWeaponModel;
entity(vector org, float counts_round) SoE_SpawnParasite;
void() GrenadeExplode;
void(float weapon_id, float weapon_mag, float weapon_reserve, float weapon_tier) Weapon_GiveWeapon;

void(entity pod) SoE_HarvestPodRefreshVisual =
{
    // Gameplay state never depends on the placeholder visual.
    // Cleared final models/materials can be keyed off soe_pod_stage later.
    if (pod.soe_pod_stage == SOE_POD_DORMANT) {
        pod.effects = 0;
        return;
    }

    pod.effects = EF_FULLBRIGHT;

    // Use scale as a cheap development signal until actual stage meshes/skins
    // are integrated: green=0.75, red=0.9, purple=1.05.
    if (pod.soe_pod_stage == SOE_POD_GREEN)
        pod.scale = 0.75;
    else if (pod.soe_pod_stage == SOE_POD_RED)
        pod.scale = 0.9;
    else
        pod.scale = 1.05;
};

void() SoE_FumigatorPickupTouch =
{
    if (other.classname != "player" || other.downed || other.soe_has_fumigator)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;
    other.soe_has_fumigator = true;

    self.solid = SOLID_NOT;
    self.touch = SUB_Null;
    if (self.model != "")
        setmodel(self, "");

    SoE_FireEntityTargets(self);
};

void() soe_fumigator_pickup =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Pick Up Fumigator";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_FumigatorPickupTouch;

    if (self.model != "")
        setmodel(self, self.model);
    else
        setsize(self, '-10 -10 -10', '10 10 10');
};

void() SoE_PodRewardExpire =
{
    remove(self);
};

void() SoE_PodWeaponRewardTouch =
{
    if (other.classname != "player" || other.downed)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;

    entity old_self = self;
    self = other;
    Weapon_GiveWeapon(old_self.weapon, 0, 0, 0);
    self = old_self;

    remove(self);
};

entity(vector org, float weapon_id) SoE_SpawnPodWeaponReward =
{
    entity reward = spawn();
    reward.classname = "soe_pod_weapon_reward";
    reward.weapon = weapon_id;
    reward.movetype = MOVETYPE_NONE;
    reward.solid = SOLID_TRIGGER;
    reward.touch = SoE_PodWeaponRewardTouch;
    reward.think = SoE_PodRewardExpire;
    reward.nextthink = time + 30;
    reward.soe_reward_expire = reward.nextthink;
    reward.useprint_string_1 = "Hold %b to Take Weapon";
    reward.useprint_index_1 = Useprint_Register(reward.useprint_string_1, '1 1 1');

    string model_path = GetWeaponModel(weapon_id, 1);
    if (model_path != "")
        setmodel(reward, model_path);
    else
        setmodel(reward, "models/sprites/sprkle.spr");

    setsize(reward, '-12 -12 -12', '12 12 12');
    setorigin(reward, org + '0 0 18');
    reward.effects = EF_FULLBRIGHT;

    return reward;
};

void(vector org) SoE_SpawnLiveGrenadeReward =
{
    entity nade = spawn();
    nade.owner = world;
    nade.movetype = MOVETYPE_BOUNCE;
    nade.solid = SOLID_BBOX;
    nade.classname = "projectile_grenade";
    nade.avelocity = '50 -50 50';
    nade.velocity_x = (random() * 120) - 60;
    nade.velocity_y = (random() * 120) - 60;
    nade.velocity_z = 160;
    nade.touch = GrenadeExplode;
    nade.think = GrenadeExplode;
    nade.nextthink = time + 2.5;
    setsize(nade, '-2 -2 -2', '2 2 2');
    setorigin(nade, org + '0 0 20');
};

void(vector org) SoE_SpawnTentacleReward =
{
    if (soe_has_margwa_tentacle)
        return;

    entity drop = spawn();
    drop.style = SOE_PICKUP_MARGWA_TENTACLE;
    drop.useprint_string_1 = "Hold %b to Pick Up Margwa Tentacle";

    entity old_self = self;
    self = drop;
    soe_quest_pickup();
    self = old_self;

    setorigin(drop, org + '0 0 16');
};

float(float stage) SoE_HarvestPodChooseReward =
{
    float roll = random();

    // Weights are intentionally project-tunable approximations. The tier
    // relationships are verified; exact BO3 percentages are not.
    if (stage == SOE_POD_GREEN) {
        if (roll < 0.18) return SOE_POD_REWARD_PARASITE;
        if (roll < 0.32) return SOE_POD_REWARD_LIVE_GRENADE;
        if (roll < 0.52) return SOE_POD_REWARD_POINTS;
        if (roll < 0.78) return SOE_POD_REWARD_POWERUP;
        return SOE_POD_REWARD_WEAPON;
    }

    if (stage == SOE_POD_RED) {
        if (roll < 0.10) return SOE_POD_REWARD_PARASITE;
        if (roll < 0.16) return SOE_POD_REWARD_LIVE_GRENADE;
        if (roll < 0.31) return SOE_POD_REWARD_POINTS;
        if (roll < 0.61) return SOE_POD_REWARD_POWERUP;
        return SOE_POD_REWARD_WEAPON;
    }

    // Purple is the only tier capable of producing the Servant tentacle.
    if (!soe_has_margwa_tentacle && roll < 0.18)
        return SOE_POD_REWARD_TENTACLE;
    if (roll < 0.23) return SOE_POD_REWARD_PARASITE;
    if (roll < 0.33) return SOE_POD_REWARD_POINTS;
    if (roll < 0.63) return SOE_POD_REWARD_POWERUP;
    return SOE_POD_REWARD_WEAPON;
};

float(float stage) SoE_HarvestPodChooseWeapon =
{
    float roll = random();

    // Until BO3-era weapons are added to the project, use native NZ:P
    // equivalents by class/rarity. The reward table is isolated so exact
    // RK5/L-CAR/KRM/Kuda/HVK/Man-O-War/Haymaker/Bootlegger assets can replace
    // these IDs without touching pod logic.
    if (stage == SOE_POD_GREEN) {
        if (roll < 0.34) return W_COLT;
        if (roll < 0.67) return W_TRENCH;
        return W_MP40;
    }

    if (stage == SOE_POD_RED) {
        if (roll < 0.34) return W_MP40;
        if (roll < 0.67) return W_STG;
        return W_TRENCH;
    }

    if (roll < 0.08)
        return W_RAY;
    if (roll < 0.38)
        return W_STG;
    if (roll < 0.68)
        return W_MG;

    return W_BROWNING;
};

float(float stage) SoE_HarvestPodChoosePowerup =
{
    float roll = random();

    if (stage == SOE_POD_PURPLE && roll < 0.08)
        return PU_FREEPERK;
    if (roll < 0.18)
        return PU_NUKE;
    if (roll < 0.36)
        return PU_INSTAKILL;
    if (roll < 0.54)
        return PU_DOUBLEPTS;
    if (roll < 0.72)
        return PU_MAXAMMO;
    if (roll < 0.88)
        return PU_BONUSPOINTS;

    return PU_CARPENTER;
};

void(entity pod, entity player, float stage) SoE_HarvestPodDispense =
{
    float reward = SoE_HarvestPodChooseReward(stage);
    vector reward_org = pod.origin + '0 0 12';

    if (reward == SOE_POD_REWARD_PARASITE) {
        SoE_SpawnParasite(reward_org, false);
        return;
    }

    if (reward == SOE_POD_REWARD_LIVE_GRENADE) {
        SoE_SpawnLiveGrenadeReward(reward_org);
        return;
    }

    if (reward == SOE_POD_REWARD_POINTS) {
        Player_ChangeScore(player, 500, false);
        return;
    }

    if (reward == SOE_POD_REWARD_POWERUP) {
        Spawn_Powerup(reward_org, SoE_HarvestPodChoosePowerup(stage));
        return;
    }

    if (reward == SOE_POD_REWARD_WEAPON) {
        SoE_SpawnPodWeaponReward(reward_org, SoE_HarvestPodChooseWeapon(stage));
        return;
    }

    if (reward == SOE_POD_REWARD_TENTACLE) {
        SoE_SpawnTentacleReward(reward_org);
        return;
    }
};

void() SoE_HarvestPodTouch =
{
    if (other.classname != "player" || other.downed || other.isBuying)
        return;

    if (!other.soe_has_fumigator || self.soe_pod_stage == SOE_POD_DORMANT)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;

    float harvested_stage = self.soe_pod_stage;
    SoE_HarvestPodDispense(self, other, harvested_stage);

    self.soe_pod_stage = SOE_POD_DORMANT;

    float regrow = self.soe_pod_regrow_rounds;
    if (regrow <= 0)
        regrow = 2;

    self.soe_pod_next_growth_round = rounds + regrow;
    SoE_HarvestPodRefreshVisual(self);
    SoE_FireEntityTargets(self);
};

void() soe_harvest_pod =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Harvest Pod";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_HarvestPodTouch;

    if (self.soe_pod_growth_rounds <= 0)
        self.soe_pod_growth_rounds = 2;

    if (self.soe_pod_regrow_rounds <= 0)
        self.soe_pod_regrow_rounds = 2;

    // Map can override initial stage with style 1/2/3; default green.
    if (self.style >= SOE_POD_GREEN && self.style <= SOE_POD_PURPLE)
        self.soe_pod_stage = self.style;
    else
        self.soe_pod_stage = SOE_POD_GREEN;

    self.soe_pod_next_growth_round = rounds + self.soe_pod_growth_rounds;

    if (self.model != "")
        setmodel(self, self.model);
    else {
        setmodel(self, "models/sprites/sprkle.spr");
        setsize(self, '-16 -16 -10', '16 16 20');
    }

    SoE_HarvestPodRefreshVisual(self);
};

void() SoE_HarvestPodsOnNewRound =
{
    if (!soe_active)
        return;

    entity pod = find(world, classname, "soe_harvest_pod");

    while (pod != world) {
        if (pod.soe_pod_next_growth_round > 0 &&
            rounds >= pod.soe_pod_next_growth_round) {

            float growth = pod.soe_pod_growth_rounds;
            if (growth <= 0)
                growth = 2;

            if (pod.soe_pod_stage == SOE_POD_DORMANT)
                pod.soe_pod_stage = SOE_POD_GREEN;
            else if (pod.soe_pod_stage == SOE_POD_GREEN)
                pod.soe_pod_stage = SOE_POD_RED;
            else if (pod.soe_pod_stage == SOE_POD_RED)
                pod.soe_pod_stage = SOE_POD_PURPLE;

            if (pod.soe_pod_stage < SOE_POD_PURPLE)
                pod.soe_pod_next_growth_round = rounds + growth;
            else
                pod.soe_pod_next_growth_round = 0;

            SoE_HarvestPodRefreshVisual(pod);
        }

        pod = find(pod, classname, "soe_harvest_pod");
    }
};
