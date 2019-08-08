//================================================
// ClassicWeap_AssaultRifle_M16M203_UM
//================================================
// Modified Classic Mode M16-M203 for Unofficial Mod
//================================================
// (c) 2019 "Insert Name Here"
//================================================
class ClassicWeap_AssaultRifle_M16M203_UM extends KFWeap_AssaultRifle_M16M203_UM;

// Just copy/paste the defaultproperties
defaultproperties
{
    // Ammo
    InitialSpareMags[0]=4
    InitialSpareMags[1]=5
    SpareAmmoCapacity[1]=11

    // Inventory / Grouping
    GroupPriority=190
    
	AssociatedPerkClasses(1)=class'KFGame.KFPerk_Demolitionist'

    // DEFAULT_FIREMODE
    Spread(DEFAULT_FIREMODE)=0.015

    // ALT_FIREMODE
    WeaponProjectiles(ALTFIRE_FIREMODE)=class'UnofficialMod.ClassicProj_HighExplosive_M16M203_UM'
    InstantHitDamage(ALTFIRE_FIREMODE)=350.0
    Spread(ALTFIRE_FIREMODE)=0.015
}