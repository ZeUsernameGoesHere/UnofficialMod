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

/** Custom STraderItem, used to fix ammo bugs */
var KFGFxObject_TraderItems.STraderItem CustomSTraderItem;

simulated event PreBeginPlay()
{
	// Do this first, because KFWeapon's PreBeginPlay()
	// initializes ammo capacity
	class'UnofficialMod.UMClientConfig'.static.GetCustomSTraderItemFor(class'KFGame.KFWeapDef_M16M203', CustomSTraderItem);

	super.PreBeginPlay();
}

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
	// Copy/paste modified
	local KFPerk CurrentPerk;

	InitializeAmmoCapacity();

	AmmoCount[0] = MagazineCapacity[0];
	AmmoCount[1] = MagazineCapacity[1];

	AddAmmo(default.InitialSpareMags[0] * default.MagazineCapacity[0]);

	CurrentPerk = GetPerk();
	if (CurrentPerk != none)
	{
		// Hard check for Demo to use custom STraderItem
		if (KFPerk_Demolitionist(CurrentPerk) != None)
			CurrentPerk.ModifySpareAmmoAmount(None, SpareAmmoCount[DEFAULT_FIREMODE], CustomSTraderItem);
		else
			CurrentPerk.ModifySpareAmmoAmount(self, SpareAmmoCount[DEFAULT_FIREMODE]);

		CurrentPerk.ModifySpareAmmoAmount(self, SpareAmmoCount[ALTFIRE_FIREMODE], , true);
	}

	// HACK: Finalize our spare ammo values
	AddAmmo(0);

	bForceNetUpdate	= TRUE;
	
	// Copy/paste from super
	// Add Secondary ammo to our secondary spare ammo count both of these are important, in order to allow dropping the weapon to function properly.
	SpareAmmoCount[1]	= Min(SpareAmmoCount[1] + InitialSpareMags[1] * default.MagazineCapacity[1], GetMaxAmmoAmount(1) - AmmoCount[1]);
	ServerTotalAltAmmo += SpareAmmoCount[1];

	// Make sure the server doesn't get extra shots on listen servers.
	if(Role == ROLE_Authority && !Instigator.IsLocallyControlled())
		ServerTotalAltAmmo += AmmoCount[1];
}

/** Same as above */
simulated function ModifySpareAmmoCapacity(out int InSpareAmmo, optional int FireMode = DEFAULT_FIREMODE, optional int UpgradeIndex = INDEX_NONE, optional KFPerk CurrentPerk)
{
	// Copy/paste modified
	if (FireMode == BASH_FIREMODE)
		return;

	InSpareAmmo = GetUpgradedSpareAmmoCapacity(FireMode, UpgradeIndex);

	if (CurrentPerk == none)
		CurrentPerk = GetPerk();

	if (CurrentPerk != none)
	{
		// Hard check for Demo to use custom STraderItem
		if (KFPerk_Demolitionist(CurrentPerk) != None)
			CurrentPerk.ModifyMaxSpareAmmoAmount(None, InSpareAmmo, CustomSTraderItem, FireMode == ALTFIRE_FIREMODE);
		else
			CurrentPerk.ModifyMaxSpareAmmoAmount(self, InSpareAmmo,, FireMode == ALTFIRE_FIREMODE);
	}
}

defaultproperties
{
}