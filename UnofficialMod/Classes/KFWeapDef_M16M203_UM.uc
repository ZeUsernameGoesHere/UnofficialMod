//================================================
// KFWeapDef_M16M203_UM
//================================================
// Modified M16/M203 for Unofficial Mod
//================================================
// (c) 2018 "Insert Name Here"
//================================================
class KFWeapDef_M16M203_UM extends KFWeapDef_M16M203
	abstract;

/** Workaround for potentially missing INT file */
static function string GetItemLocalization(string KeyName)
{
	return class'UnofficialMod.UMClientConfig'.static.GetWeaponLocalization(KeyName, default.class, class'KFGame.KFWeapDef_M16M203');
}

defaultproperties
{
	WeaponClassPath="UnofficialMod.KFWeap_AssaultRifle_M16M203_UM"
}