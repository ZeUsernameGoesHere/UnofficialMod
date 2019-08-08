//================================================
// KFWeap_GrenadeLauncher_HX25
//================================================
// Modified HX-25 for Unofficial Mod
// Alt-fire fires whole grenade instead of pellets
//================================================
// (c) 2019 "Insert Name Here"
//================================================
class KFWeap_GrenadeLauncher_HX25_UM extends KFWeap_GrenadeLauncher_HX25;

/** Fire whole grenade on alt-fire */
simulated function AltFireMode()
{
	if (!Instigator.IsLocallyControlled())
		return;

	StartFire(ALTFIRE_FIREMODE);
}

defaultproperties
{
	// Alt-fire
	// NOTE: the projectile and damage type
	// are in the SDK code but unused
	FireModeIconPaths(ALTFIRE_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_Grenade'
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFireAndReload
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'KFGameContent.KFProj_Explosive_HX25'
	InstantHitDamage(ALTFIRE_FIREMODE)=100.0 // Arbitrary damage value
	InstantHitDamageTypes(ALTFIRE_FIREMODE)=class'KFGameContent.KFDT_Ballistic_HX25Impact'
	Spread(ALTFIRE_FIREMODE)=0.1f
	FireInterval(ALTFIRE_FIREMODE)=0.25
	NumPellets(ALTFIRE_FIREMODE)=1

	// Same as primary
	WeaponFireSnd(ALTFIRE_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_SA_HX25.Play_WEP_SA_HX25_Fire_3P', FirstPersonCue=AkEvent'WW_WEP_SA_HX25.Play_WEP_SA_HX25_Fire_1P')
	WeaponDryFireSnd(ALTFIRE_FIREMODE)=None

	// Override these to account for alt-fire
	// We just use the same scale from primary
	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.25f), (Stat=EWUS_Damage1, Scale=1.25f), (Stat=EWUS_Weight, Add=1)))
	WeaponUpgrades[2]=(Stats=((Stat=EWUS_Damage0, Scale=1.4f), (Stat=EWUS_Damage1, Scale=1.4f), (Stat=EWUS_Weight, Add=2)))
	WeaponUpgrades[3]=(Stats=((Stat=EWUS_Damage0, Scale=1.6f), (Stat=EWUS_Damage1, Scale=1.6f), (Stat=EWUS_Weight, Add=3)))
	WeaponUpgrades[4]=(Stats=((Stat=EWUS_Damage0, Scale=1.9f), (Stat=EWUS_Damage1, Scale=1.9f), (Stat=EWUS_Weight, Add=4)))
}