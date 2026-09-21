/*
    Shadows of Evil map-state foundation for NZ:P.

    This file intentionally contains only clean-room gameplay state and hooks.
    It does not contain Treyarch assets, scripts, dialogue, or leaked map data.

    Target upstream: nzp-team/quakec
    Pin: 04bd544172e16193162277a7c356c827e9653b06
*/

#define SOE_QUEST_NONE                  0
#define SOE_QUEST_RITUALS               1
#define SOE_QUEST_PAP_OPEN              2
#define SOE_QUEST_SWORDS                3
#define SOE_QUEST_REBORN_SWORDS         4
#define SOE_QUEST_FLAGS                 5
#define SOE_QUEST_SHADOWMAN             6
#define SOE_QUEST_FINALE                7
#define SOE_QUEST_COMPLETE              8

float soe_active;
float soe_quest_stage;

float soe_ritual_nero;
float soe_ritual_jackie;
float soe_ritual_jessica;
float soe_ritual_floyd;
float soe_gateworm_count;
float soe_gateworm_collected_mask;
float soe_gateworm_placed_mask;
float soe_pap_unlocked;

entity soe_active_ritual_controller;
float soe_ritual_keeper_next_spawn;

float soe_tram_symbol_a;
float soe_tram_symbol_b;
float soe_tram_symbol_c;

float soe_flag_district;
float soe_flag_defense_index;

float soe_finale_active;
float soe_giant_gateworm_hit;
float soe_station_shock_mask;
float soe_keeper_shock_mask;

float soe_scripted_margwa_pending;
float soe_next_regular_margwa_round;
float soe_pending_parasites;
float soe_margwa_kills;

float soe_margwa_mask_targets_enabled;
float soe_margwa_mask_heart_mask;
float soe_margwa_mask_first_route;
float soe_margwa_mask_complete;
.float soe_has_margwa_mask;

float soe_has_summoning_key;
float soe_has_lawyers_pen;
float soe_has_detective_badge;
float soe_has_toupee;
float soe_has_champ_belt;
float soe_has_margwa_heart;
float soe_has_xenomatter;
float soe_xenomatter_drop_active;
float soe_has_margwa_tentacle;
float soe_ritual_active;

// Reborn Sword quest bridge. Declared in the earliest SoE module so the
// Margwa runtime can tag quest-owned bosses before soe_sword.qc is compiled.
entity soe_reborn_pending_owner;
vector soe_reborn_pending_origin;
float soe_reborn_pending_circle_bit;
entity soe_reborn_active_owner;
float soe_reborn_global_circle_bit;
float soe_reborn_margwas_alive;
float soe_reborn_spawn_tag_remaining;
float soe_last_margwa_spawn_was_reborn;

.entity soe_reborn_owner;
.float soe_reborn_circle_bit;
.float soe_reborn_has_arch_ovum;
.float soe_reborn_ritual_mask;
.float soe_reborn_active_circle_bit;
.float soe_reborn_last_ritual_round;
.float soe_finale_beast_meter;
.float soe_perk_powered;

void(entity margwa) SoE_RebornOnMargwaKilled;
float(entity victim, entity attacker, float damage, float d_style) SoE_HandleShadowmanDamage;
void(entity margwa) SoE_FinaleOnMargwaKilled;
void(entity margwa) SoE_MargwaMaskOnMargwaKilled;
void() SoE_MargwaMaskOnTramRideStart;
float(entity victim, entity attacker, float damage, float d_style) SoE_HandleMargwaMaskHeartDamage;
float(entity victim, entity attacker, float damage, float d_style) SoE_HandleFlagShadowmanDamage;
float(entity victim, entity attacker, float damage, float d_style) SoE_HandleRoundSkipDamage;
float(entity victim, entity attacker, float damage, float d_style) SoE_HandleNoirPortraitDamage;
void() SoE_ResetSideQuests;
void(entity controller) SoE_RitualRuntimeStart;
void(entity controller) SoE_RitualRuntimeComplete;
void() SoE_RitualFrame;

float() SoE_IsMap =
{
    return (mapname == "soe" || mapname == "soe_g1" || mapname == "soe_g2" || mapname == "soe_g3" || mapname == "soe_g4" || mapname == "soe_g5" || mapname == "soe_g6" || mapname == "soe_g7" || mapname == "shadows_of_evil" || mapname == "zm_zod");
};

