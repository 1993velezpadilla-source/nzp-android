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
