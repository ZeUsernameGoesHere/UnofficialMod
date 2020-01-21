//================================================
// UMTraderItemsHelper
//================================================
// Basic helper class for adding to and modifying
// the Trader for-sale weapons list
// This is used for GameInfos/Mutators that create
// their own KFGFxObject_TraderItems instances
// (e.g. Trader Inventory Mutator)
//================================================
// (c) 2018 "Insert Name Here"
//================================================
class UMTraderItemsHelper extends ReplicationInfo;

/** Trader list entry */
struct TraderWeaponMod
{
	/** New WeaponDef */
	var class<KFWeaponDefinition> NewWeapDef;
	/** Old WeaponDef to replace, leave at None to
	    just add this entry to the Trader list */
	var class<KFWeaponDefinition> ReplWeapDef;
	/** Old weapon name for WeaponDef
		Used for mod weapons instead of WeaponDef */
	var name ReplWeapName;
	/** Is this a gameplay-affecting weapon?
		False for QoL-only weapons */
	var bool bAffectsGameplay;
	/** WeaponDef class to check against
		for gameplay-affecting weapons
		Used for mod weapons as base
		UMTraderItemsHelper is used
		to create original config */
	var class<KFWeaponDefinition> CheckWeapDef;
	/** Minimum version for this
		WeaponDef to be considered
		for inclusion in Trader list
		Used for betas */
	var int MinVersion;
	/** Maximum version for this
		WeaponDef to be considered
		for inclusion in Trader list
		Used in case any weapons are removed */
	var int MaxVersion;
	
	structdefaultproperties
	{
		MinVersion=1000
		MaxVersion=10000
	}
};

/** List of Trader modifications */
var const array<TraderWeaponMod> TraderModList;

/** Has the Trader list been modified? */
var repnotify bool bModifiedTraderList;

/** Bitflag for enabled weapons */
var int EnabledWeapons;

/** Trader item count */
var int TraderItemCount;

/** Current game version
	Used in conjunction with 
	TraderWeaponMod.Min/MaxVersion */
var int GameVersion;

/** Don't log if a WeaponDef cannot
	be found or replaced
	Used for mods */
var const bool bNoLog;

replication
{
	if (bNetDirty)
		bModifiedTraderList, EnabledWeapons;
}

simulated event PreBeginPlay()
{
	super.PreBeginPlay();
	
	GameVersion = class'KFGame.KFGameEngine'.static.GetKFGameVersion();
}

simulated event ReplicatedEvent(name VarName)
{
	if (VarName == 'bModifiedTraderList')
		SetTimer(1.0, false, nameof(CheckTraderListClient));
		
	super.ReplicatedEvent(VarName);
}

function CheckTraderList()
{
	if (bModifiedTraderList)
		return;

	ModifyTraderList();
	bModifiedTraderList = true;
}

/** Check Trader list on client
	We do this as an intermediate step to
	ModifyTraderList() to check if Trader list
	is still being compiled using TraderItemCount
	NOTE: Although UnofficialModMut does not call
	CheckTraderList() until the first player spawns
	in, we still check this on the client in case
	a player joins mid-game */
simulated function CheckTraderListClient()
{
	if (WorldInfo.GRI == None)
	{
		SetTimer(1.0, false, nameof(CheckTraderListClient));
		return;
	}
	
	TraderItemCount = KFGameReplicationInfo(WorldInfo.GRI).TraderItems.SaleItems.Length;
	SetTimer(1.0, false, nameof(ModifyTraderList));
}

