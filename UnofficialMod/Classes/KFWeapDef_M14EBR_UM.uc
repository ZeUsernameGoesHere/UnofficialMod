//================================================
// KFWeapDef_M14EBR_UM
//================================================
// Modified M14 EBR for Unofficial Mod
//================================================
// (c) 2018 "Insert Name Here"
//================================================
class KFWeapDef_M14EBR_UM extends KFWeapDef_M14EBR
	abstract;

/** Workaround for potentially missing INT file */
static function string GetItemName()
{
	return class'UnofficialMod.UMClientConfig'.static.GetLocalWeaponName(default.class, class'KFGame.KFWeapDef_M14EBR');
}

static function string GetItemDescription()
{
	return class'UnofficialMod.UMClientConfig'.static.GetLocalWeaponDesc(default.class, class'KFGame.KFWeapDef_M14EBR');
}

defaultproperties
{
	WeaponClassPath="UnofficialMod.KFWeap_Rifle_M14EBR_UM"
}