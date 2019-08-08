//================================================
// ClassicWeapDef_MedicRifleGrenadeLauncher_UM
//================================================
// Modified Classic Mode M7A3 for Unofficial Mod
//================================================
// (c) 2019 "Insert Name Here"
//================================================
class ClassicWeapDef_MedicRifleGrenadeLauncher_UM extends KFWeapDef_MedicRifleGrenadeLauncher_UM
	abstract;
	
// Copy/paste/modify
static function string GetItemLocalization( string KeyName )
{
	if (KeyName ~= "ItemName")
        return "M7A3 Medic Gun [UM]";

    return class'KFGame.KFWeapDef_MedicRifleGrenadeLauncher'.static.GetItemLocalization(KeyName);
}

defaultproperties
{
    WeaponClassPath="UnofficialMod.ClassicWeap_AssaultRifle_M7A3_UM"
    BuyPrice=2050
    AmmoPricePerMag=15
}