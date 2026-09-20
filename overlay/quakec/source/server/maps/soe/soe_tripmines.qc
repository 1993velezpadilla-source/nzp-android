/*
    Shadows of Evil - Trip Mine + pastry-cart upgrade runtime.

    SoE uses NZ:P's existing secondary-equipment count/HUD slot:
      - custom wallbuy grants 2 Trip Mines
      - secondary_grenades stores current count
      - normal round/Max Ammo refill paths already refill this slot
      - impulse 33 is diverted to Trip Mine placement only on SoE owners

    Upgrade routes:
      route 1 "help Holly": damage all 4 Devil-O-Donuts carts
      route 2 "help Devil": damage all 3 Holly's Cream Cakes carts
      hitting a cart from the side being helped locks the quest for the match
*/

#define SOE_TRIP_ROUTE_NONE   0
#define SOE_TRIP_ROUTE_HOLLY  1
#define SOE_TRIP_ROUTE_DEVIL  2

#define SOE_CART_HOLLY        1
#define SOE_CART_DEVIL        2

float soe_tripmine_route;
float soe_tripmine_cart_mask;
float soe_tripmine_locked;
float soe_tripmine_upgraded;

.float soe_has_tripmines;
.float soe_tripmine_variant;
.float soe_tripmine_cart_kind;
.float soe_tripmine_cart_id;

void(entity victim, entity attacker, float damage, float d_style) DamageHandler;
void(entity who, float value, float impacted_by_2x_points) Player_ChangeScore;
void() SoE_SpecialVisualExpire;

float(float id) SoE_TripMineCartBit =
{
    if (id == 1) return 1;
    if (id == 2) return 2;
    if (id == 3) return 4;
    if (id == 4) return 8;
    return 0;
};

void() SoE_ResetTripMines =
{
    soe_tripmine_route = SOE_TRIP_ROUTE_NONE;
    soe_tripmine_cart_mask = 0;
    soe_tripmine_locked = false;
    soe_tripmine_upgraded = false;
};

void(entity player) SoE_GiveTripMines =
{
    player.soe_has_tripmines = true;
    player.grenades = player.grenades | 2;
    player.secondary_grenades = 2;

    if (soe_tripmine_upgraded)
        player.soe_tripmine_variant = soe_tripmine_route;
    else
        player.soe_tripmine_variant = SOE_TRIP_ROUTE_NONE;
};

void() SoE_TripMineWallbuyTouch =
{
    if (other.classname != "player" || other.downed || other.isBuying)
        return;

    if (!PlayerIsLooking(other, self))
        return;

    float price = self.cost;
    if (price <= 0)
        price = 1000;

    if (other.soe_has_tripmines && other.secondary_grenades >= 2)
        return;

    Player_UseprintWithWait(other, self, self.useprint_index_1, price);

    if (!Player_UseButtonPressed(other, self) ||
        (other.semi_actions & SEMIACTION_USE))
        return;

    other.semi_actions |= SEMIACTION_USE;

    if (other.points < price) {
        centerprint(other, STR_NOTENOUGHPOINTS);
        Sound_PlaySound(other, "sounds/misc/denybuy.wav", SOUND_TYPE_ENV_CHING, SOUND_PRIORITY_PLAYALWAYS);
        return;
    }

    Player_ChangeScore(other, -price, false);
    SoE_GiveTripMines(other);
    Sound_PlaySound(other, "sounds/misc/ching.wav", SOUND_TYPE_ENV_CHING, SOUND_PRIORITY_PLAYALWAYS);
    SoE_FireEntityTargets(self);
};

void() soe_tripmine_wallbuy =
{
    if (self.useprint_string_1 == "")
        self.useprint_string_1 = "Hold %b to Buy Trip Mines";

    if (self.cost <= 0)
        self.cost = 1000;

    self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = SoE_TripMineWallbuyTouch;

    if (self.model != "")
        setmodel(self, self.model);
    else
        setsize(self, '-18 -10 -18', '18 10 24');
};

