/*
    Shadows of Evil - Main quest flag phase foundation.

    Flow:
      all active Sword owners upgraded + Pack-a-Punch open
      -> interact with Nero's book
      -> Flag spawns at Rift marker
      -> pickup clears the current combat wave
      -> defend at two sites in one district, 30 seconds each
      -> deliver to that district's Keeper
      -> next district starts on a later round
      -> all four district Keepers complete -> Shadowman phase

    District IDs:
      1 Junction
      2 Footlight
      3 Waterfront
      4 Canals
*/

float soe_book_used;
float soe_flag_spawned;
entity soe_flag_entity;
entity soe_flag_carrier;

float soe_flag_active_district;
float soe_flag_site_mask;
float soe_flag_completed_district_mask;
float soe_flag_defense_active;
float soe_flag_defense_until;
float soe_flag_health;
float soe_flag_last_completed_round;
float soe_flag_failed_round;
float soe_flag_next_enemy_spawn;
float soe_flag_shadowman_next_at;
entity soe_flag_current_site;
entity soe_flag_shadowman_ent;

.float soe_flag_shadowman_expire;

.float soe_flag_district_id;
.float soe_flag_site_index;

void(entity victim, entity attacker, float damage, float d_style) DamageHandler;
entity(vector org, float counts_round) SoE_SpawnParasite;
entity(vector org, entity target, float counts_round) SoE_SpawnElementalWarning;
void(vector where, float type) Spawn_Powerup;
void() SoE_FlagPickupTouch;

float(float district_id) SoE_FlagDistrictBit =
{
    if (district_id == 1) return 1;
    if (district_id == 2) return 2;
    if (district_id == 3) return 4;
    if (district_id == 4) return 8;
    return 0;
};

void() SoE_ResetMainQuest =
{
    soe_book_used = false;
    soe_flag_spawned = false;
    soe_flag_entity = world;
    soe_flag_carrier = world;

    soe_flag_active_district = 0;
    soe_flag_site_mask = 0;
    soe_flag_completed_district_mask = 0;
    soe_flag_defense_active = false;
    soe_flag_defense_until = 0;
    soe_flag_health = 100;
    soe_flag_last_completed_round = -1;
    soe_flag_failed_round = -1;
    soe_flag_next_enemy_spawn = 0;
    soe_flag_shadowman_next_at = 0;
    soe_flag_current_site = world;
    soe_flag_shadowman_ent = world;
};

entity() SoE_FindFlagSpawnMarker =
{
    return find(world, classname, "soe_flag_spawn");
};

void(entity flag) SoE_ShowFlag =
{
    flag.solid = SOLID_TRIGGER;
    flag.touch = SoE_FlagPickupTouch;
    flag.effects = EF_FULLBRIGHT;

    if (flag.model == "")
        setmodel(flag, "models/sprites/sprkle.spr");

    setsize(flag, '-12 -12 -18', '12 12 28');
};

entity(vector org) SoE_SpawnQuestFlagAt =
{
    if (soe_flag_entity != world)
        remove(soe_flag_entity);

    entity flag = spawn();
    flag.classname = "soe_quest_flag";
    flag.movetype = MOVETYPE_NONE;
    flag.useprint_string_1 = "Hold %b to Take the Flag";
    flag.useprint_index_1 = Useprint_Register(flag.useprint_string_1, '1 1 1');
    setorigin(flag, org);
    SoE_ShowFlag(flag);

    soe_flag_entity = flag;
    soe_flag_spawned = true;
    soe_flag_carrier = world;
    return flag;
};

void() SoE_SpawnQuestFlagAtRift =
{
    entity marker = SoE_FindFlagSpawnMarker();
    if (marker == world)
        return;

    SoE_SpawnQuestFlagAt(marker.origin);
};

void() soe_flag_spawn =
{
    self.solid = SOLID_NOT;
    self.movetype = MOVETYPE_NONE;
    setsize(self, '0 0 0', '0 0 0');
};

