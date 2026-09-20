/*
    Shadows of Evil - randomized spawn groups.

    Candidate entities may set:
      "soe_random_group" "<id>"

    Exactly one candidate in each known group remains active after map load.
    Others are made non-solid/invisible but remain allocated for stable map
    entity numbering.

    Group IDs:
      101 Spawn Fumigator
      102 Junction Fumigator
      103 Canals Fumigator
      104 Waterfront Fumigator

      201 Canals Rocket Shield part
      202 Footlight Rocket Shield part
      203 Waterfront Rocket Shield part

      301 Canals Civil Protector fuse
      302 Footlight Civil Protector fuse
      303 Waterfront Civil Protector fuse
*/

.float soe_random_group;
.float soe_random_resolved;
float soe_random_spawns_resolved;

void(entity ent) SoE_DisableRandomCandidate =
{
    ent.solid = SOLID_NOT;
    ent.touch = SUB_Null;
    ent.use = SUB_Null;
    ent.soe_random_resolved = true;

    if (ent.model != "")
        setmodel(ent, "");
};

void(float group_id) SoE_ResolveRandomGroup =
{
    entity candidate = findfloat(world, soe_random_group, group_id);
    entity chosen = world;
    float seen = 0;

    while (candidate != world) {
        seen = seen + 1;

        if (random() < (1 / seen))
            chosen = candidate;

        candidate = findfloat(candidate, soe_random_group, group_id);
    }

    if (chosen == world)
        return;

    candidate = findfloat(world, soe_random_group, group_id);
    while (candidate != world) {
        entity next = findfloat(candidate, soe_random_group, group_id);

        if (candidate != chosen)
            SoE_DisableRandomCandidate(candidate);
        else
            candidate.soe_random_resolved = true;

        candidate = next;
    }
};

void() SoE_ResetRandomSpawns =
{
    soe_random_spawns_resolved = false;
};

void() SoE_RandomSpawnFrame =
{
    if (!soe_active || soe_random_spawns_resolved)
        return;

    // Wait until every map entity has had its spawn function called.
    if (time < 0.20)
        return;

    SoE_ResolveRandomGroup(101);
    SoE_ResolveRandomGroup(102);
    SoE_ResolveRandomGroup(103);
    SoE_ResolveRandomGroup(104);

    SoE_ResolveRandomGroup(201);
    SoE_ResolveRandomGroup(202);
    SoE_ResolveRandomGroup(203);

    SoE_ResolveRandomGroup(301);
    SoE_ResolveRandomGroup(302);
    SoE_ResolveRandomGroup(303);

    soe_random_spawns_resolved = true;
};
