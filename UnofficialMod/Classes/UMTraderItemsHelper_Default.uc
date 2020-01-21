//================================================
// UMTraderItemsHelper_Default
//================================================
// Extended Trader Items Helper
// Used when the TraderItems is the default one
//================================================
// (c) 2019 "Insert Name Here"
//================================================
class UMTraderItemsHelper_Default extends UMTraderItemsHelper;

/** We create a custom KFGFxObject_TraderItems,
	then call the super version
	This is the simplest way to do this */
simulated function ModifyTraderList()
{
	local KFGFxObject_TraderItems DefaultTraderItems, CustomTraderItems;
	local int i;

	if (WorldInfo.GRI == None)
	{
		SetTimer(1.0, false, nameof(ModifyTraderList));
		return;
	}
	
	DefaultTraderItems = class'UnofficialMod.UMClientConfig'.static.GetDefaultTraderItems();
	CustomTraderItems = new class'KFGame.KFGFxObject_TraderItems';
	
	for (i = 0;i < DefaultTraderItems.SaleItems.Length;i++)
		CustomTraderItems.SaleItems.AddItem(DefaultTraderItems.SaleItems[i]);
		
	KFGameReplicationInfo(WorldInfo.GRI).TraderItems = CustomTraderItems;
	
	super.ModifyTraderList();
}

defaultproperties
{
}