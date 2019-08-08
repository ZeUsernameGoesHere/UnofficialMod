//================================================
// UnofficialModMut
//================================================
// Mutator for Unofficial Mod
//================================================
// (c) 2018 "Insert Name Here"
//================================================
class UnofficialModMut extends KFMutator
	config(UnofficialMod);

/** Information for starting weapon replacements */
struct StartingWeaponRepl
{
	/** Old weapon name */
	var name OldWeaponName;
	/** New weapon class */
	var class<KFWeapon> NewWeaponClass;
};

/** Starting weapon replacements */
var const array<StartingWeaponRepl> StartWeaponReplList;

/** Information for pickup weapon replacements */
struct PickupWeaponRepl
{
	/** Old weapon class */
	var class<KFWeapon> OldWeaponClass;
	/** New weapon class */
	var class<KFWeapon> NewWeaponClass;
};

/** Pickup weapon replacements */
var const array<PickupWeaponRepl> PickupWeaponReplList;

/** Our Trader Items archetype */
var const KFGFxObject_TraderItems UMTraderItems, UMTraderItemsBeta;

/** Config version, incremented when new settings are
	added so that config can be saved with new defaults*/
var config int INIVersion;

/** Disable weapon upgrades */
var config bool bDisableWeaponUpgrades;

/** Start without Tier 1 weapons */
var config bool bStartWithoutTier1Weapons;

/** KF1-style syringe (50% ammo use for healing
	teammates, 15sec recharge regardless of firemode) */
var config bool bKF1StyleSyringe;

/** Disable random map objectives (e.g. Stand Your Ground) */
var config bool bDisableRandomMapObjectives;

/** Max failed kick vote attempts ( <= 0 disables this ) */
var config int MaxFailedKickVoteAttempts;

/** Kick player for attempting and failing too many kick votes
	(if false, it just prevents them from attempting any more) */
var config bool bKickFailedVoteInitiator;

/** TODO: [DEPRECATED] Give speed boost when perk knife is equipped
	0 disables this
	1 hard-caps the speed increase (i.e. only for slower perks)
	2 enables this for all perks */
var config byte PerkKnifeSpeedBoostLevel;

/** Additional Trader time given once per
	wave for players who join mid-game
	NOTE: time added will not make Trader time
	exceed map/difficulty default Trader time*/
var config int MidGameJoinerTraderTime;

/** For the two below config settings:
	0 disables weapon upgrades
	>0 enables that many upgrades (i.e. 2 enables 2 upgrades)
	<0 enables all upgrades EXCEPT for that many (i.e. -1 prevents upgrading to Tier 5)
	NOTE: These settings are ignored if bDisableWeaponUpgrades==true */
/** Default maximum number of weapon upgrades */
var config int DefaultWeaponUpgradeLevel;

/** Weapon upgrade override for specific weapons */
struct WeaponUpgradeOverrideInfo
{
	/** The WeaponDef
		NOTE: we only need either the single
		or dual for dual weapons */
	var class<KFWeaponDefinition> WeaponDef;
	/** The upgrade level allowed */
	var int UpgradeLevel;
};

/** List of weapon-specific upgrade overrides */
var config array<WeaponUpgradeOverrideInfo> WeaponUpgradeOverrides;

/** Gameplay-affecting weapons */
struct GameplayWeaponInfo
{
	/** The weapon */
	var class<KFWeapon> WeaponClass;
	/** Is weapon enabled? */
	var bool bEnabled;
};

/** List of gameplay-affecting weapons */
var config array<GameplayWeaponInfo> GameplayWeapons;

/** Disable picking up others' weapons */
var config bool bDisableOthersWeaponsPickup;

/** Perk knife speed boost */
struct PerkKnifeSpeedBoostInfo
{
	/** Additional speed multiplier */
	var float AdditionalSpeed;
	/** Maximum speed multiplier */
	var float MaxSpeed;
};

/** Perk knife speed boost during wave */
var config PerkKnifeSpeedBoostInfo PerkKnifeSpeedBoostWave;

/** Perk knife speed boost during Trader time */
var config PerkKnifeSpeedBoostInfo PerkKnifeSpeedBoostTrader;

/** Information for PRIs who have had a Tier 1 weapon
	removed from them on their first life so we can
	give them the sell dosh for the weapon */
struct Tier1RemovedPRI
{
	/** The PRI */
	var KFPlayerReplicationInfo KFPRI;
	/** The sell price of the weapon */
	var int SellPrice;
};

/** List of PRIs with removed Tier 1 weapons */
var array<Tier1RemovedPRI> Tier1RemovedPRIList;

/** Trader helper */
var UMTraderItemsHelper TraderHelper;

/** Custom UMTraderItemsHelper info */
struct CustomTraderHelperInfo
{
	/** Class name of GameInfo/Mutator */
	var name ClassName;
	/** Is this a GameInfo? False means that this is a Mutator */
	var bool bIsGameInfo;
	/** Custom UMTraderItemsHelper class
		Leave as None for default UMTraderItemsHelper */
	var class<UMTraderItemsHelper> TraderHelperClass;
	
	structdefaultproperties
	{
		TraderHelperClass=class'UnofficialMod.UMTraderItemsHelper'
	}
};

/** Compatible GameInfos/Mutators for Trader helper */
var const array<CustomTraderHelperInfo> CustomTraderHelperList;

/** Tier 1 weapon classes, used to remove Tier 1
	weapons if config option is set */
var const array< class<KFWeapon> > Tier1Weapons;

/** Client config */
var UMClientConfig ClientConfig;

/** Dropped pickup tracker */
var UMDroppedPickupTracker PickupTracker;

/** Steam friend info for dropped weapon pickups
	NOTE: We manually keep track of this
	as there doesn't seem to be a way to
	check friend status server-side */
struct FriendPRIInfo
{
	/** PlayerReplicationInfo for this player */
	var PlayerReplicationInfo PRI;
	/** Whether this player allows Steam friends to pickup weapons */
	var bool bAllowFriendPickup;
	/** List of Steam friend PRIs */
	var array<PlayerReplicationInfo> FriendPRIs;
};

/** List of Steam friend infos */
var array<FriendPRIInfo> FriendPRIInfoList;

/** Beta version check (used for things
	like Trader list for new beta weapons)
	NOTE: This is set to a very high number
	when not in a beta */
var const int BetaCheckVersion;

/** Maximum weapon upgrades as of the most current UM version */
var const int MaxWeaponUpgradeCount;

/** Mod version */
var const string ModVersion;

/** Debugging */
var bool bUMDebug;

/** Cached value for IsInBeta() */
var bool bIsInBeta;

/** Was Trader open last check?
	Used for Bloat mine bug workaround */
var bool bWasTraderOpen;

