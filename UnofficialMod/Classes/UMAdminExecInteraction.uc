//================================================
// UMAdminExecInteraction
//================================================
// Custom Interaction for Unofficial Mod
// Used to modify server settings
// using the console
//================================================
// (c) 2019 "Insert Name Here"
//================================================
class UMAdminExecInteraction extends UMBaseInteraction;

// NOTE: Unless otherwise mentioned, these
// settings take effect on map change
// This ensures that gameplay is consistent
// throughout each game session

/** Found WeaponDefs from last search
	Used to quickly select WeaponDef with
	another command if several were found */
var array< class<KFWeaponDefinition> > LastFoundWeaponDefs;

function Initialized()
{
	super.Initialized();

	if (OwningKFPC.WorldInfo.NetMode == NM_Standalone)
		ConsoleMsg("<Unofficial Mod> Added console commands for solo mod settings");
	else
		ConsoleMsg("<Unofficial Mod> Added console commands for server mod settings");
}

/** Is this player an admin?
	NOTE: this class won't be added
	to the PlayerController's Interactions
	unless the player qualifies, but we
	check here anyways in case the player
	logs out as admin */
function bool CheckPlayerAdmin()
{
	local bool bAdmin;

	bAdmin = (OwningKFPC.WorldInfo.NetMode == NM_Standalone || OwningKFPC.PlayerReplicationInfo.bAdmin);
	
	if (!bAdmin)
		ConsoleMsg("This function is only available to solo players and server admins!");
		
	return bAdmin;
}

/** Disable weapon upgrades */
exec function UMDisableWeaponUpgrades(bool bDisable)
{
	if (!CheckPlayerAdmin())
		return;
		
	OwningKFPC.ConsoleCommand("Mutate UMDisableWeaponUpgrades" @ bDisable, false);
}

/** Start without Tier 1 weapons */
exec function UMStartWithoutTier1(bool bEnable)
{
	if (!CheckPlayerAdmin())
		return;
		
	OwningKFPC.ConsoleCommand("Mutate UMStartWithoutTier1" @ bEnable, false);
}

/** KF1-style Syringe */
exec function UMKF1StyleSyringe(bool bEnable)
{
	if (!CheckPlayerAdmin())
		return;
	
	OwningKFPC.ConsoleCommand("Mutate UMKF1StyleSyringe" @ bEnable, false);
}

/** Disable random map objectives */
exec function UMDisableRandomMapObj(bool bDisable)
{
	if (!CheckPlayerAdmin())
		return;
	
	OwningKFPC.ConsoleCommand("Mutate UMDisableRandomMapObj" @ bDisable, false);
}

/** Maximum failed kick vote attempts per player
	Takes effect immediately, and will block further
	kick vote attempts if player is already at their limit */
exec function UMMaxFailedKickVoteAttempts(int Attempts)
{
	if (!CheckPlayerAdmin())
		return;
	
	OwningKFPC.ConsoleCommand("Mutate UMMaxFailedKickVoteAttempts" @ Attempts, false);
}

/** Kick the kick vote initiator once they attempt
	and fail their limit of kick votes
	Takes effect on the next failed kick vote attempt,
	so if a player has already failed their limit of
	kick votes, you'll have to kick them manually as
	they won't be able to attempt any more kick votes */
exec function UMKickFailedVoteInitiator(bool bEnable)
{
	if (!CheckPlayerAdmin())
		return;
	
	OwningKFPC.ConsoleCommand("Mutate UMKickFailedVoteInitiator" @ bEnable, false);
}

/** Perk knife speed boost
	Takes effect immediately */
/*exec function UMPerkKnifeSpeedBoostLevel(byte BoostLevel)
{
	if (!CheckPlayerAdmin())
		return;
	
	// Check for proper values
	if (BoostLevel > 2)
	{
		ConsoleMsg("Proper values for Perk Knife speed boost are 0 (disabled), 1 (slower players), and 2 (all players)");
		return;
	}

	OwningKFPC.ConsoleCommand("Mutate UMPerkKnifeSpeedBoostLevel" @ BoostLevel, false);
}*/

/** Additional Trader time for mid-game joiners
	Takes effect immediately */
exec function UMMidGameJoinerTraderTime(int TraderTime)
{
	if (!CheckPlayerAdmin())
		return;
	
	// Check for proper values
	if (TraderTime < 0)
	{
		ConsoleMsg("Extra Trader time must be zero or positive");
		return;
	}

	OwningKFPC.ConsoleCommand("Mutate UMMidGameJoinerTraderTime" @ TraderTime, false);
}

/** Default weapon upgrade level */
exec function UMDefaultWeaponUpgradeLevel(int UpgradeLevel)
{
	local int MaxUpgradeCount;

	if (!CheckPlayerAdmin())
		return;
	
	MaxUpgradeCount = class'UnofficialMod.UnofficialModMut'.default.MaxWeaponUpgradeCount;
	UpgradeLevel = Clamp(UpgradeLevel, -MaxUpgradeCount, MaxUpgradeCount);

	OwningKFPC.ConsoleCommand("Mutate UMDefaultWeaponUpgradeLevel" @ UpgradeLevel, false);
}

/** Find weapon definition for string
	NOTE: This ignores dual weapons as dual
	weapons will often get multiple entries
	per search term (e.g. "9mm" will return
	both single and dual 9mm)
	Having dual weapons is not necessary for the
	weapon upgrade override configs anyways and
	UnofficialModMut handles the relevant checks */
