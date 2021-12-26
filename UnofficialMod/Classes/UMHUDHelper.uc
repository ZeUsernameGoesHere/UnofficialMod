//================================================
// UMHUDHelper
//================================================
// Custom HUD helper class for Unofficial Mod
// Collects common HUD code in one place
//================================================
// (c) 2019 "Insert Name Here"
//================================================
class UMHUDHelper extends Info;

// NOTE:
// Canvas.EnableStencilTest() makes Canvas elements
// draw behind the weapon model, so keep it disabled
// for stuff drawn with the Flash HUD (e.g. Medic
// charge display, M16-M203/HM-501 grenade icon)

/** UMClientConfig instance */
var UMClientConfig ClientConfig;

/** Owning KFPlayerController */
var KFPlayerController TheKFPC;

/** General background texture */
var const Texture2D BackgroundTexture;
/** General HUD background color */
var const color BackgroundColor;
/** General HUD text color */
var const color TextColor;
/** General HUD text outline color */
var const color TextOutlineColor;
/** General FontRenderInfo */
var const FontRenderInfo MyFontRenderInfo;

/** Medic lock-on icon */
var const Texture2D MedicLockOnIcon;
var const float MedicLockOnIconSize;
var const color MedicLockOnColor, MedicPendingLockOnColor;

// Custom KFDroppedPickup class
// with special replicated info
var KFDroppedPickup_UM WeaponPickup;
/** Maximum distance at which pickup info will render */
var const float MaxWeaponPickupDist;
/** Radius in which to scan for dropped weapons */
var const float WeaponPickupScanRadius;
/** Radius in which to scan for living zeds,
	which will prevent pickup info from rendering */
var const float ZedScanRadius;
/** Weapon pickup ammo and weight icons */
var const Texture2D WeaponAmmoIcon, WeaponWeightIcon;
/** Base size of pickup info icons
	This is scaled by the below font scale */
var const float WeaponIconSize;
/** Font scale at which to render text for pickup info
	This is also used to scale the icons */
var const float WeaponFontScale;
/** Second is for weapons that cannot be picked up due to weight
	These also apply to the text color */
var const color WeaponIconColor,WeaponOverweightIconColor;

/** Rotator used to draw rotated
	HMTech Medic weapon icons */
var const rotator MedicWeaponRot;
/** Default height for HMTech Medic
	weapon icons (1920x1080)
	Width is half of this */
var const float MedicWeaponHeight;
/** Colors used for HMTech Medic weapon recharge
	depending on whether a dart can be fired */
var const color MedicWeaponNotChargedColor, MedicWeaponChargedColor;
/** Positions for HMTech Medic weapon icons
	depending on UMClientConfig.HMTechChargeHUDPos
	Vectors are (X, Y, Position Offset) */
var const array<vector> MedicWeaponPositions;
/** Index for MedicWeaponPositions */
var byte MedicWeaponPosIndex;

/** M203/HM-501 reload indicator icon and background texture */
var const Texture2D GrenadeReloadTexture;
/** Colors for above textures */
var const Color GrenadeReloadTextureColor, GrenadeReloadLineColor;
/** Width of reload indicator icon */
var const float GrenadeReloadTextureWidth;

/** Zed time indicator texture */
var const Texture2D ZedTimeTexture;
/** Colors for Zed time texture */
var const color ZedTimeTextureBGColor;
var const LinearColor ZedTimeTextureColor;
/** Zed time icon size */
var const float ZedTimeIconSize;
/** Zed time font scale */
var const float ZedTimeFontScale;
/** Zed time remaining
	NOTE: The UMClientConfig sets this initially
	and we simulate it from there */
var float ZedTimeRemaining;

/** Are we in a beta? */
var bool bIsInBeta;

/** Medic weapon dart charge info */
struct MedicWeaponDartChargeInfo
{
	/** Weapon class */
	var class<KFWeapon> KFWClass;
	/** Required charge to shoot a dart
		NOTE: This is a raw value rather
		than a percentage since the dart
		magazine capacity can change due
		to e.g. Zedternal skills */
	var int MinDartCharge;
};

/** List of minimum dart charge per weapon */
var array<MedicWeaponDartChargeInfo> MedicWeaponDartInfoList;

event PostBeginPlay()
{
	super.PostBeginPlay();
	
	ClientConfig = UMClientConfig(Owner);
	
	bIsInBeta = class'UnofficialMod.UnofficialModMut'.static.IsInBeta();
	
	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		TheKFPC = ClientConfig.GetLocalPC();
		SetTimer(0.1, true, nameof(CheckForWeaponPickup));
		SetupMedicDartInfo();
		SetupMedicWeaponPosInfo(ClientConfig.HMTechChargeHUDPos);
	}
}

