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
static function string GetItemName()
{
	return class'UnofficialMod.UMClientConfig'.static.GetLocalWeaponName(default.class, class'KFGame.KFWeapDef_Nailgun');
}

static function string GetItemDescription()
{
	return class'UnofficialMod.UMClientConfig'.static.GetLocalWeaponDesc(default.class, class'KFGame.KFWeapDef_Nailgun');
}

defaultproperties
{
	WeaponClassPath="UnofficialMod.KFWeap_Shotgun_Nailgun_UM"
}