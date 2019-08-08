//================================================
// UMExecInteraction
//================================================
// Custom Interaction for Unofficial Mod
// Used to change client settings
// on the fly using the console
//================================================
// (c) 2018 "Insert Name Here"
//================================================
class UMExecInteraction extends UMBaseInteraction;

/** Disable/enable M14 laser sight by default */
exec function UMM14LaserSightDisable(bool bDisabled)
{
	// We don't update the weapon itself, just the setting
	ClientConfig.bM14EBRLaserSightDisabled = bDisabled;
	ClientConfig.SaveConfig();
}

/** Enable/disable M203 manual reload */
exec function UMM203ManualReload(bool bManualReload)
{
	local KFWeap_AssaultRifle_M16M203_UM M16M203;

	ClientConfig.bM203ManualReload = bManualReload;
	ClientConfig.SaveConfig();
	
	// Now update weapon if in inventory
	if (OwningKFPC.Pawn != None && OwningKFPC.Pawn.InvManager != None)
	{
		foreach OwningKFPC.Pawn.InvManager.InventoryActors(class'UnofficialMod.KFWeap_AssaultRifle_M16M203_UM', M16M203)
		{
			M16M203.SetManualReload();
			
			// Auto-reload if necessary
			if (!bManualReload && M16M203.AmmoCount[1] == 0)
				M16M203.SendToAltReload();
		}
	}
}

// All colors have optional parameters
// This enables a reset to defaults
// using just the command alone

/** Custom HUD health color */
exec function UMHealthColor(optional byte R = 95, optional byte G = 210, optional byte B = 255, optional byte A = 192)
{
	ClientConfig.HUDHealthColor = MakeColor(R, G, B, A);
	ClientConfig.SaveConfig();
	UpdateHUDColors();
}

/** Custom HUD armor color */
exec function UMArmorColor(optional byte R = 0, optional byte G = 0, optional byte B = 255, optional byte A = 192)
{
	ClientConfig.HUDArmorColor = MakeColor(R, G, B, A);
	ClientConfig.SaveConfig();
	UpdateHUDColors();
}

/** Custom HUD regen health color */
exec function UMRegenHealthColor(optional byte R = 255, optional byte G = 255, optional byte B = 255, optional byte A = 192)
{
	ClientConfig.HUDRegenHealthColor = MakeColor(R, G, B, A);
	ClientConfig.SaveConfig();
	UpdateHUDColors();
}

/** Updates color in HUD after it is changed here */
function UpdateHUDColors()
{
	local KFGFxHudWrapper_UM UMHUD;
	local Interaction BaseInt;
	local UMHUDInteraction UMHUDInt;
	
	UMHUD = KFGFxHudWrapper_UM(OwningKFPC.myHUD);
	
	if (UMHUD != None)
	{
		UMHUD.UMHealthColor = ClientConfig.HUDHealthColor;
		UMHUD.UMArmorColor = ClientConfig.HUDArmorColor;
		UMHUD.UMRegenHealthColor = ClientConfig.HUDRegenHealthColor;
	}
	else
	{
		foreach OwningKFPC.Interactions(BaseInt)
		{
			UMHUDInt = UMHUDInteraction(BaseInt);
			if (UMHUDInt != None)
			{
				UMHUDInt.SetupColors();
				break;
			}
		}
	}
}

/** Show weapon upgrade overrides in console */
exec function UMWeaponUpgrades()
{
	local string InfoString;
	local int i;

	if (ClientConfig.bDisableWeaponUpgrades)
	{
		ConsoleMsg("ALL weapon upgrades are DISABLED!");
		return;
	}
	
	ConsoleMsg(ClientConfig.GetWeaponUpgradeString(ClientConfig.DefaultWeaponUpgradeLevel) @ "are ENABLED by default");

	InfoString = ClientConfig.WeaponUpgradeOverrideCount @ "override";
	if (ClientConfig.WeaponUpgradeOverrideCount != 1)
		InfoString $= "s";
	if (ClientConfig.WeaponUpgradeOverrideCount > 0)
		InfoString $= ":";

	ConsoleMsg(InfoString);
	
	for (i = 0;i < ClientConfig.WeaponUpgradeOverrideCount;i++)
	{
		if (ClientConfig.WeaponUpgradeOverrides[i].WeaponDef != None)
			InfoString = ClientConfig.WeaponUpgradeOverrides[i].WeaponDef.static.GetItemName();
		else // Shouldn't happen
			InfoString = "???";
			
		InfoString $= (":" @ GetWeaponUpgradeCount(i));
		ConsoleMsg(InfoString);
	}
}

