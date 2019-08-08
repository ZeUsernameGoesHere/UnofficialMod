//================================================
// KFWeap_Thrown_C4_UM
//================================================
// Modified C4 for Unofficial Mod
// Alt-fire switches to special Targeted mode
// allowing player to lock on to and explode
// a specific planted C4
//================================================
// (c) 2018 "Insert Name Here"
//================================================
class KFWeap_Thrown_C4_UM extends KFWeap_Thrown_C4;

/** A lot of the lock-on code is taken from KFGameContent.KFWeap_MedicBase
	and modified for simpler lock-on mechanics */

/** What C4 we're locked on to */
var KFProj_Thrown_C4 CurrentLockedC4;

/** What C4 we're locking on to */
var KFProj_Thrown_C4 PendingLockedC4;

/** The frequency with which we will check for a lock */
var const float LockCheckTime;

/** How far out should we be considering actors for a lock */
var const float LockRange;

/** How long does the player need to target an actor to lock on to it*/
var const float LockAcquireTime;

/** Once locked, how long can the player go without painting the object before they lose the lock */
var const float LockTolerance;

/** When true, this weapon is locked on target */
var bool bLockedOnTarget;

/** angle for locking for lock targets */
var const float LockAim;

/** Lock range squared */
var float LockRangeSq;

/** Sound Effects to play when Locking */
var AkBaseSoundObject LockAcquiredSoundFirstPerson;
var AkBaseSoundObject LockTargetingSoundFirstPerson;

/** If true, weapon will try to lock onto targets */
var bool bTargetLockingActive;

/** How much time is left before pending lock-on can be acquired */
var float PendingLockAcquireTimeLeft;
/** How much time is left before pending lock-on is lost */
var float PendingLockTimeout;
/** How much time is left before lock-on is lost */
var float LockedOnTimeout;

/** Locked on C4 texture for HUD */
var const Texture2D LockOnC4Texture;

/** Colors for above texture */
var const Color PendingLockColor, LockedOnColor;

/** Ideal locked on C4 texture size */
var const float LockOnC4IconSize;

replication
{
	if (bNetDirty && Role == ROLE_Authority)
		CurrentLockedC4, PendingLockedC4;
}

simulated event PreBeginPlay()
{
	super.PreBeginPlay();

	LockRangeSq = Square(LockRange);
}

/** Draw custom targeting icons */
simulated function DrawHUD(HUD H, Canvas C)
{
	local KFProj_Thrown_C4 CurrentC4;
	local Color IconColor;
	local vector ScreenPos;
	local float IconSize;

	if (Instigator.Controller == None)
		return;

	// Are we in Targeted mode and have a locked-on C4?
	if (!bUseAltFireMode || (PendingLockedC4 == None && CurrentLockedC4 == None))
		return;
	
	if (CurrentLockedC4 != None)
	{
		CurrentC4 = CurrentLockedC4;
		IconColor = LockedOnColor;
	}
	else
	{
		CurrentC4 = PendingLockedC4;
		IconColor = PendingLockColor;
	}
	
	ScreenPos = C.Project(CurrentC4.ChargeMesh.GetPosition());
	if (ScreenPos.X < 0 || ScreenPos.X > C.ClipX || ScreenPos.Y < 0 || ScreenPos.Y > C.ClipY)
		return;

	IconSize = WorldInfo.static.GetResolutionBasedHUDScale() * LockOnC4IconSize;
	
	C.EnableStencilTest(true);
	C.DrawColor = IconColor;
	C.SetPos(ScreenPos.X - (IconSize / 2.0), ScreenPos.Y - (IconSize / 2.0));
	C.DrawTile(LockOnC4Texture, IconSize, IconSize, 0, 0, 256, 256);
	C.EnableStencilTest(false);
}

/** Sets the new locked C4 */
function AdjustLockTarget(KFProj_Thrown_C4 NewC4)
{
	if (CurrentLockedC4 == NewC4)
		return;
		
	if (NewC4 == None)
	{
		// Clear the locked C4
		bLockedOnTarget = false;
		CurrentLockedC4 = None;
	}
	else
	{
		bLockedOnTarget = true;
		CurrentLockedC4 = NewC4;
		
		ClientPlayTargetingSound(LockAcquiredSoundFirstPerson);
	}
}

/** Is this weapon allowed to lock on? */
function bool AllowTargetLockOn()
{
	// Alt-fire switches to Targeted mode, so we check that here
	return !Instigator.bNoWeaponFiring || !bUseAltFireMode;
}

