//================================================
// ClassicWeap_Thrown_C4_UM
//================================================
// Modified Classic Mode C4 for Unofficial Mod
//================================================
// (c) 2019 "Insert Name Here"
//================================================
class ClassicWeap_Thrown_C4_UM extends KFWeap_Thrown_C4_UM;

// Just copy/paste the defaultproperties
// (with modifications for alt-fire)
defaultproperties
{
    // THROW_FIREMODE
    WeaponProjectiles(THROW_FIREMODE)=class'UnofficialMod.ClassicProj_Thrown_C4_UM'
    WeaponProjectiles(ALTFIRE_FIREMODE)=class'UnofficialMod.ClassicProj_Thrown_C4_UM'

    // Inventory / Grouping
    InventorySize=1
    GroupPriority=1
}