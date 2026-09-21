/*
    Shadows of Evil - Four-player Apocalypse Averted finale.

    Canonical coordination:
      - endless purple Margwas replace normal zombies
      - kill a purple Margwa near a curse torch to relight Beast access
      - periodic corruption is cleansed by white wisps
      - three train-station boxes electrify the rails while the Tram moves
      - Tram knocks the giant Gateworm away at Junction
      - shock all three central Keepers before the Gateworm returns

    `soe_solo_finale 1` keeps the same state machine but allows one/small
    lobbies to perform station/keeper shocks sequentially for portable testing.
*/

float soe_finale_started;
float soe_finale_complete;
float soe_finale_station_mask;
float soe_finale_keeper_mask;
float soe_finale_rail_window_until;
float soe_finale_gateworm_present;
float soe_finale_gateworm_absent_until;
float soe_finale_next_margwa_at;
float soe_finale_next_corruption_at;

#define SOE_FINALE_CORRUPTION_MIN_SECONDS 30
#define SOE_FINALE_CORRUPTION_MAX_SECONDS 45
#define SOE_FINALE_CLEANSE_DEADLINE_SECONDS 15
#define SOE_FINALE_BEAST_CORRUPTION_DRAIN 40

.float soe_finale_torch_active;
.float soe_finale_corrupted;
.float soe_finale_corrupt_deadline;

void(entity victim, entity attacker, float damage, float d_style) DamageHandler;
void(entity ent) Zombie_Death_Cleanup;
void() removeZombie;

void(entity player) SoE_FinaleClearPlayerCorruption =
{
    if (player == world)
        return;

    player.soe_finale_corrupted = false;
    player.soe_finale_corrupt_deadline = 0;
};

void() SoE_ResetFinale =
{
    soe_finale_started = false;
    soe_finale_complete = false;
    soe_finale_station_mask = 0;
    soe_finale_keeper_mask = 0;
    soe_finale_rail_window_until = 0;
    soe_finale_gateworm_present = true;
    soe_finale_gateworm_absent_until = 0;
    soe_finale_next_margwa_at = 0;
    soe_finale_next_corruption_at = 0;

    // Reset can run after a failed/restarted quest. Never let per-player
    // corruption state leak into the next attempt.
    entity player = find(world, classname, "player");
    while (player != world) {
        SoE_FinaleClearPlayerCorruption(player);
        player = find(player, classname, "player");
    }
};

void() SoE_FinaleTransitionPopulation =
{
    entity zombie = find(world, classname, "ai_zombie");
    entity old_self = self;

    while (zombie != world) {
        entity next = find(zombie, classname, "ai_zombie");

        if (zombie.aistatus == "1") {
            if (zombie.soe_special_type == SOE_SPECIAL_MARGWA) {
                // Existing Margwas transition into the purple finale variant.
                zombie.soe_margwa_purple = true;
            } else {
                // The canonical finale removes the normal zombie population.
                // Use NZ:P's cleanup path so barricade ownership, limbs and
                // pooled slots cannot leak into the endless-Margwa phase.
                Zombie_Death_Cleanup(zombie);
                self = zombie;
                removeZombie();
                self = old_self;
            }
        }

        zombie = next;
    }

    self = old_self;
};

void() SoE_FinaleBegin =
{
    if (!soe_finale_active || soe_finale_started)
        return;

    soe_finale_started = true;
    soe_finale_complete = false;
    soe_finale_station_mask = 0;
    soe_finale_keeper_mask = 0;
    soe_finale_gateworm_present = true;
    soe_finale_gateworm_absent_until = 0;
    soe_finale_rail_window_until = 0;
    soe_finale_next_margwa_at = time + 1;
    soe_finale_next_corruption_at = time + SOE_FINALE_CORRUPTION_MIN_SECONDS + (random() * (SOE_FINALE_CORRUPTION_MAX_SECONDS - SOE_FINALE_CORRUPTION_MIN_SECONDS));

    SoE_FinaleTransitionPopulation();

    // Freeze normal round completion; finale enemies are an independent stream.
    Remaining_Zombies = 9999;
    roundtype = 5;

    entity player = find(world, classname, "player");
    while (player != world) {
        SoE_FinaleClearPlayerCorruption(player);
        player = find(player, classname, "player");
    }
};

