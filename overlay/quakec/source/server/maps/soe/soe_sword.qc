/*
    Shadows of Evil - Apothicon Sword acquisition runtime.

    Flow:
      Tram selects 3 unique symbols from a 9-symbol pool.
      Beast shocks those 3 glyphs on the Rift wall in any order.
      Any wrong glyph resets progress and locks retry until next round.
      Wall opens -> each player takes an Ovum.
      Each player charges that Ovum at Rift/Canal/Footlight/Waterfront statues.
      ~12 normal-zombie souls per statue.
      Fully charged Ovum returns to Rift altar, then Sword is claimed.
*/

float soe_sword_wall_open;
float soe_sword_glyph_mask;
float soe_sword_glyph_count;
float soe_sword_wall_failed_round;

.float soe_sword_has_egg;
.float soe_sword_statue_mask;
.entity soe_sword_statue_ent;
.float soe_sword_souls;
.float soe_sword_statue_charged;
.float soe_sword_egg_returned;
.float soe_has_sword;
.float soe_sword_upgraded;

float(float glyph_id) SoE_GlyphBit =
{
    if (glyph_id == 0) return 1;
    if (glyph_id == 1) return 2;
    if (glyph_id == 2) return 4;
    if (glyph_id == 3) return 8;
    if (glyph_id == 4) return 16;
    if (glyph_id == 5) return 32;
    if (glyph_id == 6) return 64;
    if (glyph_id == 7) return 128;
    if (glyph_id == 8) return 256;
    return 0;
};

float(float glyph_id) SoE_IsCorrectSwordGlyph =
{
    return (
        glyph_id == soe_tram_symbol_a ||
        glyph_id == soe_tram_symbol_b ||
        glyph_id == soe_tram_symbol_c
    );
};

void() SoE_ResetSword =
{
    soe_sword_wall_open = false;
    soe_sword_glyph_mask = 0;
    soe_sword_glyph_count = 0;
    soe_sword_wall_failed_round = -1;
};

void() SoE_SwordGlyphTouch =
{
    if (other.classname != "player" || !other.soe_beast_active)
        return;

    if (soe_sword_wall_open)
        return;

    // A wrong input hides/resets the wall for the rest of the current round.
    if (soe_sword_wall_failed_round == rounds)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;

    float glyph_id = self.style;
    float bit = SoE_GlyphBit(glyph_id);

    if (!SoE_IsCorrectSwordGlyph(glyph_id)) {
        soe_sword_glyph_mask = 0;
        soe_sword_glyph_count = 0;
        soe_sword_wall_failed_round = rounds;
        SoE_FireEntityTargets(self);
        return;
    }

    if (soe_sword_glyph_mask & bit)
        return;

    soe_sword_glyph_mask = soe_sword_glyph_mask | bit;
    soe_sword_glyph_count = soe_sword_glyph_count + 1;

    if (soe_sword_glyph_count >= 3) {
        soe_sword_wall_open = true;

        if (soe_quest_stage < SOE_QUEST_SWORDS)
            soe_quest_stage = SOE_QUEST_SWORDS;

        SoE_FireEntityTargets(self);
    }
};

void() soe_sword_glyph =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Shock Glyph";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_SwordGlyphTouch;

    if (self.model != "")
        setmodel(self, self.model);
    else {
        setmodel(self, "models/sprites/sprkle.spr");
        setsize(self, '-12 -6 -12', '12 6 12');
        self.effects = EF_FULLBRIGHT;
    }
};

void() SoE_SwordAltarTouch =
{
    if (other.classname != "player" || other.downed || other.isBuying)
        return;

    if (!soe_sword_wall_open || other.soe_has_sword)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;

    // First interaction: each player receives their own Ovum.
    if (!other.soe_sword_has_egg &&
        other.soe_sword_statue_mask == 0 &&
        !other.soe_sword_egg_returned) {
        other.soe_sword_has_egg = true;
        other.soe_sword_souls = 0;
        return;
    }

    // Fully charged egg is returned to the Rift pedestal first.
    if (other.soe_sword_has_egg &&
        other.soe_sword_statue_mask == 15 &&
        !other.soe_sword_egg_returned) {
        other.soe_sword_has_egg = false;
        other.soe_sword_egg_returned = true;
        return;
    }

    // Second interaction after returning the egg draws the Sword.
    if (other.soe_sword_egg_returned) {
        other.soe_has_sword = true;
        other.soe_sword_egg_returned = false;
        SoE_FireEntityTargets(self);
    }
};

void() soe_sword_altar =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Interact with Ovum Altar";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_SwordAltarTouch;

    if (self.model != "")
        setmodel(self, self.model);
    else
        setsize(self, '-30 -20 -20', '30 20 36');
};

