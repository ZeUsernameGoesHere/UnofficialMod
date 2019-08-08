//================================================
// KFWeap_AssaultRifle_MedicRifleGrenadeLauncher_UM
//================================================
// Custom HM-501 Medic Grenade Launcher for Unofficial Mod
// Adds option to manually reload HM-501 with alt-fire
//================================================
// (c) 2019 "Insert Name Here"
//================================================
class KFWeap_AssaultRifle_MedicRifleGrenadeLauncher_UM extends KFWeap_AssaultRifle_MedicRifleGrenadeLauncher;

/** Whether to manually reload HM-501 */
var bool bHM501ManualReload;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	
	SetManualReload();
}

/** Set up manual reload if client has it set */
simulated function SetManualReload()
{
	local UMClientConfig UMCC;

	UMCC = class'UnofficialMod.UMClientConfig'.static.GetInstance();
	if (UMCC != None)
	{
		bHM501ManualReload = UMCC.bHM501ManualReload;
		if (Role < ROLE_Authority)
			ServerSetManualReload(bHM501ManualReload);
	}
}

reliable server function ServerSetManualReload(bool bEnabled)
{
	bHM501ManualReload = bEnabled;
}

/** Check if we can manual reload
	This bypasses the bCanceledAltAutoReload
	check in CanAltAutoReload() and also
	ignores a couple of other unnecessary checks */
simulated function bool CanAltManualReload()
{
	if(PendingFire(DEFAULT_FIREMODE) && HasAmmo(DEFAULT_FIREMODE))
		return false;

	if(!CanReload(ALTFIRE_FIREMODE))
		return false;

	return true;
}

/** Override alt-fire to reload if manual reload is desired */
simulated function AltFireMode()
{
	if (!Instigator.IsLocallyControlled())
		return;
		
	if (bHM501ManualReload && IsInState('Active') && CanAltManualReload())
		SendToAltReload();
	else
		super.AltFireMode();
}

/** Override to auto-reload only if we have manual reload disabled */
simulated function TryToAltReload()
{
	if (!bHM501ManualReload)
		super.TryToAltReload();
}

/** Allow reload key to reload HM-501 if rifle doesn't need to reload */
simulated state Active
{
	// Complete override
	simulated function bool CanReload(optional byte FireModeNum)
	{
		if (Global.CanReload(FireModeNum))
			return true;

		// Check for HM-501
		if (Global.CanReload(ALTFIRE_FIREMODE) && Instigator.IsLocallyControlled())
		{
			SendToAltReload();
			return false;
		}

		// If this attempt to reload failed try to play a idle fidget instead
		if (PendingFire(RELOAD_FIREMODE) && CanPlayIdleFidget(true))
			PlayIdleFidgetAnim();

		return false;
	}
}

defaultproperties
{
}