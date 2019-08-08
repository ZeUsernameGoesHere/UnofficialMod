//================================================
// UMDroppedPickupTracker
//================================================
// Dropped weapon tracker for Unofficial Mod
//================================================
// (c) 2019 "Insert Name Here"
//================================================
class UMDroppedPickupTracker extends Info;

/** Weapon pickup registry entry */
struct WeaponPickupRegInfo
{
	/** PRI of weapon's original owner */
	var PlayerReplicationInfo OrigOwnerPRI;
	/** Current carrier of weapon */
	var PlayerController CurrCarrier;
	/** Dropped pickup instance */
	var KFDroppedPickup_UM KFDP;
	/** Weapon class */
	var class<KFWeapon> KFWClass;
};

/** Weapon pickup registry */
var array<WeaponPickupRegInfo> WeaponPickupRegistry;

/** Mutator reference */
var UnofficialModMut MutRef;

function PostBeginPlay()
{
	super.PostBeginPlay();
	
	MutRef = UnofficialModMut(Owner);
	
	SetTimer(1.0, true, nameof(PurgePickupList));
}

/** Register weapon pickup for system (or check if this was previously owned by someone else) */
function PlayerReplicationInfo RegisterDroppedPickup(KFDroppedPickup_UM KFDP, PlayerController DroppedBy)
{
	local int i;
	local class<KFWeapon> KFWC;

	// We check for class here because
	// dual weapons set single class
	// after this is called
	KFWC = class<KFWeapon>(KFDP.InventoryClass);
	if (class<KFWeap_DualBase>(KFWC) != None)
		KFWC = class<KFWeap_DualBase>(KFWC).default.SingleClass;

	// First check registry
	for (i = 0;i < WeaponPickupRegistry.Length;i++)
	{
		if (WeaponPickupRegistry[i].KFWClass == KFWC && WeaponPickupRegistry[i].CurrCarrier == DroppedBy)
		{
			WeaponPickupRegistry[i].KFDP = KFDP;
			WeaponPickupRegistry[i].CurrCarrier = None;
			// TODO?: System message
			return WeaponPickupRegistry[i].OrigOwnerPRI;
		}
	}
	
	// Add entry if none was found
	i = WeaponPickupRegistry.Length;
	WeaponPickupRegistry.Add(1);
	WeaponPickupRegistry[i].OrigOwnerPRI = DroppedBy.PlayerReplicationInfo;
	WeaponPickupRegistry[i].KFDP = KFDP;
	WeaponPickupRegistry[i].KFWClass = KFWC;
	return DroppedBy.PlayerReplicationInfo;
}

/** When weapon pickup is destroyed, check if this is the original owner */
function OnDroppedPickupDestroyed(KFDroppedPickup_UM KFDP, optional PlayerController PickedUpBy)
{
	local int Index, EncodedSwitch;

	Index = WeaponPickupRegistry.Find('KFDP', KFDP);
	
	// Shouldn't happen, but exit if so
	if (Index == INDEX_NONE)
		return;
		
	// None means that this pickup faded out
	if (PickedUpBy == None || PickedUpBy.PlayerReplicationInfo == WeaponPickupRegistry[Index].OrigOwnerPRI)
		WeaponPickupRegistry.Remove(Index, 1);
	else
	{
		EncodedSwitch = UMSMT_PlayerPickedUpOthersWeapon | (GetSellValueFor(KFDP, PickedUpBy) << 8);
		WeaponPickupRegistry[Index].KFDP = None;
		WeaponPickupRegistry[Index].CurrCarrier = PickedUpBy;
		WorldInfo.Game.BroadcastLocalized(WorldInfo.Game, class'UnofficialMod.UMSystemMessage', EncodedSwitch, PickedUpBy.PlayerReplicationInfo,
			WeaponPickupRegistry[Index].OrigOwnerPRI, WeaponPickupRegistry[Index].KFWClass);
	}
}

/** Purges entries that are no longer relevant */
function PurgePickupList()
{
	local int i;
	local PlayerController PC;
	local bool bFound;

	// Iterate backwards as we might remove entries
	for (i = WeaponPickupRegistry.Length - 1;i >= 0;i--)
	{
		// Check if pickup is active
		if (WeaponPickupRegistry[i].KFDP != None || WeaponPickupRegistry[i].CurrCarrier == None)
			continue;
			
		PC = WeaponPickupRegistry[i].CurrCarrier;
		if (PC.Pawn == None || PC.Pawn.InvManager == None)
			// Player died and didn't drop this
			// weapon, so remove from registry
			WeaponPickupRegistry.Remove(i, 1);
		else
		{
			// Check current inventory as player
			// might have sold this weapon
			bFound = (PC.Pawn.InvManager.FindInventoryType(WeaponPickupRegistry[i].KFWClass) != None);
			
			// Check for dual class
			if (!bFound && WeaponPickupRegistry[i].KFWClass.default.DualClass != None)
				bFound = (PC.Pawn.InvManager.FindInventoryType(WeaponPickupRegistry[i].KFWClass.default.DualClass) != None);

			if (!bFound)
				WeaponPickupRegistry.Remove(i, 1);
		}
	}
}

/** Get dosh value for passed pickup */
function int GetSellValueFor(KFDroppedPickup KFDP, PlayerController PC)
{
	local KFGameReplicationInfo KFGRI;
	local KFInventoryManager KFIM;
	local byte ItemIndex;
	local KFGFxObject_TraderItems.STraderItem TraderItem;
	
	// Shouldn't happen, but check anyways
	if (KFGameReplicationInfo(WorldInfo.GRI) == None || PC.Pawn == None || KFInventoryManager(PC.Pawn.InvManager) == None)
		return 0;
		
	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	KFIM = KFInventoryManager(PC.Pawn.InvManager);

	if (!KFGRI.TraderItems.GetItemIndicesFromArche(ItemIndex, KFDP.InventoryClass.name))
		return 0;
		
	TraderItem = KFGRI.TraderItems.SaleItems[ItemIndex];
	return KFIM.GetAdjustedSellPriceFor(TraderItem);
}

defaultproperties
{
}