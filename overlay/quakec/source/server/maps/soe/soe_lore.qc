/*
    Shadows of Evil - lore / secret discovery runtime.

    Tracks discovery without bundling Treyarch text, VO, or imagery.
    Mapper/client targets supply project-owned presentation.

    Entities:
      soe_scrap_piece style 1..10
      soe_cipher style 1..5
      soe_lore_device style 1..12
      soe_shadowman_sighting style 1..8
      soe_noir_portrait
*/

.float soe_scrap_mask;
.float soe_cipher_mask;
.float soe_lore_heard_mask;
.float soe_shadowman_sighting_mask;
.float soe_shadowman_sighting_count;
.float soe_noir_enabled;

.float soe_lore_enabled;
.float soe_noir_exposed;

float(float index) SoE_LoreBit =
{
    if (index < 1 || index > 16)
        return 0;

    float bit = 1;
    for (float i = 1; i < index; i++)
        bit = bit * 2;

    return bit;
};

void(entity relay, entity player, float alt_target) SoE_FirePlayerPresentation =
{
    if (relay == world)
        return;

    string saved_target = relay.target;

    if (alt_target && relay.target2 != "")
        relay.target = relay.target2;

    entity old_self = self;
    entity old_other = other;

    self = relay;
    other = player;
    SoE_FireEntityTargets(relay);

    self = old_self;
    other = old_other;
    relay.target = saved_target;
};

/* Scrap mural discovery */

void() SoE_ScrapTouch =
{
    if (other.classname != "player" || other.downed || other.isBuying)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    float bit = SoE_LoreBit(self.style);
    if (bit == 0)
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) ||
        (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;

    if (!(other.soe_scrap_mask & bit)) {
        other.soe_scrap_mask = other.soe_scrap_mask | bit;
        SoE_FirePlayerPresentation(self, other, false);
    }

    if (other.soe_scrap_mask == 1023)
        SoE_FirePlayerPresentation(self, other, true);
};

void() soe_scrap_piece =
{
    if (self.style < 1 || self.style > 10)
        objerror("soe_scrap_piece requires style 1..10\n");

    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Inspect Scrap";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_ScrapTouch;

    if (self.model != "")
        setmodel(self, self.model);
    else
        setsize(self, '-8 -8 -4', '8 8 6');
};

/* Cipher discovery/reveal */

void() SoE_CipherRevealUse =
{
    self.soe_lore_enabled = true;
    self.solid = SOLID_TRIGGER;

    if (self.oldmodel != "")
        setmodel(self, self.oldmodel);

    self.effects = EF_FULLBRIGHT;
};

void() SoE_CipherTouch =
{
    if (!self.soe_lore_enabled ||
        other.classname != "player" ||
        other.downed)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    float bit = SoE_LoreBit(self.style);
    if (bit == 0)
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) ||
        (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;

    if (!(other.soe_cipher_mask & bit)) {
        other.soe_cipher_mask = other.soe_cipher_mask | bit;
        SoE_FirePlayerPresentation(self, other, false);
    }

    if (other.soe_cipher_mask == 31)
        SoE_FirePlayerPresentation(self, other, true);
};

void() soe_cipher =
{
    if (self.style < 1 || self.style > 5)
        objerror("soe_cipher requires style 1..5\n");

    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Inspect Cipher";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.touch = SoE_CipherTouch;
    self.use = SoE_CipherRevealUse;

    if (self.model != "")
        self.oldmodel = self.model;

    // spawnflag 1 = hidden until another entity reveals it.
    if (self.spawnflags & 1) {
        self.soe_lore_enabled = false;
        self.solid = SOLID_NOT;
        if (self.model != "")
            setmodel(self, "");
    } else {
        self.soe_lore_enabled = true;
        self.solid = SOLID_TRIGGER;
        if (self.model != "")
            setmodel(self, self.model);
    }
};