float() SoE_FinaleCountPurpleMargwas =
{
    float count = 0;
    entity ent = find(world, classname, "ai_zombie");

    while (ent != world) {
        if (ent.soe_special_type == SOE_SPECIAL_MARGWA &&
            ent.soe_margwa_purple &&
            ent.aistatus == "1")
            count = count + 1;

        ent = find(ent, classname, "ai_zombie");
    }

    return count;
};

void(entity margwa) SoE_FinaleOnMargwaKilled =
{
    if (!soe_finale_active || margwa == world || !margwa.soe_margwa_purple)
        return;

    entity torch = find(world, classname, "soe_finale_beast_torch");
    entity nearest = world;
    float nearest_distance = 260;

    while (torch != world) {
        float distance = vlen(torch.origin - margwa.origin);
        if (distance < nearest_distance) {
            nearest_distance = distance;
            nearest = torch;
        }

        torch = find(torch, classname, "soe_finale_beast_torch");
    }

    if (nearest != world) {
        nearest.soe_finale_torch_active = true;
        nearest.effects = EF_FULLBRIGHT;
        SoE_FireEntityTargets(nearest);
    }
};

void() SoE_FinaleTorchTouch =
{
    if (!soe_finale_active ||
        !self.soe_finale_torch_active ||
        other.classname != "player" ||
        other.downed ||
        other.soe_beast_active)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;
    other.soe_beast_charges = 1;
    SoE_BeginBeast(other);

    if (other.soe_beast_active) {
        other.soe_finale_beast_meter = 100;
        self.soe_finale_torch_active = false;
        self.effects = 0;
    }
};

void() soe_finale_beast_torch =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Become the Beast";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_FinaleTorchTouch;
    self.soe_finale_torch_active = false;

    if (self.model != "")
        setmodel(self, self.model);
    else
        setsize(self, '-24 -24 -16', '24 24 48');
};

void() SoE_FinaleCleanseTouch =
{
    if (!soe_finale_active || other.classname != "player")
        return;

    SoE_FinaleClearPlayerCorruption(other);
};

void() soe_finale_cleanse_wisp =
{
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_FinaleCleanseTouch;

    if (self.model != "")
        setmodel(self, self.model);
    else {
        setmodel(self, "models/sprites/sprkle.spr");
        setsize(self, '-24 -24 -24', '24 24 40');
        self.effects = EF_FULLBRIGHT;
    }
};

float(float id) SoE_FinaleThreeBit =
{
    if (id == 1) return 1;
    if (id == 2) return 2;
    if (id == 3 || id == 4) return 4;
    return 0;
};

void() SoE_FinaleStationBoxTouch =
{
    if (!soe_finale_active ||
        other.classname != "player" ||
        !other.soe_beast_active)
        return;

    // Classic finale requires the three station boxes to be shocked while
    // the tram is actually moving. The explicit portable solo adaptation
    // may perform them sequentially because one player cannot occupy three
    // stations during the same ride.
    if (!soe_tram_in_transit && cvar("soe_solo_finale") == 0)
        return;

    float station_bit = SoE_FinaleThreeBit(self.style);
    if (station_bit == 0)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;
    soe_finale_station_mask = soe_finale_station_mask | station_bit;

    // Rails remain blue/electrified for the coordination window.
    soe_finale_rail_window_until = time + 30;
    SoE_FireEntityTargets(self);
};

void() soe_finale_station_box =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Electrify Rails";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_FinaleStationBoxTouch;

    if (self.model != "")
        setmodel(self, self.model);
    else
        setsize(self, '-18 -10 -18', '18 10 24');
};

