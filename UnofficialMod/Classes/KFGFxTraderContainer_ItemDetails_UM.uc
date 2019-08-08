//================================================
// KFGFxTraderContainer_ItemDetails_UM
//================================================
// Modified Item details container for Unofficial Mod
// Can disable weapon upgrades and fixes a couple
// of ammo bugs in the Trader UI
//================================================
// (c) 2018 "Insert Name Here"
//================================================
class KFGFxTraderContainer_ItemDetails_UM extends KFGFxTraderContainer_ItemDetails;

/** UMClientConfig instance */
var UMClientConfig ClientConfig;

/** Override this to get our UMClientConfig */
function Initialize(KFGFxObject_Menu NewParentMenu)
{
	super.Initialize(NewParentMenu);
	
	ClientConfig = class'UnofficialMod.UMClientConfig'.static.GetInstance();
}

/** Override this to disable weapon upgrades and fix a couple of ammo bugs */
function SetGenericItemDetails(const out STraderItem TraderItem, out GFxObject ItemData, optional int UpgradeLevel = INDEX_NONE)
{
	local KFPerk CurrentPerk;
	local int FinalMaxSpareAmmoCount;
	local byte FinalMagazineCapacity;
	local Float DamageValue;
	local Float NextDamageValue;

	// Disable weapon upgrades if desired
	if ((KFGFxMenu_Trader_UM(MyTraderMenu) != None && KFGFxMenu_Trader_UM(MyTraderMenu).bDisableWeaponUpgrades) ||
		!ClientConfig.IsWeaponUpgradeAllowed(TraderItem))
	{
		ItemData.SetInt("upgradePrice", 0);
		ItemData.SetInt("upgradeWeight", 0);
		ItemData.SetBool("bCanUpgrade", false);
		ItemData.SetBool("bCanBuyUpgrade", false);
		ItemData.SetBool("bCanCarryUpgrade", false);
	}

	//@todo: rename flash objects to something more generic, like stat0text, stat0bar, etc.
	if( TraderItem.WeaponStats.Length >= TWS_Damage && TraderItem.WeaponStats.length > 0)
	{
		DamageValue = TraderItem.WeaponStats[TWS_Damage].StatValue * (UpgradeLevel > INDEX_NONE ? TraderItem.WeaponUpgradeDmgMultiplier[UpgradeLevel] : 1.0f);
		SetDetailsVisible("damage", true);
		SetDetailsText("damage", GetLocalizedStatString(TraderItem.WeaponStats[TWS_Damage].StatType));
		ItemData.SetInt("damageValue", DamageValue);
		ItemData.SetInt("damagePercent", (FMin(DamageValue / GetStatMax(TraderItem.WeaponStats[TWS_Damage].StatType), 1.f) ** 0.5f) * 100.f);

		if (UpgradeLevel + 1 < ArrayCount(TraderItem.WeaponUpgradeDmgMultiplier))
		{
			NextDamageValue = TraderItem.WeaponStats[TWS_Damage].StatValue * TraderItem.WeaponUpgradeDmgMultiplier[UpgradeLevel + 1];
			ItemData.SetInt("damageUpgradePercent", (FMin(NextDamageValue / GetStatMax(TraderItem.WeaponStats[TWS_Damage].StatType), 1.f) ** 0.5f) * 100.f);

		}
		//`log("THIS IS THE old DAMAGE VALUE: " @((FMin(DamageValue / GetStatMax(TraderItem.WeaponStats[TWS_Damage].StatType), 1.f) ** 0.5f) * 100.f));
		//`log("THIS IS THE NEXT DAMAGE VALUE: " @((FMin(NextDamageValue / GetStatMax(TraderItem.WeaponStats[TWS_Damage].StatType), 1.f) ** 0.5f) * 100.f));
	}
	else
	{
		SetDetailsVisible("damage", false);
	}

	if( TraderItem.WeaponStats.Length >= TWS_Penetration )
	{

		SetDetailsVisible("penetration", true);
		SetDetailsText("penetration", GetLocalizedStatString(TraderItem.WeaponStats[TWS_Penetration].StatType));
		if(TraderItem.TraderFilter != FT_Melee)
		{
			ItemData.SetInt("penetrationValue", TraderItem.WeaponStats[TWS_Penetration].StatValue);
			ItemData.SetInt("penetrationPercent", (FMin(TraderItem.WeaponStats[TWS_Penetration].StatValue / GetStatMax(TraderItem.WeaponStats[TWS_Penetration].StatType), 1.f) ** 0.5f) * 100.f);
		}
		else
		{
			SetDetailsVisible("penetration", false);
		}
	}
	else
	{
		SetDetailsVisible("penetration", false);
	}

	if( TraderItem.WeaponStats.Length >= TWS_RateOfFire )
	{
		SetDetailsVisible("fireRate", true);
		SetDetailsText("fireRate", GetLocalizedStatString(TraderItem.WeaponStats[TWS_RateOfFire].StatType));
		if(TraderItem.TraderFilter != FT_Melee)
		{
			ItemData.SetInt("fireRateValue", TraderItem.WeaponStats[TWS_RateOfFire].StatValue);
			ItemData.SetInt("fireRatePercent", FMin(TraderItem.WeaponStats[TWS_RateOfFire].StatValue / GetStatMax(TraderItem.WeaponStats[TWS_RateOfFire].StatType), 1.f) * 100.f);
		}
		else
		{
			SetDetailsVisible("fireRate", false);
		}
	}
	else
	{
		SetDetailsVisible("fireRate", false);
	}

	//actually range?
	if( TraderItem.WeaponStats.Length >= TWS_Range )
	{
		SetDetailsVisible("accuracy", true);
		SetDetailsText("accuracy", GetLocalizedStatString(TraderItem.WeaponStats[TWS_Range].StatType));
		ItemData.SetInt("accuracyValue", TraderItem.WeaponStats[TWS_Range].StatValue);
		ItemData.SetInt("accuracyPercent", FMin(TraderItem.WeaponStats[TWS_Range].StatValue / GetStatMax(TraderItem.WeaponStats[TWS_Range].StatType), 1.f) * 100.f);

	}
	else
	{
		SetDetailsVisible("accuracy", false);
	}

 	ItemData.SetString("type", TraderItem.WeaponDef.static.GetItemName());
 	ItemData.SetString("name", TraderItem.WeaponDef.static.GetItemCategory());
 	ItemData.SetString("description", TraderItem.WeaponDef.static.GetItemDescription());

	CurrentPerk = KFPlayerController(GetPC()).CurrentPerk;
	if( CurrentPerk != none )
	{
		FinalMaxSpareAmmoCount = TraderItem.MaxSpareAmmo;
		FinalMagazineCapacity = TraderItem.MagazineCapacity;

		CurrentPerk.ModifyMagSizeAndNumber(none, FinalMagazineCapacity, TraderItem.AssociatedPerkClasses,, TraderItem.ClassName);

		// When a perk calculates total available weapon ammo, it expects MaxSpareAmmo+MagazineCapacity
		CurrentPerk.ModifyMaxSpareAmmoAmount(none, FinalMaxSpareAmmoCount, TraderItem,);
		
		// Modify values here as necessary
		ModifyAmmoValues(TraderItem, CurrentPerk, FinalMagazineCapacity, FinalMaxSpareAmmoCount);

		FinalMaxSpareAmmoCount += FinalMagazineCapacity;
	}
	else
	{
		FinalMaxSpareAmmoCount = TraderItem.MaxSpareAmmo;
		FinalMagazineCapacity = TraderItem.MagazineCapacity;
	}

 	ItemData.SetInt("ammoCapacity", FinalMaxSpareAmmoCount);
 	ItemData.SetInt("magSizeValue", FinalMagazineCapacity);

	ItemData.SetInt("weight", MyTraderMenu.GetDisplayedBlocksRequiredFor(TraderItem));

	ItemData.SetBool("bIsFavorite", MyTraderMenu.GetIsFavorite(TraderItem.ClassName));

 	ItemData.SetString("texturePath", "img://"$TraderItem.WeaponDef.static.GetImagePath());
 	if( TraderItem.AssociatedPerkClasses.length > 0 && TraderItem.AssociatedPerkClasses[0] != none )
 	{
 		ItemData.SetString("perkIconPath", "img://"$TraderItem.AssociatedPerkClasses[0].static.GetPerkIconPath());
 		//secondary perk icon
 		if( TraderItem.AssociatedPerkClasses.length > 1 )
 		{
 			ItemData.SetString("perkIconPathSecondary", "img://"$TraderItem.AssociatedPerkClasses[1].static.GetPerkIconPath());
 		}
	}
	else
	{
		ItemData.SetString("perkIconPath", "img://"$class'KFGFxObject_TraderItems'.default.OffPerkIconPath);
	}

 	SetObject("itemData", ItemData);
}

/** Modifies ammo counts to fix some Trader UI bugs */
function ModifyAmmoValues(const out STraderItem TraderItem, KFPerk CurrentPerk, out byte MagCapacity, out int MaxSpareAmmo)
{
	// Only Demo for now
	if (KFPerk_Demolitionist(CurrentPerk) != None)
	{
		if (TraderItem.ClassName == 'KFWeap_AssaultRifle_M16M203_UM')
		{
			// Passive ammo for M16 part of M16/M203
			MaxSpareAmmo = TraderItem.MaxSpareAmmo;
		}
		else if (TraderItem.ClassName == 'KFWeap_Thrown_C4_UM')
		{
			// Extra Ammo perk skill
			if (KFPerk_Demolitionist(CurrentPerk).IsAmmoActive())
				MaxSpareAmmo -= 5;
		}
	}
}

defaultproperties
{
}