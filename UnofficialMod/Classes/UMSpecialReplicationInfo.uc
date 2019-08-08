//================================================
// UMSpecialReplicationInfo
//================================================
// Special ReplicationInfo containing relevant
// info on players
// Also includes some server-relevant stuff
// which is here for easy access by the mutator
//================================================
// (c) 2018 "Insert Name Here"
//================================================
class UMSpecialReplicationInfo extends ReplicationInfo;

// NOTES:
// We use parallel arrays instead of an
// array of structs to minimize net
// traffic (because updating any part
// of a struct re-sends the whole struct)
// 8 length covers 6 players + 2 spectators
// More UMSpecialReplicationInfo
// are created as needed (e.g. Versus)
const REP_INFO_COUNT = 8;

/** Player controllers */
var Controller PCArray[REP_INFO_COUNT];

/** Pawns */
var KFPawn_Human KFPHArray[REP_INFO_COUNT];

/** Total health (Health + HealthToRegen)
	Done this way to minimize net traffic
	0 means HealthToRegen==0 */
var int TotalRegenHealthArray[REP_INFO_COUNT];

/** Lose only one 9mm upgrade on death */
var int NineMMUpgradeArray[REP_INFO_COUNT];

/** Last ground/sprint speed of players
	NOTE: These update under the following conditions:
	-Weapon changes
	-Crouch/uncrouch
	-Player health changes that affect move speed */
var float LastGroundSpeed[REP_INFO_COUNT];
var float LastSprintSpeed[REP_INFO_COUNT];

/** Maximum speed multiplier allowed */
var float MaxSpeedMult;

/** Additional speed multiplier for perk knife if player qualifies */
var float AdditionalSpeedMult;

/** Was this Trader time the last time we checked? */
var bool bWasTraderOpen;

/** Owning UMClientConfig */
var UMClientConfig ClientConfig;

/** Next UMSpecialReplicationInfo in linked list */
var UMSpecialReplicationInfo NextRepInfo;

replication
{
	// We don't need to replicate PCArray
	if (bNetDirty)
		KFPHArray,TotalRegenHealthArray,NextRepInfo;
}

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	
	ClientConfig = UMClientConfig(Owner);
	
	if (WorldInfo.NetMode != NM_Client)
		SetTimer(0.1, true, nameof(UpdateInfo));
}

/** Add logged-in player to array */
simulated function NotifyLogin(Controller C)
{
	local int i;

	// Second check is for bot debugging
	if (PlayerController(C) == None && KFPawn_Human(C.Pawn) == None)
		return;

	// Find empty spot
	for (i = 0;i < REP_INFO_COUNT;i++)
	{
		if (PCArray[i] == None)
		{
			PCArray[i] = C;
			// Probably not necessary, but better safe than sorry
			NineMMUpgradeArray[i] = 0;
			LastGroundSpeed[i] = 0.0;
			LastSprintSpeed[i] = 0.0;
			return;
		}
	}
	
	// No empty spot, pass to NextRepInfo
	if (NextRepInfo == None)
		NextRepInfo = Spawn(class'UnofficialMod.UMSpecialReplicationInfo', ClientConfig);
		
	NextRepInfo.NotifyLogin(C);
}

/** Remove logged-out player from array */
simulated function NotifyLogout(Controller C)
{
	local int i;
	
	// Second check is for bot debugging
	if (PlayerController(C) == None && KFPawn_Human(C.Pawn) == None)
		return;
		
	for (i = 0;i < REP_INFO_COUNT;i++)
	{
		if (PCArray[i] == C)
		{
			PCArray[i] = None;
			KFPHArray[i] = None;
			TotalRegenHealthArray[i] = 0;
			NineMMUpgradeArray[i] = 0;
			LastGroundSpeed[i] = 0.0;
			LastSprintSpeed[i] = 0.0;
			return;
		}
	}
	
	// Didn't find it, check with NextRepInfo if it exists
	if (NextRepInfo != None)
		NextRepInfo.NotifyLogout(C);
}

/** Updates relevant info */
function UpdateInfo()
{
	local int i;

	AdditionalSpeedMult = ClientConfig.CurrentPerkKnifeSpeedBoost.AdditionalSpeed;
	MaxSpeedMult = ClientConfig.CurrentPerkKnifeSpeedBoost.MaxSpeed;

	for (i = 0;i < REP_INFO_COUNT;i++)
	{
		if (PCArray[i] == None)
			continue;

		KFPHArray[i] = KFPawn_Human(PCArray[i].Pawn);

		if (KFPHArray[i] != None && KFPHArray[i].Health > 0 && KFPHArray[i].HealthToRegen > 0)
			TotalRegenHealthArray[i] = KFPHArray[i].Health + KFPHArray[i].HealthToRegen;
		else
			TotalRegenHealthArray[i] = 0;

		if (KFPHArray[i] != None && AdditionalSpeedMult > 0.0)
			UpdatePawnSpeed(i);
	}
}

