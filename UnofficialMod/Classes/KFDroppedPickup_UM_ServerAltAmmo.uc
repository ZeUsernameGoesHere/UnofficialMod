//================================================
// KFDroppedPickup_UM_ServerAltAmmo
//================================================
// Custom dropped weapon pickup for Unofficial Mod
// Used for weapons with server-tracked
// alt-ammo (e.g. M16-M203, HM-501)
//================================================
// (c) 2019 "Insert Name Here"
//================================================
class KFDroppedPickup_UM_ServerAltAmmo extends KFDroppedPickup_UM;

/** Server-tracked alt-ammo */
function CustomUpdateInfo(KFWeapon KFW)
{
	// Dedicated Server specific
	if (WorldInfo.NetMode == NM_DedicatedServer)
	{
		if (KFWeap_AssaultRifle_M16M203(KFW) != None)
			SpareAmmo[1] = KFWeap_AssaultRifle_M16M203(KFW).ServerTotalAltAmmo - MagazineAmmo[1];
		else if (KFWeap_AssaultRifle_MedicRifleGrenadeLauncher(KFW) != None)
			SpareAmmo[1] = KFWeap_AssaultRifle_MedicRifleGrenadeLauncher(KFW).ServerTotalAltAmmo - MagazineAmmo[1];
	}
}

defaultproperties
{
}