/** Get upgrade override count for specific weapon */
function int GetWeaponUpgradeCount(int Index)
{
	local int UpgradeCount;
	
	if (ClientConfig.WeaponUpgradeOverrides[Index].WeaponDef == None)
		return 0;

	UpgradeCount = ClientConfig.WeaponUpgradeOverrides[Index].UpgradeLevel;
	if (UpgradeCount < 0)
		UpgradeCount += ClientConfig.WeaponUpgradeOverrides[Index].WeaponDef.default.UpgradePrice.Length;
		
	return Max(UpgradeCount, 0);
}

/** Create or update weapon upgrade config file */
exec function UMMakeWeaponUpgradesConfig()
{
	local KFGameReplicationInfo KFGRI;
	local int WeaponCount;

	KFGRI = KFGameReplicationInfo(ClientConfig.WorldInfo.GRI);
	WeaponCount = class'UnofficialMod.UMWeaponUpgradeConfigHelper'.static.CreateTraderWeaponUpgradeConfig(KFGRI);

	ConsoleMsg("Weapon upgrade info written to KFUnofficialModExtra.ini (" $ WeaponCount @ "entries)");
}

/** Enable/disable HM-501 manual reload */
exec function UMHM501ManualReload(bool bManualReload)
{
	local KFWeap_AssaultRifle_MedicRifleGrenadeLauncher_UM HM501;

	ClientConfig.bHM501ManualReload = bManualReload;
	ClientConfig.SaveConfig();
	
	// Now update weapon if in inventory
	if (OwningKFPC.Pawn != None && OwningKFPC.Pawn.InvManager != None)
	{
		foreach OwningKFPC.Pawn.InvManager.InventoryActors(class'UnofficialMod.KFWeap_AssaultRifle_MedicRifleGrenadeLauncher_UM', HM501)
		{
			HM501.SetManualReload();
			
			// Auto-reload if necessary
			if (!bManualReload && HM501.AmmoCount[1] == 0)
				HM501.SendToAltReload();
		}
	}
}

/** Enable/disable HMTech charge display */
exec function UMHMTechChargeHUD(optional int DisableLevel = 0)
{
	ClientConfig.DisableHMTechChargeHUD = Clamp(DisableLevel, 0, 2);
	ClientConfig.SaveConfig();
}

/** Disable Trader dialog */
exec function UMDisableTraderDialog(optional bool bAll, optional bool bArmorAmmoGrenade, optional bool bDeath)
{
	ClientConfig.DisableTraderDialog.bAll =  bAll;
	ClientConfig.DisableTraderDialog.bArmorAmmoGrenade = bArmorAmmoGrenade;
	ClientConfig.DisableTraderDialog.bDeath = bDeath;
	ClientConfig.SaveConfig();
	
	// Update the Trader dialog manager
	ClientConfig.CheckTraderDialog();
}

/** Find weapon path for auto-set alt-fire 
	NOTE: This ignores dual weapons as dual
	weapons will often get multiple entries
	per search term (e.g. "9mm" will return
	both single and dual 9mm)
	No current dual weapons are eligible for
	the auto-set alt-fire feature anyways */