/** Find out if this player is in here
	Used for bots in solo offline testing for now */
function bool IsPlayerInRepInfo(Controller C)
{
	local int i;
	
	for (i = 0;i < REP_INFO_COUNT;i++)
	{
		if (PCArray[i] == C)
			return true;
	}
	
	return (NextRepInfo != None ? NextRepInfo.IsPlayerInRepInfo(C) : false);
}

/** Get regen health for passed-in KFPawn_Human */
simulated function int GetRegenHealth(KFPawn_Human KFPH)
{
	local int i;
	
	for (i = 0;i < REP_INFO_COUNT;i++)
	{
		// UpdateInfo() adds Health + HealthToRegen
		// so we subtract it here
		if (KFPHArray[i] == KFPH)
			return (TotalRegenHealthArray[i] > 0 ? TotalRegenHealthArray[i] - KFPH.Health : 0);
	}
	
	// Didn't find it, check with NextRepInfo if it exists
	return (NextRepInfo != None ? NextRepInfo.GetRegenHealth(KFPH) : 0);
}

/** Set 9mm upgrade level for the passed in Controller */
function Set9mmUpgradeLevelOnDeath(Controller C)
{
	local int i;
	local KFWeapon KFW;
	
	for (i = 0;i < REP_INFO_COUNT;i++)
	{
		if (PCArray[i] != C)
			continue;
			
		if (KFPHArray[i] != None && KFInventoryManager(KFPHArray[i].InvManager) != None)
		{
			KFW = class'UnofficialMod.UnofficialModMut'.static.Get9MMPistol(KFInventoryManager(KFPHArray[i].InvManager));

			if (KFW != None)
				// We subtract one level here
				NineMMUpgradeArray[i] = Max(KFW.CurrentWeaponUpgradeIndex - 1, 0);
		}
		else
			NineMMUpgradeArray[i] = 0;
		
		return;
	}
	
	// Didn't find it, check with NextRepInfo if it exists
	if (NextRepInfo != None)
		NextRepInfo.Set9mmUpgradeLevelOnDeath(C);
}

/** Get 9mm upgrade level when respawning */
function int Get9mmUpgradeLevel(Controller C)
{
	local int i;
	
	for (i = 0;i < REP_INFO_COUNT;i++)
	{
		if (PCArray[i] == C)
			return NineMMUpgradeArray[i];
	}
	
	// Didn't find it, check with NextRepInfo if it exists
	return (NextRepInfo != None ? NextRepInfo.Get9mmUpgradeLevel(C) : 0);
}

/** Update pawn's ground/sprint speed */
function UpdatePawnSpeed(int Index)
{
	local float CurrentSpeed, DefaultSpeed;

	// Don't bother if we don't have Perk knife out
	if (KFPHArray[Index] == None || KFWeap_Edged_Knife(KFPHArray[Index].Weapon) == None)
		return;

	if (KFPHArray[Index].GroundSpeed != LastGroundSpeed[Index])
	{
		DefaultSpeed = KFPHArray[Index].default.GroundSpeed;
		CurrentSpeed = KFPHArray[Index].GroundSpeed;

		if (CurrentSpeed < DefaultSpeed * MaxSpeedMult)
			KFPHArray[Index].GroundSpeed = FMin(CurrentSpeed + DefaultSpeed * AdditionalSpeedMult, DefaultSpeed * MaxSpeedMult);

		LastGroundSpeed[Index] = KFPHArray[Index].GroundSpeed;
	}
	
	if (KFPHArray[Index].SprintSpeed != LastSprintSpeed[Index])
	{
		DefaultSpeed = KFPHArray[Index].default.SprintSpeed;
		CurrentSpeed = KFPHArray[Index].SprintSpeed;

		if (CurrentSpeed < DefaultSpeed * MaxSpeedMult)
			KFPHArray[Index].SprintSpeed = FMin(CurrentSpeed + DefaultSpeed * AdditionalSpeedMult, DefaultSpeed * MaxSpeedMult);

		LastSprintSpeed[Index] = KFPHArray[Index].SprintSpeed;
	}
}

/** Forces update to ground/sprint speed
	Used both in testing and when the server
	admin modifies the perk knife boost property */
function ForcePawnSpeedUpdate()
{
	local int i;
	
	for (i = 0;i < REP_INFO_COUNT;i++)
	{
		LastGroundSpeed[i] = 0.0;
		LastSprintSpeed[i] = 0.0;
	}
	
	if (NextRepInfo != None)
		NextRepInfo.ForcePawnSpeedUpdate();
}

defaultproperties
{
	MaxSpeedMult=1.0
	AdditionalSpeedMult=0.0
}