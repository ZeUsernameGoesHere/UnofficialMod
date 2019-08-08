//================================================
// KFGFxMoviePlayer_Manager_Versus_UM
//================================================
// Modified GFx Manager for Unofficial Mod
// This one is for Versus mode
//================================================
// (c) 2018 "Insert Name Here"
//================================================
class KFGFxMoviePlayer_Manager_Versus_UM extends KFGFxMoviePlayer_Manager_Versus
	config(UI);

defaultproperties
{
	// Just override the Trader UI
	WidgetBindings.Remove((WidgetName="traderMenu",WidgetClass=class'KFGFxMenu_Trader'))
	WidgetBindings.Add((WidgetName="traderMenu",WidgetClass=class'UnofficialMod.KFGFxMenu_Trader_UM'))
}