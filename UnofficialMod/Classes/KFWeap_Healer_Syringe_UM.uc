//================================================
// KFWeap_Healer_Syringe_UM
//================================================
// Modified Syringe for Unofficial Mod
// Uses KF1-like mechanics (use 50% charge
// to heal teammates and 15sec charge
// regardless of heal mode used)
//================================================
// (c) 2018 "Insert Name Here"
//================================================

class KFWeap_Healer_Syringe_UM extends KFWeap_Healer_Syringe;

defaultproperties
{
	AmmoCost(DEFAULT_FIREMODE)=50
	HealOtherRechargeSeconds=15
	
	// We have to copy/paste this here from the superclass to
	// avoid "Graph is linked to external private object" warning
	Begin Object Name=FirstPersonMesh
		Animations=AnimTree'CHR_1P_Arms_ARCH.WEP_1stP_Animtree_Healer'
	End Object
}