void() SoE_SwordStatueRevealUse =
{
    self.state = 1;
    self.solid = SOLID_TRIGGER;

    if (self.model != "")
        setmodel(self, self.model);
};

void() SoE_SwordStatueTouch =
{
    if (self.state == 0)
        return;

    if (other.classname != "player" || other.downed || other.isBuying)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    float statue_bit = self.style;
    if (statue_bit != 1 && statue_bit != 2 && statue_bit != 4 && statue_bit != 8)
        return;

    // Return a fully charged Ovum from this statue.
    if (other.soe_sword_statue_ent == self && other.soe_sword_statue_charged) {
        Player_UseprintWithWait(other, self, self.useprint_index_2, 0);

        if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
            return;

        other.semi_actions |= SEMIACTION_USE;
        other.soe_sword_statue_mask = other.soe_sword_statue_mask | statue_bit;
        other.soe_sword_statue_ent = world;
        other.soe_sword_statue_charged = false;
        other.soe_sword_souls = 0;
        other.soe_sword_has_egg = true;
        return;
    }

    // Place a held Ovum at a statue the player has not completed.
    if (!other.soe_sword_has_egg ||
        other.soe_sword_statue_ent != world ||
        (other.soe_sword_statue_mask & statue_bit))
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;
    other.soe_sword_has_egg = false;
    other.soe_sword_statue_ent = self;
    other.soe_sword_statue_charged = false;
    other.soe_sword_souls = 0;
};

void() soe_sword_statue =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Place Ovum";
    if (self.useprint_string_2 == "")
        self.useprint_string_2 = "Hold %b to Take Charged Ovum";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.useprint_index_2 = Useprint_Register(self.useprint_string_2, self.useprint_color_2);

    self.movetype = MOVETYPE_NONE;
    self.touch = SoE_SwordStatueTouch;
    self.use = SoE_SwordStatueRevealUse;

    // spawnflag 1: already exposed for testing/clean-room iteration.
    if (self.spawnflags & 1) {
        self.state = 1;
        self.solid = SOLID_TRIGGER;
    } else {
        self.state = 0;
        self.solid = SOLID_NOT;
    }

    if (self.model != "")
        setmodel(self, self.model);
    else {
        setmodel(self, "models/sprites/sprkle.spr");
        setsize(self, '-22 -22 -20', '22 22 40');
        self.effects = EF_FULLBRIGHT;
    }
};

void(entity dead_enemy) SoE_SwordOnEnemyDeath =
{
    if (!soe_active || dead_enemy == world)
        return;

    // Ovum statues consume normal zombie souls, not Margwa/special-enemy deaths.
    if (dead_enemy.classname != "ai_zombie" ||
        dead_enemy.soe_special_type != SOE_SPECIAL_NONE)
        return;

    entity player = find(world, classname, "player");
    while (player != world) {
        if (player.soe_sword_statue_ent != world &&
            !player.soe_sword_statue_charged) {

            float distance = vlen(dead_enemy.origin - player.soe_sword_statue_ent.origin);
            if (distance <= 220) {
                player.soe_sword_souls = player.soe_sword_souls + 1;

                if (player.soe_sword_souls >= 12)
                    player.soe_sword_statue_charged = true;
            }
        }

        player = find(player, classname, "player");
    }
};


/*
    Reborn Keeper Sword / Arch-Ovum upgrade.

    Mapper contract:
      soe_reborn_keeper style 1..4 = player slot / character path
      soe_reborn_circle style 1,2,4,8 = the four red ritual circles
      target on each circle may drive clean-room FX/arena doors

    The player-slot mapping is intentionally explicit so co-op quest ownership
    cannot bleed between players. A later Morg City geometry pass can map
    slots to Nero/Jackie/Jessica/Floyd presentation without changing logic.
*/


float(float mask) SoE_RebornCompletedCircleCount =
{
    float count = 0;
    if (mask & 1) count = count + 1;
    if (mask & 2) count = count + 1;
    if (mask & 4) count = count + 1;
    if (mask & 8) count = count + 1;
    return count;
};

float() SoE_AllActiveSwordOwnersUpgraded =
{
    entity player = find(world, classname, "player");
    float found = false;

    while (player != world) {
        if (!player.is_spectator && player.soe_has_sword) {
            found = true;
            if (!player.soe_sword_upgraded)
                return false;
        }

        player = find(player, classname, "player");
    }

    return found;
};

