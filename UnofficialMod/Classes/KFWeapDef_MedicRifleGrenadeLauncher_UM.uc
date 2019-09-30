//================================================
// KFWeapDef_MedicRifleGrenadeLauncher_UM
//================================================
// Custom HM-501 Grenade Launcher for Unofficial Mod
//================================================
// (c) 2019 "Insert Name Here"
//================================================
class KFWeapDef_MedicRifleGrenadeLauncher_UM extends KFWeapDef_MedicRifleGrenadeLauncher
	abstract;

/** Workaround for potentially missing INT file */
static function string GetItemLocalization(string KeyName)
{
	return class'UnofficialMod.UMClientConfig'.static.GetWeaponLocalization(KeyName, default.class, class'KFGame.KFWeapDef_MedicRifleGrenadeLauncher');
}

defaultproperties
{
	WeaponClassPath="UnofficialMod.KFWeap_AssaultRifle_MedicRifleGrenadeLauncher_UM"
}