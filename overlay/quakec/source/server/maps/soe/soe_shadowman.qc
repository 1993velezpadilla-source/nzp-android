/*
    Shadows of Evil - Shadowman boss phase.

    After all four district Keepers receive the flag:
      - activate all four Sacred Place Keepers within the shared window
      - their beam strips the Shadowman's shield
      - damage pushes/teleports him toward the Summoning Key ritual table
      - interact at the table while he is trapped to capture him
      - four-player classic lobbies proceed to the finale
      - optional solo/small-lobby finale can be enabled with soe_solo_finale 1
*/

float soe_shadowman_keeper_mask;
float soe_shadowman_keeper_window_until;
float soe_shadowman_vulnerable;
float soe_shadowman_vulnerable_until;
float soe_shadowman_pushes;
float soe_shadowman_ready_capture;
float soe_shadowman_captured;
entity soe_shadowman_ent;

.float soe_shadowman_keeper_committed;
.float soe_shadowman_damage_bucket;

void() SoE_ResetShadowman =
{
    soe_shadowman_keeper_mask = 0;
    soe_shadowman_keeper_window_until = 0;
    soe_shadowman_vulnerable = false;
    soe_shadowman_vulnerable_until = 0;
    soe_shadowman_pushes = 0;
    soe_shadowman_ready_capture = false;
    soe_shadowman_captured = false;
    soe_shadowman_ent = world;
};

float(float keeper_id) SoE_ShadowmanKeeperBit =
{
    if (keeper_id == 1) return 1;
    if (keeper_id == 2) return 2;
    if (keeper_id == 3) return 4;
    if (keeper_id == 4) return 8;
    return 0;
};

void() SoE_ShadowmanResetKeeperCommitments =
{
    entity player = find(world, classname, "player");
    while (player != world) {
        player.soe_shadowman_keeper_committed = false;
        player = find(player, classname, "player");
    }
};

entity() SoE_ShadowmanRandomNode =
{
    entity node = find(world, classname, "soe_shadowman_node");
    entity chosen = world;
    float seen = 0;

    while (node != world) {
        seen = seen + 1;
        if (random() < (1 / seen))
            chosen = node;

        node = find(node, classname, "soe_shadowman_node");
    }

    return chosen;
};

void() SoE_ShadowmanMoveToNode =
{
    if (soe_shadowman_ent == world)
        return;

    entity node;

    if (soe_shadowman_ready_capture)
        node = find(world, classname, "soe_shadowman_capture_marker");
    else
        node = SoE_ShadowmanRandomNode();

    if (node == world)
        return;

    setorigin(soe_shadowman_ent, node.origin);

    if (node.angles != '0 0 0')
        soe_shadowman_ent.angles = node.angles;
};

entity() SoE_SpawnShadowmanBoss =
{
    if (soe_shadowman_ent != world)
        return soe_shadowman_ent;

    entity node = SoE_ShadowmanRandomNode();
    if (node == world)
        return world;

    entity boss = spawn();
    boss.classname = "soe_shadowman_boss";
    boss.movetype = MOVETYPE_FLY;
    boss.solid = SOLID_BBOX;
    boss.takedamage = DAMAGE_YES;
    boss.health = 999999;
    boss.effects = EF_FULLBRIGHT;
    boss.soe_shadowman_damage_bucket = 0;

    // Placeholder presentation until a cleared Shadowman model/FX is used.
    setmodel(boss, "models/sprites/sprkle.spr");
    setsize(boss, '-16 -16 -28', '16 16 34');
    setorigin(boss, node.origin);

    soe_shadowman_ent = boss;
    return boss;
};

void() SoE_ShadowmanBreakShield =
{
    if (soe_shadowman_captured)
        return;

    if (SoE_SpawnShadowmanBoss() == world)
        return;

    soe_shadowman_vulnerable = true;
    soe_shadowman_vulnerable_until = time + 12;
    soe_shadowman_ent.soe_shadowman_damage_bucket = 0;

    // Canonical boss pressure: a Margwa joins each shield-break cycle.
    soe_scripted_margwa_pending = soe_scripted_margwa_pending + 1;

    SoE_ShadowmanMoveToNode();
};

void() SoE_ShadowmanKeeperTouch =
{
    if (other.classname != "player" || other.downed || other.isBuying)
        return;

    if (soe_quest_stage != SOE_QUEST_SHADOWMAN ||
        soe_shadowman_captured ||
        soe_shadowman_vulnerable)
        return;

    if (!other.soe_sword_upgraded)
        return;

    float keeper_bit = SoE_ShadowmanKeeperBit(self.style);
    if (keeper_bit == 0 || (soe_shadowman_keeper_mask & keeper_bit))
        return;

    float player_count_local = SoE_PlayerCount();

    // In a true four-player lobby each player commits one Keeper/Sword.
    // Smaller lobbies may activate multiple Keepers so they can reach the
    // Shadowman capture, matching the portable/small-lobby quest path.
    if (player_count_local >= 4 && other.soe_shadowman_keeper_committed)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;

    if (soe_shadowman_keeper_mask == 0)
        soe_shadowman_keeper_window_until = time + 10;

    soe_shadowman_keeper_mask = soe_shadowman_keeper_mask | keeper_bit;
    other.soe_shadowman_keeper_committed = true;

    SoE_FireEntityTargets(self);

    if (soe_shadowman_keeper_mask == 15)
        SoE_ShadowmanBreakShield();
};