/** Check to see if we are locked on to a C4 */
function CheckTargetLock()
{
	local KFProj_Thrown_C4 BestC4, CheckC4;
	local vector ViewLoc, ViewVec;
	local rotator ViewRot;
	local float C4Dot, BestDot;
	
	// Basic checks first
	if (Instigator == None || Instigator.Controller == None || Self != Instigator.Weapon)
		return;

	if (!AllowTargetLockOn())
	{
		AdjustLockTarget(None);
		PendingLockedC4 = None;
		return;
	}

	// Check if our locked C4 has been destroyed (e.g. Siren screams)
	if (CurrentLockedC4 != None && CurrentLockedC4.bDeleteMe)
		AdjustLockTarget(None);
	
	// Do we have any C4 out that we can target?
	if (NumDeployedCharges == 0)
		return;
		
	Instigator.Controller.GetPlayerViewPoint(ViewLoc, ViewRot);
	ViewVec = vector(ViewRot);
	BestDot = LockAim;

	// This is a significantly simpler version
	// of KFWeap_MedicBase's CheckTargetLock() that
	// only checks among already placed C4
	foreach DeployedCharges(CheckC4)
	{
		// We only target C4 that has been stuck to something
		// This makes it a little more difficult to accidentally
		// blow yourself up just after throwing a C4
		if (CheckC4.StuckToActor == None)
			continue;

		C4Dot = Normal(CheckC4.Location - ViewLoc) dot ViewVec;
		
		// More precise, in range, and in line of sight
		if (C4Dot > BestDot && VSizeSq(CheckC4.Location - ViewLoc) <= LockRangeSq && FastTrace(CheckC4.Location, ViewLoc, , true))
		{
			BestC4 = CheckC4;
			BestDot = C4Dot;
		}
	}

	if (BestC4 != None)
	{
		// Found one, check everything else
		if (BestC4 == CurrentLockedC4)
			// Still locked on
			LockedOnTimeout = LockTolerance;
		else if (BestC4 != PendingLockedC4)
		{
			// New pending lock-on
			PendingLockedC4 = BestC4;
			PendingLockTimeout = LockTolerance;
			PendingLockAcquireTimeLeft = LockAcquireTime;

			ClientPlayTargetingSound(LockTargetingSoundFirstPerson);
		}
		
		// Acquire new target C4 if pending lock-on for long enough
		if (PendingLockedC4 != None)
		{
			PendingLockAcquireTimeLeft -= LockCheckTime;
			if (PendingLockedC4 == BestC4 && PendingLockAcquireTimeLeft <= 0.0)
			{
				AdjustLockTarget(BestC4);
				PendingLockedC4 = None;
			}
		}
	}
	else if (PendingLockedC4 != None)
	{
		// Lost target, attempt to invalidate current pending lock-on
		PendingLockTimeout -= LockCheckTime;
		if (PendingLockTimeout <= 0.0 || PendingLockedC4.bDeleteMe)
			PendingLockedC4 = None;
	}
	
	// If new best C4 is different, try to invalidate old best C4
	if (CurrentLockedC4 != None && CurrentLockedC4 != BestC4)
	{
		LockedOnTimeout -= LockCheckTime;
		if (LockedOnTimeout <= 0.0 || CurrentLockedC4.bDeleteMe)
			AdjustLockTarget(None);
	}
}

/** Plays first person targeting sounds */
unreliable client function ClientPlayTargetingSound(AkBaseSoundObject Sound)
{
	if (Sound != None && !bSuppressSounds && Instigator != None && Instigator.IsHumanControlled())
		PlaySoundBase(Sound, true);
}

/** Inactive state here to set/remove target locking as needed */
auto simulated state Inactive
{
	simulated function BeginState(name PreviousStateName)
	{
		super.BeginState(PreviousStateName);

		// We don't check for Targeted mode active
		// because it's harmless to do this anyways
		if (Role == ROLE_Authority)
		{
			AdjustLockTarget(None);
			ClearTimer(nameof(CheckTargetLock));
		}

		// force stop beep/lock
		PendingLockedC4 = None;
	}

	simulated function EndState(Name NextStateName)
	{
		super.EndState(NextStateName);

		// Here we check for Targeted mode
		if (Role == ROLE_Authority && bUseAltFireMode)
			SetTimer(LockCheckTime, true, nameof(CheckTargetLock));
	}
}

/** Ignore locking on when sprinting */
simulated state WeaponSprinting
{
	ignores AllowTargetLockOn;
}

/** Override alt-fire to switch between Sequential and Targeted mode */
simulated function AltFireMode()
{
	// KFWeapon's version does exactly what we want
	super(KFWeapon).AltFireMode();
	
	// Because alt-fire mode setting is only applicable
	// to clients and isn't replicated to the dedicated
	// server, we have to replicate the value manually
	// to get Targeted mode to work correctly
	if (Role == ROLE_Authority)
		CheckAltFireMode();
	else
		ServerSetAltFireMode(bUseAltFireMode);
}