function string FindWeaponPath(string SearchString)
{
	local KFGFxObject_TraderItems TraderItems;
	local KFGFXObject_TraderItems.STraderItem TraderItem;
	local int i;
	local array<string> FoundWeaponPaths;
	local class<KFWeaponDefinition> WeaponDef;
	
	// NOTE: We search through the Trader items for this
	// because this is the only real way to get these weapons
	// The weapons not on the Trader list are ineligible anyways
	TraderItems = KFGameReplicationInfo(OwningKFPC.WorldInfo.GRI).TraderItems;
	
	// Use default if we don't have a TraderItems right now
	if (TraderItems == None || TraderItems.SaleItems.Length == 0)
		TraderItems = class'KFGame.KFGameReplicationInfo'.default.TraderItems;
		
	for (i = 0;i < TraderItems.SaleItems.Length;i++)
	{
		TraderItem = TraderItems.SaleItems[i];
		
		// Skip dual weapons
		if (TraderItem.SingleClassName != '')
			continue;
			
		if (Instr(TraderItem.WeaponDef.default.WeaponClassPath, SearchString, false, true) > INDEX_NONE)
		{
			// We hard-code Unofficial Mod's C4 because it
			// has an alt-fire but the vanilla C4 doesn't
			if (TraderItem.WeaponDef == class'KFGame.KFWeapDef_C4' || TraderItem.WeaponDef == class'UnofficialMod.KFWeapDef_C4_UM')
				FoundWeaponPaths.AddItem(class'UnofficialMod.KFWeapDef_C4_UM'.default.WeaponClassPath);
			else if (TraderItem.WeaponDef.GetPackageName() == 'UnofficialMod')
			{
				// Try to convert Unofficial Mod WeaponDef to vanilla
				// Done to ensure that any weapons with alt-fire eligibility
				// in both UM and vanilla (e.g. Nailgun) can be modified
				// as such regardless of whether the server disables UM weapons
				WeaponDef = class'UnofficialMod.UMTraderItemsHelper'.static.GetOriginalWeaponDef(TraderItem.WeaponDef);
				if (WeaponDef != None)
					FoundWeaponPaths.AddItem(WeaponDef.default.WeaponClassPath);
				else
					FoundWeaponPaths.AddItem(TraderItem.WeaponDef.default.WeaponClassPath);
			}
			else
				FoundWeaponPaths.AddItem(TraderItem.WeaponDef.default.WeaponClassPath);
		}
	}
	
	if (FoundWeaponPaths.Length == 0)
	{
		ConsoleMsg("No weapons found for search term" @ SearchString);
		return "";
	}
	else if (FoundWeaponPaths.Length > 1)
	{
		ConsoleMsg("Found" @ FoundWeaponPaths.Length @ "weapons for search term" @ SearchString $ ":");
		
		for (i = 0;i < FoundWeaponPaths.Length;i++)
			ConsoleMsg(GetLocalizedWeaponName(FoundWeaponPaths[i]) $ ":" @ FoundWeaponPaths[i]);
			
		return "";
	}
	
	return FoundWeaponPaths[0];
}

/** Get localized weapon name from class path */
function string GetLocalizedWeaponName(string WeaponPath)
{
	local array<string> PathParts;
	ParseStringIntoArray(WeaponPath, PathParts, ".", true);
	return Localize(PathParts[1], "ItemName", PathParts[0]);
}

/** Add weapon to auto-set alt-fire feature */
exec function UMAddAltFireWeapon(string WeaponName)
{
	local string WeaponPath;
	local class<KFWeapon> WeaponClass;
	local int i;
	
	WeaponPath = FindWeaponPath(WeaponName);
	
	// FindWeaponPath() handles console output
	// if we don't find anything
	if (WeaponPath == "")
		return;

	// Prevent duplicate entries
	// We don't use Find() because the
	// UMClientConfig's class paths may
	// be lower-case or missing the package
	// (for KFGameContent package weapons)
	for (i = 0;i < ClientConfig.AltFireWeaponClassPaths.Length;i++)
	{
		if (Instr(WeaponPath, ClientConfig.AltFireWeaponClassPaths[i], false, true) > INDEX_NONE)
		{
			ConsoleMsg(GetLocalizedWeaponName(WeaponPath) @ "is already in the alt-fire list!");
			return;
		}
	}

	WeaponClass = class<KFWeapon>(DynamicLoadObject(WeaponPath, class'Class'));
	
	if (WeaponClass == None)
	{
		// This should never happen,
		// but mention it if it does
		ConsoleMsg("Could not load weapon for path" @ WeaponPath $ "!?");
		return;
	}
	
	// Check if this weapon is eligible
	if (ClientConfig.IsEligibleAltFireWeaponClass(WeaponClass))
	{
		ClientConfig.AltFireWeaponClassPaths.AddItem(WeaponPath);
		ClientConfig.SaveConfig();
		ClientConfig.AltFireWeaponClasses.AddItem(WeaponClass);
		
		// Check timers and enable if necessary
		ClientConfig.CheckAltFireWeaponTimers();
		
		ConsoleMsg("Added" @ GetLocalizedWeaponname(WeaponPath) @ "for auto-set alt-fire");
	}
	else
		ConsoleMsg(GetLocalizedWeaponName(WeaponPath) @ "is not eligible for auto-set alt fire feature");
}

