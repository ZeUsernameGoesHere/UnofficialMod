//================================================
// KFWeap_Rifle_M14EBR_UM
//================================================
// Modified M14 EBR for Unofficial Mod
// Allows player to toggle laser sight with alt-fire
//================================================
// (c) 2018 "Insert Name Here"
//================================================
class KFWeap_Rifle_M14EBR_UM extends KFWeap_Rifle_M14EBR;

/** Whether the laser sight is currently enabled */
var bool bIsLaserSightEnabled;

/** Whether this weapon was created from a pickup
	Used to ensure that the laser sight is set properly */
var bool bIsFromPickup;

simulated function AttachLaserSight()
{
	local UMClientConfig UMCC;
	local bool bEnabled;

	super.AttachLaserSight();

	// Setup our laser sight on the client
	if (bIsFromPickup)
		bEnabled = bIsLaserSightEnabled;
	else
	{
		UMCC = class'UnofficialMod.UMClientConfig'.static.GetInstance();
		bEnabled = (UMCC != None ? !UMCC.bM14EBRLaserSightDisabled : true);
	}
	
	SetLaserSightEnabled(bEnabled);
}

/** Set laser sight */
simulated function SetLaserSightEnabled(bool bEnabled, optional bool SendToServer = true)
{
	bIsLaserSightEnabled = bEnabled;

	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		if (LaserSight != None)
		{
			// We don't use LaserSight.ChangeVisibility() because
			// that hides the laser sight mesh itself
			LaserSight.LaserBeamMeshComp.SetHidden(!bIsLaserSightEnabled);
			LaserSight.LaserDotMeshComp.SetHidden(!bIsLaserSightEnabled);
			if (Role < ROLE_Authority && SendToServer)
				ServerSetLaserSight(bIsLaserSightEnabled);
		}
		else
		{
			// When this weapon is created from a pickup,
			// the laser sight isn't created yet, so just
			// let AttachLaserSight() handle it
			bIsFromPickup = true;
		}
	}
}

/** Alt-fire toggles laser sight */
simulated function AltFireMode()
{
	if (!Instigator.IsLocallyControlled())
		return;

	SetLaserSightEnabled(!bIsLaserSightEnabled);

	// Play switch fire mode sound for audio confirmation
	Instigator.PlaySoundBase(KFInventoryManager(InvManager).SwitchFireModeEvent);
}

/** Overrides from both KFWeapon and KFWeap_ScopedBase
	to prevent laser sight from updating if not enabled
	This prevents the dot from showing */
simulated event Tick(float DeltaTime)
{
	local float InterpValue;
	local float DefaultZoomInTime;

	// Copy/paste modified from KFWeapon
	if (LaserSight != None && bIsLaserSightEnabled)
		LaserSight.Update(DeltaTime, Self);
	
	// Copy/paste modified from KFWeap_ScopedBase
	if(ScopeLenseMIC == none)
		return;

	if(Instigator != none && Instigator.Controller != none && Instigator.IsHumanControlled())
	{
		if(bZoomingOut)
		{
			InterpValue = ZoomTime/default.ZoomOutTime;
			ScopeLenseMIC.SetScalarParameterValue(InterpParamName, InterpValue);
		}
		else if(bZoomingIn)
		{
			DefaultZoomInTime = default.ZoomInTime;
			InterpValue = -ZoomTime/DefaultZoomInTime + 1;
			ScopeLenseMIC.SetScalarParameterValue(InterpParamName, InterpValue);
		}
	}
}

/** Transfers laser sight setting to server for dropped weapon pickup purposes */
reliable server function ServerSetLaserSight(bool bEnabled)
{
	bIsLaserSightEnabled = bEnabled;
}

/** Transfers laser sight setting to client when picking up dropped weapon */
reliable client function ClientSetLaserSight(bool bEnabled)
{
	if (Role < ROLE_Authority)
		SetLaserSightEnabled(bEnabled, false);
}

/** Transfer laser sight setting to client */
function SetOriginalValuesFromPickup(KFWeapon PickedUpWeapon)
{
	super.SetOriginalValuesFromPickup(PickedUpWeapon);
	SetLaserSightEnabled(KFWeap_Rifle_M14EBR_UM(PickedUpWeapon).bIsLaserSightEnabled);
	ClientSetLaserSight(bIsLaserSightEnabled);
}

defaultproperties
{
	bIsLaserSightEnabled=true
}