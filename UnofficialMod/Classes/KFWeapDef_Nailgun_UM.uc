//================================================
// KFWeapDef_Nailgun_UM
//================================================
// Modified VLAD-1000 for Unofficial Mod
//================================================
// (c) 2018 "Insert Name Here"
//================================================
class KFWeapDef_Nailgun_UM extends KFWeapDef_Nailgun
	abstract;

/** Workaround for potentially missing INT file */
static function string GetItemLocalization(string KeyName)
{
	return class'UnofficialMod.UMClientConfig'.static.GetWeaponLocalization(KeyName, default.class, class'KFGame.KFWeapDef_Nailgun');
}

defaultproperties
{
	WeaponClassPath="UnofficialMod.KFWeap_Shotgun_Nailgun_UM"
}