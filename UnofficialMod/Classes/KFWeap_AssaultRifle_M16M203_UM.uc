//================================================
// KFWeap_AssaultRifle_M16M203_UM
//================================================
// Modified M16/M203 for Unofficial Mod
// Adds option to manually reload M203 with alt-fire
//================================================
// (c) 2018 "Insert Name Here"
//================================================
class KFWeap_AssaultRifle_M16M203_UM extends KFWeap_AssaultRifle_M16M203;

/** Whether to manually reload M203 */
var bool bM203ManualReload;

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
		bM203ManualReload = UMCC.bM203ManualReload;
		if (Role < ROLE_Authority)
			ServerSetManualReload(bM203ManualReload);
	}
}

reliable server function ServerSetManualReload(bool bEnabled)
{
	bM203ManualReload = bEnabled;
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
		
	if (bM203ManualReload && IsInState('Active') && CanAltManualReload())
		SendToAltReload();
	else
		super.AltFireMode();
}

/** Override to auto-reload only if we have manual reload disabled */
simulated function TryToAltReload()
{
	if (!bM203ManualReload)
		super.TryToAltReload();
}

/** Allow reload key to reload M203 if M16 doesn't need to reload */
simulated state Active
{
	// Complete override
	simulated function bool CanReload(optional byte FireModeNum)
	{
		if (Global.CanReload(FireModeNum))
			return true;

		// Check for M203
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

/** Fixes a bug that grants extra current/spare ammo to M16 when wielded by Demo
	This is due to the superclass being excluded from this modification in the
	perk, but since it relies on exact class name, this one isn't excluded
	NOTE: this doesn't work for the weapon in the Trader UI when initially bought,
	only for in-game amounts. Other classes handle the Trader UI bugs */
function InitializeAmmo()
{
	super.InitializeAmmo();
	
	// We only do this for Demo, because other perks can modify this as well
	if (KFPerk_Demolitionist(GetPerk()) != None)
	{
		SpareAmmoCapacity[0] = default.SpareAmmoCapacity[0];
		SpareAmmoCount[0] = InitialSpareMags[0] * default.MagazineCapacity[0];
		AddAmmo(0);
		bForceNetUpdate = true;
	}
}

/** Same as above */
simulated function InitializeAmmoCapacity(optional int UpgradeIndex = INDEX_NONE, optional KFPerk CurrentPerk)
{
	super.InitializeAmmoCapacity(UpgradeIndex, CurrentPerk);

	if (KFPerk_Demolitionist(GetPerk()) != None)
	{
		SpareAmmoCapacity[0] = default.SpareAmmoCapacity[0];
		AddAmmo(0);
		bForceNetUpdate = true;
	}
}

defaultproperties
{
}