void() SoE_RebornKeeperTouch =
{
    if (other.classname != "player" || other.downed || other.isBuying)
        return;

    if (!other.soe_has_sword || other.soe_sword_upgraded)
        return;

    // style 1..4 binds the Keeper to the corresponding player/character slot.
    if (self.style >= 1 && self.style <= 4 && other.playernum != self.style)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;

    // First interaction after obtaining the Sword gives the character Arch-Ovum.
    if (!other.soe_reborn_has_arch_ovum && other.soe_reborn_ritual_mask == 0) {
        other.soe_reborn_has_arch_ovum = true;
        other.soe_reborn_global_circle_bit = 0;
        other.soe_reborn_last_ritual_round = -1;
        SoE_FireEntityTargets(self);
        return;
    }

    // Return fully charged Arch-Ovum and receive Reborn Sword.
    if (other.soe_reborn_has_arch_ovum &&
        other.soe_reborn_ritual_mask == 15 &&
        other.soe_reborn_active_circle_bit == 0) {
        other.soe_reborn_has_arch_ovum = false;
        other.soe_sword_upgraded = true;

        if (SoE_AllActiveSwordOwnersUpgraded())
            soe_quest_stage = SOE_QUEST_REBORN_SWORDS;

        SoE_FireEntityTargets(self);
    }
};

void() soe_reborn_keeper =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Commune with Keeper";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_RebornKeeperTouch;

    if (self.model != "")
        setmodel(self, self.model);
    else {
        setmodel(self, "models/sprites/sprkle.spr");
        setsize(self, '-18 -18 -28', '18 18 36');
        self.effects = EF_FULLBRIGHT;
    }
};

void() SoE_RebornCircleTouch =
{
    if (other.classname != "player" || other.downed || other.isBuying)
        return;

    if (!other.soe_has_sword ||
        !other.soe_reborn_has_arch_ovum ||
        other.soe_sword_upgraded)
        return;

    if (other.soe_reborn_active_circle_bit != 0)
        return;

    // One red-circle ritual per player per round.
    if (other.soe_reborn_last_ritual_round == rounds)
        return;

    float circle_bit = self.style;
    if (circle_bit != 1 && circle_bit != 2 && circle_bit != 4 && circle_bit != 8)
        return;

    if (other.soe_reborn_ritual_mask & circle_bit)
        return;

    // Only one Arch-Ovum ritual may run globally at a time.
    if (soe_reborn_active_owner != world)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;
    other.soe_reborn_global_circle_bit = circle_bit;
    other.soe_reborn_last_ritual_round = rounds;

    float completed = SoE_RebornCompletedCircleCount(other.soe_reborn_ritual_mask);
    float margwa_count = 2;

    // Canonical upgrade pacing: first red-circle ritual spawns one Margwa;
    // the following three spawn two each, for seven total per player.
    if (completed == 0)
        margwa_count = 1;

    soe_reborn_active_owner = other;
    soe_reborn_global_circle_bit = circle_bit;
    soe_reborn_margwas_alive = margwa_count;
    soe_reborn_spawn_tag_remaining = margwa_count;

    soe_reborn_pending_owner = other;
    soe_reborn_pending_origin = self.origin;
    soe_reborn_pending_circle_bit = circle_bit;

    soe_scripted_margwa_pending = soe_scripted_margwa_pending + margwa_count;

    SoE_FireEntityTargets(self);
};

void() soe_reborn_circle =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Begin Arch-Ovum Ritual";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_RebornCircleTouch;

    if (self.model != "")
        setmodel(self, self.model);
    else {
        setmodel(self, "models/sprites/sprkle.spr");
        setsize(self, '-34 -34 -8', '34 34 12');
        self.effects = EF_FULLBRIGHT;
    }
};

void(entity margwa) SoE_RebornOnMargwaKilled =
{
    if (!soe_active || margwa == world)
        return;

    entity owner = margwa.soe_reborn_owner;
    float circle_bit = margwa.soe_reborn_circle_bit;

    if (owner == world || circle_bit == 0)
        return;

    // Ownership survives all three Margwa head phases and is consumed only
    // when the quest Margwa actually dies.
    if (!owner.soe_reborn_has_arch_ovum ||
        owner.soe_sword_upgraded ||
        owner.soe_reborn_active_circle_bit != circle_bit)
        return;

    margwa.soe_reborn_owner = world;
    margwa.soe_reborn_circle_bit = 0;

    if (soe_reborn_margwas_alive > 0)
        soe_reborn_margwas_alive = soe_reborn_margwas_alive - 1;

    // The ritual completes only when all Margwas spawned by that circle die.
    if (soe_reborn_margwas_alive > 0)
        return;

    owner.soe_reborn_ritual_mask = owner.soe_reborn_ritual_mask | circle_bit;
    owner.soe_reborn_global_circle_bit = 0;

    soe_reborn_active_owner = world;
    soe_reborn_global_circle_bit = 0;
    soe_reborn_spawn_tag_remaining = 0;
    soe_reborn_pending_owner = world;
    soe_reborn_pending_circle_bit = 0;

    // FX/arena cleanup is mapper-driven by entities that watch the completed
    // player's state; gameplay ownership remains per-player.
};