/** Special check for Zedternal compatibility */
event PreBeginPlay()
{
	super.PreBeginPlay();
	
	bUMDebug = false;

	if (bDeleteMe)
		return;

	// TODO: Make this not hard-coded
	// If Zedternal is loaded, we replace its
	// default Trader items with our own
	// This is a workaround for the fact that we replace
	// vanilla weapons instead of adding new ones
	// If we modify the trader list after the game starts,
	// Zedternal weapon upgrades can be purchased but won't work
	if (WorldInfo.Game.IsA('WMGameInfo_Endless'))
	{
		`log("[Unofficial Mod]Zedternal found, replacing weapons in Trader list...");
		WMGameInfo_Endless(WorldInfo.Game).DefaultTraderItems = class'UnofficialMod.UMTraderItemsHelper'.static.GetZedternalTraderItems(GetDisabledUMWeapons()); //GetTraderItems();
	}
}

event PostBeginPlay()
{
	super.PostBeginPlay();

	if (bDeleteMe)
		return;
		
	bIsInBeta = IsInBeta();

	// InitMutator() never gets called if we're
	// added to ServerActors, so set MyKFGI manually
	MyKFGI = KFGameInfo(WorldInfo.Game);

	// TODO: Make Zedternal check not hard-coded
	// Check for Trader items
	// WorldInfo.GRI does not exist yet, so wait
	// We ignore this if it's Zedternal (handled in PreBeginPlay() above)
	if (!WorldInfo.Game.IsA('WMGameInfo_Endless'))
		SetTimer(5.0, false, nameof(CheckTraderItems));
	
	// Spawn our client config
	ClientConfig = Spawn(class'UnofficialMod.UMClientConfig');

	SetupConfig();

	// Disable random map objectives
	// Wait a bit to ensure that KFMapInfo is loaded properly
	if (bDisableRandomMapObjectives)
		SetTimer(5.0, false, nameof(CheckMapInfo));
		
	// Check for bots every now and then (for HUD testing)
	if (bUMDebug)
		SetTimer(10.0, true, nameof(CheckBots));

	// NOTE: BetaCheckVersion is set to 1082 (next version)
	// early as invisible Bloat mine bug should be fixed then
	// Set up timer for Bloat mine check if on server
	if (WorldInfo.NetMode == NM_DedicatedServer && !bIsInBeta)
		SetTimer(1.0, true, nameof(CheckBloatMines));

	// Add ourselves to mutator list in case
	// we were added to server actors
	if (WorldInfo.Game.BaseMutator == None)
		WorldInfo.Game.BaseMutator = Self;
	else
		WorldInfo.Game.BaseMutator.AddMutator(Self);

	// Override the UI Manager
	// We only do this if it's the default
	// as some other mods may change this as well
	if (MyKFGI.KFGFxManagerClass == class'KFGameContent.KFGameInfo_VersusSurvival'.default.KFGFxManagerClass)
		MyKFGI.KFGFxManagerClass = class'UnofficialMod.KFGFxMoviePlayer_Manager_Versus_UM';
	else if (MyKFGI.KFGFxManagerClass == class'KFGame.KFGameInfo'.default.KFGFxManagerClass)
		MyKFGI.KFGFxManagerClass = class'UnofficialMod.KFGFxMoviePlayer_Manager_UM';
	else
		`log("[Unofficial Mod]Custom KFGFxManagerClass found, skipping replacement...");
		
	// Override the HUD
	// We only do this if it's the default
	// as some other mods may change this as well
	if (MyKFGI.HudType == class'KFGame.KFGameInfo'.default.HudType)
		MyKFGI.HudType = class'UnofficialMod.KFGFxHudWrapper_UM';
	else
		`log("[Unofficial Mod]Custom HudType found, UMClientConfig will set up custom Interaction overlay!");
}

/** Check for zed time */
event Tick(float DeltaTime)
{
	super.Tick(DeltaTime);
	
	if (`IsInZedTime(Self))
	{
		// We only update this on Zed time start or extension
		// The client-side code handles simulating the HUD stuff
		if (MyKFGI.ZedTimeExtensionsUsed != ClientConfig.ZedTimeExtensions)
		{
			ClientConfig.ZedTimeExtensions = MyKFGI.ZedTimeExtensionsUsed;
			ClientConfig.ZedTimeRemaining = MyKFGI.ZedTimeRemaining;
			if (WorldInfo.NetMode == NM_DedicatedServer)
				ClientConfig.bForceNetUpdate = true;
			else if (ClientConfig.HUDHelper != None)
				ClientConfig.HUDHelper.ZedTimeRemaining = MyKFGI.ZedTimeRemaining;
		}
	}
	else
	{
		// 255 indicates that Zed time is over
		ClientConfig.ZedTimeExtensions = 255;
		ClientConfig.ZedTimeRemaining = 0.0;
	}
}

function AddMutator(Mutator M)
{
	// Checks for mutator added via PostBeginPlay()
	// interfering with mutator added via command line
	if (M == Self)
		return;
	   
	if (M.class == class)
		M.Destroy();
	else
		super.AddMutator(M);
}

/** Replace player's purchase helper and weapon's dropped pickup with our custom classes */
function bool CheckReplacement(Actor Other)
{
	local KFPlayerController KFPC;
	local KFWeapon KFW;
	local KFGameReplicationInfo KFGRI;
	local KFDroppedPickup_UM KFDP;

	KFPC = KFPlayerController(Other);
	
	if (KFPC != None && KFPC.PurchaseHelperClass == class'KFGame.KFPlayerController'.default.PurchaseHelperClass)
		KFPC.PurchaseHelperClass = class'UnofficialMod.KFAutoPurchaseHelper_UM';
		
	KFW = KFWeapon(Other);
	
	// We only replace if this is the default because
	// carryable objectives use their own pickup class
	if (KFW != None && KFW.DroppedPickupClass == class'KFGame.KFDroppedPickup')
		KFW.DroppedPickupClass = class'UnofficialMod.KFDroppedPickup_UM';

	KFDP = KFDroppedPickup_UM(Other);
	
	if (KFDP != None)
	{
		if (PickupTracker == None)
			PickupTracker = Spawn(class'UnofficialMod.UMDroppedPickupTracker', Self);

		KFDP.PickupTracker = PickupTracker;
	}

	KFGRI = KFGameReplicationInfo(Other);

	if (KFGRI != None)
		KFGRI.VoteCollectorClass = class'UnofficialMod.KFVoteCollector_UM';

	return true;
}