void() soe_shadowman_keeper =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Ready Keeper";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_ShadowmanKeeperTouch;

    if (self.model != "")
        setmodel(self, self.model);
    else {
        setmodel(self, "models/sprites/sprkle.spr");
        setsize(self, '-18 -18 -28', '18 18 36');
        self.effects = EF_FULLBRIGHT;
    }
};

void() soe_shadowman_node =
{
    self.solid = SOLID_NOT;
    self.movetype = MOVETYPE_NONE;
    setsize(self, '0 0 0', '0 0 0');
};

void() soe_shadowman_capture_marker =
{
    self.solid = SOLID_NOT;
    self.movetype = MOVETYPE_NONE;
    setsize(self, '0 0 0', '0 0 0');
};

float(entity victim, entity attacker, float damage, float d_style) SoE_HandleShadowmanDamage =
{
    if (!soe_active || victim.classname != "soe_shadowman_boss")
        return false;

    // Shielded Shadowman eats damage without progressing.
    if (!soe_shadowman_vulnerable || soe_shadowman_ready_capture)
        return true;

    if (damage <= 0)
        return true;

    victim.soe_shadowman_damage_bucket = victim.soe_shadowman_damage_bucket + damage;

    // Damage threshold is deliberately centralized/tunable. Each push mimics
    // the visible teleport/reposition cadence toward the ritual table.
    if (victim.soe_shadowman_damage_bucket >= 300) {
        victim.soe_shadowman_damage_bucket = 0;
        soe_shadowman_pushes = soe_shadowman_pushes + 1;

        if (soe_shadowman_pushes >= 6) {
            soe_shadowman_ready_capture = true;
            SoE_ShadowmanMoveToNode();
        } else {
            SoE_ShadowmanMoveToNode();
        }
    }

    return true;
};

void() SoE_ShadowmanCaptureTableTouch =
{
    if (other.classname != "player" || other.downed || other.isBuying)
        return;

    if (!soe_shadowman_ready_capture ||
        soe_shadowman_ent == world ||
        soe_shadowman_captured ||
        !soe_has_summoning_key)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, 0);

    if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;

    remove(soe_shadowman_ent);
    soe_shadowman_ent = world;
    soe_shadowman_captured = true;
    soe_shadowman_ready_capture = false;
    soe_shadowman_vulnerable = false;

    SoE_FireEntityTargets(self);

    // Classic finale remains four-player. Portable testing can opt into the
    // solo/small-lobby synchronization adaptation with a cvar.
    if (SoE_PlayerCount() >= 4 || cvar("soe_solo_finale") != 0)
        SoE_StartFinale();
};

void() soe_shadowman_capture_table =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Trap the Shadowman";

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_ShadowmanCaptureTableTouch;

    if (self.model != "")
        setmodel(self, self.model);
    else
        setsize(self, '-28 -24 -14', '28 24 24');
};

void() SoE_ShadowmanFrame =
{
    if (!soe_active ||
        soe_quest_stage != SOE_QUEST_SHADOWMAN ||
        soe_shadowman_captured)
        return;

    // Keeper activation is a coordinated timed step. Miss the window and the
    // Keeper mask resets so the team must reactivate all four.
    if (!soe_shadowman_vulnerable &&
        soe_shadowman_keeper_mask != 0 &&
        soe_shadowman_keeper_mask != 15 &&
        soe_shadowman_keeper_window_until > 0 &&
        time >= soe_shadowman_keeper_window_until) {
        soe_shadowman_keeper_mask = 0;
        soe_shadowman_keeper_window_until = 0;
        SoE_ShadowmanResetKeeperCommitments();
    }

    // If the team fails to push him to the ritual table while vulnerable,
    // he shields again and all four Keepers must be re-readied.
    if (soe_shadowman_vulnerable &&
        !soe_shadowman_ready_capture &&
        time >= soe_shadowman_vulnerable_until) {
        soe_shadowman_vulnerable = false;
        soe_shadowman_keeper_mask = 0;
        soe_shadowman_keeper_window_until = 0;
        SoE_ShadowmanResetKeeperCommitments();

        // Failed cycle punishment.
        soe_scripted_margwa_pending = soe_scripted_margwa_pending + 1;
    }
};