/** Check alt-fire mode and enable/disable timer as necessary */
simulated function CheckAltFireMode()
{
	if (bUseAltFireMode)
		SetTimer(LockCheckTime, true, nameof(CheckTargetLock));
	else
	{
		ClearTimer(nameof(CheckTargetLock));
		AdjustLockTarget(None);
		PendingLockedC4 = None;
	}
}

/** Set alt-fire mode for server */
reliable server function ServerSetAltFireMode(bool bAltFire)
{
	bUseAltFireMode = bAltFire;
	CheckAltFireMode();
}

/** Override for Targeted mode */
simulated function Detonate()
{
	if (!bUseAltFireMode)
	{
		super.Detonate();
		return;
	}

	// Auto switch weapon when out of ammo and after detonating the last deployed charge
	if(Role == ROLE_Authority)
	{
		if(CurrentLockedC4 != None)
		{
			CurrentLockedC4.Detonate();
			AdjustLockTarget(None);
		}

		if(!HasAnyAmmo() && NumDeployedCharges == 0 && CanSwitchWeapons())
	        Instigator.Controller.ClientSwitchToBestWeapon(false);
	}
}

/** Override for Targeted mode */
simulated function PrepareAndDetonate()
{
	local name DetonateAnimName;
	local float AnimDuration;
	local bool bInSprintState;

	if (!bUseAltFireMode)
	{
		super.PrepareAndDetonate();
		return;
	}

	DetonateAnimName = ShouldPlayLastAnims() ? DetonateLastAnim : DetonateAnim;
	AnimDuration = MySkelMesh.GetAnimLength(DetonateAnimName);
	bInSprintState = IsInState('WeaponSprinting');

	if(WorldInfo.NetMode != NM_DedicatedServer)
	{
		if(CurrentLockedC4 != None)
			PlaySoundBase(DetonateAkEvent, true);
		else
			PlaySoundBase(DryFireAkEvent, true);

		if(bInSprintState)
		{
			AnimDuration *= 0.25f;
			PlayAnimation(DetonateAnimName, AnimDuration);
		}
		else
			PlayAnimation(DetonateAnimName);
	}

	if (CurrentLockedC4 != None)
	{
		if(Role == ROLE_Authority)
			Detonate();

		IncrementFlashCount();
	}

	if(bInSprintState)
		SetTimer(AnimDuration * 0.8f, false, nameof(PlaySprintStart));
	else
		SetTimer(AnimDuration * 0.5f, false, nameof(GotoActiveState));
}

/** Fixes a bug that grants extra current/spare ammo to C4 with Extra Ammo perk skill
	This is due to the superclass being excluded from this modification in the
	perk, but since it relies on exact class name, this one isn't excluded
	NOTE: this doesn't work for the weapon in the Trader UI when initially bought,
	only for in-game amounts. Other classes handle the Trader UI bugs */
simulated function InitializeAmmoCapacity(optional int UpgradeIndex = INDEX_NONE, optional KFPerk CurrentPerk)
{
	super.InitializeAmmoCapacity(UpgradeIndex, CurrentPerk);

	if (KFPerk_Demolitionist(GetPerk()) != None && KFPerk_Demolitionist(GetPerk()).IsAmmoActive())
	{
		SpareAmmoCapacity[0] -= 5;
		AddAmmo(0);
		bForceNetUpdate = true;
	}
}

defaultproperties
{
	// 100m range, with same targeting precision as HMTech weapons
	LockRange=10000
	LockAim=0.98
	LockChecktime=0.1
	LockAcquireTime=0.2
	LockTolerance=0.2

	LockAcquiredSoundFirstPerson=AkEvent'WW_WEP_SA_MedicDart.Play_WEP_SA_Medic_Alert_Locked_1P'
	LockTargetingSoundFirstPerson=AkEvent'WW_WEP_SA_MedicDart.Play_WEP_SA_Medic_Alert_Locking_1P'
	
	// Alt-fire throws C4 just like default fire
	// Only difference is in targeting/detonation
	FireInterval(ALTFIRE_FIREMODE)=0.25
	FireModeIconPaths(ALTFIRE_FIREMODE)=Texture2D'UI_SecondaryAmmo_TEX.UI_FireModeSelect_AutoTarget'
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'KFProj_Thrown_C4'
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponThrowing
	AmmoCost(ALTFIRE_FIREMODE)=1
	
	LockOnC4Texture=Texture2D'UI_PerkIcons_TEX.UI_PerkIcon_Demolition'
	PendingLockColor=(R=92, G=92, B=92, A=192)
	LockedOnColor=(R=255, G=0, B=0, A=192)
	LockOnC4IconSize=32
}