void() SoE_ClearEnemiesForFlag =
{
    entity ent;
    entity next;

    ent = find(world, classname, "ai_zombie");
    while (ent != world) {
        next = find(ent, classname, "ai_zombie");

        // Keep quest Margwas alive; the flag step must not silently complete
        // somebody's Arch-Ovum ritual.
        if (ent.aistatus == "1" &&
            ent.soe_special_type != SOE_SPECIAL_MARGWA)
            DamageHandler(ent, world, 999999, DMG_TYPE_OTHER);

        ent = next;
    }

    ent = find(world, classname, "ai_dog");
    while (ent != world) {
        next = find(ent, classname, "ai_dog");
        if (ent.aistatus == "1")
            DamageHandler(ent, world, 999999, DMG_TYPE_OTHER);
        ent = next;
    }

    ent = find(world, classname, "soe_parasite");
    while (ent != world) {
        next = find(ent, classname, "soe_parasite");
        DamageHandler(ent, world, 999999, DMG_TYPE_OTHER);
        ent = next;
    }

    ent = find(world, classname, "soe_elemental");
    while (ent != world) {
        next = find(ent, classname, "soe_elemental");
        DamageHandler(ent, world, 999999, DMG_TYPE_OTHER);
        ent = next;
    }

    ent = find(world, classname, "soe_elemental_warning");
    while (ent != world) {
        next = find(ent, classname, "soe_elemental_warning");
        remove(ent);
        ent = next;
    }

    // Flag encounters own their enemy stream; do not let a scheduled special
    // round continue spawning on top of it.
    soe_special_round_active = false;
    soe_special_round_type = SOE_SPECIAL_ROUND_NONE;
    roundtype = 4;

    // Hold the round open until district delivery or failure.
    Remaining_Zombies = 1;
};

void() SoE_FlagPickupTouch =
{
    if (other.classname != "player" || other.downed || other.isBuying)
        return;

    if (soe_flag_carrier != world || soe_flag_defense_active)
        return;

    if (soe_flag_last_completed_round == rounds)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;

    soe_flag_carrier = other;
    soe_flag_spawned = false;
    self.solid = SOLID_NOT;
    self.touch = SUB_Null;
    setmodel(self, "");

    // Only the first pickup for a district cycle clears the existing wave.
    if (soe_flag_active_district == 0 && soe_flag_site_mask == 0)
        SoE_ClearEnemiesForFlag();
};

void() SoE_FlagSiteTouch =
{
    if (other.classname != "player" || other != soe_flag_carrier)
        return;

    if (soe_flag_defense_active)
        return;

    float district_id = self.soe_flag_district_id;
    float site_index = self.soe_flag_site_index;
    float district_bit = SoE_FlagDistrictBit(district_id);

    if (district_bit == 0 || (soe_flag_completed_district_mask & district_bit))
        return;

    if (site_index != 1 && site_index != 2)
        return;

    if (soe_flag_active_district != 0 && soe_flag_active_district != district_id)
        return;

    float site_bit = site_index;
    if (site_index == 2)
        site_bit = 2;

    if (soe_flag_site_mask & site_bit)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;

    soe_flag_active_district = district_id;
    soe_flag_carrier = world;
    soe_flag_current_site = self;
    soe_flag_defense_active = true;
    soe_flag_defense_until = time + 30;
    soe_flag_health = 100;
    soe_flag_next_enemy_spawn = time + 0.2;
    soe_flag_shadowman_next_at = time + 4 + (random() * 2);

    setorigin(soe_flag_entity, self.origin + '0 0 20');
    SoE_ShowFlag(soe_flag_entity);

    // While planted the flag is visible but cannot be picked up.
    soe_flag_entity.solid = SOLID_NOT;
    soe_flag_entity.touch = SUB_Null;

    SoE_FireEntityTargets(self);
};

void() soe_flag_site =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Plant Flag";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.soe_flag_district_id = self.style;
    self.soe_flag_site_index = self.health;

    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_FlagSiteTouch;

    if (self.model != "")
        setmodel(self, self.model);
    else
        setsize(self, '-28 -28 -12', '28 28 28');
};

void() SoE_FlagKeeperTouch =
{
    if (other.classname != "player" || other != soe_flag_carrier)
        return;

    float district_id = self.soe_flag_district_id;
    float district_bit = SoE_FlagDistrictBit(district_id);

    if (district_id != soe_flag_active_district ||
        soe_flag_site_mask != 3 ||
        district_bit == 0)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;

    soe_flag_completed_district_mask = soe_flag_completed_district_mask | district_bit;
    soe_flag_last_completed_round = rounds;
    soe_flag_carrier = world;
    soe_flag_spawned = false;

    if (soe_flag_entity != world) {
        remove(soe_flag_entity);
        soe_flag_entity = world;
    }

    soe_flag_active_district = 0;
    soe_flag_site_mask = 0;
    soe_flag_current_site = world;

    SoE_FireEntityTargets(self);

    // Delivering the charged flag to a district Keeper spawns a Margwa.
    soe_scripted_margwa_pending = soe_scripted_margwa_pending + 1;

    if (soe_flag_completed_district_mask == 15) {
        soe_quest_stage = SOE_QUEST_SHADOWMAN;
    }

    // The district is one-per-round; release the round after delivery.
    Remaining_Zombies = 0;
    roundtype = 1;
};