void() SoE_ResetQuestState =
{
    soe_quest_stage = SOE_QUEST_NONE;

    soe_ritual_nero = false;
    soe_ritual_jackie = false;
    soe_ritual_jessica = false;
    soe_ritual_floyd = false;
    soe_gateworm_count = 0;
    soe_gateworm_collected_mask = 0;
    soe_gateworm_placed_mask = 0;
    soe_pap_unlocked = false;

    soe_active_ritual_controller = world;
    soe_ritual_keeper_next_spawn = 0;

    soe_tram_symbol_a = -1;
    soe_tram_symbol_b = -1;
    soe_tram_symbol_c = -1;

    soe_flag_district = 0;
    soe_flag_defense_index = 0;

    soe_finale_active = false;
    soe_giant_gateworm_hit = false;
    soe_station_shock_mask = 0;
    soe_keeper_shock_mask = 0;

    soe_scripted_margwa_pending = 0;
    soe_next_regular_margwa_round = 8;
    soe_pending_parasites = 0;
    soe_margwa_kills = 0;

    soe_margwa_mask_targets_enabled = false;
    soe_margwa_mask_heart_mask = 0;
    soe_margwa_mask_first_route = -1;
    soe_margwa_mask_complete = false;

    soe_has_summoning_key = false;
    soe_has_lawyers_pen = false;
    soe_has_detective_badge = false;
    soe_has_toupee = false;
    soe_has_champ_belt = false;
    soe_has_margwa_heart = false;
    soe_has_xenomatter = false;
    soe_xenomatter_drop_active = false;
    soe_has_margwa_tentacle = false;
    soe_ritual_active = false;

    soe_reborn_pending_owner = world;
    soe_reborn_pending_origin = '0 0 0';
    soe_reborn_pending_circle_bit = 0;
    soe_reborn_active_owner = world;
    soe_reborn_global_circle_bit = 0;
    soe_reborn_margwas_alive = 0;
    soe_reborn_spawn_tag_remaining = 0;
    soe_last_margwa_spawn_was_reborn = false;
};

void() SoE_Init =
{
    soe_active = SoE_IsMap();

    if (!soe_active)
        return;

    SoE_ResetQuestState();
    soe_quest_stage = SOE_QUEST_RITUALS;

    // Shadows of Evil does not use the classic global power-switch flow.
    // Individual Beast-powered interactions will be implemented by the
    // dedicated SoE entity modules.
    isPowerOn = false;
};

void() SoE_OnNewRound =
{
    if (!soe_active)
        return;

    // NZ:P invokes this hook before its NewRound() body increments rounds.
    float upcoming_round = rounds + 1;

    // Natural Margwa scheduling begins on round 8. After a natural spawn,
    // soe_specials.qc chooses the next regular boss gap.
    if (upcoming_round == soe_next_regular_margwa_round)
        soe_scripted_margwa_pending = soe_scripted_margwa_pending + 1;
};

void() SoE_MarkRitualComplete =
{
    if (!soe_active)
        return;

    // Map entities set one of the ritual flags before calling this helper.
    soe_gateworm_count =
        soe_ritual_nero +
        soe_ritual_jackie +
        soe_ritual_jessica +
        soe_ritual_floyd;

    // Original behavior: scripted Margwas after ritual #2 and #4.
    if (soe_gateworm_count == 2 || soe_gateworm_count == 4)
        soe_scripted_margwa_pending = soe_scripted_margwa_pending + 1;
};

void() SoE_UnlockPackAPunch =
{
    if (!soe_active || soe_gateworm_count < 4)
        return;

    soe_pap_unlocked = true;

    // Sword progression can legitimately happen before the fifth ritual.
    // Never regress a more advanced parallel quest stage when PaP opens.
    if (soe_quest_stage < SOE_QUEST_PAP_OPEN)
        soe_quest_stage = SOE_QUEST_PAP_OPEN;
};

void() SoE_StartFinale =
{
    if (!soe_active)
        return;

    soe_finale_active = true;
    soe_quest_stage = SOE_QUEST_FINALE;
};

void() SoE_CompleteQuest =
{
    if (!soe_active)
        return;

    soe_finale_active = false;
    soe_quest_stage = SOE_QUEST_COMPLETE;
};
