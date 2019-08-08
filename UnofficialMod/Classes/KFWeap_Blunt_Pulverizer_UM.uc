//================================================
// KFWeap_Blunt_Pulverizer_UM
//================================================
// Modified Pulverizer for Unofficial Mod
// Now single-shot with re-chamber after
// explosive hit being the reload
// Reload toggles explosive hit
// Also makes the re-chamber after an
// explosive attack 50% faster
//================================================
// (c) 2018 "Insert Name Here"
//================================================
class KFWeap_Blunt_Pulverizer_UM extends KFWeap_Blunt_Pulverizer;

/** Re-chamber anim names */
var const array<name> RechamberAnimNames;

/** Do explosive hit on heavy attack? */
var bool bExplosiveOnHeavyAttack;

/** HUD elements for disabled explosive hit */
var const Texture2D PulvNoExploBGTexture, PulvNoExploTexture;
var const color PulvNoExploBGColor, PulvNoExploTexColor, PulvNoExploLineColor;
var float PulvNoExploIconSize;
/** Relative location for no explosive icon */
var Vector2D PulvNoExploIconLocation;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();

	if (WorldInfo.NetMode != NM_DedicatedServer)
		CheckHUDType();
}

/** Check HUD type for Classic Mode */
simulated function CheckHUDType()
{
	local PlayerController PC;

	PC = GetALocalPlayerController();
	
	// Shouldn't happen, but just to be safe
	if (PC == None || PC.myHUD == None)
	{
		SetTimer(1.0, false, nameof(CheckHUDType));
		return;
	}
	
	if (PC.myHUD.IsA('KFHUDInterface'))
	{
		// Slightly smaller icon fits
		// Classic Mode HUD better
		PulvNoExploIconSize = 46;
		PulvNoExploIconLocation.X = 0.830;
		PulvNoExploIconLocation.Y = 0.935;
	}
}

/** HUD element for disabled explosive hit */
simulated function DrawHUD(HUD H, Canvas C)
{
	local float IconSize, IconX, IconY;

	// Only if explosive hit is disabled
	if (bExplosiveOnHeavyAttack)
		return;

	IconSize = PulvNoExploIconSize * (C.SizeX / 1920.0);
	
	// Above ammo counter
	IconX = C.SizeX * PulvNoExploIconLocation.X;
	IconY = C.SizeY * PulvNoExploIconLocation.Y;
	
	// Draw background
	C.DrawColor = PulvNoExploBGColor;
	C.SetPos(IconX, IconY);
	C.DrawTile(PulvNoExploBGTexture, IconSize, IconSize, 0, 0, 32, 32);
	
	// Draw icon
	C.DrawColor = PulvNoExploTexColor;
	C.SetPos(IconX, IconY);
	C.DrawTexture(PulvNoExploTexture, IconSize / 256.0);
	
	// Draw line (bottom-left to upper-right)
	C.Draw2DLine(IconX, IconY + IconSize, IconX + IconSize, IconY, PulvNoExploLineColor);
}

/** Faster re-chamber animation */
simulated function PlayAnimation(name Sequence, optional float fDesiredDuration, optional bool bLoop, optional float BlendInTime=0.1, optional float BlendOutTime=0.0)
{
	if (RechamberAnimNames.Find(Sequence) != INDEX_NONE)
		fDesiredDuration /= 1.5f;

	super.PlayAnimation(Sequence, fDesiredDuration, bLoop, BlendInTime, BlendOutTime);
}

/** Toggle explosive hit on heavy attack with reload */
simulated function SendToFiringState(byte FireModeNum)
{
	if (FireModeNum == RELOAD_FIREMODE)
	{
		bExplosiveOnHeavyAttack = !bExplosiveOnHeavyAttack;

		// Play switch fire mode sound for audio confirmation
		Instigator.PlaySoundBase(KFInventoryManager(InvManager).SwitchFireModeEvent);
		return;
	}
	
	super.SendToFiringState(FireModeNum);
}

/** Overridden to check for toggled explosive hit */
simulated state MeleeHeavyAttacking
{
	simulated function NotifyMeleeCollision(Actor HitActor, optional vector HitLocation)
	{
		if (bExplosiveOnHeavyAttack)
			super.NotifyMeleeCollision(HitActor, HitLocation);
	}
}

/** Overridden to add in artificial reload */
simulated function CustomFire()
{
	if (Instigator.Role < ROLE_Authority)
		return;
		
	super.CustomFire();
	
	TimeArtificialReload();
}

/** Times artificial reload */
simulated function TimeArtificialReload()
{
	SetTimer(FireInterval[CUSTOM_FIREMODE], false, nameof(PerformArtificialReload));
}

/** Performs artificial reload at end of explosive hit */
simulated function PerformArtificialReload()
{
	PerformReload();
}

/** Check ammo to see if we need to add it */
simulated state Active
{
	simulated event BeginState(name PreviousStateName)
	{
		// Check our ammo
		if (Instigator.Role == ROLE_Authority && AmmoCount[0] == 0 && SpareAmmoCount[0] > 0 && !IsTimerActive(nameof(PerformArtificialReload)))
			TimeArtificialReload();

		super.BeginState(PreviousStateName);
	}
	
	/** Add ammo to mag if we picked up ammo and we had none */
	function int AddAmmo(int Amount)
	{
		local int OldAmmo, AddedAmmo;
		
		OldAmmo = AmmoCount[0];

		AddedAmmo = global.AddAmmo(Amount);
	
		if (AddedAmmo > 0 && OldAmmo == 0)
			TimeArtificialReload();
			
		return AddedAmmo;
	}
}

defaultproperties
{
	// Faster re-chamber (approximately 1/1.725)
	FireInterval(CUSTOM_FIREMODE)=0.6f
	
	RechamberAnimNames(0)=HardFire_L
	RechamberAnimNames(1)=HardFire_R
	RechamberAnimNames(2)=HardFire_F
	RechamberAnimNames(3)=HardFire_B
	
	// Modified for single-shot
	MagazineCapacity[0]=1
	SpareAmmoCapacity[0]=19
	InitialSpareMags[0]=4
	AmmoPickupScale[0]=5
	bReloadFromMagazine=false
	bAllowClientAmmoTracking=false
	
	// This allows toggling the explosive on
	// heavy attack without any delay
	// Due to how the reload key functions here,
	// reload cancelling cannot be exploited
	ReloadCancelTimeLimit=0.01f

	bExplosiveOnHeavyAttack=true
	
	PulvNoExploBGTexture=Texture2D'EngineResources.WhiteSquareTexture'
	PulvNoExploTexture=Texture2D'UI_PerkIcons_TEX.UI_PerkIcon_Demolition'
	PulvNoExploBGColor=(R=0, G=0, B=0, A=128)
	PulvNoExploTexColor=(R=192, G=192, B=192, A=192)
	PulvNoExploLineColor=(R=255, G=0, B=0, A=192)
	PulvNoExploIconSize=48
	PulvNoExploIconLocation=(X=0.861,Y=0.829)
}