void() soe_flag_keeper =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Give Flag to Keeper";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.soe_flag_district_id = self.style;

    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_FlagKeeperTouch;

    if (self.model != "")
        setmodel(self, self.model);
    else {
        setmodel(self, "models/sprites/sprkle.spr");
        setsize(self, '-18 -18 -26', '18 18 36');
        self.effects = EF_FULLBRIGHT;
    }
};

void() SoE_FlagDefenseFail =
{
    soe_flag_defense_active = false;
    soe_flag_carrier = world;
    soe_flag_spawned = false;
    soe_flag_health = 100;
    soe_flag_current_site = world;

    if (soe_flag_shadowman_ent != world) {
        remove(soe_flag_shadowman_ent);
        soe_flag_shadowman_ent = world;
    }

    // Canonical retry behavior: a destroyed flag immediately returns to the
    // Underground. Completed site progress in this district is preserved.
    SoE_SpawnQuestFlagAtRift();
};

void() SoE_FlagDefenseComplete =
{
    if (!soe_flag_defense_active || soe_flag_current_site == world)
        return;

    float site_index = soe_flag_current_site.soe_flag_site_index;
    float site_bit = 1;
    if (site_index == 2)
        site_bit = 2;

    soe_flag_site_mask = soe_flag_site_mask | site_bit;
    soe_flag_defense_active = false;
    soe_flag_health = 100;

    if (soe_flag_shadowman_ent != world) {
        remove(soe_flag_shadowman_ent);
        soe_flag_shadowman_ent = world;
    }

    Spawn_Powerup(soe_flag_entity.origin + '0 0 28', PU_MAXAMMO);

    // The charged flag can now be picked up and moved to the second site or
    // to the district Keeper after both sites are complete.
    SoE_ShowFlag(soe_flag_entity);
    soe_flag_spawned = true;
    soe_flag_current_site = world;
};

void() SoE_FlagSpawnDefenseEnemy =
{
    if (!soe_flag_defense_active || soe_flag_entity == world)
        return;

    entity target = find(world, classname, "player");
    if (target == world)
        return;

    vector org = soe_flag_entity.origin;
    org_x = org_x + ((random() * 420) - 210);
    org_y = org_y + ((random() * 420) - 210);
    org_z = org_z + 64;

    if (random() < 0.72)
        SoE_SpawnElementalWarning(org, target, false);
    else
        SoE_SpawnParasite(org, false);
};


void() SoE_FlagShadowmanThink =
{
    if (!soe_flag_defense_active ||
        soe_flag_entity == world ||
        self != soe_flag_shadowman_ent) {
        if (self == soe_flag_shadowman_ent)
            soe_flag_shadowman_ent = world;
        remove(self);
        return;
    }

    if (time < self.soe_flag_shadowman_expire) {
        self.nextthink = time + 0.05;
        return;
    }

    // If players fail to drive him away, he damages/delays the flag and
    // escalates pressure with an extra Parasite burst.
    soe_flag_health = soe_flag_health - 35;

    for (float i = 0; i < 3; i++) {
        vector org = soe_flag_entity.origin;
        org_x = org_x + ((random() * 240) - 120);
        org_y = org_y + ((random() * 240) - 120);
        org_z = org_z + 80;
        SoE_SpawnParasite(org, false);
    }

    soe_flag_shadowman_ent = world;
    soe_flag_shadowman_next_at = time + 4 + (random() * 3);
    remove(self);

    if (soe_flag_health <= 0)
        SoE_FlagDefenseFail();
};

entity(float district_id) SoE_FindFlagShadowmanMarker =
{
    entity marker = find(world, classname, "soe_flag_shadowman_spawn");
    entity chosen = world;
    float seen = 0;

    while (marker != world) {
        if (marker.style == 0 || marker.style == district_id) {
            seen = seen + 1;
            if (random() < (1 / seen))
                chosen = marker;
        }

        marker = find(marker, classname, "soe_flag_shadowman_spawn");
    }

    return chosen;
};

