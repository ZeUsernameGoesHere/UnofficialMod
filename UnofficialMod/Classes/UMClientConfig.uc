//================================================
// UMClientConfig
//================================================
// Client-side config settings for Unofficial Mod
// Also contains replicated server-side config settings
//================================================
// (c) 2018 "Insert Name Here"
//================================================
class UMClientConfig extends ReplicationInfo
	config(UnofficialMod)
	dependson(UnofficialModMut);

/** NOTE: All of these settings only matter on clients
	as they are intended to be per-client configs
	In cases where the setting matters on the server, the
	relevant class is responsible for replicating it */

/** Config version, incremented when new settings are
	added so that config can be saved with new defaults */
var globalconfig int INIVersion;

/** Disable laser sight on M14 EBR by default */
var globalconfig bool bM14EBRLaserSightDisabled;

/** Enable manual reload on M203 part of M16/M203 */
var globalconfig bool bM203ManualReload;

/** HUD Health/Armor colors */
var globalconfig color HUDHealthColor;
var globalconfig color HUDRegenHealthColor; // Defaults to white
var globalconfig color HUDArmorColor;

/** Enable manual reload on HM-501 grenade launcher */
var globalconfig bool bHM501ManualReload;

/** Disable Medic weapon charge display
	0 enables display for all
	1 disables display for Field Medic
	2 disables display for all perks */
var globalconfig int DisableHMTechChargeHUD;

/** Options to disable Trader dialog */
struct TraderDialogOptions
{
	/** Disable Trader dialog entirely */
	var bool bAll;
	/** Disable Armor/Ammo/Grenade nags */
	var bool bArmorAmmoGrenade;
	/** Disable death dialogs */
	var bool bDeath;
};

/** Disable Trader dialog in whole or in part */
var globalconfig TraderDialogOptions DisableTraderDialog;

/** DLO Paths for weapon classes for which to auto-set alt-fire
	We have to use this roundabout method because we cannot
	use class<KFWeapon> as a config value directly */
var globalconfig array<string> AltFireWeaponClassPaths;

/** Whether we are notified when someone else kills a large zed */
var globalconfig bool bShowOthersLargeZedKills;

/** HUD Supplier icon colors */
var globalconfig color HUDSupplierUsableColor;
var globalconfig color HUDSupplierHalfUsableColor;
var globalconfig color HUDSupplierActiveColor;

/** Show zed time extension info */
var globalconfig bool bShowZedTimeExtensionHUD;

/** Disable zed time desaturation filter */
var globalconfig bool bDisableZedTimeDesaturationFilter;

/** Allow Steam friends to pick up dropped
	weapons regardless of server settings */
var globalconfig bool bAllowFriendWeaponsPickup;

/** Medic weapon charge HUD position
	So far only 0 (bottom left) and 1 (bottom right) */
var globalconfig byte HMTechChargeHUDPos;

/** Show server settings in chat box */
var globalconfig bool bDisplayServerSettings;

/** Replicated server-side config settings */

/** Disable weapon upgrades */
var bool bDisableWeaponUpgrades;

/** Start without Tier 1 weapons */
var bool bStartWithoutTier1Weapons;

/** KF1-style syringe */
var bool bKF1StyleSyringe;

/** Disable random map objectives */
var bool bDisableRandomMapObjectives;

/** TODO: [DEPRECATED] Perk knife speed boost level */
var byte PerkKnifeSpeedBoostLevel;

/** Additional Trader time for mid-game joiners */
var int MidGameJoinerTraderTime;

/** Default weapon upgrade level */
var int DefaultWeaponUpgradeLevel;

/** Weapon-specific upgrade override count */
var int WeaponUpgradeOverrideCount;

/** Weapon-specific upgrade overrides */
var UnofficialModMut.WeaponUpgradeOverrideInfo WeaponUpgradeOverrides[255];

/** Is Trader time extension available for this wave? */
var bool bCanExtendTraderTime;

/** Maximum Trader time used for this game */
var int MaxTraderTime;

/** Gameplay-affecting weapons */
var UnofficialModMut.GameplayWeaponInfo GameplayWeapons[16];

/** Disable picking up others' weapons */
var bool bDisableOthersWeaponsPickup;

/** Perk knife speed boost during wave */
var repnotify UnofficialModMut.PerkKnifeSpeedBoostInfo PerkKnifeSpeedBoostWave;

/** Perk knife speed boost during Trader time */
var repnotify UnofficialModMut.PerkKnifeSpeedBoostInfo PerkKnifeSpeedBoostTrader;

/** Other variables */

/** Local KFPlayerController */
var KFPlayerController TheKFPC;

/** Special ReplicationInfo */
var UMSpecialReplicationInfo SpecialRepInfo;

/** Last kick vote initiator name held in reserve
	Used to broadcast name if user is kicked for
	attempting and failing too many kick votes */
var string LastKickVoteInitiatorName;

/** Weapons for which to automatically set alt-fire when added to inventory */
var array< class<KFWeapon> > AltFireWeaponClasses;

/** Specifically disallowed weapon classes for AltFireWeaponClasses */
var const array< class<KFWeapon> > DisallowedAltFireClasses;

/** Specifically allowed weapon classes for AltFireWeaponClasses */
var const array< class<KFWeapon> > AllowedAltFireClasses;

