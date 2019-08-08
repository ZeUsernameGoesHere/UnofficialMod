//================================================
// KFGFxMenu_Trader_UM
//================================================
// Modified Trader menu for Unofficial Mod
// Can disable weapon upgrades
//================================================
// (c) 2018 "Insert Name Here"
//================================================
class KFGFxMenu_Trader_UM extends KFGFxMenu_Trader;

/** Disable weapon upgrades */
var bool bDisableWeaponUpgrades;

function InitializeMenu( KFGFxMoviePlayer_Manager InManager )
{
	super.InitializeMenu(InManager);

	bDisableWeaponUpgrades = class'UnofficialMod.UMClientConfig'.static.GetInstance().bDisableWeaponUpgrades;
}

/** Override this to check for disabled weapon upgrades */
function Callback_UpgradeItem()
{
	// We don't check UMClientConfig.IsWeaponUpgradeAllowed() as
	// KFAutoPurchaseHelper_UM and KFGFxTraderContainer_ItemDetails_UM
	// handle the relevant upgrade stuff
	if (!bDisableWeaponUpgrades)
		super.Callback_UpgradeItem();
}

defaultproperties
{
	// Override the Item Details panel and Store container
	SubWidgetBindings.Remove((WidgetName="itemDetailsContainer",WidgetClass=class'KFGFxTraderContainer_ItemDetails'))
	SubWidgetBindings.Add((WidgetName="itemDetailsContainer",WidgetClass=class'UnofficialMod.KFGFxTraderContainer_ItemDetails_UM'))
	
	SubWidgetBindings.Remove((WidgetName="shopContainer",WidgetClass=class'KFGFxTraderContainer_Store'))
	SubWidgetBindings.Add((WidgetName="shopContainer",WidgetClass=class'UnofficialMod.KFGFxTraderContainer_Store_UM'))
}