/** Setup our modifications */
simulated function ModifyTraderList()
{
	local KFGFxObject_TraderItems TraderItems;
	local class<KFWeaponDefinition> OldWeapDef, NewWeapDef;
	local array<KFGFxObject_TraderItems.STraderItem> TempTraderItem;
	local bool bWeaponDefReplaced, bWeaponDefAlreadyExists;
	local int i, Index;

	if (WorldInfo.GRI == None)
	{
		SetTimer(1.0, false, nameof(ModifyTraderList));
		return;
	}

	TraderItems = KFGameReplicationInfo(WorldInfo.GRI).TraderItems;

	// Check to ensure that original Trader list is done compiling
	if (WorldInfo.NetMode == NM_Client && TraderItems.SaleItems.Length != TraderItemCount)
	{
		TraderItemCount = TraderItems.SaleItems.Length;
		SetTimer(1.0, false, nameof(ModifyTraderList));
		return;
	}

	for (i = 0;i < TraderModList.Length;i++)
	{
		// Check for erroneous entries
		if (TraderModList[i].NewWeapDef == None)
		{
			`log("[Unofficial Mod]Empty/erroneous entry in UMTraderItemsHelper.TraderModList entry #" $ i);
			continue;
		}

		// Check for version
		if (!IsRelevantVersion(i))
			continue;

		bWeaponDefReplaced = false;
		bWeaponDefAlreadyExists = false;
		TempTraderItem.Length = 0;
		TempTraderItem.Add(1);

		// Get our WeaponDefs
		if (!GetWeaponDefs(i, OldWeapDef, NewWeapDef))
			continue;

		// Check if this is already in the Trader list, possible reasons:
		// -If using TIM and weapon is disabled
		// -If using UM archetype and weapon is already correct
		Index = TraderItems.SaleItems.Find('WeaponDef', NewWeapDef);

		if (Index != INDEX_NONE)
			bWeaponDefAlreadyExists = true;
		else
		{
			Index = TraderItems.SaleItems.Find('WeaponDef', OldWeapDef);
			if (Index != INDEX_NONE)
			{
				TempTraderItem[0].WeaponDef = NewWeapDef;
				TraderItems.SetItemsInfo(TempTraderItem);
				// NOTE: We set the ItemID after SetItemsInfo() because it defaults
				// to the array index. This way we don't have to call SetItemsInfo()
				// on the entire KFGFxObject_TraderItems.SaleItems array afterwards
				TempTraderItem[0].ItemID = TraderItems.SaleItems[Index].ItemID;
				TraderItems.SaleItems[Index] = TempTraderItem[0];
				bWeaponDefReplaced = true;
			}
		}

		// Continue if this weapon is already in the list
		if (bWeaponDefReplaced || bWeaponDefAlreadyExists)
			continue;

		// Log it if we didn't find the class (may be a
		// typo or original weapon was removed via TIM)
		if (TraderModList[i].ReplWeapDef != None && !bWeaponDefReplaced && !bNoLog)
			`log("[Unofficial Mod]Couldn't find any weapons of type" @ TraderModList[i].ReplWeapDef @ "(trying to replace with" @ TraderModList[i].NewWeapDef $ ")");

		// If this entry doesn't have a WeaponDef
		// to replace, just add it to the list
		// TODO: Re-add this and fix if/when we add
		// weapons that don't replace vanilla weapons
		/*if (TraderModList[i].ReplWeapDef == None)
		{
			TempTraderItem[0].WeaponDef = TraderModList[i].NewWeapDef;
			TraderItems.SetItemsInfo(TempTraderItem);
			// See above use of SetItemsInfo() for why we
			// set the ItemID after SetItemsInfo() call
			TempTraderItem[0].ItemID = TraderItems.SaleItems.Length;
			TraderItems.SaleItems.AddItem(TempTraderItem[0]);
		}*/
	}
}

/** Compiles weapon bitflag from given list */
function CompileWeaponList(array< class<KFWeapon> > DisabledWeapons)
{
	local int i, j;
	local bool bEnabled;
	local class<KFWeaponDefinition> WeaponDef;
	local array<string> ClassPathParts;

	EnabledWeapons = 0;

	for (i = 0;i < TraderModList.Length;i++)
	{
		bEnabled = true;

		// Only check gameplay-affecting weapons
		if (DisabledWeapons.Length > 0 && TraderModList[i].bAffectsGameplay)
		{
			WeaponDef = (TraderModList[i].CheckWeapDef != None ? TraderModList[i].CheckWeapDef : TraderModList[i].NewWeapDef);
			ParseStringIntoArray(WeaponDef.default.WeaponClassPath, ClassPathParts, ".", true);
			
			for (j = 0;j < DisabledWeapons.Length;j++)
			{
				if (ClassPathParts[1] ~= string(DisabledWeapons[j].name))
				{
					bEnabled = false;
					break;
				}
			}
		}
		
		if (bEnabled)
			EnabledWeapons = EnabledWeapons | (1 << i);
	}
}

/** Get old and new WeaponDefs */
simulated function bool GetWeaponDefs(int Index, out class<KFWeaponDefinition> OldWeapDef, out class<KFWeaponDefinition> NewWeapDef)
{
	local KFGFxObject_TraderItems TraderItems;
	local int TraderIndex;
	local class<KFWeaponDefinition> OrigWeapDef;

	// Check for class name
	if (TraderModList[Index].ReplWeapDef == None && TraderModList[Index].ReplWeapName != '')
	{
		TraderItems = KFGameReplicationInfo(WorldInfo.GRI).TraderItems;
		TraderIndex = TraderItems.SaleItems.Find('ClassName', TraderModList[Index].ReplWeapName);
		
		if (TraderIndex == INDEX_NONE)
		{
			// Mention this as this may be a typo
			if (!bNoLog)
				`log("[Unofficial Mod]Couldn't find Trader item for name" @ TraderModList[Index].ReplWeapName);

			return false;
		}
		else
			OrigWeapDef = TraderItems.SaleItems[TraderIndex].WeaponDef;
	}
	else
		OrigWeapDef = TraderModList[Index].ReplWeapDef;
		
	// Check our bitflag
	if ((EnabledWeapons & (1 << Index)) != 0)
	{
		OldWeapDef = OrigWeapDef;
		NewWeapDef = TraderModList[Index].NewWeapDef;
	}
	else
	{
		OldWeapDef = TraderModList[Index].NewWeapDef;
		NewWeapDef = OrigWeapDef;
	}
	
	return true;
}

/** Checks if weapon is replaced */
function bool IsWeaponDefReplaced(class<KFWeaponDefinition> KFWeapDef)
{
	local int Index;
	
	Index = TraderModList.Find('ReplWeapDef', KFWeapDef);
	
	if (Index == INDEX_NONE)
		return false;
		
	return ((EnabledWeapons & (1 << Index)) != 0);
}

/** Checks if this Trader entry is relevant for this version */
simulated function bool IsRelevantVersion(int Index)
{
	return (GameVersion >= TraderModList[Index].MinVersion && GameVersion <= TraderModList[Index].MaxVersion);
}

/** Get custom KFGFxObject_TraderItems (e.g. for Zedternal use) */
static function KFGFxObject_TraderItems GetCustomTraderItems(array< class<KFWeapon> > DisabledWeapons)
{
	local KFGFxObject_TraderItems DefaultTraderItems, CustomTraderItems;
	local array<KFGFxObject_TraderItems.STraderItem> TempTraderItem;
	local int i, j, Index, KFVersion;
	local bool bEnabled;
	local array<string> ClassPathParts;

	DefaultTraderItems = class'UnofficialMod.UMClientConfig'.static.GetDefaultTraderItems();
	CustomTraderItems = new class'KFGame.KFGFxObject_TraderItems';
	KFVersion = class'KFGame.KFGameEngine'.static.GetKFGameVersion();
	
	for (i = 0;i < DefaultTraderItems.SaleItems.Length;i++)
	{
		Index = default.TraderModList.Find('ReplWeapDef', DefaultTraderItems.SaleItems[i].WeaponDef);
		if (Index == INDEX_NONE)
			CustomTraderItems.SaleItems.AddItem(DefaultTraderItems.SaleItems[i]);
		else
		{
			bEnabled = true;
			
			// Check version first
			if (KFVersion < default.TraderModList[Index].MinVersion || KFVersion > default.TraderModList[Index].MaxVersion)
				bEnabled = false;
			else if (DisabledWeapons.Length > 0 && default.TraderModList[Index].bAffectsGameplay)
			{
				ParseStringIntoArray(default.TraderModList[Index].NewWeapDef.default.WeaponClassPath, ClassPathParts, ".", true);
				
				for (j = 0;j < DisabledWeapons.Length;j++)
				{
					if (ClassPathParts[1] ~= string(DisabledWeapons[j].name))
					{
						bEnabled = false;
						break;
					}
				}
			}
			
			if (bEnabled)
			{
				TempTraderItem.Length = 1;
				TempTraderItem[0].WeaponDef = default.TraderModList[Index].NewWeapDef;
				CustomTraderItems.SetItemsInfo(TempTraderItem);
				TempTraderItem[0].ItemID = CustomTraderItems.SaleItems.Length;
				CustomTraderItems.SaleItems.AddItem(TempTraderItem[0]);
			}
			else
				CustomTraderItems.SaleItems.AddItem(DefaultTraderItems.SaleItems[i]);
		}
	}
	
	return CustomTraderItems;
}

/** Find WeaponDef for string */
static function class<KFWeaponDefinition> FindWeaponDef(string WeaponName, bool bGameplayWeaponsOnly)
{
	local int i;
	local class<KFWeaponDefinition> WeaponDef;
	
	for (i = 0;i < default.TraderModList.Length;i++)
	{
		if (!bGameplayWeaponsOnly || default.TraderModList[i].bAffectsGameplay)
		{
			WeaponDef = default.TraderModList[i].NewWeapDef;
			if (Instr(WeaponDef.default.WeaponClassPath, WeaponName, false, true) != INDEX_NONE)
				return WeaponDef;
		}
	}
	
	return None;
}

/** Get vanilla WeaponDef for Unofficial Mod WeaponDef */
static function class<KFWeaponDefinition> GetOriginalWeaponDef(class<KFWeaponDefinition> UMWeapDef)
{
	local int i;
	
	// First check
	if (UMWeapDef.GetPackageName() != 'UnofficialMod')
	{
		`log("[Unofficial Mod]WeaponDef from outside package!" @ UMWeapDef.GetPackageName() $ "." $ UMWeapDef.name);
		return None;
	}

	for (i = 0;i < default.TraderModList.Length;i++)
	{
		if (default.TraderModList[i].NewWeapDef == UMWeapDef)
			return default.TraderModList[i].ReplWeapDef;
	}

	`log("[Unofficial Mod]Couldn't find original WeaponDef for" @ UMWeapDef.name $ "!?");
	return None;
}

/** Copy skins from vanilla weapons to Unofficial Mod weapons */
static simulated function CopyWeaponSkins()
{
	local int i;
	local class<KFWeaponDefinition> KFWeapDef, UMWeapDef;
	local class<KFWeapon> KFWC;
	
	for (i = 0;i < default.TraderModList.Length;i++)
	{
		KFWeapDef = default.TraderModList[i].ReplWeapDef;
		UMWeapDef = default.TraderModList[i].NewWeapDef;

		// Second check ignores WeaponDefs that remove content-lock
		if (KFWeapDef != None && !(KFWeapDef.default.WeaponClassPath ~= UMWeapDef.default.WeaponClassPath))
		{
			KFWC = class<KFWeapon>(DynamicLoadObject(KFWeapDef.default.WeaponClassPath, class'Class'));
			if (KFWC != None && KFWC.default.SkinItemId != 0)
				class'KFGame.KFWeaponSkinList'.static.SaveWeaponSkin(UMWeapDef, KFWC.default.SkinItemId);
		}
	}
}

defaultproperties
{
	// Replacement weapon defs
	TraderModList.Add((NewWeapDef=class'UnofficialMod.KFWeapDef_M14EBR_UM',ReplWeapDef=class'KFGame.KFWeapDef_M14EBR'))
	TraderModList.Add((NewWeapDef=class'UnofficialMod.KFWeapDef_Nailgun_UM',ReplWeapDef=class'KFGame.KFWeapDef_Nailgun',bAffectsGameplay=true))
	TraderModList.Add((NewWeapDef=class'UnofficialMod.KFWeapDef_Pulverizer_UM',ReplWeapDef=class'KFGame.KFWeapDef_Pulverizer',bAffectsGameplay=true))
	TraderModList.Add((NewWeapDef=class'UnofficialMod.KFWeapDef_M16M203_UM',ReplWeapDef=class'KFGame.KFWeapDef_M16M203'))
	TraderModList.Add((NewWeapDef=class'UnofficialMod.KFWeapDef_C4_UM',ReplWeapDef=class'KFGame.KFWeapDef_C4',bAffectsGameplay=true))
	TraderModList.Add((NewWeapDef=class'UnofficialMod.KFWeapDef_HX25_UM',ReplWeapDef=class'KFGame.KFWeapDef_HX25',bAffectsGameplay=true))
	TraderModList.Add((NewWeapDef=class'UnofficialMod.KFWeapDef_MedicRifleGrenadeLauncher_UM',ReplWeapDef=class'KFGame.KFWeapDef_MedicRifleGrenadeLauncher'))
	// Weapons with content-lock removed
	TraderModList.Add((NewWeapDef=class'UnofficialMod.KFWeapDef_ChainBat_UM',ReplWeapDef=class'KFGame.KFWeapDef_ChainBat'))
	TraderModList.Add((NewWeapDef=class'UnofficialMod.KFWeapDef_Zweihander_UM',ReplWeapDef=class'KFGame.KFWeapDef_Zweihander'))
	TraderModList.Add((NewWeapDef=class'UnofficialMod.KFWeapDef_IonThruster_UM',ReplWeapDef=class'KFGame.KFWeapDef_IonThruster',MinVersion=1082))
	TraderModList.Add((NewWeapDef=class'UnofficialMod.KFWeapDef_ChiappaRhino_UM',ReplWeapDef=class'KFGame.KFWeapDef_ChiappaRhino',MinVersion=1082))
	TraderModList.Add((NewWeapDef=class'UnofficialMod.KFWeapDef_ChiappaRhinoDual_UM',ReplWeapDef=class'KFGame.KFWeapDef_ChiappaRhinoDual',MinVersion=1082))
	TraderModList.Add((NewWeapDef=class'UnofficialMod.KFWeapDef_G18_UM',ReplWeapDef=class'KFGame.KFWeapDef_G18',MinVersion=1090))
	TraderModList.Add((NewWeapDef=class'UnofficialMod.KFWeapDef_MosinNagant_UM',ReplWeapDef=class'KFGame.KFWeapDef_MosinNagant',MinVersion=1090))
}