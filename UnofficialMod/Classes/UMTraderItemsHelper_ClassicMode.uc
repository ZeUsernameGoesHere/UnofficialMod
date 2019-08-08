//================================================
// UMTraderItemsHelper_ClassicMode
//================================================
// Extended Trader Items Helper
// used for Classic Mode
//================================================
// (c) 2019 "Insert Name Here"
//================================================
class UMTraderItemsHelper_ClassicMode extends UMTraderItemsHelper;

// Just add the various Classic Mode replacement weapons
// NOTES:
// -If Classic Mode has gameplay changes
// disabled, Unofficial Mod will just replace
// vanilla weapons as normal
// -The VLAD-1000 and Pulverizer are not modified:
// --Unofficial Mod's VLAD-1000 only
//	 has a KF2-specific mag-size buff
// --Classic Mode does not have a Pulverizer variant
defaultproperties
{
	// Don't log if a WeaponDef cannot be found
	// because which weapons are replaced will
	// depend on whether Classic Mode has
	// gameplay changes disabled
	bNoLog=true

	TraderModList.Add((NewWeapDef=class'UnofficialMod.ClassicWeapDef_M14EBR_UM',ReplWeapName=ClassicWeap_Rifle_M14EBR))
	TraderModList.Add((NewWeapDef=class'UnofficialMod.ClassicWeapDef_M16M203_UM',ReplWeapName=ClassicWeap_AssaultRifle_M16M203))
	TraderModList.Add((NewWeapDef=class'UnofficialMod.ClassicWeapDef_C4_UM',ReplWeapName=ClassicWeap_Thrown_C4,bAffectsGameplay=true,CheckWeapDef=class'UnofficialMod.KFWeapDef_C4_UM'))
	TraderModList.Add((NewWeapDef=class'UnofficialMod.ClassicWeapDef_HX25_UM',ReplWeapName=ClassicWeap_GrenadeLauncher_HX25,bAffectsGameplay=true,CheckWeapDef=class'UnofficialMod.KFWeapDef_HX25_UM'))
	TraderModList.Add((NewWeapDef=class'UnofficialMod.ClassicWeapDef_MedicRifleGrenadeLauncher_UM',ReplWeapName=ClassicWeap_AssaultRifle_M7A3))
}