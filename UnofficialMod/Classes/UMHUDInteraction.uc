//================================================
// UMHUDInteraction
//================================================
// Custom Interaction for Unofficial Mod
// Used to render HUD overlays if Unofficial
// Mod cannot replace the base HUD class
//================================================
// (c) 2018 "Insert Name Here"
//================================================
class UMHUDInteraction extends UMBaseInteraction;

/** Checks for health/armor color
	Ensures that HUD overlay does not waste time
	rendering health/armor that isn't a custom color */
var bool bDifferentHealthColor;
var bool bDifferentArmorColor;
var bool bDifferentSupplierColor;

/** Special ReplicationInfo */
var UMSpecialReplicationInfo SpecialRepInfo;

/** Initialize our values */
simulated function Initialized()
{
	SetupColors();
	SpecialRepInfo = ClientConfig.SpecialRepInfo;
}

/** Setup our colors */
simulated function SetupColors()
{
	bDifferentHealthColor = !IsSameColor(ClientConfig.HUDHealthColor, class'KFGame.KFHUDBase'.default.HealthColor);
	bDifferentArmorColor = !IsSameColor(ClientConfig.HUDArmorColor, class'KFGame.KFHUDBase'.default.ArmorColor);
	bDifferentSupplierColor = !(IsSameColor(ClientConfig.HUDSupplierUsableColor, class'KFGame.KFHUDBase'.default.SupplierUsableColor) &&
		IsSameColor(ClientConfig.HUDSupplierHalfUsableColor, class'KFGame.KFHUDBase'.default.SupplierHalfUsableColor) &&
		IsSameColor(ClientConfig.HUDSupplierActiveColor, class'KFGame.KFHUDBase'.default.SupplierActiveColor));
}

