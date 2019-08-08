//================================================
// UMWeaponUpgradeConfigHelper
//================================================
// Helper class for Unofficial Mod that creates
// a config file displaying all Trader
// weapons and upgrades available for them
//================================================
// (c) 2019 "Insert Name Here"
//================================================
class UMWeaponUpgradeConfigHelper extends Object
	config(UnofficialModExtra)
	dependson(UnofficialModMut);
	
/** Info for weapons and upgrades */
struct WeaponUpgradeInfo
{
	/** Weapon's name (localized) */
	var string WeaponName;
	/** Weapon upgrade override info
		NOTE: this is the same name
		used for UnofficialModMut
		to allow easy copy/paste
		between configs */
	var UnofficialModMut.WeaponUpgradeOverrideInfo WeaponUpgradeOverrides;
};

/** Trader weapon upgrades */
var config array<WeaponUpgradeInfo> WeaponUpgrades;

/** Get Trader weapons upgrade info */
static function int CreateTraderWeaponUpgradeConfig(KFGameReplicationInfo KFGRI)
{
	local KFGFxObject_TraderItems TraderItems;
	local class<KFWeaponDefinition> WeaponDef;
	local WeaponUpgradeInfo WUI;
	local name PackageName;
	local int i;
	
	// Reset first
	default.WeaponUpgrades.Length = 0;
	
	// Go through default Trader inventory first
	TraderItems = class'KFGame.KFGameReplicationInfo'.default.TraderItems;
	
	for (i = 0;i < TraderItems.SaleItems.Length;i++)
	{
		WeaponDef = TraderItems.SaleItems[i].WeaponDef;
		WUI.WeaponName = WeaponDef.static.GetItemName();
		WUI.WeaponUpgradeOverrides.WeaponDef = WeaponDef;
		WUI.WeaponUpgradeOverrides.UpgradeLevel = WeaponDef.default.UpgradePrice.Length;
		default.WeaponUpgrades.AddItem(WUI);
	}

	// This should never skip, but check anyways
	if (KFGRI != None && KFGRI.TraderItems != None && KFGRI.TraderItems.SaleItems.Length > 0)
	{
		// Now go through current Trader inventory
		TraderItems = KFGRI.TraderItems;
		
		for (i = 0;i < TraderItems.SaleItems.Length;i++)
		{
			WeaponDef = TraderItems.SaleItems[i].WeaponDef;
			PackageName = WeaponDef.GetPackageName();
			
			// Ignore vanilla and Unofficial Mod weapons
			if (PackageName == 'KFGame' || PackageName == 'UnofficialMod')
				continue;
				
			WUI.WeaponName = WeaponDef.static.GetItemName();
			WUI.WeaponUpgradeOverrides.WeaponDef = WeaponDef;
			WUI.WeaponUpgradeOverrides.UpgradeLevel = WeaponDef.default.UpgradePrice.Length;
			default.WeaponUpgrades.AddItem(WUI);
		}
	}

	StaticSaveConfig();
	return default.WeaponUpgrades.Length;
}

defaultproperties
{
}