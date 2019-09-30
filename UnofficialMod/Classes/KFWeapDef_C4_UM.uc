//================================================
// KFWeapDef_C4_UM
//================================================
// Modified C4 for Unofficial Mod
//================================================
// (c) 2018 "Insert Name Here"
//================================================
class KFWeapDef_C4_UM extends KFWeapDef_C4
	abstract;

/** Workaround for potentially missing INT file */
static function string GetItemLocalization(string KeyName)
{
	return class'UnofficialMod.UMClientConfig'.static.GetWeaponLocalization(KeyName, default.class, class'KFGame.KFWeapDef_C4');
}

defaultproperties
{
	WeaponClassPath="UnofficialMod.KFWeap_Thrown_C4_UM"
}