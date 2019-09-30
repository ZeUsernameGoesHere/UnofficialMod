//================================================
// KFWeapDef_HX25_UM
//================================================
// Modified HX-25 for Unofficial Mod
//================================================
// (c) 2019 "Insert Name Here"
//================================================
class KFWeapDef_HX25_UM extends KFWeapDef_HX25
	abstract;

/** Workaround for potentially missing INT file */
static function string GetItemLocalization(string KeyName)
{
	return class'UnofficialMod.UMClientConfig'.static.GetWeaponLocalization(KeyName, default.class, class'KFGame.KFWeapDef_HX25');
}

defaultproperties
{
	WeaponClassPath="UnofficialMod.KFWeap_GrenadeLauncher_HX25_UM"
}