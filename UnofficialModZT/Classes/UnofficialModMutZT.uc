//================================================
// UnofficialModMutZT
//================================================
// Mutator for Unofficial Mod
// Modified for Zedternal compatibility
//================================================
// (c) 2019 "Insert Name Here"
//================================================
class UnofficialModMutZT extends UnofficialModMut;

/** Cached default TraderItems */
var KFGFxObject_TraderItems DefaultTraderItems;

/** Replaced WeaponDef string in config */
struct ReplWeapDefString
{
	/** Original string */
	var string KFString;
	/** New string */
	var string UMString;
};

/** Replaced WeaponDef strings in config
	Used to revert configs afterwards */
var array<ReplWeapDefString> ReplWeapDefStringList;

event PreBeginPlay()
{
	local int i, j;
	local string WeapDefStr;
	local array<UMTraderItemsHelper.TraderWeaponMod> TraderModList;
	local ReplWeapDefString WeapDefEntry;

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
					// Add this so we can revert afterwards
					WeapDefEntry.KFString = WeapDefStr;
					WeapDefEntry.UMString = PathName(TraderModList[j].NewWeapDef);
					ReplWeapDefStringList.AddItem(WeapDefEntry);
					class'Zedternal.Config_Weapon'.default.Weapon_PlayerStartingWeaponDefList[i] = WeapDefEntry.UMString;
					break;
				}
			}
		}
	}
	
	// Check if we need to revert
	if (ReplWeapDefStringList.Length > 0)
		SetTimer(1.0, false, nameof(RevertZTConfig));
}

/** Overridden because this is not necessary for Zedternal */
function CheckTraderItems();

/** Reverts Zedternal config
	This is done because we modify the config before
	it has a chance to check the mod's version
	If Zedternal has updated, it'll save our values to
	its config, which is what we don't want */
function RevertZTConfig()
{
	local int i, Index;

	if (WMGameInfo_Endless(WorldInfo.Game).PerkStartingWeapon.Length == 0)
	{
		SetTimer(1.0, false, nameof(RevertZTConfig));
		return;
	}
	
	for (i = 0;i < ReplWeapDefStringList.Length;i++)
	{
		Index = class'Zedternal.Config_Weapon'.default.Weapon_PlayerStartingWeaponDefList.Find(ReplWeapDefStringList[i].UMString);
		if (Index != INDEX_NONE)
			class'Zedternal.Config_Weapon'.default.Weapon_PlayerStartingWeaponDefList[Index] = ReplWeapDefStringList[i].KFString;
		else
			`warn("[Unofficial Mod]Could not find replaced ZT WeaponDef" @ ReplWeapDefStringList[i].KFString @
				"- UM WeaponDef =" @ ReplWeapDefStringList[i].UMString);
	}

	class'Zedternal.Config_Weapon'.static.StaticSaveConfig();
	ReplWeapDefStringList.Length = 0;
}

defaultproperties
{
}