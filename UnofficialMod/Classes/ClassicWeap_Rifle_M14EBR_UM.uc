//================================================
// ClassicWeap_Rifle_M14EBR_UM
//================================================
// Modified Classic Mode M14 EBR for Unofficial Mod
//================================================
// (c) 2019 "Insert Name Here"
//================================================
class ClassicWeap_Rifle_M14EBR_UM extends KFWeap_Rifle_M14EBR_UM;

// Just copy/paste the defaultproperties
defaultproperties
{
    // Inventory / Grouping
    InventorySize=8
    GroupPriority=165
    
    // Ammo
    SpareAmmoCapacity[0]=140

    // Recoil
    RecoilRate=0.085

    // DEFAULT_FIREMODE
    FireInterval(DEFAULT_FIREMODE)=0.25
    Spread(DEFAULT_FIREMODE)=0.005
}