//================================================
// KFGFxTraderContainer_Store_UM
//================================================
// Custom Trader Store widget for Unofficial Mod
// Removes filtering for content-locked weapons
//================================================
// (c) 2018 "Insert Name Here"
//================================================
class KFGFxTraderContainer_Store_UM extends KFGFxTraderContainer_Store;

/** Copy/paste modified to not check and
	filter weapons that are content-locked */
function bool IsItemFiltered(STraderItem Item, optional bool bDebug)
{
	local KFAutoPurchaseHelper KFAPH;
	
	KFAPH = KFPC.GetPurchaseHelper();
	
	return (KFAPH.IsInOwnedItemList(Item.ClassName) || KFAPH.IsInOwnedItemList(Item.DualClassName) || !KFAPH.IsSellable(Item));
}

defaultproperties
{
}