function class<KFWeaponDefinition> FindWeaponDef(string SearchString, string CommandName)
{
	local KFGFxObject_TraderItems TraderItems;
	local KFGFXObject_TraderItems.STraderItem TraderItem;
	local int i;

	// Check for number
	i = int(SearchString);
	if (i > 0 && i <= LastFoundWeaponDefs.Length)
		return LastFoundWeaponDefs[i - 1];

	LastFoundWeaponDefs.Length = 0;
	TraderItems = KFGameReplicationInfo(OwningKFPC.WorldInfo.GRI).TraderItems;

	// Use default TraderItems if none is available
	// We use 2 as an arbitrary value because no
	// mods should be setting the Trader list that small
	// but the unimplemented Horde Weekly has a Trader list
	// with one item in it (the single 9mm pistol)
	if (TraderItems == None || TraderItems.SaleItems.Length < 2)
		TraderItems = class'UnofficialMod.UMClientConfig'.static.GetDefaultTraderItems();

	for (i = 0;i < TraderItems.SaleItems.Length;i++)
	{
		TraderItem = TraderItems.SaleItems[i];
		
		// Skip dual weapons
		if (TraderItem.SingleClassName != '')
			continue;
			
		if (Instr(string(TraderItem.WeaponDef.name), SearchString, false, true) > INDEX_NONE)
			LastFoundWeaponDefs.AddItem(TraderItem.WeaponDef);
	}
	
	if (LastFoundWeaponDefs.Length == 0)
	{
		ConsoleMsg("No weapons found for search term" @ SearchString);
		return None;
	}
	else if (LastFoundWeaponDefs.Length > 1)
	{
		ConsoleMsg("Found" @ LastFoundWeaponDefs.Length @ "weapons for search term" @ SearchString $ ":");
		
		for (i = 0;i < LastFoundWeaponDefs.Length;i++)
			ConsoleMsg((i + 1) $ ")" @ LastFoundWeaponDefs[i].static.GetItemName() $ ":" @ string(LastFoundWeaponDefs[i].name));

		ConsoleMsg("Use" @ CommandName @ "again with the index in place of the search term to use that weapon");

		return None;
	}
	
	return LastFoundWeaponDefs[0];
}

/** Add weapon to weapon upgrade override */
exec function UMAddWeaponUpgradeOverride(string WeaponName, int UpgradeLevel)
{
	local class<KFWeaponDefinition> WeaponDef;
	local string WeaponDefPath;

	if (!CheckPlayerAdmin())
		return;
	
	WeaponDef = FindWeaponDef(WeaponName, "UMAddWeaponUpgradeOverride");
	
	// FindWeaponDef() handles console output
	// if we don't find anything
	if (WeaponDef == None)
		return;
		
	WeaponDefPath = string(WeaponDef.GetPackageName()) $ "." $ string(WeaponDef.name);

	OwningKFPC.ConsoleCommand("Mutate UMAddWeaponUpgradeOverride" @ WeaponDefPath @ UpgradeLevel, false);
}

/** Remove weapon from weapon upgrade override */
exec function UMRemoveWeaponUpgradeOverride(string WeaponName)
{
	local class<KFWeaponDefinition> WeaponDef;
	local string WeaponDefPath;

	if (!CheckPlayerAdmin())
		return;
	
	WeaponDef = FindWeaponDef(WeaponName, "UMRemoveWeaponUpgradeOverride");
	
	// FindWeaponDef() handles console output
	// if we don't find anything
	if (WeaponDef == None)
		return;
		
	WeaponDefPath = string(WeaponDef.GetPackageName()) $ "." $ string(WeaponDef.name);

	OwningKFPC.ConsoleCommand("Mutate UMRemoveWeaponUpgradeOverride" @ WeaponDefPath, false);
}

/** Enable/disable gameplay-affecting weapon */
exec function UMEnableGameplayWeapon(string WeaponName, bool bEnabled)
{
	local class<KFWeaponDefinition> WeaponDef;

	if (!CheckPlayerAdmin())
		return;
		
	WeaponDef = class'UnofficialMod.UMTraderItemsHelper'.static.FindWeaponDef(WeaponName, true);
	
	if (WeaponDef == None)
	{
		ConsoleMsg("Could not find any weapons for search string" @ WeaponName);
		return;
	}

	OwningKFPC.ConsoleCommand("Mutate UMEnableGameplayWeapon" @ WeaponDef.default.WeaponClassPath @ bEnabled, false);
}

/** Disable picking up others' weapons
	Takes effect immediately */
exec function UMDisableOthersWeaponsPickup(bool bDisabled)
{
	if (!CheckPlayerAdmin())
		return;
	
	OwningKFPC.ConsoleCommand("Mutate UMDisableOthersWeaponsPickup" @ bDisabled, false);
}

/** Perk Knife speed boost during wave
	Takes effect immediately */
exec function UMPerkKnifeSpeedBoostWave(float AdditionalSpeed, float MaxSpeed)
{
	if (!CheckPlayerAdmin())
		return;
	
	OwningKFPC.ConsoleCommand("Mutate UMPerkKnifeSpeedBoostWave" @ AdditionalSpeed @ MaxSpeed, false);
}

/** Perk Knife speed boost during Trader time
	Takes effect immediately */
exec function UMPerkKnifeSpeedBoostTrader(float AdditionalSpeed, float MaxSpeed)
{
	if (!CheckPlayerAdmin())
		return;
	
	OwningKFPC.ConsoleCommand("Mutate UMPerkKnifeSpeedBoostTrader" @ AdditionalSpeed @ MaxSpeed, false);
}

/*exec function
{
	if (!CheckPlayerAdmin())
		return;
	
	OwningKFPC.ConsoleCommand("Mutate " @ , false);
}*/

defaultproperties
{
}