void() SoE_SpawnFlagShadowman =
{
    if (!soe_flag_defense_active ||
        soe_flag_entity == world ||
        soe_flag_shadowman_ent != world)
        return;

    entity marker = SoE_FindFlagShadowmanMarker(soe_flag_active_district);
    vector org;

    if (marker != world) {
        org = marker.origin;
    } else {
        org = soe_flag_entity.origin;
        org_x = org_x + ((random() * 320) - 160);
        org_y = org_y + ((random() * 320) - 160);
        org_z = org_z + 120;
    }

    entity shadow = spawn();
    shadow.classname = "soe_flag_shadowman";
    shadow.movetype = MOVETYPE_FLY;
    shadow.solid = SOLID_BBOX;
    shadow.takedamage = DAMAGE_YES;
    shadow.health = 1;
    shadow.effects = EF_FULLBRIGHT;
    shadow.soe_flag_shadowman_expire = time + 3.5;
    shadow.think = SoE_FlagShadowmanThink;
    shadow.nextthink = time + 0.05;

    setmodel(shadow, "models/sprites/sprkle.spr");
    setsize(shadow, '-14 -14 -24', '14 14 30');
    setorigin(shadow, org);

    soe_flag_shadowman_ent = shadow;
};

float(entity victim, entity attacker, float damage, float d_style) SoE_HandleFlagShadowmanDamage =
{
    if (!soe_active || victim.classname != "soe_flag_shadowman")
        return false;

    if (attacker.classname == "player" && damage > 0) {
        if (victim == soe_flag_shadowman_ent)
            soe_flag_shadowman_ent = world;

        soe_flag_shadowman_next_at = time + 4 + (random() * 3);
        remove(victim);
    }

    return true;
};

void() soe_flag_shadowman_spawn =
{
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_NOT;
    setsize(self, '0 0 0', '0 0 0');
};

void() SoE_FlagDefenseCheckImpacts =
{
    if (!soe_flag_defense_active || soe_flag_entity == world)
        return;

    entity ent = findradius(soe_flag_entity.origin, 52);

    while (ent != world) {
        entity next = ent.chain;

        if (ent.classname == "soe_elemental" ||
            ent.classname == "soe_elemental_warning") {
            soe_flag_health = soe_flag_health - 24;
            remove(ent);
        } else if (ent.classname == "soe_parasite") {
            soe_flag_health = soe_flag_health - 12;
            remove(ent);
        }

        ent = next;
    }

    if (soe_flag_health <= 0)
        SoE_FlagDefenseFail();
};

void() SoE_MainQuestFrame =
{
    if (!soe_active || soe_quest_stage != SOE_QUEST_FLAGS)
        return;

    // Carrier loss: if the carrier goes down, return the flag to the Rift and
    // keep the district progress for that round.
    if (soe_flag_carrier != world && soe_flag_carrier.downed) {
        entity marker = SoE_FindFlagSpawnMarker();
        soe_flag_carrier = world;

        if (marker != world)
            SoE_SpawnQuestFlagAt(marker.origin);
    }

    if (!soe_flag_defense_active)
        return;

    SoE_FlagDefenseCheckImpacts();

    if (!soe_flag_defense_active)
        return;

    if (time >= soe_flag_defense_until) {
        SoE_FlagDefenseComplete();
        return;
    }

    if (soe_flag_next_enemy_spawn <= time) {
        SoE_FlagSpawnDefenseEnemy();
        soe_flag_next_enemy_spawn = time + 0.45;
    }

    if (soe_flag_shadowman_next_at <= time &&
        soe_flag_shadowman_ent == world) {
        SoE_SpawnFlagShadowman();
    }
};

void() SoE_MainQuestOnNewRound =
{
    if (!soe_active || !soe_book_used || soe_quest_stage != SOE_QUEST_FLAGS)
        return;

    if (soe_flag_completed_district_mask == 15)
        return;

    if (soe_flag_entity != world ||
        soe_flag_carrier != world ||
        soe_flag_defense_active)
        return;

    // Successful district delivery is one-per-round; the next district flag
    // respawns after the round rolls.
    SoE_SpawnQuestFlagAtRift();
};

void() SoE_MainQuestBookTouch =
{
    if (other.classname != "player" || other.downed || other.isBuying)
        return;

    if (soe_book_used || !soe_pap_unlocked)
        return;

    if (soe_quest_stage < SOE_QUEST_REBORN_SWORDS ||
        !SoE_AllActiveSwordOwnersUpgraded())
        return;

    if (!PlayerIsLooking(other, self))
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;
    soe_book_used = true;
    soe_quest_stage = SOE_QUEST_FLAGS;

    SoE_SpawnQuestFlagAtRift();
    SoE_FireEntityTargets(self);
};

void() soe_mainquest_book =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Open the Book";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_MainQuestBookTouch;

    if (self.model != "")
        setmodel(self, self.model);
    else
        setsize(self, '-14 -10 -6', '14 10 8');
};