/** Current inventory of eligible alt-fire weapons,
	used to check for alt-fire on weapon addition */
var array<KFWeapon> CurrentAltFireInv;

/** Current perk knife speed boost info
	depending on whether we're in Trader time */
var UnofficialModMut.PerkKnifeSpeedBoostInfo CurrentPerkKnifeSpeedBoost;

/** Were we in Trader time last check?
	Used for perk knife speed boost check */
var bool bWasTraderOpen;

/** HUD Helper */
var UMHUDHelper HUDHelper;

/** Did we notify player of server settings? */
var bool bNotifyServerSettings;

/** PRIs of already-checked Steam friends */
var array<PlayerReplicationInfo> SteamFriendPRIs;

/** Zed time extensions */
var repnotify byte ZedTimeExtensions;

/** Remaining Zed time
	NOTE: This is only set on initial zed time
	and extensions to minimize net traffic
	The UMHUDHelper simulates this value from there */
var float ZedTimeRemaining;

replication
{
	if (bNetDirty)
		bDisableWeaponUpgrades,bKF1StyleSyringe,bStartWithoutTier1Weapons,bDisableRandomMapObjectives,
		PerkKnifeSpeedBoostLevel,MidGameJoinerTraderTime,DefaultWeaponUpgradeLevel,WeaponUpgradeOverrideCount,
		WeaponUpgradeOverrides,bCanExtendTraderTime,MaxTraderTime,GameplayWeapons,
		bDisableOthersWeaponsPickup,PerkKnifeSpeedBoostWave,PerkKnifeSpeedBoostTrader,
		ZedTimeExtensions,ZedTimeRemaining,SpecialRepInfo;
}

/** Setup config on the client when spawning */
simulated event PostBeginPlay()
{
	local string AltFireClassPath;
	local class<KFWeapon> KFWC;

	super.PostBeginPlay();
	
	SetupConfig();

	if (Role == ROLE_Authority)
	{
		SpecialRepInfo = Spawn(class'UnofficialMod.UMSpecialReplicationInfo', self);
		SetTimer(0.1, true, nameof(CheckPerkKnifeSpeedBoost));
	}

	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		CheckLocalPC();
		SetTimer(2.0, false, nameof(CheckTraderDialog));
		
		// Setup our alt-fire weapons
		foreach AltFireWeaponClassPaths(AltFireClassPath)
		{
			// Default config has one empty entry
			if (AltFireClassPath == "")
				continue;

			// Check for full class name (defaults to KFGameContent package if none specified)
			if (InStr(AltFireClassPath, ".") == INDEX_NONE)
				AltFireClassPath = "KFGameContent." $ AltFireClassPath;

			KFWC = class<KFWeapon>(DynamicLoadObject(AltFireClassPath, class'Class', true));
			
			if (KFWC == None)
			{
				`log("[Unofficial Mod]" $ AltFireClassPath @ "is not a valid KFWeapon class. Check for typos.");
				continue;
			}

			if (IsEligibleAltFireWeaponClass(KFWC))
				AltFireWeaponClasses.AddItem(KFWC);
			else
				`log("[Unofficial Mod]" $ AltFireClassPath @ "is not eligible for auto-set alt-fire feature.");
		}

		CheckAltFireWeaponTimers();
		SetTimer(1.0, true, nameof(CheckAdminStatus));
	}
}