/** Render our HUD */
event PostRender(Canvas C)
{
	local KFPawn_Human KFPH;
	local vector ViewLoc, ViewVec, PlayerInfoLoc;
	local rotator ViewRot;

	// First conditions
	if (OwningKFPC == None || OwningKFPC.myHUD == None || !OwningKFPC.myHUD.bShowHUD || OwningKFPC.bCinematicMode ||
		KFPawn_Customization(OwningKFPC.Pawn) != None || OwningKFPC.GetTeamNum() != 0)
		return;

	// Render health/armor/regen health overlay
	// Done here because this is the same draw
	// order that KFGFxHudWrapper_UM uses
	OwningKFPC.GetPlayerViewPoint(ViewLoc, ViewRot);
	ViewVec = vector(ViewRot);
	
	// All of these checks are the same
	// as used in KFHUDBase.DrawHUD()
	foreach OwningKFPC.WorldInfo.AllPawns(class'KFGame.KFPawn_Human', KFPH)
	{
		if (KFPH.IsAliveAndWell() && KFPH != OwningKFPC.Pawn && KFPH.Mesh.SkeletalMesh != none && KFPH.Mesh.bAnimTreeInitialised)
		{
			PlayerInfoLoc = KFPH.Mesh.GetPosition() + (KFPH.CylinderComponent.CollisionHeight * vect(0,0,1));
			if (`TimeSinceEx(KFPH, KFPH.Mesh.LastRenderTime) < 0.2f && Normal(PlayerInfoLoc - ViewLoc) dot ViewVec > 0.f)
				DrawFriendlyHumanPlayerOverlay(OwningKFPC.myHUD, C, KFPH);
		}
	}

	ClientConfig.HUDHelper.DrawHUD(OwningKFPC.myHUD, C);
}

/** Draw friendly health/armor/regen overlay */
simulated function DrawFriendlyHumanPlayerOverlay(HUD H, Canvas C, KFPawn_Human KFPH)
{
	local KFPlayerReplicationInfo KFPRI;
	local KFHUDBase KFHUD;
	local float Percentage, YPos;
	local float BarHeight, BarLength;
	local vector ScreenPos, TargetLocation;
	local float FontScale;
	local float ResModifier;
	// Added variables so we only have
	// to calculate some stuff once
	local float InfoBaseX, FontAndResMod;
	// Regen health
	local int RegenHealth;
	// Supplier color/icon size
	local color SupplierColor;
	local float SupplierIconSize;

	// Heavily cut down and modified from KFHUDBase.DrawFriendlyHumanPlayerInfo()
	KFPRI = KFPlayerReplicationInfo(KFPH.PlayerReplicationInfo);
	if (KFPRI == None)
		return;
		
	KFHUD = KFHUDBase(H);
	if (KFHUD == None)
		return;

	// Do we need to overlay anything?
	RegenHealth = (SpecialRepInfo != None ? SpecialRepInfo.GetRegenHealth(KFPH) : 0);
	if (!bDifferentArmorColor && !bDifferentHealthColor && !bDifferentSupplierColor && RegenHealth == 0)
		return;

	TargetLocation = KFPH.Mesh.GetPosition() + (KFPH.CylinderComponent.CollisionHeight * vect(0,0,2.5f));
	ScreenPos = C.Project(TargetLocation);
	if(ScreenPos.X < 0 || ScreenPos.X > C.ClipX || ScreenPos.Y < 0 || ScreenPos.Y > C.ClipY)
		return;

	ResModifier = KFPH.WorldInfo.static.GetResolutionBasedHUDScale() * KFHUD.FriendlyHudScale;
	BarLength = FMin(KFHUD.PlayerStatusBarLengthMax * (C.ClipX / 1024.f), KFHUD.PlayerStatusBarLengthMax) * ResModifier;
	BarHeight = FMin(8.f * (C.ClipX / 1024.f), 8.f) * ResModifier;
	InfoBaseX = ScreenPos.X - (BarLength * 0.5f);
	FontScale = class'KFGame.KFGameEngine'.static.GetKFFontScale() * KFHUD.FriendlyHudScale;
	FontAndResMod = 36 * FontScale * ResModifier;

	C.EnableStencilTest(true);

	// We overlay health and armor only if it's with a custom color
	// NOTE: we draw an opaque overlay first
	// to ensure that the color is correct
	if (bDifferentArmorColor)
	{
		Percentage = FMin(float(KFPH.Armor) / float(KFPH.MaxArmor), 100);
		YPos = ScreenPos.Y + BarHeight + FontAndResMod + 1;

		C.SetDrawColor(0, 0, 0, 255);
		C.SetPos(InfoBaseX, YPos);
		C.DrawTile(KFHUD.PlayerStatusBarBGTexture, (BarLength - 2.0) * Percentage, BarHeight - 2.0, 0, 0, 32, 32);

		C.DrawColor = ClientConfig.HUDArmorColor;
		C.SetPos(InfoBaseX, YPos);
		C.DrawTile(KFHUD.PlayerStatusBarBGTexture, (BarLength - 2.0) * Percentage, BarHeight - 2.0, 0, 0, 32, 32);
	}
	
	// We get the percentage regardless because
	// we might need it for regen health position
	Percentage = FMin(float(KFPH.Health) / float(KFPH.HealthMax), 100);
	YPos = ScreenPos.Y + BarHeight * 2 + FontAndResMod + 1;
	if (bDifferentHealthColor)
	{
		C.SetDrawColor(0, 0, 0, 255);
		C.SetPos(InfoBaseX, YPos);
		C.DrawTile(KFHUD.PlayerStatusBarBGTexture, (BarLength - 2.0) * Percentage, BarHeight - 2.0, 0, 0, 32, 32);

		C.DrawColor = ClientConfig.HUDHealthColor;
		C.SetPos(InfoBaseX, YPos);
		C.DrawTile(KFHUD.PlayerStatusBarBGTexture, (BarLength - 2.0) * Percentage, BarHeight - 2.0, 0, 0, 32, 32);
	}

	if (RegenHealth > 0)
	{
		// We don't need the opaque overlay bar here
		C.DrawColor = ClientConfig.HUDRegenHealthColor;
		C.SetPos(InfoBaseX + (BarLength - 2.0) * Percentage, YPos);
		Percentage = FMin(float(RegenHealth) / float(KFPH.HealthMax),100);
		C.DrawTile(KFHUD.PlayerStatusBarBGTexture, (BarLength - 2.0) * Percentage, BarHeight - 2.0, 0, 0, 32, 32);
	}
	
	if (KFPRI.PerkSupplyLevel > 0 && KFPRI.CurrentPerkClass.static.GetInteractIcon() != None &&
		bDifferentSupplierColor && ClientConfig.HUDHelper.GetSupplierColor(KFPRI, SupplierColor, true))
	{
		InfoBaseX = ScreenPos.X + (BarLength * 0.5f);
		YPos = ScreenPos.Y + FontAndResMod + 4 * ResModifier;

		SupplierIconSize = KFHUD.PlayerStatusIconSize * 0.75 * ResModifier;

		C.SetDrawColor(0, 0, 0, 255);
		C.SetPos(InfoBaseX, YPos);
		C.DrawTile(KFPRI.CurrentPerkClass.static.GetInteractIcon(), SupplierIconSize, SupplierIconSize, 0, 0, 256, 256);
		
		C.DrawColor = SupplierColor;
		C.SetPos(InfoBaseX, YPos);
		C.DrawTile(KFPRI.CurrentPerkClass.static.GetInteractIcon(), SupplierIconSize, SupplierIconSize, 0, 0, 256, 256);
	}

	C.EnableStencilTest(false);
}

/** Checks if these two colors are the same */
simulated function bool IsSameColor(const out color A, const out color B)
{
	return (A.R == B.R && A.G == B.G && A.B == B.B && A.A == B.A);
}

defaultproperties
{
}