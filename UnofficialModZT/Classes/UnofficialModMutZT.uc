//================================================
// UnofficialModMutZT
//================================================
// Mutator for Unofficial Mod
// Modified for Zedternal compatibility
//================================================
// (c) 2019 "Insert Name Here"
//================================================
class UnofficialModMutZT extends UnofficialModMut;

event PreBeginPlay()
{
	local KFGFxObject_TraderItems DefaultTraderItems;
	local int i, j;
	local string WeapDefStr;
	local array<UMTraderItemsHelper.TraderWeaponMod> TraderModList;

	super.PreBeginPlay();

	// Replace Zedternal's default Trader items with our own
	// This is a workaround for the fact that we replace
	// vanilla weapons instead of adding new ones
	// If we modify the trader list after the game starts,
	// Zedternal weapon upgrades can be purchased but won't work
	`log("[Unofficial Mod]Zedternal found, replacing weapons in Trader list...");
	DefaultTraderItems = class'UnofficialMod.UMTraderItemsHelper'.static.GetCustomTraderItems(GetDisabledUMWeapons());
	WMGameInfo_Endless(WorldInfo.Game).DefaultTraderItems = DefaultTraderItems;

	// Replace player starting weapons as needed
	// This also replaces these weapons in pickup factories
	TraderModList = class'UnofficialMod.UMTraderItemsHelper'.default.TraderModList;
	for (i = 0;i < class'Zedternal.Config_Weapon'.default.Weapon_PlayerStartingWeaponDefList.Length;i++)
	{
		WeapDefStr = class'Zedternal.Config_Weapon'.default.Weapon_PlayerStartingWeaponDefList[i];
		// Only for vanilla WeaponDefs
		if (Left(WeapDefStr, 7) ~= "KFGame.")
		{
			for (j = 0;j < TraderModList.Length;j++)
			{
				if (TraderModList[j].ReplWeapDef == None || DefaultTraderItems.SaleItems.Find('WeaponDef', TraderModList[j].NewWeapDef) == INDEX_NONE)
					continue;

				if (Instr(WeapDefStr, TraderModList[j].ReplWeapDef.name, , true) != INDEX_NONE)
				{
					class'Zedternal.Config_Weapon'.default.Weapon_PlayerStartingWeaponDefList[i] = PathName(TraderModList[j].NewWeapDef);
					break;
				}
			}
		}
	}
}

/** Overridden because this is not necessary for Zedternal */
function CheckTraderItems();

defaultproperties
{
}