void(entity origin_mine) SoE_TripMineCheckCarts =
{
    if (soe_tripmine_locked || soe_tripmine_upgraded)
        return;

    entity cart = findradius(origin_mine.origin, 150);

    while (cart != world) {
        entity next = cart.chain;

        if (cart.classname == "soe_tripmine_cart") {
            float kind = cart.soe_tripmine_cart_kind;
            float bit = SoE_TripMineCartBit(cart.soe_tripmine_cart_id);

            if (bit > 0) {
                if (soe_tripmine_route == SOE_TRIP_ROUTE_NONE) {
                    if (kind == SOE_CART_DEVIL)
                        soe_tripmine_route = SOE_TRIP_ROUTE_HOLLY;
                    else if (kind == SOE_CART_HOLLY)
                        soe_tripmine_route = SOE_TRIP_ROUTE_DEVIL;
                }

                float correct_kind = SOE_CART_DEVIL;
                float required_mask = 15;

                if (soe_tripmine_route == SOE_TRIP_ROUTE_DEVIL) {
                    correct_kind = SOE_CART_HOLLY;
                    required_mask = 7;
                }

                if (kind != correct_kind) {
                    soe_tripmine_locked = true;
                    soe_tripmine_cart_mask = 0;
                    SoE_FireEntityTargets(cart);
                    return;
                }

                if (!(soe_tripmine_cart_mask & bit)) {
                    soe_tripmine_cart_mask = soe_tripmine_cart_mask | bit;
                    SoE_FireEntityTargets(cart);
                }

                if (soe_tripmine_cart_mask == required_mask) {
                    soe_tripmine_upgraded = true;

                    entity player = find(world, classname, "player");
                    while (player != world) {
                        if (player.soe_has_tripmines)
                            player.soe_tripmine_variant = soe_tripmine_route;
                        player = find(player, classname, "player");
                    }

                    return;
                }
            }
        }

        cart = next;
    }
};

void(entity mine) SoE_TripMineExplode =
{
    float radius = 150;
    float damage = 1800;

    if (mine.owner.soe_tripmine_variant != SOE_TRIP_ROUTE_NONE) {
        radius = 210;
        damage = 3000;
    }

    SoE_TripMineCheckCarts(mine);

    entity ent = findradius(mine.origin, radius);
    while (ent != world) {
        entity next = ent.chain;

        if (ent.classname == "ai_zombie" ||
            ent.classname == "ai_dog" ||
            ent.classname == "soe_parasite" ||
            ent.classname == "soe_elemental" ||
            ent.classname == "soe_keeper") {
            DamageHandler(ent, mine.owner, damage, DMG_TYPE_EXPLOSIVE);
        }

        ent = next;
    }

    // Project-owned FX can be targeted by the mapper; native explosion is a
    // temporary presentation fallback.
    entity fx = spawn();
    fx.movetype = MOVETYPE_NONE;
    fx.solid = SOLID_NOT;
    fx.effects = EF_FULLBRIGHT;
    fx.think = SoE_SpecialVisualExpire;
    fx.nextthink = time + 0.35;
    setmodel(fx, "models/sprites/explosion.spr");
    setorigin(fx, mine.origin);

    remove(mine);
};

void() SoE_TripMineTouch =
{
    if (other == self.owner)
        return;

    if (other.classname == "ai_zombie" ||
        other.classname == "ai_dog" ||
        other.classname == "soe_parasite" ||
        other.classname == "soe_elemental" ||
        other.classname == "soe_keeper") {
        SoE_TripMineExplode(self);
    }
};

void() SoE_TripMinePlaceInput =
{
    if (!soe_active ||
        self.classname != "player" ||
        self.downed ||
        self.isBuying ||
        !self.soe_has_tripmines ||
        self.secondary_grenades <= 0)
        return;

    self.secondary_grenades = self.secondary_grenades - 1;

    entity mine = spawn();
    mine.classname = "soe_tripmine";
    mine.owner = self;
    mine.movetype = MOVETYPE_NONE;
    mine.solid = SOLID_TRIGGER;
    mine.touch = SoE_TripMineTouch;
    mine.effects = EF_FULLBRIGHT;

    // Native Betty ground model is the legal placeholder until cleared Trip
    // Mine art is integrated.
    setmodel(mine, "models/weapons/grenade/g_betty.mdl");
    setsize(mine, '-20 -20 -6', '20 20 24');

    makevectors(self.v_angle);
    vector org = self.origin + (v_forward * 28);
    org_z = self.origin_z - self.view_ofs_z + 3;
    setorigin(mine, org);

    entity old_self = self;
    self = mine;

#ifdef FTE
    droptofloor();
#else
    droptofloor(0, 0);
#endif

    self = old_self;
};

void() soe_tripmine_cart =
{
    if (self.style != SOE_CART_HOLLY && self.style != SOE_CART_DEVIL)
        objerror("soe_tripmine_cart style 1=Holly, 2=Devil\n");

    if (self.health < 1 || self.health > 4)
        objerror("soe_tripmine_cart health must hold cart index 1..4\n");

    self.soe_tripmine_cart_kind = self.style;
    self.soe_tripmine_cart_id = self.health;
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_NOT;

    if (self.model != "")
        setmodel(self, self.model);
};