/* Telephones / Rift portal lore */

void() SoE_LoreDeviceEnable =
{
    self.soe_lore_enabled = true;
};

void() SoE_LoreDeviceTouch =
{
    if (!self.soe_lore_enabled ||
        other.classname != "player" ||
        other.downed ||
        other.isBuying)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    float bit = SoE_LoreBit(self.style);
    if (bit == 0)
        return;

    // spawnflag 2 = replayable. Otherwise each player hears it once.
    if (!(self.spawnflags & 2) && (other.soe_lore_heard_mask & bit))
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) ||
        (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;
    other.soe_lore_heard_mask = other.soe_lore_heard_mask | bit;

    SoE_FirePlayerPresentation(self, other, false);
};

void() soe_lore_device =
{
    if (self.style < 1 || self.style > 12)
        objerror("soe_lore_device requires style 1..12\n");

    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Listen";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_LoreDeviceTouch;
    self.use = SoE_LoreDeviceEnable;

    // spawnflag 1 = progression-gated, starts disabled.
    self.soe_lore_enabled = !(self.spawnflags & 1);

    if (self.model != "")
        setmodel(self, self.model);
    else
        setsize(self, '-12 -12 -16', '12 12 20');
};

/* Shadowman sightings / From the Shadows challenge */

void() SoE_ShadowmanSightingTouch =
{
    if (other.classname != "player" || other.downed)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    float bit = SoE_LoreBit(self.style);
    if (bit == 0 || (other.soe_shadowman_sighting_mask & bit))
        return;

    other.soe_shadowman_sighting_mask = other.soe_shadowman_sighting_mask | bit;
    other.soe_shadowman_sighting_count = other.soe_shadowman_sighting_count + 1;

    SoE_FirePlayerPresentation(self, other, false);

    if (other.soe_shadowman_sighting_count >= 5)
        SoE_FirePlayerPresentation(self, other, true);
};

void() soe_shadowman_sighting =
{
    if (self.style < 1 || self.style > 8)
        objerror("soe_shadowman_sighting requires style 1..8\n");

    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_ShadowmanSightingTouch;

    if (self.model != "")
        setmodel(self, self.model);
    else
        setsize(self, '-26 -26 -36', '26 26 44');
};

/* Noir portrait */

void() SoE_NoirPortraitTouch =
{
    if (!self.soe_noir_exposed ||
        other.classname != "player" ||
        other.downed ||
        other.isBuying)
        return;

    // Stronger current guides describe crouch-interacting after the portrait is shot.
    if (other.stance != PLAYER_STANCE_CROUCH)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) ||
        (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;
    other.soe_noir_enabled = !other.soe_noir_enabled;

    // target = enable client monochrome; target2 = disable.
    SoE_FirePlayerPresentation(self, other, !other.soe_noir_enabled);
};

float(entity victim, entity attacker, float damage, float d_style) SoE_HandleNoirPortraitDamage =
{
    if (!soe_active || victim.classname != "soe_noir_portrait")
        return false;

    if (attacker.classname != "player" || damage <= 0)
        return true;

    if (!victim.soe_noir_exposed) {
        victim.soe_noir_exposed = true;
        victim.solid = SOLID_TRIGGER;
        victim.takedamage = DAMAGE_NO;
        victim.effects = EF_FULLBRIGHT;

        SoE_FirePlayerPresentation(victim, attacker, false);
    }

    return true;
};

void() soe_noir_portrait =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Toggle Noir";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.classname = "soe_noir_portrait";
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_BBOX;
    self.takedamage = DAMAGE_YES;
    self.health = 999999;
    self.touch = SoE_NoirPortraitTouch;
    self.soe_noir_exposed = false;

    if (self.model != "")
        setmodel(self, self.model);
    else {
        setmodel(self, "models/sprites/sprkle.spr");
        setsize(self, '-12 -4 -12', '12 4 12');
    }
};
