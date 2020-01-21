//================================================
// KFDroppedPickup_UM_IonThruster
//================================================
// Custom dropped weapon pickup for Unofficial Mod
// Used for Ion Thruster's ultimate charge
//================================================
// (c) 2019 "Insert Name Here"
//================================================
class KFDroppedPickup_UM_IonThruster extends KFDroppedPickup_UM;

/** Ultimate charge */
function CustomUpdateInfo(KFWeapon KFW)
{
	MagazineAmmo[0] = int(KFWeap_Edged_IonThruster(KFW).UltimateCharge);
}

/** Ultimate charge */
simulated function string GetAmmoText()
{
	if (AmmoText == "" && MagazineAmmo[0] >= 0)
			AmmoText = MagazineAmmo[0] $ "%";

	return AmmoText;
}

defaultproperties
{
}