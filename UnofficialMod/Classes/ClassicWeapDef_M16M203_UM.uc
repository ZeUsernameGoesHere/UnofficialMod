//================================================
// ClassicWeapDef_M16M203_UM
//================================================
// Modified Classic Mode M16-M203 for Unofficial Mod
//================================================
// (c) 2019 "Insert Name Here"
//================================================
class ClassicWeapDef_M16M203_UM extends KFWeapDef_M16M203_UM
	abstract;

// Copy/paste/modify
static function string GetItemLocalization( string KeyName )
{
	if (KeyName ~= "SecondaryAmmo")
		return class'KFGame.KFWeapDef_M16M203'.static.GetItemLocalization(KeyName);
		
	return super.GetItemLocalization(KeyName);
}

defaultproperties
{
    WeaponClassPath="UnofficialMod.ClassicWeap_AssaultRifle_M16M203_UM"
    BuyPrice=2750
    AmmoPricePerMag=10
    EffectiveRange=75
}