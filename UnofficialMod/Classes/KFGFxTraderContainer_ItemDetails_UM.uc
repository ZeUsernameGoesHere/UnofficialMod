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

/** Unofficial Mod to vanilla WeaponDefs
	Used to fix Trader UI ammo bugs */
struct WeaponDefConv
{
	/** UM WeaponDef */
	var class<KFWeaponDefinition> UMWeapDef;
	/** Vanilla WeaponDef */
	var class<KFWeaponDefinition> KFWeapDef;
};

/** WeaponDef conversion list */
var const array<WeaponDefConv> WeaponDefConvList;

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
	local int FinalMagazineCapacity;
	local Float DamageValue;
	local Float NextDamageValue;
	local KFGFxObject_TraderItems.STraderItem TempTraderItem;

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
		// Get custom STraderItem if necessary
		GetSTraderItem(TraderItem, TempTraderItem);

		FinalMaxSpareAmmoCount = TempTraderItem.MaxSpareAmmo;
		FinalMagazineCapacity = TempTraderItem.MagazineCapacity;

		CurrentPerk.ModifyMagSizeAndNumber(none, FinalMagazineCapacity, TempTraderItem.AssociatedPerkClasses,, TempTraderItem.ClassName);

		// When a perk calculates total available weapon ammo, it expects MaxSpareAmmo+MagazineCapacity
		CurrentPerk.ModifyMaxSpareAmmoAmount(none, FinalMaxSpareAmmoCount, TempTraderItem,);

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

/** Get STraderItem for this WeaponDef,
	converting from UM to vanilla if necessary */
function GetSTraderItem(const out STraderItem OrigTraderItem, out STraderItem TraderItem)
{
	local int Index;

	Index = WeaponDefConvList.Find('UMWeapDef', OrigTraderItem.WeaponDef);
	
	if (Index != INDEX_NONE)
		class'UnofficialMod.UMClientConfig'.static.GetCustomSTraderItemFor(WeaponDefConvList[Index].KFWeapDef, TraderItem);
	else
		TraderItem = OrigTraderItem;
}

defaultproperties
{
	// WeaponDef conversions
	// C4
	WeaponDefConvList.Add((UMWeapDef=class'UnofficialMod.KFWeapDef_C4_UM',KFWeapDef=class'KFGame.KFWeapDef_C4'))
	// M16-M203
	WeaponDefConvList.Add((UMWeapDef=class'UnofficialMod.KFWeapDef_M16M203_UM',KFWeapDef=class'KFGame.KFWeapDef_M16M203'))
}