/** Remove weapon from auto-set alt-fire feature */
exec function UMRemoveAltFireWeapon(string WeaponName)
{
	local string WeaponPath, AltFireWeaponPath;
	local class<KFWeapon> WeaponClass;
	local int i, j;
	
	WeaponPath = FindWeaponPath(WeaponName);
	
	// FindWeaponPath() handles console output
	// if we don't find anything
	if (WeaponPath == "")
		return;

	// Search the current settings for this path
	// We don't use Find() because the
	// UMClientConfig's class paths may
	// be lower-case or missing the package
	// (for KFGameContent package weapons)
	for (i = 0;i < ClientConfig.AltFireWeaponClassPaths.Length;i++)
	{
		if (Instr(WeaponPath, ClientConfig.AltFireWeaponClassPaths[i], false, true) > INDEX_NONE)
		{
			// Remove this entry from both class paths and classes
			for (j=0;j < ClientConfig.AltFireWeaponClasses.Length;j++)
			{
				WeaponClass = ClientConfig.AltFireWeaponClasses[j];
				AltFireWeaponPath = string(WeaponClass.GetPackageName()) $ "." $ string(WeaponClass.name);
				if (WeaponPath ~= AltFireWeaponPath)
				{
					ClientConfig.AltFireWeaponClasses.Remove(j, 1);
					// Disable timers if necessary
					ClientConfig.CheckAltFireWeaponTimers();
					break;
				}
			}
			
			ClientConfig.AltFireWeaponClassPaths.Remove(i, 1);
			ClientConfig.SaveConfig();
			ConsoleMsg("Removed" @ GetLocalizedWeaponName(WeaponPath) @ "from auto-set alt-fire");
			return;
		}
	}
	
	// We only get down here if weapon was
	// not currently set, so mention it
	ConsoleMsg(GetLocalizedWeaponName(WeaponPath) @ "is not currently in list for auto-set alt-fire feature");
}

/** List gameplay-affecting weapons */
exec function UMGameplayWeapons()
{
	local int i;
	local bool bEnabled;
	
	for (i = 0;i < 16;i++)
	{
		if (ClientConfig.GameplayWeapons[i].WeaponClass == None)
			continue;
			
		bEnabled = ClientConfig.GameplayWeapons[i].bEnabled;
		ConsoleMsg(ClientConfig.GameplayWeapons[i].WeaponClass.default.ItemName $ ":" @ (bEnabled ? "ENABLED" : "DISABLED"));
	}
}

/** Enable/disable showing others' large zed kills in kill ticker */
exec function UMShowOthersLargeZedKills(bool bEnable)
{
	ClientConfig.bShowOthersLargeZedKills = bEnable;
	ClientConfig.SaveConfig();
}

/** Custom HUD Supplier usable color */
exec function UMSupplierUsableColor(optional byte R = 0, optional byte G = 192, optional byte B = 0, optional byte A = 192)
{
	ClientConfig.HUDSupplierUsableColor = MakeColor(R, G, B, A);
	ClientConfig.SaveConfig();
	UpdateHUDColors();
}

/** Custom HUD Supplier half-usable color */
exec function UMSupplierHalfUsableColor(optional byte R = 160, optional byte G = 192, optional byte B = 0, optional byte A = 192)
{
	ClientConfig.HUDSupplierHalfUsableColor = MakeColor(R, G, B, A);
	ClientConfig.SaveConfig();
	UpdateHUDColors();
}

/** Custom HUD Supplier active color */
exec function UMSupplierActiveColor(optional byte R = 192, optional byte G = 192, optional byte B = 192, optional byte A = 192)
{
	ClientConfig.HUDSupplierActiveColor = MakeColor(R, G, B, A);
	ClientConfig.SaveConfig();
	UpdateHUDColors();
}

/** Enable/disable Zed Time extension HUD */
exec function UMZedTimeExtensionHUD(bool bEnable)
{
	ClientConfig.bShowZedTimeExtensionHUD = bEnable;
	ClientConfig.SaveConfig();
}

/** Enable/disable Zed Time desaturation filter */
exec function UMDisableZedTimeDesaturationFilter(bool bDisable)
{
	ClientConfig.bDisableZedTimeDesaturationFilter = bDisable;
	ClientConfig.SaveConfig();
}

/** Enable/disable Steam friends weapons pickup */
exec function UMAllowFriendWeaponsPickup(bool bEnable)
{
	ClientConfig.bAllowFriendWeaponsPickup = bEnable;
	ClientConfig.SaveConfig();
	
	// Notify server that this has changed
	if (ClientConfig.WorldInfo.NetMode == NM_Client)
		ClientConfig.SendAllowFriendPickup();
}

/** Show Unofficial Mod version in console */
exec function UMVersion()
{
	ConsoleMsg("[Unofficial Mod] Version" @ class'UnofficialMod.UnofficialModMut'.default.ModVersion);
}

defaultproperties
{
}