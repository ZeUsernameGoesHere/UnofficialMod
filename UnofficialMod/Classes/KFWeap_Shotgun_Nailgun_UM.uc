//================================================
// KFWeap_Shotgun_Nailgun_UM
//================================================
// Modified VLAD-1000 for Unofficial Mod
//================================================
// (c) 2018 "Insert Name Here"
//================================================
class KFWeap_Shotgun_Nailgun_UM extends KFWeap_Shotgun_Nailgun;

defaultproperties
{
	/* This increased magazine capacity compensates
		for the VLAD-1000 now shooting 8 nails per
		burst shot, ensuring 6 full bursts per mag
		I don't adjust the spare ammo capacity
		because the default of 336 is evenly
		divisible by both 42 and 48*/
	MagazineCapacity[0]=48
}