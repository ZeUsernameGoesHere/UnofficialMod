//================================================
// KFAutoPurchaseHelper_UM
//================================================
// Modified purchase helper for Unofficial Mod
// Can disable weapon upgrades and fixes a couple
// of ammo bugs in the Trader UI
//================================================
// (c) 2018 "Insert Name Here"
//================================================
class KFAutoPurchaseHelper_UM extends KFAutoPurchaseHelper within KFPlayerController;

/** UMClientConfig instance */
var UMClientConfig ClientConfig;

function Initialize(optional bool bInitOwnedItems = true)
{
	super.Initialize(bInitOwnedItems);

	ClientConfig = class'UnofficialMod.UMClientConfig'.static.GetInstance();
}

/** Override this to check for disabled weapon upgrades */
function bool CanUpgrade(STraderItem SelectedItem, out int CanCarryIndex, out int bCanAffordIndex, optional bool bPlayDialog)
{
	local bool bReturn;
	
	bReturn = super.CanUpgrade(SelectedItem, CanCarryIndex, bCanAffordIndex, bPlayDialog);
	return (bReturn ? ClientConfig.IsWeaponUpgradeAllowed(SelectedItem) : false);
}

/** Override this to do Trader UI modifications for some items
	Fixes ammo bugs for weapons like M16/M203 and C4
	NOTE: We cannot override AddWeaponToOwnedItemList() because
	it uses the private function AddTransactionAmmo() */
function int AddItemByPriority( out SItemInformation WeaponInfo )
{
	local byte i;
	local byte WeaponGroup, WeaponPriority;
	local byte BestIndex;

	BestIndex = 0;
	WeaponGroup = WeaponInfo.DefaultItem.InventoryGroup;
	WeaponPriority = WeaponInfo.DefaultItem.GroupPriority;
	for( i = 0; i < OwnedItemList.length; i++ )
	{
		//Receiving a single for a dual we already own (Ex: Weapon thrown at the player)
		if (WeaponInfo.DefaultItem.DualClassName == OwnedItemList[i].DefaultItem.ClassName)
		{
			MergeSingleIntoDual(OwnedItemList[i], WeaponInfo);
			return i;
		}

		// If the weapon belongs in the group prior to the current weapon, we've found the spot
		if( WeaponGroup < OwnedItemList[i].DefaultItem.InventoryGroup )
		{
			BestIndex = i;
			break;
		}
		else if( WeaponGroup == OwnedItemList[i].DefaultItem.InventoryGroup )
		{
			if( WeaponPriority > OwnedItemList[i].DefaultItem.GroupPriority )
			{
				// if the weapon is in the same group but has a higher priority, we've found the spot
				BestIndex = i;
				break;
			}
			else if( WeaponPriority == OwnedItemList[i].DefaultItem.GroupPriority &&
				WeaponInfo.DefaultItem.AssociatedPerkClasses.Find(CurrentPerk.Class) != INDEX_NONE )
			{
				// if the weapons have the same priority give the slot to the on perk weapon
				BestIndex = i;
				break;
			}
		}
		else
		{
			// Covers the case if this weapon is the only item in the last group
			BestIndex = i + 1;
		}
	}
	
	// Here is where we put our modifications as necessary
	ModifyOwnedWeaponInfo( WeaponInfo, WeaponInfo.DefaultItem);

	OwnedItemList.InsertItem( BestIndex, WeaponInfo );

	// Add secondary ammo immediately after the main weapon
	if( WeaponInfo.DefaultItem.WeaponDef.static.UsesSecondaryAmmo() )
   	{
   		WeaponInfo.bIsSecondaryAmmo = true;
		WeaponInfo.SellPrice = 0;
		OwnedItemList.InsertItem( BestIndex + 1, WeaponInfo );
   	}

	if( MyGfxManager != none && MyGfxManager.TraderMenu != none )
	{
		MyGfxManager.TraderMenu.OwnedItemList = OwnedItemList;
	}

   	return BestIndex;
}

/** Modify the passed weapon information as needed
	This fixes ammo bugs for some weapons */
simulated function ModifyOwnedWeaponInfo(out SItemInformation WeaponInfo, const out STraderItem DefaultItem)
{
	local class<KFWeaponDefinition> KFWeapDef;
	local KFGFxObject_TraderItems.STraderItem TempTraderItem;

	// Only Demo for now
	if (KFPerk_Demolitionist(CurrentPerk) != None)
	{
		if (DefaultItem.ClassName == 'KFWeap_AssaultRifle_M16M203_UM')
		{
			// Passive ammo/Extra Ammo perk skill for M16 part of M16/M203
			KFWeapDef = class'KFGame.KFWeapDef_M16M203';
		}
		else if (DefaultItem.ClassName == 'KFWeap_Thrown_C4_UM')
		{
			// Extra Ammo perk skill
			if (KFPerk_Demolitionist(CurrentPerk).IsAmmoActive())
				KFWeapDef = class'KFGame.KFWeapDef_C4';
		}
	}
	
	if (KFWeapDef == None)
		return;
		
	class'UnofficialMod.UMClientConfig'.static.GetCustomSTraderItemFor(KFWeapDef, TempTraderItem);

	// Reset to vanilla defaults
   	WeaponInfo.MagazineCapacity = DefaultItem.MagazineCapacity;
	CurrentPerk.ModifyMagSizeAndNumber( none, WeaponInfo.MagazineCapacity, TempTraderItem.AssociatedPerkClasses,, TempTraderItem.ClassName );

	WeaponInfo.MaxSpareAmmo = DefaultItem.MaxSpareAmmo;
	CurrentPerk.ModifyMaxSpareAmmoAmount(none, WeaponInfo.MaxSpareAmmo, TempTraderItem);
	WeaponInfo.MaxSpareAmmo +=  WeaponInfo.MagazineCapacity;

	WeaponInfo.SpareAmmoCount = DefaultItem.InitialSpareMags * DefaultItem.MagazineCapacity;
	CurrentPerk.ModifySpareAmmoAmount(none, WeaponInfo.SpareAmmoCount, TempTraderItem);
	WeaponInfo.SpareAmmoCount += WeaponInfo.MagazineCapacity;
	
	WeaponInfo.SecondaryAmmoCount = DefaultItem.InitialSecondaryAmmo;
	CurrentPerk.ModifyMagSizeAndNumber( none, WeaponInfo.MagazineCapacity, TempTraderItem.AssociatedPerkClasses, true, TempTraderItem.ClassName );
	CurrentPerk.ModifySpareAmmoAmount( none, WeaponInfo.SecondaryAmmoCount, TempTraderItem, true );

	WeaponInfo.MaxSecondaryAmmo = DefaultItem.MaxSecondaryAmmo;
	CurrentPerk.ModifyMaxSpareAmmoAmount( none, WeaponInfo.MaxSecondaryAmmo, TempTraderItem, true );
}

defaultproperties
{
}