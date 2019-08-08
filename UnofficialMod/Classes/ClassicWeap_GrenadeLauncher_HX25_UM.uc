//================================================
// ClassicWeap_GrenadeLauncher_HX25
//================================================
// Modified Classic Mode HX-25 for Unofficial Mod
//================================================
// (c) 2019 "Insert Name Here"
//================================================
class ClassicWeap_GrenadeLauncher_HX25_UM extends KFWeap_GrenadeLauncher_HX25_UM;

// Only need to modify this so it
// isn't cross-perk with Gunslinger
defaultproperties
{
	AssociatedPerkClasses(1)=class'KFGame.KFPerk_Demolitionist'
}