/** Simulate zed time counting down */
event Tick(float DeltaTime)
{
	super.Tick(DeltaTime);

	if (ZedTimeRemaining > 0.0 && WorldInfo.TimeDilation > 0.0)
		ZedTimeRemaining -= (DeltaTime / WorldInfo.TimeDilation);
}

/** Draw relevant HUD stuff */
function DrawHUD(HUD H, Canvas C)
{
	local KFPawn LockPawn;
	local color LockColor;

	// Don't draw canvas HUD in cinematic mode
	if(TheKFPC == None || TheKFPC.bCinematicMode)
		return;

	if(TheKFPC.Pawn != None)
	{
		// HMTech Medic weapon lock-on
		if (GetLockedOnPlayer(KFWeapon(TheKFPC.Pawn.Weapon), LockPawn, LockColor))
			DrawMedicWeaponLockOn(H, C, LockPawn, LockColor);

		// Unequipped HMTech recharge
		if (ClientConfig.AllowHMTechChargeDisplay())
			DrawMedicWeaponRecharge(H, C, TheKFPC.Pawn);

		// Empty secondary ammo
		if (KFWeapon(TheKFPC.Pawn.Weapon) != None)
			CheckAndDrawEmptySecondaryIcon(H, C, KFWeapon(TheKFPC.Pawn.Weapon));
		
		// Zed time HUD
		if (`IsInZedTime(Self) && ClientConfig.bShowZedTimeExtensionHUD && ClientConfig.ZedTimeRemaining > 0.0 && ZedTimeRemaining > 0.0)
			DrawZedTimeHUD(H, C);
	}

	// Dropped weapon pickup info
	if (WeaponPickup != None)
		DrawWeaponPickupInfo(H, C, WeaponPickup, TheKFPC.Pawn);
}

/** Check for dropped weapon pickup */
function CheckForWeaponPickup()
{
	local KFDroppedPickup_UM KFDP, BestKFDP;
	local int KFDPCount, ZedCount;
	local vector StartTrace, EndTrace, HitLocation, HitNormal;
	local rotator AimRot;
	local Actor HitActor;
	local float DistSq, BestDistSq;
	local KFPawn_Monster KFPM;

	if (TheKFPC == None || TheKFPC.WorldInfo.GRI == None || !TheKFPC.WorldInfo.GRI.bMatchHasBegun)
	{
		WeaponPickup = None;
		return;
	}

	TheKFPC.GetPlayerViewPoint(StartTrace, AimRot);
	EndTrace = StartTrace + vector(AimRot) * MaxWeaponPickupDist;
	// Make sure we're only tracing against the world, because
	// we base the below CollidingActors() check on it
	HitActor = Trace(HitLocation, HitNormal, EndTrace, StartTrace);
	
	if (HitActor == None)
	{
		WeaponPickup = None;
		return;
	}
		
	// Check for living zeds in small radius
	// This prevents pickup info from blocking
	// sightlines to certain zeds (e.g. Crawlers)
	foreach CollidingActors(class'KFGame.KFPawn_Monster', KFPM, ZedScanRadius, HitLocation)
	{
		if (KFPM.IsAliveAndWell())
		{
			WeaponPickup = None;
			return;
		}

		// We limit this to 20 zeds for time reasons
		// This usually won't happen, but better safe than sorry
		ZedCount++;
		if (ZedCount > 20)
		{
			WeaponPickup = None;
			return;
		}
	}

	BestDistSq = WeaponPickupScanRadius * WeaponPickupScanRadius;

	// Check for dropped pickups in small radius
	foreach CollidingActors(class'UnofficialMod.KFDroppedPickup_UM', KFDP, WeaponPickupScanRadius, HitLocation)
	{
		if (KFDP.Velocity.Z == 0)
		{
			// We get the weapon closest to HitLocation
			DistSq = VSizeSq(KFDP.Location - HitLocation);
			if (DistSq < BestDistSq)
			{
				BestKFDP = KFDP;
				BestDistSq = DistSq;
			}
		}

		KFDPCount++;
		// We limit this to only 3 total KFDroppedPickup_UM
		// to limit potential time cost in case a bunch of
		// dropped pickups are dropped in one place
		// This usually won't happen, but better safe than sorry
		if (KFDPCount > 2)
			break;
	}

	WeaponPickup = BestKFDP;
}

/** Get locked-on player if relevant */
function bool GetLockedOnPlayer(KFWeapon KFW, out KFPawn LockPawn, out color LockColor)
{
	local KFWeap_MedicBase KFWMB;
	local KFWeap_HRG_Healthrower KFWHT;

	// Shouldn't happen, but better safe than sorry
	if (KFW == None)
		return false;

	if (KFWeap_MedicBase(KFW) != None)
	{
		// Most Medic weapons
		KFWMB = KFWeap_MedicBase(KFW);
		if (KFWMB.LockedTarget != None)
		{
			LockPawn = KFPawn(KFWMB.LockedTarget);
			LockColor = MedicLockOnColor;
		}
		else if (KFWMB.PendingLockedTarget != None)
		{
			LockPawn = KFPawn(KFWMB.PendingLockedTarget);
			LockColor = MedicPendingLockOnColor;
		}
		
		return (LockPawn != None);
	}
	else if (KFWeap_HRG_Healthrower(KFW) != None)
	{
		// Healthrower
		KFWHT = KFWeap_HRG_Healthrower(KFW);
		if (KFWHT.LockedTarget != None)
		{
			LockPawn = KFPawn(KFWHT.LockedTarget);
			LockColor = MedicLockOnColor;
		}
		else if (KFWHT.PendingLockedTarget != None)
		{
			LockPawn = KFPawn(KFWHT.PendingLockedTarget);
			LockColor = MedicPendingLockOnColor;
		}
		
		return (LockPawn != None);
	}
	else if (KFW.MedicComp != None && KFW.TargetingComp != None &&
		((KFW.TargetingComp.TargetingModeFlags[0] & class'KFGame.KFTargetingWeaponComponent'.const.TARGETINGMODE_FLAGS_PLAYER) != 0 ||
		(KFW.TargetingComp.TargetingModeFlags[1] & class'KFGame.KFTargetingWeaponComponent'.const.TARGETINGMODE_FLAGS_PLAYER) != 0))
	{
		// General Medic weapon
		if (KFW.TargetingComp.LockedTarget[ETargetingMode_Player] != None)
		{
			LockPawn = KFW.TargetingComp.LockedTarget[ETargetingMode_Player];
			LockColor = MedicLockOnColor;
		}
		else if (KFW.TargetingComp.PendingLockedTarget[ETargetingMode_Player] != None)
		{
			LockPawn = KFW.TargetingComp.PendingLockedTarget[ETargetingMode_Player];
			LockColor = MedicPendingLockOnColor;
		}

		return (LockPawn != None);
	}
	
	return false;
}

/** Draw HMTech Medic weapon lock-on */
function DrawMedicWeaponLockOn(HUD H, Canvas C, KFPawn CurrentActor, color IconColor)
{
	local vector ScreenPos;
	local float IconSize;

	ScreenPos = C.Project(CurrentActor.Mesh.GetPosition() + (CurrentActor.CylinderComponent.CollisionHeight * vect(0,0,1.25)));
	if (ScreenPos.X < 0 || ScreenPos.X > C.ClipX || ScreenPos.Y < 0 || ScreenPos.Y > C.ClipY)
		return;

	IconSize = WorldInfo.static.GetResolutionBasedHUDScale() * MedicLockOnIconSize;
	
	C.EnableStencilTest(true);
	C.DrawColor = IconColor;
	C.SetPos(ScreenPos.X - (IconSize / 2.0), ScreenPos.Y - (IconSize / 2.0));
	C.DrawTile(MedicLockOnIcon, IconSize, IconSize, 0, 0, 256, 256);
	C.EnableStencilTest(false);
}

/** Setup Medic weapon dart charge info */
function SetupMedicDartInfo()
{
	local int i, j; //, DartCharge;
	local KFGFxObject_TraderItems TraderItems;
	local class<KFWeapon> WeaponClass;
	local KFWeapon MedicWeapon;
	local MedicWeaponDartChargeInfo DartInfo;

	// Make sure we can get the current TraderItems
	if (WorldInfo.GRI == None)
	{
		SetTimer(1.0, false, nameof(SetupMedicDartInfo));
		return;
	}

	// Check default TraderItems first
	TraderItems = class'UnofficialMod.UMClientConfig'.static.GetDefaultTraderItems();
	
	for (i = 0;i < 2;i++)
	{
		for (j = 0;j < TraderItems.SaleItems.Length;j++)
		{
			// We go through vanilla weapons the first time
			// through, so skip them the second time through
			if (i == 1 && TraderItems.SaleItems[j].WeaponDef.GetPackageName() == 'KFGame')
				continue;
				
			// Ignore non-Medic weapons
			if (TraderItems.SaleItems[j].AssociatedPerkClasses.Find(class'KFGame.KFPerk_FieldMedic') == INDEX_NONE)
				continue;
				
			// Load this class
			// NOTE: We use KFWeapon as several Medic
			// weapons do not extend KFWeap_MedicBase
			WeaponClass = class<KFWeapon>(DynamicLoadObject(TraderItems.SaleItems[j].WeaponDef.default.WeaponClassPath, class'Class', true));

			// Second check excludes HM-501 and any other non-recharging Medic weapons
			if (WeaponClass == None || WeaponClass.default.bCanRefillSecondaryAmmo)
				continue;
				
			// Hard-code for Hemoclobber because
			// its HasAmmo() works differently
			if (ClassIsChildOf(WeaponClass, class'KFGameContent.KFWeap_Blunt_MedicBat'))
			{
				DartInfo.KFWClass = WeaponClass;
				DartInfo.MinDartCharge = class<KFWeap_Blunt_MedicBat>(WeaponClass).default.AttackHealCosts[0];
			}
			else
			{
				DartInfo.KFWClass = WeaponClass;

				// We have to get the minimum charge this
				// way because AmmoCost is protected
				MedicWeapon = Spawn(WeaponClass);
				
				// Shouldn't happen, but check anyways
				if (MedicWeapon == None)
				{
					// Flag this so that the Medic Weapon charge
					// function can grab this on the fly
					DartInfo.MinDartCharge = -1;
				}
				else
				{
					DartInfo.MinDartCharge = GetMinDartCharge(MedicWeapon);
					MedicWeapon.Destroy();
				}
			}
			
			MedicWeaponDartInfoList.AddItem(DartInfo);
		}
		
		// Change to current Trader list the second time through
		TraderItems = KFGameReplicationInfo(WorldInfo.GRI).TraderItems;
	}
}

/** Get minimum dart charge for Medic weapon */
function int GetMinDartCharge(KFWeapon MedicWeapon)
{
	local int DartCharge, OrigCharge;

	OrigCharge = MedicWeapon.AmmoCount[1];

	// Go up by 10, then down by 1
	// This minimizes the number of cycles
	// while ensuring that any Medic weapon
	// with a dart charge not divisible by
	// 10 has an accurate display in the HUD
	for (DartCharge = 10;DartCharge <= (MedicWeapon.MagazineCapacity[1] + 10);DartCharge += 10)
	{
		MedicWeapon.AmmoCount[1] = DartCharge;
		if (MedicWeapon.HasAmmo(1))
			break;
	}
	
	while (DartCharge >= 0)
	{
		MedicWeapon.AmmoCount[1] = DartCharge - 1;
		if (!MedicWeapon.HasAmmo(1))
			break;
			
		DartCharge--;
	}
	
	MedicWeapon.AmmoCount[1] = OrigCharge;
	
	return DartCharge;
}

/** Setup HMTech Medic weapon info position */
function byte SetupMedicWeaponPosInfo(byte PosIndex)
{
	// Check for proper values
	if (PosIndex > 1)
		PosIndex = 0;
		
	MedicWeaponPosIndex = PosIndex;
	
	return PosIndex;
}

/** Draw unequipped HMTech Medic weapon recharge */
function DrawMedicWeaponRecharge(HUD H, Canvas C, Pawn P)
{
	local KFWeapon KFW;
	local int MedicWeaponCount, Index;
	local float IconBaseX, IconBaseY, IconHeight, IconWidth;
	local float IconRatioX, IconRatioY, ChargePct, ChargeBaseY, WeaponBaseX;
	local color ChargeColor;
	local bool bHasAmmo;
	local MedicWeaponDartChargeInfo DartInfo;
	
	if (P.InvManager == None)
		return;
	
	// Avoiding a compiler warning
	MedicWeaponCount = 0;

	// Our settings are based off of 1920x1080,
	// so scale if necessary
	IconRatioX = C.SizeX / 1920.0;
	IconRatioY = C.SizeY / 1080.0;
	IconHeight = MedicWeaponHeight * IconRatioY;
	IconWidth = IconHeight / 2.0;
	// Position depends on client setting
	IconBaseX = MedicWeaponPositions[MedicWeaponPosIndex].X * IconRatioX; //300 * IconRatioX;
	IconBaseY = MedicWeaponPositions[MedicWeaponPosIndex].Y * IconRatioY; //947 * IconRatioY;

	foreach P.InvManager.InventoryActors(class'KFGame.KFWeapon', KFW)
	{
		// TODO: Make this check not hard-coded
		// Specific check for Hemoclobber needed because it
		// extends KFWeap_MeleeBase and not KFWeap_MedicBase
		// Also only for weapons with rechargeable darts
		//if ((!KFW.IsA('KFWeap_MedicBase') || KFW.bCanRefillSecondaryAmmo) && KFWeap_Blunt_MedicBat(KFW) == None
		//	&& KFWeap_HRG_Healthrower(KFW) == None)
		if (KFW.GetWeaponPerkClass(class'KFGame.KFPerk_FieldMedic') != class'KFGame.KFPerk_FieldMedic' || KFW.bCanRefillSecondaryAmmo)
			continue;

		// Only if this is not our current weapon
		if (KFW == P.Weapon)
			continue;
			
		// Either to the right of the player's health/armor
		// or to the left of ammo
		WeaponBaseX = IconBaseX + (MedicWeaponCount * IconWidth * MedicWeaponPositions[MedicWeaponPosIndex].Z);

		// Draw background
		C.DrawColor = BackgroundColor;
		C.SetPos(WeaponBaseX, IconBaseY);
		C.DrawTile(BackgroundTexture, IconWidth, IconHeight, 0, 0, 32, 32);
		
		// Draw charge
		ChargePct = float(KFW.AmmoCount[1]) / float(KFW.MagazineCapacity[1]);
		ChargeBaseY = IconBaseY + IconHeight * (1.0 - ChargePct);
		bHasAmmo = (KFWeap_Blunt_MedicBat(KFW) != None ? KFW.AmmoCount[1] >= KFWeap_Blunt_MedicBat(KFW).AttackHealCosts[0] : KFW.HasAmmo(1));
		ChargeColor = (bHasAmmo ? MedicWeaponChargedColor : MedicWeaponNotChargedColor);
		C.DrawColor = ChargeColor;
		C.SetPos(WeaponBaseX, ChargeBaseY);
		C.DrawTile(BackgroundTexture, IconWidth, IconHeight * ChargePct, 0, 0, 32, 32);

		// Find our required dart charge
		Index = MedicWeaponDartInfoList.Find('KFWClass', KFW.class);
		
		if (Index != INDEX_NONE)
		{
			// Grab this on the fly if necessary
			if (MedicWeaponDartInfoList[Index].MinDartCharge < 0)
				MedicWeaponDartInfoList[Index].MinDartCharge = GetMinDartCharge(KFW);

			if (MedicWeaponDartInfoList[Index].MinDartCharge > 0)
			{
				// Draw lines for minimum charge
				ChargePct = float(MedicWeaponDartInfoList[Index].MinDartCharge) / float(KFW.MagazineCapacity[1]);
				ChargeBaseY = IconBaseY + IconHeight * (1.0 - ChargePct);
				C.Draw2DLine(WeaponBaseX, ChargeBaseY, WeaponBaseX + IconWidth * 0.2, ChargeBaseY, WeaponIconColor);
				C.Draw2DLine(WeaponBaseX + IconWidth * 0.8, ChargeBaseY, WeaponBaseX + IconWidth, ChargeBaseY, WeaponIconColor);
			}
		}
		else
		{
			// Compile this now, this will render next frame
			DartInfo.KFWClass = KFW.class;
			DartInfo.MinDartCharge = GetMinDartCharge(KFW);
			MedicWeaponDartInfoList.AddItem(DartInfo);
		}

		// Draw weapon
		C.DrawColor = WeaponIconColor;
		// Weapon texture is rotated from the top-left corner, so offset the X
		C.SetPos(WeaponBaseX + IconWidth, IconBaseY);
		C.DrawRotatedTile(KFW.WeaponSelectTexture, MedicWeaponRot, IconHeight, IconWidth, 0, 0,
			KFW.WeaponSelectTexture.GetSurfaceWidth(), KFW.WeaponSelectTexture.GetSurfaceHeight(), 0, 0);
		
		MedicWeaponCount++;
	}
}

/** Draw dropped weapon pickup info */
function DrawWeaponPickupInfo(HUD H, Canvas C, KFDroppedPickup_UM KFDP, Pawn P)
{
	local vector ScreenPos;
	local bool bHasAmmo, bCanCarry;
	local Inventory Inv;
	local KFInventoryManager KFIM;
	local string AmmoText, WeightText;
	local class<KFWeapon> KFWC;
	local color CanCarryColor;
	local float FontScale, ResModifier, IconSize;
	local float AmmoTextWidth, WeightTextWidth, TextWidth, TextHeight, TextYOffset;
	local float InfoBaseX, InfoBaseY;
	local float BGX, BGY, BGWidth, BGHeight;
	local float WeaponTextBGX, WeaponTextBGY;

	// Lift this a bit off of the ground
	ScreenPos = C.Project(KFDP.Location + vect(0,0,25));
	if (ScreenPos.X < 0 || ScreenPos.X > C.ClipX || ScreenPos.Y < 0 || ScreenPos.Y > C.ClipY)
		return;
		
	bHasAmmo = KFDP.MagazineAmmo[0] >= 0;

	AmmoText = KFDP.GetAmmoText();
	WeightText = KFDP.GetWeightText(P);

	// This is only set to false on living
	// players who cannot pick up the weapon
	if (P != None && KFInventoryManager(P.InvManager) != None)
	{
		KFIM = KFInventoryManager(P.InvManager);
		KFWC = class<KFWeapon>(KFDP.InventoryClass);
		if (KFIM.CanCarryWeapon(KFWC, KFDP.UpgradeLevel))
		{
			if (KFWC.default.DualClass != None)
				bCanCarry = !KFIM.ClassIsInInventory(KFWC.default.DualClass, Inv);
			else
				bCanCarry = !KFIM.ClassIsInInventory(KFWC, Inv);
		}
	}
	else
		bCanCarry = true;

	CanCarryColor = (bCanCarry ? WeaponIconColor : WeaponOverweightIconColor);

	// TODO?: Check for scaling, maybe make WeaponFontScale configurable
	ResModifier = KFDP.WorldInfo.static.GetResolutionBasedHUDScale();
	FontScale = class'KFGame.KFGameEngine'.static.GetKFFontScale() * WeaponFontScale;
	C.Font = class'KFGame.KFGameEngine'.static.GetKFCanvasFont();
	// We don't draw the ammo text or icon if it's not relevant, so check this
	if (bHasAmmo)
	{
		// Grab the wider of the two strings
		// Text height should be the same for both
		C.TextSize(AmmoText, AmmoTextWidth, TextHeight, FontScale, FontScale);
		C.TextSize(WeightText, WeightTextWidth, TextHeight, FontScale, FontScale);
		TextWidth = FMax(AmmoTextWidth, WeightTextWidth);
	}
	else
		C.TextSize(WeightText, TextWidth, TextHeight, FontScale, FontScale);

	IconSize = WeaponIconSize * WeaponFontScale * ResModifier;
	InfoBaseX = ScreenPos.X - ((IconSize * 1.5 + TextWidth) * 0.5);
	InfoBaseY = ScreenPos.Y;
	TextYOffset = (IconSize - TextHeight) * 0.5;

	// Setup the background
	BGWidth = IconSize * 2.0 + TextWidth;
	BGX = InfoBaseX - (IconSize * 0.25);
	if (bHasAmmo)
	{
		BGHeight = (IconSize * 2.5) * 1.25;
		BGY = InfoBaseY - (BGHeight * 0.125);
	}
	else
	{
		BGHeight = IconSize * 1.5;
		BGY = InfoBaseY + IconSize * 1.5 - (BGHeight * 0.125);
	}

	C.EnableStencilTest(true);

	// Background
	C.DrawColor = class'KFGame.KFHUDBase'.default.PlayerBarBGColor;
	C.SetPos(BGX, BGY);
	C.DrawTile(BackgroundTexture, BGWidth, BGHeight, 0, 0, 32, 32);

	// We only draw ammo if it's relevant
	if (bHasAmmo)
	{
		// Ammo icon
		C.DrawColor = WeaponIconColor;
		C.SetPos(InfoBaseX, InfoBaseY);
		C.DrawTile(WeaponAmmoIcon, IconSize, IconSize, 0, 0, 256, 256);
	
		// Ammo text
		C.SetPos(InfoBaseX + IconSize * 1.5, InfoBaseY + TextYOffset);
		C.DrawText(AmmoText, , FontScale, FontScale, MyFontRenderInfo);
	}

	// Weight icon
	C.DrawColor = CanCarryColor;
	C.SetPos(InfoBaseX, InfoBaseY + IconSize * 1.5);
	C.DrawTile(WeaponWeightIcon, IconSize, IconSize, 0, 0, 256, 256);

	// Weight (and upgrade level if applicable) text
	C.SetPos(InfoBaseX + IconSize * 1.5, InfoBaseY + IconSize * 1.5 + TextYOffset);
	C.DrawText(WeightText, , FontScale, FontScale, MyFontRenderInfo);
	
	// Weapon name
	if (KFDP.InventoryClass.default.ItemName != "")
	{
		C.TextSize(KFDP.InventoryClass.default.ItemName, TextWidth, TextHeight, FontScale, FontScale);
		
		WeaponTextBGX = ScreenPos.X - (TextWidth * 0.5625);
		WeaponTextBGY = BGY - TextHeight * 1.25;

		C.DrawColor = class'KFGame.KFHUDBase'.default.PlayerBarBGColor;
		C.SetPos(WeaponTextBGX, WeaponTextBGY);
		C.DrawTile(BackgroundTexture, TextWidth * 1.125, TextHeight * 1.125, 0, 0, 32, 32);
	
		C.DrawColor = WeaponIconColor;
		C.SetPos(WeaponTextBGX + TextWidth * 0.0625, WeaponTextBGY + TextHeight * 0.0625);
		C.DrawText(KFDP.InventoryClass.default.ItemName, , FontScale, FontScale, MyFontRenderInfo);
	}

	// Owner's name
	if (KFDP.OriginalOwnerPlayerName != "")
	{
		C.TextSize(KFDP.OriginalOwnerPlayerName, TextWidth, TextHeight, FontScale, FontScale);
	
		BGX += (BGWidth * 0.5 - TextWidth * 0.5625);
		BGY += (BGHeight + TextHeight * 0.25);
		BGWidth = TextWidth * 1.125;
		BGHeight = TextHeight * 1.125;
	
		C.DrawColor = class'KFGame.KFHUDBase'.default.PlayerBarBGColor;
		C.SetPos(BGX, BGY);
		C.DrawTile(BackgroundTexture, BGWidth, BGHeight, 0, 0, 32, 32);
	
		C.DrawColor = WeaponIconColor;
		C.SetPos(BGX + TextWidth * 0.0625, BGY + TextHeight * 0.0625);
		C.DrawText(KFDP.OriginalOwnerPlayerName, , FontScale, FontScale, MyFontRenderInfo);
	}

	C.EnableStencilTest(false);
}

/** Draw no grenade loaded icon for M16-M203 and HM-501 */
function CheckAndDrawEmptySecondaryIcon(HUD H, Canvas C, KFWeapon KFW)
{
	local float IconWidth, IconX, IconY;

	// Heuristic check for empty weapon
	if (!(KFW != None && KFW.CanRefillSecondaryAmmo() && KFW.AmmoCount[1] <= 0))
		return;

	IconWidth = WorldInfo.static.GetResolutionBasedHUDScale() * GrenadeReloadTextureWidth;
	// Right above ammo counter
	// NOTE: this might be off for resolutions
	// other than 1920x1080, especially
	// if they're not in 16:9 ratio
	IconX = C.SizeX * 0.855;
	IconY = C.SizeY * 0.8;

	// Draw background
	C.DrawColor = BackgroundColor;
	C.SetPos(IconX, IconY);
	C.DrawTile(BackgroundTexture, IconWidth, IconWidth * 0.5, 0, 0, 32, 32);
	
	// Draw icon
	C.DrawColor = GrenadeReloadTextureColor;
	C.SetPos(IconX, IconY);
	C.DrawTile(KFW.SecondaryAmmoTexture, IconWidth, IconWidth * 0.5, 0, 0, KFW.SecondaryAmmoTexture.GetSurfaceWidth(), KFW.SecondaryAmmoTexture.GetSurfaceHeight());
	
	// Draw line (bottom-left to upper-right)
	C.Draw2DLine(IconX, IconY + (IconWidth * 0.5), IconX + IconWidth, IconY, GrenadeReloadLineColor);
}

// TODO: This
/** Draw no explosive icon for Pulverizer */
function DrawNoExploIcon(HUD H, Canvas C, Texture2D NoExploTexture)
{
}

/** Draw Zed Time extension HUD */
function DrawZedTimeHUD(HUD H, Canvas C)
{
	local float IconSize, IconX, IconY;
	local float FontScale, TextWidth, TextHeight, TextPosX, TextPosY;
	local string ExtensionsString;
	local int XS, YS, Steps, Size;

	IconSize = WorldInfo.static.GetResolutionBasedHUDScale() * ZedTimeIconSize;
	// Right above health/armor status area
	// NOTE: this might be off for resolutions
	// other than 1920x1080, especially
	// if they're not in 16:9 ratio
	IconX = C.SizeX * 0.016667;
	IconY = C.SizeY * 0.785;

	// Draw background
	C.DrawColor = BackgroundColor;
	C.SetPos(IconX, IconY);
	C.DrawTile(BackgroundTexture, IconSize, IconSize, 0, 0, 32, 32);
	
	// Draw background icon
	C.DrawColor = ZedTimeTextureBGColor;
	C.SetPos(IconX, IconY);
	C.DrawTile(ZedTimeTexture, IconSize, IconSize, 0, 0, 128, 128);
	
	// Draw remaining zed time left
	C.SetPos(IconX, IconY);
	C.DrawTimer(ZedTimeTexture, 0.0, ZedTimeRemaining / ClientConfig.ZedTimeRemaining, IconSize, IconSize, 0, 0, 128, 128, ZedTimeTextureColor);
	
	// Setup extensions text
	ExtensionsString = string(ClientConfig.ZedTimeExtensions);
	FontScale = class'KFGame.KFGameEngine'.static.GetKFFontScale() * ZedTimeFontScale;
	C.Font = class'KFGame.KFGameEngine'.static.GetKFCanvasFont();
	C.TextSize(ExtensionsString, TextWidth, TextHeight, FontScale, FontScale);
	
	TextPosX = IconX + (IconSize - TextWidth) * 0.5;
	TextPosY = IconY + (IconSize - TextHeight) * 0.5;

	C.DrawColor = TextOutlineColor;

	Size = 2;
	Steps = (Size * 2) / 3;
	if (Steps < 1 ) Steps = 1;

	for (XS = -Size; XS <= Size; XS+=Steps)
	{
		for (YS = -Size; YS <= Size; YS+=Steps)
		{
			C.SetPos(TextPosX + XS, TextPosY + YS);
			C.DrawText(ExtensionsString, , FontScale, FontScale, MyFontRenderInfo);
		}
	}

	C.DrawColor = TextColor;
	C.SetPos(TextPosX, TextPosY);
	C.DrawText(ExtensionsString, , FontScale, FontScale, MyFontRenderInfo);
}

/** Get custom Supplier color for passed KFPlayerReplicationInfo
	Returns true if this is different than default */
function bool GetSupplierColor(KFPlayerReplicationInfo KFPRI, out color SupplierColor, optional bool bCheckDifferent)
{
	local color OrigColor;

	if (KFPRI.PerkSupplyLevel == 2)
	{
		if (KFPRI.bPerkPrimarySupplyUsed && KFPRI.bPerkSecondarySupplyUsed)
		{
			SupplierColor = ClientConfig.HUDSupplierActiveColor;
			OrigColor = class'KFGame.KFHUDBase'.default.SupplierActiveColor;
		}
		else if (KFPRI.bPerkPrimarySupplyUsed || KFPRI.bPerkSecondarySupplyUsed)
		{
			SupplierColor = ClientConfig.HUDSupplierHalfUsableColor;
			OrigColor = class'KFGame.KFHUDBase'.default.SupplierHalfUsableColor;
		}
		else
		{
			SupplierColor = ClientConfig.HUDSupplierUsableColor;
			OrigColor = class'KFGame.KFHUDBase'.default.SupplierUsableColor;
		}
	}
	else if (KFPRI.PerkSupplyLevel == 1)
	{
		if (KFPRI.bPerkPrimarySupplyUsed)
		{
			SupplierColor = ClientConfig.HUDSupplierActiveColor;
			OrigColor = class'KFGame.KFHUDBase'.default.SupplierActiveColor;
		}
		else
		{
			SupplierColor = ClientConfig.HUDSupplierUsableColor;
			OrigColor = class'KFGame.KFHUDBase'.default.SupplierUsableColor;
		}
	}
	else
		// Shouldn't get here, but just in case
		return false;

	if (bCheckDifferent)
		return IsDifferentColor(SupplierColor, OrigColor);
		
	return false;
}

/** Checks if these two colors are different */
function bool IsDifferentColor(const out color A, const out color B)
{
	return (A.R != B.R || A.G != B.G || A.B != B.B || A.A != B.A);
}

defaultproperties
{
	BackgroundTexture=Texture2D'EngineResources.WhiteSquareTexture'
	BackgroundColor=(R=0, G=0, B=0, A=128)
	TextColor=(R=250, G=250, B=250, A=255)
	TextOutlineColor=(R=25, G=25, B=25, A=255)
	MyFontRenderInfo=(bClipText=true)

	MedicLockOnIcon=Texture2D'UI_PerkIcons_TEX.UI_PerkIcon_Medic'
	MedicLockOnIconSize=40
	MedicLockOnColor=(R=0, G=255, B=255, A=192)
	MedicPendingLockOnColor=(R=92, G=92, B=92, A=192)

	MaxWeaponPickupDist=700 // 7m
	WeaponPickupScanRadius=75 // 75cm
	ZedScanRadius=200 // 2m
	WeaponAmmoIcon=Texture2D'UI_Menus.TraderMenu_SWF_I10B'
	WeaponWeightIcon=Texture2D'UI_Menus.TraderMenu_SWF_I26'
	WeaponIconSize=16
	WeaponFontScale=1.25
	WeaponIconColor=(R=192, G=192, B=192, A=192)
	WeaponOverweightIconColor=(R=255, G=0, B=0, A=192)
	
	MedicWeaponRot=(Yaw=16384)
	// This is about the height of the Syringe icon at 1920x1080
	MedicWeaponHeight=88
	MedicWeaponNotChargedColor=(R=224, G=0, B=0, A=128)
	MedicWeaponChargedColor=(R=0, G=224, B=224, A=128)
	// Based off of 1920x1080 and scaled (Z is offset for each weapon displayed)
	MedicWeaponPositions(0)=(X=300,Y=947,Z=1.2)
	MedicWeaponPositions(1)=(X=1576,Y=947,Z=-1.2)
	
	GrenadeReloadTexture=Texture2D'UI_FireModes_TEX.UI_FireModeSelect_Grenade'
	GrenadeReloadTextureColor=(R=192, G=192, B=192, A=192)
	GrenadeReloadLineColor=(R=255, G=0, B=0, A=192)
	GrenadeReloadTextureWidth=64
	
	ZedTimeTexture=Texture2D'UI_Award_PersonalMulti.UI_Award_PersonalMulti-Headshots'
	ZedTimeTextureBGColor=(R=96, G=96, B=96, A=192)
	ZedTimeTextureColor=(R=0.75, G=0.75, B=0.75, A=0.75)
	ZedTimeIconSize=64
	ZedTimeFontScale=1.5
}