/** Replace/remove starter weapons */
function ModifyPlayer(Pawn Other)
{
	local StartingWeaponRepl SWR;
	local KFInventoryManager KFIM;
	local class<KFWeapon> KFWClass;
	local KFWeapon KFW;
	local KFPlayerReplicationInfo KFPRI;
	local KFGFxObject_TraderItems.STraderItem TraderItem;
	local KFGFxObject_TraderItems TraderItems;
	local int i;
	local Tier1RemovedPRI T1RPRI;

	// Modify Trader list on first spawn
	// This gives more than enough time for
	// TIM to send everything to each client
	if (TraderHelper != None)
		TraderHelper.CheckTraderList();

	// Replace Tier 1 weapons as necessary
	// NOTE: We replace these even if Tier 1
	// weapons are disabled because the Trader
	// list check used to give first spawn dosh
	// depends on the exact class name
	foreach StartWeaponReplList(SWR)
	{
		ReplaceWeaponInv(Other, SWR.OldWeaponName, SWR.NewWeaponClass, true);
	}

	// KF1-style syringe
	if (ClientConfig.bKF1StyleSyringe)
		ReplaceWeaponInv(Other, 'KFWeap_Healer_Syringe', class'UnofficialMod.KFWeap_Healer_Syringe_UM');

	// Modify 9mm upgrade level
	KFIM = KFInventoryManager(Other.InvManager);

	if (KFIM != None && Other.PlayerReplicationInfo.Deaths > 0)
	{
		KFW = Get9MMPistol(KFIM);
		if (KFW != None)
			KFW.SetWeaponUpgradeLevel(ClientConfig.SpecialRepInfo.Get9mmUpgradeLevel(Other.Controller));
	}

	// Remove Tier 1 weapons
	if (ClientConfig.bStartWithoutTier1Weapons)
	{
		if (KFIM != None)
		{
			foreach Tier1Weapons(KFWClass)
			{
				// TODO?: Make this not matter/use heuristics to
				// get Tier 1 instead of using a hardcoded list
				// We use FindInventoryType() instead of GetWeaponFromClass()
				// as this allows subclasses, in case we replace Tier 1 weapons
				KFW = KFWeapon(KFIM.FindInventoryType(KFWClass, true));
				if (KFW != None)
					break;
			}

			if (KFW != None)
			{
				KFPRI = KFPlayerReplicationInfo(Other.PlayerReplicationInfo);

				// Give sell price for Tier 1 on first spawn
				if (KFPRI != None && KFPRI.Deaths == 0)
				{
					TraderItems = MyKFGI.MyKFGRI.TraderItems;
					for (i = 0;i < TraderItems.SaleItems.Length;i++)
					{
						if (KFW.class.name == TraderItems.SaleItems[i].ClassName)
						{
							// We have to delay this because KFGameInfo_Survival.RestartPlayer()
							// calls ModifyPlayer() before it sets starting dosh
							T1RPRI.KFPRI = KFPRI;
							TraderItem = TraderItems.SaleItems[i];
							T1RPRI.SellPrice = KFIM.GetAdjustedSellPriceFor(TraderItem);
							Tier1RemovedPRIList.AddItem(T1RPRI);

							if (!IsTimerActive(nameof(GiveTier1Dosh)))
								SetTimer(2.0, false, nameof(GiveTier1Dosh));
							break;
						}
					}
				}

				// Now that we have the relevant info, we can remove the weapon
				KFIM.RemoveFromInventory(KFW);

				// Increase 9mm pistol ammo to beyond maximum
				// NOTE: we only do this on early waves (either
				// started match or respawned after wave 1 is over)
				// NOTE: changing perk/perk skills or dropping/picking up
				// a 9mm pistol will reset this to its normal maximum
				if (MyKFGI.MyKFGRI.WaveNum < 2)
				{
					KFW = Get9MMPistol(KFIM);
					if (KFW != None)
					{
						// TODO: make this not hard-coded 120 (in case this changes)
						KFW.SpareAmmoCount[0] = 120 - KFW.MagazineCapacity[0];
						// Set capacity to 120 max
						KFW.SpareAmmoCapacity[0] = 120 - KFW.MagazineCapacity[0];
						if (WorldInfo.NetMode != NM_Standalone)
							KFW.ClientForceAmmoUpdate(KFW.AmmoCount[0], KFW.SpareAmmoCount[0]);
					}
					else
						`log("[Unofficial Mod]ModifyPlayer() - couldn't find 9mm Pistol!");
				}
			}
			else
				`log("[Unofficial Mod]ModifyPlayer() - couldn't find Tier 1 in player's inventory!");
		}
	}
	
	// Extend Trader time for mid-game joiners
	if (ClientConfig.CanExtendTraderTimeFor(Other))
		ExtendTraderTime();

	super.ModifyPlayer(Other);
}

/** Put logged-in player in special ReplicationInfo */
function NotifyLogin(Controller NewPlayer)
{
	ClientConfig.SpecialRepInfo.NotifyLogin(NewPlayer);

	super.NotifyLogin(NewPlayer);
}

/** Remove logged-out player from special ReplicationInfo */
function NotifyLogout(Controller Exiting)
{
	ClientConfig.SpecialRepInfo.NotifyLogout(Exiting);

	super.NotifyLogout(Exiting);
}

/** Reset Trader time extension if needed
	This call happens at the beginning of a wave
	and so is the best time to do this */
function ModifyNextTraderIndex(out byte NextTraderIndex)
{
	local KFPawn_Human KFPH;
	local KFWeapon KFW;

	ClientConfig.bCanExtendTraderTime = true;
	
	// Reset max pistol ammo at beginning of wave 3
	// if Start without Tier 1 weapons is enabled
	if (ClientConfig.bStartWithoutTier1Weapons && MyKFGI.MyKFGRI.WaveNum == 3)
	{
		foreach WorldInfo.AllPawns(class'KFGame.KFPawn_Human', KFPH)
		{
			KFW = Get9mmPistol(KFInventoryManager(KFPH.InvManager));
			if (KFW != None)
				KFW.ReInitializeAmmoCounts(KFW.GetPerk());
		}
	}

	super.ModifyNextTraderIndex(NextTraderIndex);
}

/** Custom functions for debugging purposes
	Also used for solo/server exec commands */
function Mutate(string MutateString, PlayerController Sender)
{
	local KFPawn_Human KFPH;
	local KFInventoryManager KFIM;
	local KFWeapon KFW;
	local KFPlayerReplicationInfo KFPRI;
	local array<string> StringParts;
	local int IntSetting, FoundIndex;
	local class<KFWeaponDefinition> WeaponDef;
	local class<KFWeapon> KFWClass;
	local UniqueNetId UniqueID;
	local PlayerReplicationInfo PRI;

	// Only if cheats are enabled
	if (Sender.CheatManager != None)
	{
		if (MutateString ~= "UMArmor")
		{
			// Set armor on bots to max
			// Used to test custom armor color
			foreach WorldInfo.AllPawns(class'KFGame.KFPawn_Human', KFPH)
			{
				if (KFAIController(KFPH.Controller) != None)
					KFPH.GiveMaxArmor();
			}
		}
		else if (MutateString ~= "UM9MMFakeDeath")
		{
			// Fake death for Sender
			// Used to test "Lose one
			// 9mm upgrade on death" feature
			ClientConfig.SpecialRepInfo.Set9mmUpgradeLevelOnDeath(Sender);
			KFIM = KFInventoryManager(Sender.Pawn.InvManager);
			if (KFIM != None)
			{
				KFW = Get9MMPistol(KFIM);
				if (KFW != None)
					KFW.SetWeaponUpgradeLevel(ClientConfig.SpecialRepInfo.Get9mmUpgradeLevel(Sender));
			}
		}
		else if (MutateString ~= "UMExtendTrader")
		{
			// Test Trader time extension
			ExtendTraderTime();
		}
		else if (MutateString ~= "UMPerkKnife")
		{
			// Toggle Perk knife move speed option
			/*if (ClientConfig.PerkKnifeSpeedBoostLevel == 1)
				ClientConfig.PerkKnifeSpeedBoostLevel = 2;
			else
				ClientConfig.PerkKnifeSpeedBoostLevel = 1;

			foreach WorldInfo.AllPawns(class'KFGame.KFPawn_Human', KFPH)
			{
				KFPH.UpdateGroundSpeed();
			}
			
			ClientConfig.SpecialRepInfo.ForcePawnSpeedUpdate();*/
		}
		else if (MutateString ~= "UMMedicBat")
		{
			// Remove dart ammo from Hemoclobber
			// Used to test HUD
			KFW = KFWeapon(Sender.Pawn.InvManager.FindInventoryType(class'KFGameContent.KFWeap_Blunt_MedicBat'));
			if (KFW != None)
				KFW.AmmoCount[1] = 0;
		}
		else if (MutateString ~= "UMLargeZed")
		{
			// Send message to test others' large zed kill ticker
			Sender.ReceiveLocalizedMessage(class'UnofficialMod.UMLocalMessage', UMLMT_OtherPlayerKilledLargeZed,
				Sender.PlayerReplicationInfo, , class'KFGameContent.KFPawn_ZedScrake');
		}
		else if (MutateString ~= "UMSupplierHUD")
		{
			// Change Supplier mode for bots
			// Used to test Supplier colors
			foreach WorldInfo.AllPawns(class'KFGame.KFPawn_Human', KFPH)
			{
				if (KFAIController(KFPH.Controller) == None)
					continue;
					
				KFPRI = KFPlayerReplicationInfo(KFPH.PlayerReplicationInfo);
				
				if (KFPRI.CurrentPerkClass != class'KFGame.KFPerk_Support')
				{
					KFPRI.CurrentPerkClass = class'KFGame.KFPerk_Support';
					KFPRI.NetPerkIndex = 2;
					KFPRI.PerkSupplyLevel = 2;
					KFPRI.bPerkPrimarySupplyUsed = false;
					KFPRI.bPerkSecondarySupplyUsed = false;
				}
				else
				{
					if (!KFPRI.bPerkPrimarySupplyUsed && !KFPRI.bPerkSecondarySupplyUsed)
						KFPRI.bPerkPrimarySupplyUsed = true;
					else if (!KFPRI.bPerkSecondarySupplyUsed)
						KFPRI.bPerkSecondarySupplyUsed = true;
					else
					{
						KFPRI.bPerkPrimarySupplyUsed = false;
						KFPRI.bPerkSecondarySupplyUsed = false;
					}
				}
			}
		}
	}
	
	if (WorldInfo.NetMode == NM_Standalone || Sender.PlayerReplicationInfo.bAdmin)
	{
		// Custom Mutate commands from UMAdminExecInteraction
		// Only for solo players and server admins
		StringParts = SplitString(MutateString, " ", true);

		if (StringParts[0] ~= "UMDisableWeaponUpgrades")
		{
			bDisableWeaponUpgrades = bool(StringParts[1]);
			SaveConfig();
			BroadcastSystemMessage(UMSMT_WeaponUpgrades, int(!bool(StringParts[1])));
		}
		else if (StringParts[0] ~= "UMStartWithoutTier1")
		{
			bStartWithoutTier1Weapons = bool(StringParts[1]);
			SaveConfig();
			BroadcastSystemMessage(UMSMT_Tier1Weapons, int(bool(StringParts[1])));
		}
		else if (StringParts[0] ~= "UMKF1StyleSyringe")
		{
			bKF1StyleSyringe = bool(StringParts[1]);
			SaveConfig();
			BroadcastSystemMessage(UMSMT_KF1Syringe, int(bool(StringParts[1])));
		}
		else if (StringParts[0] ~= "UMDisableRandomMapObj")
		{
			bDisableRandomMapObjectives = bool(StringParts[1]);
			SaveConfig();
			BroadcastSystemMessage(UMSMT_RandomMapObj, int(!bool(StringParts[1])));
		}
		else if (StringParts[0] ~= "UMMaxFailedKickVoteAttempts")
		{
			MaxFailedKickVoteAttempts = int(StringParts[1]);
			SaveConfig();
			
			// Put this into effect immediately
			SetupVoteCollector();
			// We only broadcast this message to admin
			// This is intentional as it keeps potential
			// vote-kick abusers in the dark with regards
			// to the server settings
			BroadcastSystemMessage(UMSMT_FailedKickVotes, int(StringParts[1]),, Sender);
		}
		else if (StringParts[0] ~= "UMKickFailedVoteInitiator")
		{
			bKickFailedVoteInitiator = bool(StringParts[1]);
			SaveConfig();

			// Put this into effect immediately
			SetupVoteCollector();
			// We only broadcast this message to admin
			// This is intentional as it keeps potential
			// vote-kick abusers in the dark with regards
			// to the server settings
			BroadcastSystemMessage(UMSMT_KickFailedVoteInit, int(bool(StringParts[1])),, Sender);
		}
		/*else if (StringParts[0] ~= "UMPerkKnifeSpeedBoostLevel")
		{
			// Enforce proper values
			IntSetting = int(StringParts[1]);
			if (IntSetting < 0 || IntSetting > 2)
				IntSetting = 0;
				
			PerkKnifeSpeedBoostLevel = byte(IntSetting);
			SaveConfig();
			
			// Put this into effect immediately
			ClientConfig.PerkKnifeSpeedBoostLevel = PerkKnifeSpeedBoostLevel;

			foreach WorldInfo.AllPawns(class'KFGame.KFPawn_Human', KFPH)
			{
				KFPH.UpdateGroundSpeed();
			}
			
			ClientConfig.SpecialRepInfo.ForcePawnSpeedUpdate();

			BroadcastSystemMessage(UMSMT_PerkKnifeSpeedBoost, IntSetting);
		}*/
		else if (StringParts[0] ~= "UMMidGameJoinerTraderTime")
		{
			// Enforce proper values
			IntSetting = Clamp(int(StringParts[1]), 0, 600);
			
			// Put this into effect immediately and notify UMClientConfig
			MidGameJoinerTraderTime = IntSetting;
			SaveConfig();
			ClientConfig.MidGameJoinerTraderTime = IntSetting;

			BroadcastSystemMessage(UMSMT_MidGameJoinerTraderTime, IntSetting);
		}
		else if (StringParts[0] ~= "UMDefaultWeaponUpgradeLevel")
		{
			// Enforce proper values
			IntSetting = Clamp(int(StringParts[1]), -MaxWeaponUpgradeCount, MaxWeaponUpgradeCount);
			
			DefaultWeaponUpgradeLevel = IntSetting;
			SaveConfig();
			// We add MaxWeaponUpgradeCount to make the value
			// within 0-255 for encoding into a byte
			BroadcastSystemMessage(UMSMT_DefaultUpgradeLevel, IntSetting + MaxWeaponUpgradeCount);
		}
		else if (StringParts[0] ~= "UMAddWeaponUpgradeOverride")
		{
			// Enforce proper values
			IntSetting = Clamp(int(StringParts[2]), -MaxWeaponUpgradeCount, MaxWeaponUpgradeCount);
			WeaponDef = class<KFWeaponDefinition>(DynamicLoadObject(StringParts[1], class'Class'));
			
			if (WeaponDef != None)
			{
				// Convert to vanilla WeaponDef if necessary
				if (WeaponDef.GetPackageName() == 'UnofficialMod')
					WeaponDef = class'UnofficialMod.UMTraderItemsHelper'.static.GetOriginalWeaponDef(WeaponDef);

				FoundIndex = FindUpgradeWeaponDef(WeaponDef);

				if (FoundIndex != INDEX_NONE)
				{
					WeaponUpgradeOverrides[FoundIndex].UpgradeLevel = IntSetting;
				}
				else
				{
					WeaponUpgradeOverrides.Add(1);
					FoundIndex = WeaponUpgradeOverrides.Length - 1;
					WeaponUpgradeOverrides[FoundIndex].WeaponDef = WeaponDef;
					WeaponUpgradeOverrides[FoundIndex].UpgradeLevel = IntSetting;
				}
				
				SaveConfig();
				// We add MaxWeaponUpgradeCount to make the value
				// within 0-255 for encoding into a byte
				BroadcastSystemMessage(UMSMT_AddUpgradeOverride, IntSetting + MaxWeaponUpgradeCount, WeaponDef);
			}
		}
		else if (StringParts[0] ~= "UMRemoveWeaponUpgradeOverride")
		{
			WeaponDef = class<KFWeaponDefinition>(DynamicLoadObject(StringParts[1], class'Class'));
			
			if (WeaponDef != None)
			{
				// Convert to vanilla WeaponDef if necessary
				if (WeaponDef.GetPackageName() == 'UnofficialMod')
					WeaponDef = class'UnofficialMod.UMTraderItemsHelper'.static.GetOriginalWeaponDef(WeaponDef);

				FoundIndex = FindUpgradeWeaponDef(WeaponDef);
				
				if (FoundIndex != INDEX_NONE)
				{
					WeaponUpgradeOverrides.Remove(FoundIndex, 1);

					SaveConfig();
					BroadcastSystemMessage(UMSMT_RemoveUpgradeOverride, 0, WeaponDef);
				}
				else
					BroadcastSystemMessage(UMSMT_NoUpgradeOverride, 0, WeaponDef);
			}
		}
		else if (StringParts[0] ~= "UMEnableGameplayWeapon")
		{
			KFWClass = class<KFWeapon>(DynamicLoadObject(StringParts[1], class'Class'));
			
			if (KFWClass != None)
			{
				IntSetting = GameplayWeapons.Find('WeaponClass', KFWClass);
				if (IntSetting != INDEX_NONE)
				{
					GameplayWeapons[IntSetting].bEnabled = bool(StringParts[2]);
					SaveConfig();
					
					BroadcastSystemMessage(UMSMT_GameplayWeapon, int(bool(StringParts[2])), KFWClass);
				}
			}
		}
		else if (StringParts[0] ~= "UMDisableOthersWeaponsPickup")
		{
			// Put this into effect immediately
			bDisableOthersWeaponsPickup = bool(StringParts[1]);
			SaveConfig();

			ClientConfig.bDisableOthersWeaponsPickup = bDisableOthersWeaponsPickup;
			BroadcastSystemMessage(UMSMT_DisableOthersWeaponsPickup, int(!bool(StringParts[1])));
		}
		else if (StringParts[0] ~= "UMPerkKnifeSpeedBoostWave")
		{
			// Enforce proper values
			PerkKnifeSpeedBoostWave.AdditionalSpeed = FMax(float(StringParts[1]), 0.0);
			PerkKnifeSpeedBoostWave.MaxSpeed = FMax(float(StringParts[2]), 1.0);
			SaveConfig();
			
			// Put this into effect immediately
			ClientConfig.PerkKnifeSpeedBoostWave = PerkKnifeSpeedBoostWave;

			if (!MyKFGI.MyKFGRI.bTraderIsOpen)
			{
				foreach WorldInfo.AllPawns(class'KFGame.KFPawn_Human', KFPH)
				{
					KFPH.UpdateGroundSpeed();
				}

				ClientConfig.SpecialRepInfo.ForcePawnSpeedUpdate();
			}

			// UMClientConfig will normally handle this via repnotify
			// This is for solo only
			if (WorldInfo.NetMode == NM_Standalone)
				ClientConfig.ReplicatedEvent('PerkKnifeSpeedBoostWave');
		}
		else if (StringParts[0] ~= "UMPerkKnifeSpeedBoostTrader")
		{
			// Enforce proper values
			PerkKnifeSpeedBoostTrader.AdditionalSpeed = FMax(float(StringParts[1]), 0.0);
			PerkKnifeSpeedBoostTrader.MaxSpeed = FMax(float(StringParts[2]), 1.0);
			SaveConfig();
			
			// Put this into effect immediately
			ClientConfig.PerkKnifeSpeedBoostTrader = PerkKnifeSpeedBoostTrader;

			if (MyKFGI.MyKFGRI.bTraderIsOpen)
			{
				foreach WorldInfo.AllPawns(class'KFGame.KFPawn_Human', KFPH)
				{
					KFPH.UpdateGroundSpeed();
				}
	
				ClientConfig.SpecialRepInfo.ForcePawnSpeedUpdate();
			}

			// UMClientConfig will normally handle this via repnotify
			// This is for solo only
			if (WorldInfo.NetMode == NM_Standalone)
				ClientConfig.ReplicatedEvent('PerkKnifeSpeedBoostTrader');
		}
		/*else if (StringParts[0] ~= "")
		{
			SaveConfig();
			BroadcastSystemMessage();
		}*/
	}

	if (Left(MutateString, 2) ~= "UM")
	{
		// Other client->server commands
		StringParts = SplitString(MutateString, " ", true);
		
		if (StringParts[0] ~= "UMAllowFriendPickup")
		{
			FoundIndex = FriendPRIInfoList.Find('PRI', Sender.PlayerReplicationInfo);
			
			if (FoundIndex == INDEX_NONE)
			{
				FoundIndex = FriendPRIInfoList.Length;
				FriendPRIInfoList.Length = FoundIndex + 1;
				FriendPRIInfoList[FoundIndex].PRI = Sender.PlayerReplicationInfo;
			}

			FriendPRIInfoList[FoundIndex].bAllowFriendPickup = bool(StringParts[1]);
		}
		else if (StringParts[0] ~= "UMAddSteamFriend")
		{
			FoundIndex = FriendPRIInfoList.Find('PRI', Sender.PlayerReplicationInfo);
			
			if (FoundIndex == INDEX_NONE)
			{
				FoundIndex = FriendPRIInfoList.Length;
				FriendPRIInfoList.Length = FoundIndex + 1;
				FriendPRIInfoList[FoundIndex].PRI = Sender.PlayerReplicationInfo;
			}
			
			// TODO: Check if string representation of UniqueNetId can have spaces (doesn't appear to)
			//StringParts[1] = Split(MutateString, " ", true);
			class'Engine.OnlineSubsystem'.static.StringToUniqueNetId(StringParts[1], UniqueID);
			foreach WorldInfo.GRI.PRIArray(PRI)
			{
				if (PRI.UniqueId == UniqueID)
				{ 
					if (FriendPRIInfoList[FoundIndex].FriendPRIs.Find(PRI) == INDEX_NONE)
						FriendPRIInfoList[FoundIndex].FriendPRIs.AddItem(PRI);
						
					break;
				}
			}
		}
		else if (StringParts[0] ~= "UMRemoveSteamFriend")
		{
			FoundIndex = FriendPRIInfoList.Find('PRI', Sender.PlayerReplicationInfo);
			
			if (FoundIndex == INDEX_NONE)
			{
				FoundIndex = FriendPRIInfoList.Length;
				FriendPRIInfoList.Length = FoundIndex + 1;
				FriendPRIInfoList[FoundIndex].PRI = Sender.PlayerReplicationInfo;
			}
			
			// TODO: Check if string representation of UniqueNetId can have spaces (doesn't appear to)
			//StringParts[1] = Split(MutateString, " ", true);
			class'Engine.OnlineSubsystem'.static.StringToUniqueNetId(StringParts[1], UniqueID);
			foreach WorldInfo.GRI.PRIArray(PRI)
			{
				if (PRI.UniqueId == UniqueID)
				{
					if (FriendPRIInfoList[FoundIndex].FriendPRIs.Find(PRI) != INDEX_NONE)
						FriendPRIInfoList[FoundIndex].FriendPRIs.RemoveItem(PRI);
						
					break;
				}
			}
		}
	}

	super.Mutate(MutateString, Sender);
}

/** Replace weapons that normally spawn in pickup factories */
function ModifyPickupFactories()
{
	local PickupWeaponRepl PWR;
	
	foreach PickupWeaponReplList(PWR)
	{
		ReplaceWeaponPickup(PWR.OldWeaponClass, PWR.NewWeaponClass);
	}

	super.ModifyPickupFactories();
}

/** Check for dropped pickup */
function bool OverridePickupQuery(Pawn Other, class<Inventory> ItemClass, Actor Pickup, out byte bAllowPickup)
{
	local bool bResult;
	local KFDroppedPickup_UM KFDP;
	
	bResult = super.OverridePickupQuery(Other, ItemClass, Pickup, bAllowPickup);
	
	KFDP = KFDroppedPickup_UM(Pickup);
	if (KFDP == None || WorldInfo.NetMode == NM_Standalone || !bDisableOthersWeaponsPickup || Pickup.Instigator == Other)
		return bResult;
		
	if (KFDP.OriginalOwner != None && KFDP.OriginalOwner != Other.PlayerReplicationInfo && !CheckFriendPickup(KFDP.OriginalOwner, Other.PlayerReplicationInfo))
	{
		bAllowPickup = 0;
		return true;
	}
	
	return bResult;
}

/** Temporary workaround for custom weapons not giving dosh
	Also fixes zed aggro-switching with custom weapons */
function NetDamage(int OriginalDamage, out int Damage, Pawn Injured, Controller InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType, Actor DamageCauser)
{
	local KFPawn_Monster KFPM;
	local DamageInfo Info;
	local Pawn BlockerPawn;
	local bool bChangedEnemies;
	local int HistoryIndex;
	local float DamageThreshold;
	local KFAIController KFAIC;

	// Call super first to ensure that
	// accurate damage is passed
	super.NetDamage(OriginalDamage, Damage, Injured, InstigatedBy, HitLocation, Momentum, DamageType, DamageCauser);

	// BetaCheckVersion is 1082 (next update from
	// when this was added) as the custom weapon
	// dosh bug should be fixed in the next update
	if (bIsInBeta)
		return;

	KFPM = KFPawn_Monster(Injured);
	KFAIC = KFAIController(Injured.Controller);

	// Player-on-zed damage with custom weapon
	if (KFPM != None && KFAIC != None && KFPlayerController(InstigatedBy) != None && IsFromModWeapon(DamageCauser))
	{
		// Copy/paste modified from KFPawn.UpdateDamageHistory()
		if( !KFPM.GetDamageHistory( InstigatedBy, Info, HistoryIndex ) )
		{
			KFPM.DamageHistory.Insert(0, 1);
		}

		DamageThreshold = float(KFPM.HealthMax) * KFAIC.AggroPlayerHealthPercentage;

        KFPM.UpdateDamageHistoryValues( InstigatedBy, Damage, DamageCauser, KFAIC.AggroPlayerResetTime, Info, class<KFDamageType>(DamageType) );

		if( `TimeSince(KFPM.DamageHistory[KFAIC.CurrentEnemysHistoryIndex].LastTimeDamaged) > 10 )
		{
			KFPM.DamageHistory[KFAIC.CurrentEnemysHistoryIndex].Damage = 0;
		}

		if( KFAIC.IsAggroEnemySwitchAllowed()
			&& InstigatedBy.Pawn != KFAIC.Enemy
			&& Info.Damage >= DamageThreshold
			&& Info.Damage > KFPM.DamageHistory[KFAIC.CurrentEnemysHistoryIndex].Damage )
		{
			BlockerPawn = KFAIC.GetPawnBlockingPathTo( InstigatedBy.Pawn, true );
			if( BlockerPawn == none )
			{
				bChangedEnemies = KFAIC.SetEnemy(InstigatedBy.Pawn);
			}
			else
			{
				bChangedEnemies = KFAIC.SetEnemy( BlockerPawn );
			}
		}

		KFPM.DamageHistory[HistoryIndex] = Info;
	
		if( bChangedEnemies )
		{
			KFAIC.CurrentEnemysHistoryIndex = HistoryIndex;
		}
	}
}

/** Checks for custom weapons */
function bool IsFromModWeapon(Actor DmgCauser)
{
	local name PackageName;
	
	if (DmgCauser == None)
		return false;

	PackageName = DmgCauser.GetPackageName();
	
	return (PackageName != 'KFGameContent' && PackageName != 'KFGame');
}

/** Check for player-on-large-zed kill and player death */
function ScoreKill(Controller Killer, Controller Killed)
{
	local KFPawn_Monster KFPM;
	local KFPlayerController KFPC;

	// Check for player-on-large-zed kill
	if (KFPlayerController(Killer) != None && KFAIController(Killed) != None && WorldInfo.NetMode != NM_Standalone)
	{
		KFPM = KFAIController(Killed).MyKFPawn;
		
		if (KFPM != None && KFPM.bLargeZed)
		{
			foreach WorldInfo.AllControllers(class'KFGame.KFPlayerController', KFPC)
			{
				// Only for other players
				if (KFPC == Killer)
					continue;

				KFPC.ReceiveLocalizedMessage(class'UnofficialMod.UMLocalMessage', UMLMT_OtherPlayerKilledLargeZed, Killer.PlayerReplicationInfo, , KFPM.class);
			}
		}
	}

	// NOTE: ScoreKill() is called right before
	// the player drops their inventory
	if (KFPlayerController(Killed) != None)
	{
		// Set 9mm upgrade level on death
		ClientConfig.SpecialRepInfo.Set9mmUpgradeLevelOnDeath(Killed);
	}

	super.ScoreKill(Killer, Killed);
}

function SetupConfig()
{
	local bool bSaveConfig;
	local int i, UpgradeCount, WeaponCount;
	local class<KFWeaponDefinition> WeaponDef;
	local class<KFWeapon> KFWClass;
	
	// Although false is default without a
	// config file, this allows users to reset
	// their configs by setting INIVersion to 0
	if (INIVersion < 1)
	{
		INIVersion = 1;
		bDisableWeaponUpgrades = false;
		bSaveConfig = true;
	}
	
	if (INIVersion < 2)
	{
		INIVersion = 2;
		bStartWithoutTier1Weapons = false;
		bKF1StyleSyringe = false;
		bDisableRandomMapObjectives = false;
		bSaveConfig = true;
	}
	
	if (INIVersion < 3)
	{
		INIVersion = 3;
		MaxFailedKickVoteAttempts = 2;
		bKickFailedVoteInitiator = false;
		bSaveConfig = true;
	}

	if (INIVersion < 4)
	{
		INIVersion = 4;
		//PerkKnifeSpeedBoostLevel = 0;
		MidGameJoinerTraderTime = 30;
		DefaultWeaponUpgradeLevel = default.MaxWeaponUpgradeCount;
		WeaponUpgradeOverrides.Length = 1;
		WeaponUpgradeOverrides[0].WeaponDef = None;
		WeaponUpgradeOverrides[0].UpgradeLevel = 5;
		bSaveConfig = true;
	}

	if (INIVersion < 5)
	{
		INIVersion = 5;
		// The below code ensures that this is
		// reset to default of true for everything
		GameplayWeapons.Length = 0;
		bSaveConfig = true;
	}
	
	if (INIVersion < 6)
	{
		INIVersion = 6;
		bDisableOthersWeaponsPickup = false;
		// TODO: remove these checks when
		// PerkKnifeSpeedBoostLevel is fully removed
		if (PerkKnifeSpeedBoostLevel == 1)
		{
			PerkKnifeSpeedBoostWave.AdditionalSpeed = 0.10;
			PerkKnifeSpeedBoostWave.MaxSpeed = 1.10;
			PerkKnifeSpeedBoostTrader.AdditionalSpeed = 0.10;
			PerkKnifeSpeedBoostTrader.MaxSpeed = 1.10;
		}
		else if (PerkKnifeSpeedBoostLevel == 2)
		{
			PerkKnifeSpeedBoostWave.AdditionalSpeed = 0.10;
			PerkKnifeSpeedBoostWave.MaxSpeed = 1.35;
			PerkKnifeSpeedBoostTrader.AdditionalSpeed = 0.10;
			PerkKnifeSpeedBoostTrader.MaxSpeed = 1.35;
		}
		else
		{
			PerkKnifeSpeedBoostWave.AdditionalSpeed = 0.00;
			PerkKnifeSpeedBoostWave.MaxSpeed = 1.00;
			PerkKnifeSpeedBoostTrader.AdditionalSpeed = 0.00;
			PerkKnifeSpeedBoostTrader.MaxSpeed = 1.00;
		}
		bSaveConfig = true;
	}

	// Get gameplay-affecting weapons from UMTraderItemsHelper
	// We do not update INIVersion here because
	// this will always update the config as needed
	WeaponCount = class'UnofficialMod.UMTraderItemsHelper'.default.TraderModList.Length;
	
	for (i = 0;i < WeaponCount;i++)
	{
		if (class'UnofficialMod.UMTraderItemsHelper'.default.TraderModList[i].bAffectsGameplay)
		{
			WeaponDef = class'UnofficialMod.UMTraderItemsHelper'.default.TraderModList[i].NewWeapDef;
			KFWClass = class<KFWeapon>(DynamicLoadObject(WeaponDef.default.WeaponClassPath, class'Class'));
			
			if (KFWClass == None)
			{
				`log("[Unofficial Mod]Couldn't load weapon path" @ WeaponDef.default.WeaponClassPath @ "for WeaponDef" @ WeaponDef);
				continue;
			}
			
			if (GameplayWeapons.Find('WeaponClass', KFWClass) == INDEX_NONE)
			{
				GameplayWeapons.Add(1);
				GameplayWeapons[GameplayWeapons.Length - 1].WeaponClass = KFWClass;
				GameplayWeapons[GameplayWeapons.Length - 1].bEnabled = true;
				bSaveConfig = true;
			}
		}
	}

	if (bSaveConfig)
		SaveConfig();

	// Server settings
	ClientConfig.bDisableWeaponUpgrades = bDisableWeaponUpgrades;
	ClientConfig.bStartWithoutTier1Weapons = bStartWithoutTier1Weapons;
	ClientConfig.bKF1StyleSyringe = bKF1StyleSyringe;
	ClientConfig.bDisableRandomMapObjectives = bDisableRandomMapObjectives;
	//ClientConfig.PerkKnifeSpeedBoostLevel = PerkKnifeSpeedBoostLevel;
	ClientConfig.MidGameJoinerTraderTime = MidGameJoinerTraderTime;
	ClientConfig.DefaultWeaponUpgradeLevel = DefaultWeaponUpgradeLevel;
	ClientConfig.bDisableOthersWeaponsPickup = bDisableOthersWeaponsPickup;
	ClientConfig.PerkKnifeSpeedBoostWave = PerkKnifeSpeedBoostWave;
	ClientConfig.PerkKnifeSpeedBoostTrader = PerkKnifeSpeedBoostTrader;

	if (!bDisableWeaponUpgrades && WeaponUpgradeOverrides.Length > 0)
	{
		// Account for None WeaponDef
		// Done because default config setting
		// has a single setting with None WeaponDef
		UpgradeCount = 0;
		for (i = 0;i < WeaponUpgradeOverrides.Length && i < 256;i++)
		{
			if (WeaponUpgradeOverrides[i].WeaponDef == None)
				continue;

			ClientConfig.WeaponUpgradeOverrides[UpgradeCount] = WeaponUpgradeOverrides[i];
			UpgradeCount++;
		}
		
		ClientConfig.WeaponUpgradeOverrideCount = Min(UpgradeCount, 255);
	}

	for (i = 0;i < GameplayWeapons.Length && i < 16;i++)
		ClientConfig.GameplayWeapons[i] = GameplayWeapons[i];

	// Other relevant server info
	ClientConfig.bCanExtendTraderTime = (MidGameJoinerTraderTime > 0);
	SetMaxTraderTime();
	SetupVoteCollector();
}

/** Give dosh for taken Tier 1 weapons
	if config option is enabled */
function GiveTier1Dosh()
{
	local Tier1RemovedPRI T1RPRI;

	while (Tier1RemovedPRIList.Length > 0)
	{
		T1RPRI = Tier1RemovedPRIList[0];
		T1RPRI.KFPRI.AddDosh(T1RPRI.SellPrice);
		Tier1RemovedPRIList.Remove(0,1);
	}
}

/** Replace Trader Items if mod allows it */
function CheckTraderItems()
{
	local class<UMTraderItemsHelper> TraderHelperClass;

	// WorldInfo.GRI doesn't exist when mutators
	// are created, so check it first
	if (WorldInfo.GRI == None)
	{
		SetTimer(1.0, false, nameof(CheckTraderItems));
		return;
	}
	
	// If another mod has changed this, then
	// don't override, just log and exit
	if (MyKFGI.MyKFGRI.TraderItems == class'KFGame.KFGameReplicationInfo'.default.TraderItems)
	{
		MyKFGI.MyKFGRI.TraderItems = GetTraderItems();
		// Normally you're not supposed to modify hard archetypes,
		// but since it's our own archetype and the UMTraderItemsHelper
		// ensures that everything is kept synched, it works here
		TraderHelper = Spawn(class'UnofficialMod.UMTraderItemsHelper');
	}
	else if (IsCompatibleTraderItemsMod(TraderHelperClass))
		TraderHelper = Spawn(TraderHelperClass);
	else
	{
		`log("[Unofficial Mod]Custom TraderItems found, skipping replacement...");
		`log("----Recommended to use the Trader Inventory Mutator in KF2 Workshop");
	}
	
	if (TraderHelper != None)
		TraderHelper.CompileWeaponList(GetDisabledUMWeapons());
}

/** Disable random map objectives */
function CheckMapInfo()
{
	local KFMapInfo KFMI;
	
	KFMI = KFMapInfo(WorldInfo.GetMapInfo());
	
	if (KFMI == None)
	{
		SetTimer(1.0, false, nameof(CheckMapInfo));
		return;
	}
	
	KFMI.bUseRandomObjectives = false;
}

/** Check bots (used for HUD testing) */
function CheckBots()
{
	local KFPawn_Human KFPH;
	
	// Add bots to special ReplicationInfo
	// Used to test HUD
	foreach WorldInfo.AllPawns(class'KFGame.KFPawn_Human', KFPH)
	{
		if (KFAIController(KFPH.Controller) != None && !ClientConfig.SpecialRepInfo.IsPlayerInRepInfo(KFPH.Controller))
			ClientConfig.SpecialRepInfo.NotifyLogin(KFPH.Controller);
	}
}

/** Set max Trader time for UMClientConfig */
function SetMaxTraderTime()
{
	// We check for this because on the server
	// KFGameInfo.DifficultyInfo is not created
	// as of the mutators' PostBeginPlay()
	// (despite the fact that the DifficultyInfo is
	// created in KFGameInfo.InitGame()) *shrugs*
	if (MyKFGI.DifficultyInfo == None)
	{
		SetTimer(1.0, false, nameof(SetMaxTraderTime));
		return;
	}
	
	ClientConfig.MaxTraderTime = MyKFGI.GetTraderTime();
}

/** Setup custom vote collector with config values */
function SetupVoteCollector()
{
	local KFVoteCollector_UM KFVC;
	
	if (WorldInfo.GRI == None)
	{
		SetTimer(1.0, false, nameof(SetupVoteCollector));
		return;
	}
	
	KFVC = KFVoteCollector_UM(MyKFGI.MyKFGRI.VoteCollector);
	if (KFVC != None)
	{
		KFVC.MaxFailedKickVoteAttempts = MaxFailedKickVoteAttempts;
		KFVC.bKickFailedVoteInitiator = bKickFailedVoteInitiator;
	}
}

/** Check for compatible mod for Trader Items helper
	NOTE: this only works for mods known to use a
	custom KFGFxObject_TraderItems */
function bool IsCompatibleTraderItemsMod(out class<UMTraderItemsHelper> TraderHelperClass)
{
	local int i;
	local Mutator Mut;

	for (i = 0;i < CustomTraderHelperList.Length;i++)
	{
		if (CustomTraderHelperList[i].bIsGameInfo)
		{
			if (WorldInfo.Game.IsA(CustomTraderHelperList[i].ClassName))
			{
				TraderHelperClass = CustomTraderHelperList[i].TraderHelperClass;
				return true;
			}
		}
		else
		{
			for (Mut = WorldInfo.Game.BaseMutator;Mut != None;Mut = Mut.NextMutator)
			{
				if (Mut.IsA(CustomTraderHelperList[i].ClassName))
				{
					TraderHelperClass = CustomTraderHelperList[i].TraderHelperClass;
					return true;
				}
			}
		}
	}

	return false;
}

/** Replace weapon in player's inventory with another */
function ReplaceWeaponInv(Pawn Other, name OldWeaponName, class<KFWeapon> NewWeaponClass, optional bool bSilent)
{
	local KFInventoryManager KFIM;
	local Inventory Inv;
	local KFWeapon KFW;

	if (!IsWeaponEnabled(NewWeaponClass))
		return;

	KFIM = KFInventoryManager(Other.InvManager);
	if (KFIM == None)
		return;

	if (KFIM.GetWeaponFromClass(KFW, OldWeaponName))
	{
		KFIM.RemoveFromInventory(KFW);
		Inv = KFIM.CreateInventory(NewWeaponClass);
		KFWeapon(Inv).bGivenAtStart = true;
		`log("[Unofficial Mod]ReplaceWeaponInv() - Replaced" @ OldWeaponName @ "with" @ NewWeaponClass);
	}
	else if (!bSilent)
		`log("[Unofficial Mod]ReplaceWeaponInv() - Couldn't find weapon" @ OldWeaponName @ "- trying to replace with" @ NewWeaponClass);
}

/** Replace weapon in item pickup with another */
function ReplaceWeaponPickup(class<KFWeapon> OldWeaponClass, class<KFWeapon> NewWeaponClass)
{
	local KFPickupFactory KFPF;
	local KFPickupFactory_Item KFPFI;
	local int i;
	
	if (!IsWeaponEnabled(NewWeaponClass))
		return;

	foreach MyKFGI.ItemPickups(KFPF)
	{
		KFPFI = KFPickupFactory_Item(KFPF);
		
		if (KFPFI != None)
		{
			for (i = 0;i < KFPFI.ItemPickups.Length;i++)
			{
				if (KFPFI.ItemPickups[i].ItemClass == OldWeaponClass)
				{
					// We don't need to update this clientside
					// because they still load the correct mesh
					KFPFI.ItemPickups[i].ItemClass = NewWeaponClass;
					break;
				}
			}
		}
	}
}

/** Get proper TraderItems instance based on KF2 version (used for beta) */
function KFGFxObject_TraderItems GetTraderItems()
{
	if (IsInBeta())
		return UMTraderItemsBeta;
		
	return UMTraderItems;
}

/** Get 9mm/Dual 9mm from player's inventory */
static function KFWeapon Get9MMPistol(KFInventoryManager KFIM)
{
	local KFWeapon KFW;
	
	if (KFIM == None)
	{
		`log("[Unofficial Mod]Get9mmPistol() - None passed for KFInventoryManager! This shouldn't happen!");
		return None;
	}
	
	foreach KFIM.InventoryActors(class'KFGame.KFWeapon', KFW)
	{
		// This is the same check used in KFPerk_Commando and KFPerk_SWAT Is9mm() functions
		if (KFW.default.bIsBackupWeapon && !KFW.IsMeleeWeapon())
			return KFW;
	}

	return None;
}

/** Extend Trader time for mid-game joiners */
function ExtendTraderTime()
{
	local int TraderTime;

	TraderTime = Min(WorldInfo.GRI.RemainingTime + MidGameJoinerTraderTime, MyKFGI.GetTraderTime());
	WorldInfo.GRI.RemainingTime = TraderTime;
	WorldInfo.GRI.RemainingMinute = TraderTime;
	MyKFGI.SetTimer(TraderTime, false, 'CloseTraderTimer');
	ClientConfig.bCanExtendTraderTime = false;
	MyKFGI.BroadcastLocalized(MyKFGI, class'UnofficialMod.UMLocalMessage', UMLMT_TraderTimeExtended);
}

/** Check if we are in a beta */
static function bool IsInBeta()
{
	return class'KFGame.KFGameEngine'.static.GetKFGameVersion() >= default.BetaCheckVersion;
}

/** Broadcast system message
	NOTE: Switch is encoded as follows:
	Low byte is message type
	Second byte is value */
function BroadcastSystemMessage(int MsgType, int MsgValue, optional Object OptionalObj, optional PlayerController PC)
{
	local int EncodedSwitch;
	
	EncodedSwitch = MsgType | (MsgValue << 8);
	
	// Check if we're sending this to only this player
	if (PC != None)
		PC.ReceiveLocalizedMessage(class'UnofficialMod.UMSystemMessage', EncodedSwitch,,, OptionalObj);
	else
		MyKFGI.BroadcastLocalized(MyKFGI, class'UnofficialMod.UMSystemMessage', EncodedSwitch,,, OptionalObj);
}

/** Is this weapon enabled? */
function bool IsWeaponEnabled(class<KFWeapon> KFWClass)
{
	local int i;
	
	i = GameplayWeapons.Find('WeaponClass', KFWClass);
	
	if (i == INDEX_NONE)
		return true;
		
	return GameplayWeapons[i].bEnabled;
}

/** Get disabled weapons */
function array< class<KFWeapon> > GetDisabledUMWeapons()
{
	local int i;
	local array< class<KFWeapon> > DisabledWeapons;

	for (i = 0;i < GameplayWeapons.Length;i++)
	{
		if (!GameplayWeapons[i].bEnabled)
			DisabledWeapons.AddItem(GameplayWeapons[i].WeaponClass);
	}
	
	return DisabledWeapons;
}

/** Find WeaponDef in upgrade override array */
function int FindUpgradeWeaponDef(class<KFWeaponDefinition> WeaponDef)
{
	local int FoundIndex;
	local KFGFxObject_TraderItems TraderItems;

	// This shouldn't happen
	if (WeaponDef == None)
		return INDEX_NONE;

	// Try to find this weapon in list first
	FoundIndex = WeaponUpgradeOverrides.Find('WeaponDef', WeaponDef);

	if (FoundIndex != INDEX_NONE)
		return FoundIndex;
	else
	{
		// If we didn't find this, try to see
		// if this is a dual-wieldable weapon
		TraderItems = MyKFGI.MyKFGRI.TraderItems;
		FoundIndex = TraderItems.SaleItems.Find('WeaponDef', WeaponDef);

		if (TraderItems.SaleItems[FoundIndex].SingleClassName != '')
		{
			FoundIndex = TraderItems.SaleItems.Find('ClassName', TraderItems.SaleItems[FoundIndex].SingleClassName);
			if (FoundIndex != INDEX_NONE)
				return WeaponUpgradeOverrides.Find('WeaponDef', TraderItems.SaleItems[FoundIndex].WeaponDef);
		}
		else if (TraderItems.SaleItems[FoundIndex].DualClassName != '')
		{
			FoundIndex = TraderItems.SaleItems.Find('ClassName', TraderItems.SaleItems[FoundIndex].DualClassName);
			if (FoundIndex != INDEX_NONE)
				return WeaponUpgradeOverrides.Find('WeaponDef', TraderItems.SaleItems[FoundIndex].WeaponDef);
		}
	}
	
	return INDEX_NONE;
}

/** Check for Steam friend on weapon pickup */
function bool CheckFriendPickup(PlayerReplicationInfo OwnerPRI, PlayerReplicationInfo CheckPRI)
{
	local int Index;

	// Shouldn't happen, but check anyways
	if (OwnerPRI == None || OwnerPRI == CheckPRI)
		return true;
	
	Index = FriendPRIInfoList.Find('PRI', OwnerPRI);

	// This should never happen
	if (Index == INDEX_NONE)
	{
		`log("[Unofficial Mod]Couldn't find PRI for name" @ OwnerPRI.PlayerName @ "in list!?");
		return true;
	}

	if (!FriendPRIInfoList[Index].bAllowFriendPickup)
		return false;
		
	return (FriendPRIInfoList[Index].FriendPRIs.Find(CheckPRI) != INDEX_NONE);
}

/** Check Bloat mines and delete if in Trader time
	Workaround for invisible Bloat mine bug */
function CheckBloatMines()
{
	local bool bIsTraderOpen;
	local KFProj_BloatPukeMine BloatMine;
	local int BloatMineCount;

	bIsTraderOpen = MyKFGI.MyKFGRI.bTraderIsOpen;
	if (bIsTraderOpen && !bWasTraderOpen)
	{
		BloatMineCount = 0;
		foreach DynamicActors(class'KFGameContent.KFProj_BloatPukeMine', BloatMine)
		{
			BloatMine.Destroy();
			BloatMineCount++;
		}
		
		if (BloatMineCount > 0)
			BroadcastSystemMessage(UMSMT_BloatMinesRemoved, BloatMineCount);
	}
	
	bWasTraderOpen = bIsTraderOpen;
}

defaultproperties
{
	UMTraderItems=KFGFxObject_TraderItems'UnofficialModAssets.UMTraderItems'
	UMTraderItemsBeta=KFGFxObject_TraderItems'UnofficialModAssets.UMTraderItemsBeta'
	// NOTE: This is set early because the
	// custom weapon dosh bug should be
	// fixed in the next update
	BetaCheckVersion=1082
	MaxWeaponUpgradeCount=5
	ModVersion="8"

	// Trader Inventory Mutator
	CustomTraderHelperList.Add((ClassName=TIMut))
	// Classic Mode
	CustomTraderHelperList.Add((ClassName=ClassicMode, TraderHelperClass=class'UnofficialMod.UMTraderItemsHelper_ClassicMode'))

	// TODO: Make this not hard-coded
	// Tier 1 weapons
	Tier1Weapons(0)=class'KFGameContent.KFWeap_Blunt_Crovel'
	Tier1Weapons(1)=class'KFGameContent.KFWeap_AssaultRifle_AR15'
	Tier1Weapons(2)=class'KFGameContent.KFWeap_GrenadeLauncher_HX25'
	Tier1Weapons(3)=class'KFGameContent.KFWeap_Pistol_Medic'
	Tier1Weapons(4)=class'KFGameContent.KFWeap_Flame_CaulkBurn'
	Tier1Weapons(5)=class'KFGameContent.KFWeap_Revolver_DualRem1858'
	Tier1Weapons(6)=class'KFGameContent.KFWeap_Rifle_Winchester1894'
	Tier1Weapons(7)=class'KFGameContent.KFWeap_Shotgun_MB500'
	Tier1Weapons(8)=class'KFGameContent.KFWeap_SMG_MP7'

	// NOTE: Modified 9mm/Dual 9mm pistols removed due to
	// too many hard-coded 'KFWeap_Pistol_9mm' making this
	// very difficult if not impossible to get working properly
	// Only thing I wanted to do was increase total ammo
	// to 120 anyways so no big loss
	// Starting weapon replacements
	//StartWeaponReplList(0)=(OldWeaponName=KFWeap_Pistol_9mm, NewWeaponClass=class'UnofficialMod.KFWeap_Pistol_9mm_UM')
	//StartWeaponReplList(1)=(OldWeaponName=KFWeap_Pistol_Dual9mm, NewWeaponClass=class'UnofficialMod.KFWeap_Pistol_Dual9mm_UM')
	StartWeaponReplList(0)=(OldWeaponName=KFWeap_GrenadeLauncher_HX25, NewWeaponClass=class'UnofficialMod.KFWeap_GrenadeLauncher_HX25_UM')

	// Pickup weapon replacements
	//PickupWeaponReplList(0)=(OldWeaponClass=class'KFGameContent.KFWeap_Pistol_9mm', NewWeaponClass=class'UnofficialMod.KFWeap_Pistol_9mm_UM')
	// NOTE: None of the vanilla item pickup factories have these weapons (as of v1075),
	// but we have them here for custom maps and mods that might use them
	//PickupWeaponReplList()=(OldWeaponClass=class'KFGameContent.', NewWeaponClass=class'UnofficialMod.')
	PickupWeaponReplList(0)=(OldWeaponClass=class'KFGameContent.KFWeap_AssaultRifle_M16M203', NewWeaponClass=class'UnofficialMod.KFWeap_AssaultRifle_M16M203_UM')
	PickupWeaponReplList(1)=(OldWeaponClass=class'KFGameContent.KFWeap_Blunt_Pulverizer', NewWeaponClass=class'UnofficialMod.KFWeap_Blunt_Pulverizer_UM')
	PickupWeaponReplList(2)=(OldWeaponClass=class'KFGameContent.KFWeap_Rifle_M14EBR', NewWeaponClass=class'UnofficialMod.KFWeap_Rifle_M14EBR_UM')
	PickupWeaponReplList(3)=(OldWeaponClass=class'KFGameContent.KFWeap_Shotgun_Nailgun', NewWeaponClass=class'UnofficialMod.KFWeap_Shotgun_Nailgun_UM')
	PickupWeaponReplList(4)=(OldWeaponClass=class'KFGameContent.KFWeap_Thrown_C4', NewWeaponClass=class'UnofficialMod.KFWeap_Thrown_C4_UM')
	PickupWeaponReplList(5)=(OldWeaponClass=class'KFGameContent.KFWeap_GrenadeLauncher_HX25', NewWeaponClass=class'UnofficialMod.KFWeap_GrenadeLauncher_HX25_UM')
	PickupWeaponReplList(6)=(OldWeaponClass=class'KFGameContent.KFWeap_AssaultRifle_MedicRifleGrenadeLauncher', NewWeaponClass=class'UnofficialMod.KFWeap_AssaultRifle_MedicRifleGrenadeLauncher_UM')
}