/** Zed time desaturation filter */
simulated function Tick(float DeltaTime)
{
	local MaterialInstanceConstant WorldMIC;

	super.Tick(DeltaTime);
		
	if (bDisableZedTimeDesaturationFilter && `IsInZedTime(self) && TheKFPC != None && TheKFPC.TargetZEDTimeEffectIntensity > 0.0)
	{
		TheKFPC.TargetZEDTimeEffectIntensity = 0.0;

		// Also make sure we're not above the limit now
		if (TheKFPC.CurrentZEDTimeEffectIntensity > 0.0)
		{
			TheKFPC.CurrentZEDTimeEffectIntensity = 0.0;
			TheKFPC.ZEDTimeEffectInterpTimeRemaining = 0.0;
			if(TheKFPC.GameplayPostProcessEffectMIC != None)
				TheKFPC.GameplayPostProcessEffectMIC.SetScalarParameterValue(TheKFPC.EffectZedTimeParamName, 0.0);

			foreach WorldInfo.ZedTimeMICs(WorldMIC)
				WorldMIC.SetScalarParameterValue(TheKFPC.EffectZedTimeParamName, 0.0);
		}
	}
}

/** Notifies for perk knife speed boost variables */
simulated event ReplicatedEvent(name VarName)
{
	if (VarName == 'PerkKnifeSpeedBoostWave')
	{
		if (bNotifyServerSettings)
		{
			if (PerkKnifeSpeedBoostWave.AdditionalSpeed <= 0.0)
				AddChatMessage("<Unofficial Mod> Perk Knife speed boost during wave has been DISABLED");
			else
			{
				AddChatMessage("<Unofficial Mod> Perk Knife speed boost during wave is now up to" @
					int(PerkKnifeSpeedBoostWave.AdditionalSpeed * 100.0) $ "% (max" @
					int(FMax(PerkKnifeSpeedBoostWave.MaxSpeed * 100.0, 100.0)) $ "%)");
			}
		}
	}
	else if (VarName == 'PerkKnifeSpeedBoostTrader')
	{
		if (bNotifyServerSettings)
		{
			if (PerkKnifeSpeedBoostTrader.AdditionalSpeed <= 0.0)
				AddChatMessage("<Unofficial Mod> Perk Knife speed boost during Trader time has been DISABLED");
			else
			{
				AddChatMessage("<Unofficial Mod> Perk Knife speed boost during Trader time is now up to" @
					int(PerkKnifeSpeedBoostTrader.AdditionalSpeed * 100.0) $ "% (max" @
					int(FMax(PerkKnifeSpeedBoostTrader.MaxSpeed * 100.0, 100.0)) $ "%)");
			}
		}
	}
	else if (VarName == 'ZedTimeExtensions')
	{
		// Update HUD Helper
		if (bShowZedTimeExtensionHUD && ZedTimeExtensions != 255 && HUDHelper != None)
			HUDHelper.ZedTimeRemaining = ZedTimeRemaining;
	}

	super.ReplicatedEvent(VarName);
}

simulated function SetupConfig()
{
	local bool bSaveConfig;

	// Although false is default without a
	// config file, this allows users to reset
	// their configs by setting INIVersion to 0
	if (INIVersion < 1)
	{
		INIVersion = 1;
		bM14EBRLaserSightDisabled = false;
		bM203ManualReload = false;
		bSaveConfig = true;
	}
	
	if (INIVersion < 2)
	{
		INIVersion = 2;
		HUDHealthColor = class'KFGame.KFHUDBase'.default.HealthColor;
		// Defaults to white
		HUDRegenHealthColor = MakeColor(255, 255, 255, 192);
		HUDArmorColor = class'KFGame.KFHUDBase'.default.ArmorColor;
		bSaveConfig = true;
	}
	
	if (INIVersion < 3)
	{
		INIVersion = 3;
		bHM501ManualReload = false;
		DisableHMTechChargeHUD = 0;
		DisableTraderDialog.bAll = false;
		DisableTraderDialog.bArmorAmmoGrenade = false;
		DisableTraderDialog.bDeath = false;
		AltFireWeaponClassPaths.Length = 1;
		AltFireWeaponClassPaths[0] = "";
		bSaveConfig = true;
	}

	if (INIVersion < 4)
	{
		INIVersion = 4;
		bShowOthersLargeZedKills = false;
		HUDSupplierUsableColor = class'KFGame.KFHUDBase'.default.SupplierUsableColor;
		HUDSupplierHalfUsableColor = class'KFGame.KFHUDBase'.default.SupplierHalfUsableColor;
		HUDSupplierActiveColor = class'KFGame.KFHUDBase'.default.SupplierActiveColor;
		bShowZedTimeExtensionHUD = false;
		bDisableZedTimeDesaturationFilter = false;
		bAllowFriendWeaponsPickup = true;
		bSaveConfig = true;
	}
	
	if (INIVersion < 5)
	{
		INIVersion = 5;
		HMTechChargeHUDPos = 0;
		bDisplayServerSettings = true;
		bSaveConfig = true;
	}

	if (bSaveConfig)
		SaveConfig();
}

simulated function CheckLocalPC()
{
	GetLocalPC();
	
	// This shouldn't happen, but just in case...
	if (TheKFPC == None)
	{
		SetTimer(1.0, false, nameof(CheckLocalPC));
		return;
	}

	if (WorldInfo.NetMode == NM_Client)
	{
		SetupPlayerController();
		SendAllowFriendPickup();
		// NOTE: This will always update the list
		// regardless of whether this player allows
		// friends to pick up their weapons as
		// that setting can be changed on the fly
		SetTimer(2.0, true, nameof(CheckSteamFriends));
	}

	// Give this time to get all replicated variables
	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		// Setup the delegate
		if (bDisplayServerSettings)
			AddChatMessage = AddChatMessage_ChatBoxes;
		SetTimer(2.0, false, nameof(NotifyServerSettings));
		SetTimer(2.0, false, nameof(CheckHUD));

		// Add custom Interaction for modifying our settings
		AddUMInteraction(class'UnofficialMod.UMExecInteraction');
		
		// Copy weapon skins from vanilla weapons to our weapons
		class'UnofficialMod.UMTraderItemsHelper'.static.CopyWeaponSkins();
	}
}

/** Gets local PlayerController */
simulated function KFPlayerController GetLocalPC()
{
	if (TheKFPC == None)
		TheKFPC = KFPlayerController(GetALocalPlayerController());
		
	return TheKFPC;
}

/** Since the purchase helper class isn't replicated but this is,
	we set it up here. This maximizes mod compatibility by not
	having to override KFPlayerController */
simulated function SetupPlayerController()
{
	// Replace class
	if (TheKFPC.PurchaseHelperClass == class'KFGame.KFPlayerController'.default.PurchaseHelperClass)
	{
		TheKFPC.PurchaseHelperClass = class'UnofficialMod.KFAutoPurchaseHelper_UM';
		// TODO: Is this ever necessary?
		if (TheKFPC.PurchaseHelper != None)
		{
			TheKFPC.PurchaseHelper = new(TheKFPC) TheKFPC.PurchaseHelperClass;
			TheKFPC.PurchaseHelper.Initialize();
		}
	}
}

/** Update server with Steam friend weapon pickup status */
simulated function SendAllowFriendPickup()
{
	TheKFPC.ConsoleCommand("Mutate UMAllowFriendPickup" @ bAllowFriendWeaponsPickup);
}

/** Adds a chat message */
delegate AddChatMessage(string ChatMessage);

/** Notify clients of server settings */
simulated function NotifyServerSettings()
{
	local string ChatMessage;
	local int DefaultMaxUpgrades, i, EnabledGameplayWeapons, DisabledGameplayWeapons;

	// Check to make sure the chat box is set up
	if (TheKFPC.MyGFxHUD == None || TheKFPC.MyGFxManager == None || TheKFPC.MyGFxManager.PartyWidget == None)
	{
		SetTimer(1.0, false, nameof(NotifyServerSettings));
		return;
	}

	// This isn't visible in solo play
	TheKFPC.MyGFxManager.PartyWidget.PartyChatWidget.SetVisible(true);
		
	// Add our messages
	AddChatMessage("<Unofficial Mod v" $ class'UnofficialMod.UnofficialModMut'.default.ModVersion @ "Settings>");

	DefaultMaxUpgrades = class'UnofficialMod.UnofficialModMut'.default.MaxWeaponUpgradeCount;
	if (bDisableWeaponUpgrades || (-DefaultWeaponUpgradeLevel >= DefaultMaxUpgrades && WeaponUpgradeOverrideCount == 0))
		AddChatMessage("-Weapon upgrades are DISABLED");
	else if (!bDisableWeaponUpgrades && DefaultWeaponUpgradeLevel >= DefaultMaxUpgrades && WeaponUpgradeOverrideCount == 0)
		AddChatMessage("-Weapon upgrades are ENABLED");
	else
	{
		AddChatMessage("-" $ GetWeaponUpgradeString(DefaultWeaponUpgradeLevel) @ "are ENABLED by default");
		if (WeaponUpgradeOverrideCount > 0)
			AddChatMessage("--(" $ WeaponUpgradeOverrideCount @ "overrides: use UMWeaponUpgrades console command for more info)");
	}

	AddChatMessage("-Start" @ (bStartWithoutTier1Weapons ? "WITHOUT" : "WITH") @ "Tier 1 weapons");
	AddChatMessage("-KF1-style syringe is" @ (bKF1StyleSyringe ? "ENABLED" : "DISABLED"));
	AddChatMessage("-Random map objectives are" @ (bDisableRandomMapObjectives ? "DISABLED" : "ENABLED"));

	AddChatMessage("-Perk Knife speed boost:");

	// We don't check for max speed here
	// as players can lose speed from
	// being encumbered and/or wounded
	ChatMessage = "--During waves:";
	if (PerkKnifeSpeedBoostWave.AdditionalSpeed <= 0.0)
		ChatMessage @= "DISABLED";
	else
	{
		ChatMessage @= ("Up to" @ int(PerkKnifeSpeedBoostWave.AdditionalSpeed * 100.0) $ "% boost (" $
			int(FMax(PerkKnifeSpeedBoostWave.MaxSpeed * 100,100.0)) $ "% max)");
	}
		
	AddChatMessage(ChatMessage);
	
	ChatMessage = "--During Trader time:";
	if (PerkKnifeSpeedBoostTrader.AdditionalSpeed <= 0.0)
		ChatMessage @= "DISABLED";
	else
	{
		ChatMessage @= ("Up to" @ int(PerkKnifeSpeedBoostTrader.AdditionalSpeed * 100.0) $ "% boost (" $
			int(FMax(PerkKnifeSpeedBoostTrader.MaxSpeed * 100, 100.0)) $ "% max)");
	}
		
	AddChatMessage(ChatMessage);

	if (MidGameJoinerTraderTime > 0)
		AddChatMessage("-Add up to" @ MidGameJoinerTraderTime @ "seconds to Trader time for mid-game joiners");
	else
		AddChatMessage("-Additional Trader time for mid-game joiners is DISABLED");
		
	EnabledGameplayWeapons = 0;
	DisabledGameplayWeapons = 0;
	for (i = 0;i < ArrayCount(GameplayWeapons);i++)
	{
		if (GameplayWeapons[i].WeaponClass == None)
			continue;
			
		if (GameplayWeapons[i].bEnabled)
			EnabledGameplayWeapons++;
		else
			DisabledGameplayWeapons++;
	}
	
	if (DisabledGameplayWeapons == 0)
		AddChatMessage("-All gameplay-affecting weapons are ENABLED");
	else if (EnabledGameplayWeapons == 0)
		AddChatMessage("-All gameplay-affecting weapons are DISABLED");
	else
		AddChatMessage("-Some gameplay-affecting weapons are ENABLED: use UMGameplayWeapons console command for more info");
		
	AddChatMessage("-Picking up others' dropped weapons is" @ (bDisableOthersWeaponsPickup ? "DISABLED" : "ENABLED"));

	// Check for INT file
	if (Left(Localize("KFWeap_Thrown_C4_UM", "ItemName", "UnofficialMod"), 1) == "?")
	{
		AddChatMessage("-Localization file NOT found. Workaround for Trader items implemented; other localization will not work.");
		AddChatMessage("--Check Steam workshop page for more info.");
	}

	if (!bNotifyServerSettings)
	{
		bNotifyServerSettings = true;
		// After the initial call, we set AddChatMessage
		// for the chat boxes because some future notifies
		// depend on the chat boxes being available
		if (AddChatMessage == None)
			AddChatMessage = AddChatMessage_ChatBoxes;
	}
}

/** Notify client of server settings via console
	Called from console command */
simulated function NotifyServerSettings_Console()
{
	local delegate<AddChatMessage> OrigDelegate;

	OrigDelegate = AddChatMessage;
	AddChatMessage = AddChatMessage_Console;
	NotifyServerSettings();
	AddChatMessage = OrigDelegate;
}

/** Adds a message to the chat boxes (both lobby and in-game) */
simulated function AddChatMessage_ChatBoxes(string ChatMessage)
{
	TheKFPC.MyGFxHUD.HudChatBox.AddChatMessage(ChatMessage, class'KFGame.KFLocalMessage'.default.EventColor);
	TheKFPC.MyGFxManager.PartyWidget.PartyChatWidget.AddChatMessage(ChatMessage, class'KFGame.KFLocalMessage'.default.EventColor);
}

/** Adds a message to the console */
simulated function AddChatMessage_Console(string ChatMessage)
{
	local Console GameConsole;
	
	GameConsole = class'Engine.Engine'.static.GetEngine().GameViewport.ViewportConsole;

	if (GameConsole != None)
		GameConsole.OutputTextLine(ChatMessage);
	else
		// Shouldn't happen
		`warn("[Unofficial Mod]" $ ChatMessage);
}

/** Checks HUD to see if we need to use custom Interaction */
simulated function CheckHUD()
{
	// Make sure we have a HUD first
	if (TheKFPC.myHUD == None)
	{
		SetTimer(1.0, false, nameof(CheckHUD));
		return;
	}

	// TODO: Make this not hard-coded
	// Don't add to Classic Mode, as it implements
	// many Unofficial Mod HUD features
	if (TheKFPC.myHUD.IsA('KFHUDInterface'))
	{
		`log("[Unofficial Mod]Classic Mode is active, skipping HUD additions...");
		return;
	}

	// Add HUD helper
	HUDHelper = Spawn(class'UnofficialMod.UMHUDHelper', self);
	// Add custom Interaction for wave info
	AddUMInteraction(class'UnofficialMod.UMWaveInfoInteraction');

	// If this isn't our HUD, spawn custom Interaction
	if (KFGFxHudWrapper_UM(TheKFPC.myHUD) == None)
	{
		AddUMInteraction(class'UnofficialMod.UMHUDInteraction');
		`log("[Unofficial Mod]Custom HUD overlay Interaction created!");
	}
}

/** Add custom Interaction to the player controller */
simulated function AddUMInteraction(class<UMBaseInteraction> UMIntClass)
{
	local UMBaseInteraction UMInt;

	UMInt = new (TheKFPC) UMIntClass;
	UMInt.OwningKFPC = TheKFPC;
	UMInt.ClientConfig = Self;
	TheKFPC.Interactions.AddItem(UMInt);
	// This isn't called if the Interaction
	// is added to a PlayerController
	UMInt.Initialized();
}

/** Get appropriate string for weapon upgrade level setting */
simulated function string GetWeaponUpgradeString(int UpgradeLevel)
{
	if (UpgradeLevel >= class'UnofficialMod.UnofficialModMut'.default.MaxWeaponUpgradeCount)
		return "ALL weapon upgrades";
	else if (UpgradeLevel == 0 || -UpgradeLevel >= class'UnofficialMod.UnofficialModMut'.default.MaxWeaponUpgradeCount)
		return "NO weapon upgrades";
	else if (UpgradeLevel > 0)
		return "UP TO" @ UpgradeLevel @ "weapon upgrade" $ (UpgradeLevel > 1 ? "s" : "");

	// Assumes UpgradeLevel < 0
	return "ALL BUT" @ -UpgradeLevel @ "weapon upgrade" $ (UpgradeLevel < -1 ? "s" : "");
}

/** Check to see if weapon upgrade is allowed */
simulated function bool IsWeaponUpgradeAllowed(const out KFGFxObject_TraderItems.STraderItem TraderItem)
{
	local int i, MaxUpgradeLevel;
	local byte SingleDualIndex;
	local class<KFWeaponDefinition> FoundWeaponDef;
	local KFGFxObject_TraderItems TraderItems;

	if (bDisableWeaponUpgrades)
		return false;

	if (WeaponUpgradeOverrideCount > 0)
	{
		TraderItems = KFGameReplicationInfo(WorldInfo.GRI).TraderItems;

		for (i = 0;i < WeaponUpgradeOverrideCount;i++)
		{
			// Check for WeaponDef first
			// We use ClassIsChildOf() because
			// some mods (including Unofficial
			// Mod) override base KF2 weapons
			// The Single/DualClassName checks
			// allow us to put only either
			// the single or dual WeaponDef in the
			// config instead of needing both
			if (WeaponUpgradeOverrides[i].WeaponDef == None)
				continue;

			if (ClassIsChildOf(TraderItem.WeaponDef, WeaponUpgradeOverrides[i].WeaponDef))
			{
				MaxUpgradeLevel = WeaponUpgradeOverrides[i].UpgradeLevel;
				FoundWeaponDef = TraderItem.WeaponDef;
				break;
			}
			else if (TraderItem.DualClassName != '')
			{
				if (TraderItems.GetItemIndicesFromArche(SingleDualIndex, TraderItem.DualClassName))
				{
					if (ClassIsChildOf(TraderItems.SaleItems[SingleDualIndex].WeaponDef, WeaponUpgradeOverrides[i].WeaponDef))
					{
						MaxUpgradeLevel = WeaponUpgradeOverrides[i].UpgradeLevel;
						FoundWeaponDef = TraderItems.SaleItems[SingleDualIndex].WeaponDef;
						break;
					}
				}
			}
			else if (TraderItem.SingleClassName != '')
			{
				if (TraderItems.GetItemIndicesFromArche(SingleDualIndex, TraderItem.SingleClassName))
				{
					if (ClassIsChildOf(TraderItems.SaleItems[SingleDualIndex].WeaponDef, WeaponUpgradeOverrides[i].WeaponDef))
					{
						MaxUpgradeLevel = WeaponUpgradeOverrides[i].UpgradeLevel;
						FoundWeaponDef = TraderItems.SaleItems[SingleDualIndex].WeaponDef;
						break;
					}
				}
			}
		}
	}

	// If we didn't find anything, use default
	if (FoundWeaponDef == None)
		MaxUpgradeLevel = DefaultWeaponUpgradeLevel;
	else if (MaxUpgradeLevel >= FoundWeaponDef.default.UpgradePrice.Length)
		return true;
	
	if (MaxUpgradeLevel >= class'UnofficialMod.UnofficialModMut'.default.MaxWeaponUpgradeCount)
		return true;

	// Convert negative value to "all but" upgrade count
	if (MaxUpgradeLevel < 0)
		MaxUpgradeLevel += TraderItem.WeaponDef.default.UpgradePrice.Length;
		
	if (MaxUpgradeLevel <= 0)
		return false;
		
	return (MaxUpgradeLevel > TheKFPC.GetPurchaseHelper().GetItemUpgradeLevelByClassName(TraderItem.ClassName));
}

/** Can we extend Trader time? Conditions:
	-Mid-game (any time after wave 1 is over)
	-Player joins with 0 deaths (i.e. mid-game joiner)
	-Player joins with < 2/3 of Trader time left (arbitrary value) */
simulated function bool CanExtendTraderTimeFor(Pawn Other)
{
	if (Other == None || Other.PlayerReplicationInfo == None)
		return false;

	return (MidGameJoinerTraderTime > 0 && bCanExtendTraderTime &&
			KFGameReplicationInfo(WorldInfo.GRI).WaveNum > 0 && Other.PlayerReplicationInfo.Deaths == 0 &&
			WorldInfo.GRI.RemainingTime <= (float(MaxTraderTime) * 0.6667));
}

/** Allow HMTech charge display? */
simulated function bool AllowHMTechChargeDisplay()
{
	if (DisableHMTechChargeHUD == 0)
		return true;
		
	if (DisableHMTechChargeHUD == 1 && KFPerk_FieldMedic(TheKFPC.GetPerk()) == None)
		return true;
	
	return false;
}

/** Check GRI to replace Trader dialog manager with our own
	Also used to update Trader dialog options using console */
simulated function CheckTraderDialog()
{
	local KFTraderDialogManager OrigKFTDM;
	local KFTraderDialogManager_UM KFTDM;

	if (WorldInfo.GRI == None)
	{
		SetTimer(1.0, false, nameof(CheckTraderDialog));
		return;
	}

	OrigKFTDM = KFGameReplicationInfo(WorldInfo.GRI).TraderDialogManager;

	if (KFTraderDialogManager_UM(OrigKFTDM) == None)
	{
		KFTDM = Spawn(class'UnofficialMod.KFTraderDialogManager_UM');
		KFTDM.TraderVoiceGroupClass = OrigKFTDM.TraderVoiceGroupClass;
		KFTDM.bEnabled = OrigKFTDM.bEnabled;
		KFGameReplicationInfo(WorldInfo.GRI).TraderDialogManager = KFTDM;
	}
	else
		KFTDM = KFTraderDialogManager_UM(OrigKFTDM);

	KFTDM.DialogOptions = DisableTraderDialog;
}

/** Is this weapon class eligible to have alt-fire set on acquire? */
simulated function bool IsEligibleAltFireWeaponClass(class<KFWeapon> KFWC)
{
	local class<KFWeapon> ListKFWC;

	// This shouldn't happen, but better safe than sorry
	if (KFWC == None)
		return false;
	
	// Melee weapons have alt-fire set to parry/block
	if (KFWC.static.IsMeleeWeapon())
		return false;
	
	// Check disallowed weapons
	foreach DisallowedAltFireClasses(ListKFWC)
	{
		if (ClassIsChildOf(KFWC, ListKFWC))
			return false;
	}

	// Check alt-fire mode
	if (KFWC.default.WeaponFireTypes[1] == EWFT_None || KFWC.default.WeaponProjectiles.Length < 2)
		return false;

	// Different fire modes but same projectile
	if (KFWC.default.FiringStatesArray[0] != KFWC.default.FiringStatesArray[1] &&
		KFWC.default.WeaponProjectiles[1] != None &&
		KFWC.default.WeaponProjectiles[0] == KFWC.default.WeaponProjectiles[1])
		return true;
		
	// Check allowed weapons
	foreach AllowedAltFireClasses(ListKFWC)
	{
		if (ClassIsChildOf(KFWC, ListKFWC))
			return true;
	}
	
	return false;
}

/** Check if class is in list of alt-fire weapons */
simulated function bool IsWeaponInAltFireList(class<KFWeapon> KFWC)
{
	local class<KFWeapon> ListKFWC;
	
	foreach AltFireWeaponClasses(ListKFWC)
	{
		if (ClassIsChildOf(KFWC, ListKFWC))
			return true;
	}
	
	return false;
}

/** Check alt-fire timers */
simulated function CheckAltFireWeaponTimers()
{
	if (AltFireWeaponClasses.Length > 0)
	{
		SetTimer(0.1, true, nameof(CheckAltFireWeapons));
		SetTimer(10.0, true, nameof(PurgeAltFireWeapons));
	}
	else
	{
		ClearTimer(nameof(CheckAltFireWeapons));
		ClearTimer(nameof(PurgeAltFireWeapons));
		CurrentAltFireInv.Length = 0;
	}
}

/** Check inventory for weapons that need alt-fire set */
simulated function CheckAltFireWeapons()
{
	local KFWeapon KFW;

	if (TheKFPC == None || TheKFPC.Pawn == None || TheKFPC.Pawn.InvManager == None)
	{
		CurrentAltFireInv.Length = 0;
		return;
	}
	
	foreach TheKFPC.Pawn.InvManager.InventoryActors(class'KFGame.KFWeapon', KFW)
	{
		if (IsEligibleAltFireWeaponClass(KFW.class) && CurrentAltFireInv.Find(KFW) == INDEX_NONE)
		{
			if (IsWeaponInAltFireList(KFW.class))
				SetAltFireFor(KFW);
			CurrentAltFireInv.AddItem(KFW);
		}
	}
}

/** Purge alt-fire weapon list of weapons no longer owned */
simulated function PurgeAltFireWeapons()
{
	local KFWeapon KFW;
	local int i;
	local bool bFound;

	if (CurrentAltFireInv.Length == 0)
		return;

	if (TheKFPC == None || TheKFPC.Pawn == None || TheKFPC.Pawn.InvManager == None)
		return;

	for (i = 0;i < CurrentAltFireInv.Length;i++)
	{
		bFound = false;

		if (CurrentAltFireInv[i] != None)
		{
			foreach TheKFPC.Pawn.InvManager.InventoryActors(class'KFGame.KFWeapon', KFW)
			{
				if (KFW == CurrentAltFireInv[i])
				{
					bFound = true;
					break;
				}
			}
		}
		
		if (!bFound)
		{
			CurrentAltFireInv.Remove(i, 1);
			i--;
		}
	}
}

/** Set alt-fire for this weapon */
simulated function SetAltFireFor(KFWeapon KFW)
{
	// Specific check for UM's C4 because
	// it does specific alt-fire code
	// (including replicating bUseAltFireMode
	// to the server if necessary)
	if (KFW.class == class'UnofficialMod.KFWeap_Thrown_C4_UM' && !KFW.bUseAltFireMode)
	{
		KFW.AltFireMode();
		return;
	}
	
	// We set this to the opposite of the default
	// because some weapons (e.g. FNFal) have
	// bUseAltFireMode enabled by default
	KFW.bUseAltFireMode = !KFW.default.bUseAltFireMode;
}

/** Check admin status for creating UMExecInteraction */
simulated function CheckAdminStatus()
{
	if (WorldInfo.NetMode == NM_Standalone || (TheKFPC != None && TheKFPC.PlayerReplicationInfo.bAdmin))
	{
		AddUMInteraction(class'UnofficialMod.UMAdminExecInteraction');
		ClearTimer(nameof(CheckAdminStatus));
	}
}

/** Check perk knife speed boost amount */
function CheckPerkKnifeSpeedBoost()
{
	local KFGameReplicationInfo KFGRI;
	local bool bIsTraderOpen;
	
	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	
	if (KFGRI == None)
		return;
		
	bIsTraderOpen = KFGRI.bTraderIsOpen;

	if (bIsTraderOpen)
	{
		CurrentPerkKnifeSpeedBoost.AdditionalSpeed = FMax(PerkKnifeSpeedBoostTrader.AdditionalSpeed, 0.0);
		CurrentPerkKnifeSpeedBoost.MaxSpeed = FMax(PerkKnifeSpeedBoostTrader.MaxSpeed, 1.0);
	}
	else
	{
		CurrentPerkKnifeSpeedBoost.AdditionalSpeed = FMax(PerkKnifeSpeedBoostWave.AdditionalSpeed, 0.0);
		CurrentPerkKnifeSpeedBoost.MaxSpeed = FMax(PerkKnifeSpeedBoostWave.MaxSpeed, 1.0);
	}
	
	// Force speed update in case someone
	// has their knife out when transitioning
	// between Trader and wave
	if (bIsTraderOpen != bWasTraderOpen)
		SpecialRepInfo.ForcePawnSpeedUpdate();
		
	bWasTraderOpen = bIsTraderOpen;
}

/** Check and update Steam friends for weapon pickups
	NOTES:
	-We don't check if Steam friends are allowed to
	pick up dropped weapons as the various interactions
	between UMClientConfig and UnofficialModMut handle this
	-This only gets called on WorldInfo.NetMode == NM_Client */
simulated function CheckSteamFriends()
{
	local PlayerReplicationInfo PRI;
	local bool bIsFriend;
	local int Index;

	// Shouldn't happen, but check anyways
	if (TheKFPC == None || LocalPlayer(TheKFPC.Player) == None || TheKFPC.OnlineSub == None)
		return;

	foreach WorldInfo.GRI.PRIArray(PRI)
	{
		if (PRI == TheKFPC.PlayerReplicationInfo)
			continue;
		
		bIsFriend = TheKFPC.OnlineSub.IsFriend(LocalPlayer(TheKFPC.Player).ControllerId, PRI.UniqueId);
		Index = SteamFriendPRIs.Find(PRI);

		if (Index == INDEX_NONE && bIsFriend)
		{
			// Player added friend
			TheKFPC.ConsoleCommand("Mutate UMAddSteamFriend" @ class'Engine.OnlineSubsystem'.static.UniqueNetIdToString(PRI.UniqueId));
			SteamFriendPRIs.AddItem(PRI);
		}
		else if (Index != INDEX_NONE && !bIsFriend)
		{
			// Player removed friend
			TheKFPC.ConsoleCommand("Mutate UMRemoveSteamFriend" @ class'Engine.OnlineSubsystem'.static.UniqueNetIdToString(PRI.UniqueId));
			SteamFriendPRIs.Remove(Index, 1);
		}
	}
}

/** Get a base STraderItem, used for certain
	perk-related bug fixes for specific weapons */
static simulated function GetCustomSTraderItemFor(class<KFWeaponDefinition> KFWeapDef, out KFGFxObject_TraderItems.STraderItem TraderItem)
{
	local KFGFxObject_TraderItems DefaultTI;
	local array<KFGFxObject_TraderItems.STraderItem> TempTraderItem;
	local int Index;

	DefaultTI = GetDefaultTraderItems();

	// Find the original item
	Index = DefaultTI.SaleItems.Find('WeaponDef', KFWeapDef);
	if (Index != INDEX_NONE)
	{
		TraderItem = DefaultTI.SaleItems[Index];
		return;
	}

	`log("[Unofficial Mod]Didn't find TraderItem for" @ KFWeapDef $ "; doing manual setup!");
	// If we didn't find it, set it up manually without the ItemID
	TempTraderItem.Length = 1;
	TempTraderItem[0].WeaponDef = KFWeapDef;
	DefaultTI.SetItemsInfo(TempTraderItem);
	TraderItem = TempTraderItem[0];
}

/** Get weapon localization (workaround for INT file potentially not being there) */
static simulated function string GetWeaponLocalization(string KeyName, class<KFWeaponDefinition> UMWeapDef, class<KFWeaponDefinition> KFWeapDef)
{
	local array<string> StringParts;
	local string WeaponString;

	ParseStringIntoArray(UMWeapDef.default.WeaponClassPath, StringParts, ".", true);
	WeaponString = Localize(StringParts[1], KeyName, StringParts[0]);
	
	if (Left(WeaponString, 1) == "?")
	{
		WeaponString = KFWeapDef.static.GetItemLocalization(KeyName);

		// Append "[UM]" to weapon name
		// so user knows it's our weapon
		if (KeyName ~= "ItemName")
			WeaponString @= "[UM]";
	}
	
	return WeaponString;
}

/** Get default TraderItems */
static simulated function KFGFxObject_TraderItems GetDefaultTraderItems()
{
	return  (KFGFxObject_TraderItems(DynamicLoadObject(class'KFGame.KFGameReplicationInfo'.default.TraderItemsPath, class'KFGame.KFGFxObject_TraderItems')));
}

/** Get UMClientConfig instance */
static simulated function UMClientConfig GetInstance()
{
	local WorldInfo WI;
	local UMClientConfig UMCC;
	
	WI = class'Engine.WorldInfo'.static.GetWorldInfo();
	
	foreach WI.DynamicActors(class'UnofficialMod.UMClientConfig', UMCC)
	{
		return UMCC;
	}
	
	`log("[Unofficial Mod]Could not find UMClientConfig!?");
	return None;
}

defaultproperties
{
	// Disallowed alt-fire weapon classes
	// Double-barrel Boomstick
	DisallowedAltFireClasses(0)=class'KFGameContent.KFWeap_Shotgun_DoubleBarrel'
	// Doomstick
	DisallowedAltFireClasses(1)=class'KFGameContent.KFWeap_Shotgun_ElephantGun'
	
	// Allowed alt-fire weapon classes
	// Railgun
	AllowedAltFireClasses(0)=class'KFGameContent.KFWeap_Rifle_RailGun'
	// Unofficial Mod's C4
	AllowedAltFireClasses(1)=class'UnofficialMod.KFWeap_Thrown_C4_UM'
	
	// Set to 255 to ensure that initial Zed time trigger shows HUD
	ZedTimeExtensions=255
}