void() SoE_FinaleTrainHitUse =
{
    if (!soe_finale_active ||
        !soe_finale_gateworm_present ||
        soe_finale_station_mask != 7 ||
        soe_finale_rail_window_until <= time)
        return;

    // A single Tram pass may touch/fire this target more than once depending
    // on mover geometry. Only the first valid crossing may knock the Gateworm
    // away; repeated contacts must not extend the Keeper window.
    soe_finale_gateworm_present = false;
    soe_finale_gateworm_absent_until = time + 20;
    soe_finale_keeper_mask = 0;
    soe_giant_gateworm_hit = true;

    // Mapper target can hide/move the giant Gateworm visual at the exact
    // Junction crossing frame.
    SoE_FireEntityTargets(self);
};

void() soe_finale_train_hit =
{
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_NOT;
    self.use = SoE_FinaleTrainHitUse;
    setsize(self, '0 0 0', '0 0 0');
};

void() SoE_FinaleComplete =
{
    if (soe_finale_complete)
        return;

    soe_finale_complete = true;

    // Fire ending/cutscene/sky targets before changing the global quest stage.
    SoE_FireEntityTargets(self);

    SoE_CompleteQuest();

    entity player = find(world, classname, "player");
    while (player != world) {
        SoE_FinaleClearPlayerCorruption(player);

        if (player.soe_beast_active)
            SoE_EndBeast(player);

        // Reborn Swords are returned after the quest.
        player.soe_sword_upgraded = true;
        player = find(player, classname, "player");
    }

    // Despawn the purple-Margwa finale population through normal pooled
    // zombie death cleanup, then release round flow.
    entity margwa = find(world, classname, "ai_zombie");
    while (margwa != world) {
        entity next = find(margwa, classname, "ai_zombie");

        if (margwa.soe_special_type == SOE_SPECIAL_MARGWA &&
            margwa.soe_margwa_purple &&
            margwa.aistatus == "1") {
            entity old_self = self;
            self = margwa;
            self.th_die();
            self = old_self;
        }

        margwa = next;
    }

    Remaining_Zombies = 0;
    roundtype = 1;
};

void() SoE_FinaleKeeperTouch =
{
    if (!soe_finale_active ||
        other.classname != "player" ||
        !other.soe_beast_active)
        return;

    if (soe_finale_gateworm_present ||
        soe_finale_rail_window_until <= time)
        return;

    float keeper_bit = SoE_FinaleThreeBit(self.style);
    if (keeper_bit == 0)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;
    soe_finale_keeper_mask = soe_finale_keeper_mask | keeper_bit;

    if (soe_finale_keeper_mask == 7)
        SoE_FinaleComplete();
};

void() soe_finale_keeper =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Shock Keeper";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_FinaleKeeperTouch;

    if (self.model != "")
        setmodel(self, self.model);
    else {
        setmodel(self, "models/sprites/sprkle.spr");
        setsize(self, '-16 -16 -26', '16 16 34');
        self.effects = EF_FULLBRIGHT;
    }
};

.string soe_finale_gateworm_model;

void() SoE_FinaleGatewormVisualRefresh =
{
    if (!soe_finale_active || !soe_finale_gateworm_present) {
        if (self.model != "")
            setmodel(self, "");
        self.effects = 0;
        return;
    }

    if (self.soe_finale_gateworm_model != "")
        setmodel(self, self.soe_finale_gateworm_model);
    else
        setmodel(self, "models/sprites/sprkle.spr");

    self.effects = EF_FULLBRIGHT;
};

void() SoE_FinaleGatewormVisualUse =
{
    SoE_FinaleGatewormVisualRefresh();
};

void() SoE_FinaleGatewormVisualThink =
{
    SoE_FinaleGatewormVisualRefresh();
    self.nextthink = time + 0.10;
};

