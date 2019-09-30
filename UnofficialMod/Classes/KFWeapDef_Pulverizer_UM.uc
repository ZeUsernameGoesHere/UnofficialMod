//================================================
// KFWeapDef_Pulverizer_UM
//================================================
// Modded Pulverizer for Unofficial Mod
//================================================
// (c) 2018 "Insert Name Here"
//================================================
class KFWeapDef_Pulverizer_UM extends KFWeapDef_Pulverizer
	abstract;

/** Workaround for potentially missing INT file */
static function string GetItemLocalization(string KeyName)
{
	return class'UnofficialMod.UMClientConfig'.static.GetWeaponLocalization(KeyName, default.class, class'KFGame.KFWeapDef_Pulverizer');
}

defaultproperties
{
	WeaponClassPath="UnofficialMod.KFWeap_Blunt_Pulverizer_UM"
	
	// Modified to account for single-shot mag
	AmmoPricePerMag=17
}