void() soe_finale_gateworm_visual =
{
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_NOT;
    self.use = SoE_FinaleGatewormVisualUse;

    if (self.model != "")
        self.soe_finale_gateworm_model = self.model;
    else
        self.soe_finale_gateworm_model = "models/sprites/sprkle.spr";

    setmodel(self, "");
    setsize(self, '-64 -64 -32', '64 64 96');

    self.think = SoE_FinaleGatewormVisualThink;
    self.nextthink = time + 0.10;
};

void() SoE_FinaleStartCorruption =
{
    entity player = find(world, classname, "player");
    while (player != world) {
        // Infection continues to progress even while a player is downed.
        // Do not restart an already-active deadline on the next cadence tick.
        if (!player.is_spectator && !player.soe_finale_corrupted) {
            player.soe_finale_corrupted = true;
            player.soe_finale_corrupt_deadline = time + SOE_FINALE_CLEANSE_DEADLINE_SECONDS;
        }

        player = find(player, classname, "player");
    }

    soe_finale_next_corruption_at = time + SOE_FINALE_CORRUPTION_MIN_SECONDS + (random() * (SOE_FINALE_CORRUPTION_MAX_SECONDS - SOE_FINALE_CORRUPTION_MIN_SECONDS));
};

void() SoE_FinaleUpdateCorruption =
{
    if (soe_finale_next_corruption_at <= time)
        SoE_FinaleStartCorruption();

    entity player = find(world, classname, "player");
    while (player != world) {
        if (player.soe_finale_corrupted &&
            player.soe_finale_corrupt_deadline > 0 &&
            time >= player.soe_finale_corrupt_deadline) {

            if (player.soe_beast_active) {
                SoE_FinaleClearPlayerCorruption(player);
                SoE_BeastDrain(player, SOE_FINALE_BEAST_CORRUPTION_DRAIN);
            } else if (!player.downed) {
                SoE_FinaleClearPlayerCorruption(player);
                DamageHandler(player, world, 999999, DMG_TYPE_OTHER);
            }
            // If the player is already downed, leave the expired corruption
            // armed. Cleansing can still clear it; otherwise a revive before
            // full bleed-out is immediately vulnerable to the failed cleanse.
        }

        player = find(player, classname, "player");
    }
};

void() SoE_FinaleResetRailCycle =
{
    soe_finale_station_mask = 0;
    soe_finale_keeper_mask = 0;
    soe_finale_rail_window_until = 0;
};

void() SoE_FinaleFrame =
{
    if (!soe_finale_active)
        return;

    if (!soe_finale_started)
        SoE_FinaleBegin();

    if (!soe_finale_active || soe_finale_complete)
        return;

    // Keep the normal round machine from ending/spawning a standard wave.
    if (Remaining_Zombies < 9000)
        Remaining_Zombies = 9999;

    // Purple Margwas are the endless finale population.
    if (soe_finale_next_margwa_at <= time &&
        SoE_FinaleCountPurpleMargwas() < 3 &&
        soe_scripted_margwa_pending < 2) {
        soe_scripted_margwa_pending = soe_scripted_margwa_pending + 1;
        soe_finale_next_margwa_at = time + 3;
    }

    SoE_FinaleUpdateCorruption();

    // Blue rail charge expires if coordination is too slow.
    if (soe_finale_station_mask != 0 &&
        soe_finale_rail_window_until > 0 &&
        time >= soe_finale_rail_window_until) {
        SoE_FinaleResetRailCycle();
    }

    // Failed train opening: Gateworm returns and the rail cycle must repeat.
    if (!soe_finale_gateworm_present &&
        soe_finale_gateworm_absent_until > 0 &&
        time >= soe_finale_gateworm_absent_until) {
        soe_finale_gateworm_present = true;
        soe_giant_gateworm_hit = false;
        SoE_FinaleResetRailCycle();
        soe_finale_gateworm_absent_until = 0;
    }
};
