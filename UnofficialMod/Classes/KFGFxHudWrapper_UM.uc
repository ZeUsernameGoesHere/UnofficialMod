//================================================
// KFGFxHudWrapper_UM
//================================================
// Modified HUD for Unofficial Mod
// Adds several additional HUD elements showing
// things like regen health, HMTech Medic weapon
// lock-on, dropped weapon pickup info, etc.
//================================================
// (c) 2018 "Insert Name Here"
//================================================
class KFGFxHudWrapper_UM extends KFGFxHudWrapper;

/** Colors grabbed from UMClientConfig */
var color UMHealthColor;
var color UMRegenHealthColor;
var color UMArmorColor;

/** UMClientConfig instance */
var UMClientConfig ClientConfig;

/** Special ReplicationInfo */
var UMSpecialReplicationInfo SpecialRepInfo;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	
	// Give this time to show up on client
	SetTimer(2.0, false, nameof(GetClientConfig));
}

/** Get HUD colors and special ReplicationInfo from config */
simulated function GetClientConfig()
{
	ClientConfig = class'UnofficialMod.UMClientConfig'.static.GetInstance();
	
	if (ClientConfig != None)
	{
		UMHealthColor = ClientConfig.HUDHealthColor;
		UMRegenHealthColor = ClientConfig.HUDRegenHealthColor;
		UMArmorColor = ClientConfig.HUDArmorColor;
		SpecialRepInfo = ClientConfig.SpecialRepInfo;
	}
	else
		SetTimer(1.0, false, nameof(GetClientConfig));
}

function DrawHUD()
{
	super.DrawHUD();

	if (ClientConfig != None && ClientConfig.HUDHelper != None)
		ClientConfig.HUDHelper.DrawHUD(Self, Canvas);
}

/** Copy/paste modified to put in
	custom colors and health regen */
simulated function bool DrawFriendlyHumanPlayerInfo( KFPawn_Human KFPH )
{
	local float Percentage;
	local float BarHeight, BarLength;
	local vector ScreenPos, TargetLocation;
	local KFPlayerReplicationInfo KFPRI;
	local FontRenderInfo MyFontRenderInfo;
	local float FontScale;
	local float ResModifier;
	local float PerkIconPosX, PerkIconPosY, SupplyIconPosX, SupplyIconPosY, PerkIconSize;
	// Added variables so we only have
	// to calculate some stuff once
	local float InfoBaseX, FontAndResMod;
	// Regen health
	local int RegenHealth;

	KFPRI = KFPlayerReplicationInfo(KFPH.PlayerReplicationInfo);

	if( KFPRI == none )
	{
		return false;
	}

	TargetLocation = KFPH.Mesh.GetPosition() + ( KFPH.CylinderComponent.CollisionHeight * vect(0,0,2.5f) );
	ScreenPos = Canvas.Project( TargetLocation );
	if( ScreenPos.X < 0 || ScreenPos.X > Canvas.ClipX || ScreenPos.Y < 0 || ScreenPos.Y > Canvas.ClipY )
	{
		return false;
	}

	// Moved all of these lines below the two above
	// checks because they're not necessary up there
	ResModifier = WorldInfo.static.GetResolutionBasedHUDScale() * FriendlyHudScale;
	MyFontRenderInfo = Canvas.CreateFontRenderInfo( true );
	BarLength = FMin(PlayerStatusBarLengthMax * (Canvas.ClipX / 1024.f), PlayerStatusBarLengthMax) * ResModifier;
	BarHeight = FMin(8.f * (Canvas.ClipX / 1024.f), 8.f) * ResModifier;
	InfoBaseX = ScreenPos.X - (BarLength * 0.5f);

	//Draw player name (Top)
	FontScale = class'KFGameEngine'.Static.GetKFFontScale() * FriendlyHudScale;
	FontAndResMod = 36 * FontScale * ResModifier;
	Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();

	// drop shadow for player name text
	Canvas.DrawColor = PlayerBarShadowColor;
	Canvas.SetPos(ScreenPos.X - (BarLength * 0.5f) + 1, ScreenPos.Y + 8);
	Canvas.DrawText(KFPRI.PlayerName, , FontScale, FontScale, MyFontRenderInfo);

	Canvas.DrawColor = PlayerBarTextColor;
	Canvas.SetPos(InfoBaseX, ScreenPos.Y + 7);
	Canvas.DrawText(KFPRI.PlayerName, , FontScale, FontScale, MyFontRenderInfo);

	//Draw armor bar (with custom color)
	Percentage = FMin(float(KFPH.Armor) / float(KFPH.MaxArmor), 100);
	DrawKFBar(Percentage, BarLength, BarHeight, InfoBaseX, ScreenPos.Y + BarHeight + FontAndResMod, UMArmorColor);

	//Draw health bar (with custom color)
	Percentage = FMin(float(KFPH.Health) / float(KFPH.HealthMax), 100);
	DrawKFBar(Percentage, BarLength, BarHeight, InfoBaseX, ScreenPos.Y + BarHeight * 2 + FontAndResMod, UMHealthColor);

	// Regen health
	if (SpecialRepInfo != None)
	{
		RegenHealth = SpecialRepInfo.GetRegenHealth(KFPH);
		if (RegenHealth > 0)
		{
			Canvas.DrawColor = UMRegenHealthColor;
			Canvas.SetPos(InfoBaseX + (BarLength - 2.0) * Percentage, ScreenPos.Y + BarHeight * 2 + FontAndResMod + 1);
			Percentage = FMin(float(RegenHealth) / float(KFPH.HealthMax),100);
			Canvas.DrawTile(PlayerStatusBarBGTexture, (BarLength - 2.0) * Percentage, BarHeight - 2.0, 0, 0, 32, 32);
		}
	}

	if( KFPRI.CurrentPerkClass == none )
	{
		return false;
	}

	// drop shadow for perk name text
	Canvas.DrawColor = PlayerBarShadowColor;
	Canvas.SetPos(ScreenPos.X - (BarLength * 0.5f) + 1, ScreenPos.Y + BarHeight * 3 + (36 * FontScale * ResModifier) + 1);
	Canvas.DrawText(KFPRI.GetActivePerkLevel() @KFPRI.CurrentPerkClass.default.PerkName, , FontScale, FontScale, MyFontRenderInfo);

	//Draw perk level and name text
	Canvas.DrawColor = PlayerBarTextColor;
	Canvas.SetPos(InfoBaseX, ScreenPos.Y + BarHeight * 3 + FontAndResMod);
	Canvas.DrawText(KFPRI.GetActivePerkLevel() @KFPRI.CurrentPerkClass.default.PerkName, , FontScale, FontScale, MyFontRenderInfo);

	//draw perk icon
	// drop shadow for perk icon
	Canvas.DrawColor = PlayerBarShadowColor;
	PerkIconSize = PlayerStatusIconSize * ResModifier;
	PerkIconPosX = ScreenPos.X - (BarLength * 0.5f) - PerkIconSize + 1;
	PerkIconPosY = ScreenPos.Y + FontAndResMod + 1;
	SupplyIconPosX = ScreenPos.X + (BarLength * 0.5f) + 1;
	SupplyIconPosY = PerkIconPosY + 4 * ResModifier;
	DrawPerkIcons(KFPH, PerkIconSize, PerkIconPosX, PerkIconPosY, SupplyIconPosX, SupplyIconPosY, true);

	//draw perk icon
	Canvas.DrawColor = PlayerBarIconColor;
	PerkIconPosX = ScreenPos.X - (BarLength * 0.5f) - PerkIconSize;
	PerkIconPosY = ScreenPos.Y + FontAndResMod;
	SupplyIconPosX = ScreenPos.X + (BarLength * 0.5f);
	SupplyIconPosY = PerkIconPosY + 4 * ResModifier;
	DrawPerkIcons(KFPH, PerkIconSize, PerkIconPosX, PerkIconPosY, SupplyIconPosX, SupplyIconPosY, false);

	return true;
}

/** Copy/paste modified for custom Supplier colors */
simulated function DrawPerkIcons(KFPawn_Human KFPH, float PerkIconSize, float PerkIconPosX, float PerkIconPosY, float SupplyIconPosX, float SupplyIconPosY, bool bDropShadow)
{
	local byte PrestigeLevel;
	local KFPlayerReplicationInfo KFPRI;
	local color TempColor;
	local float ResModifier;

	KFPRI = KFPlayerReplicationInfo(KFPH.PlayerReplicationInfo);

	if (KFPRI == none)
	{
		return;
	}

	PrestigeLevel = KFPRI.GetActivePerkPrestigeLevel();
	ResModifier = WorldInfo.static.GetResolutionBasedHUDScale() * FriendlyHudScale;

	if (KFPRI.CurrentVoiceCommsRequest == VCT_NONE && KFPRI.CurrentPerkClass != none && PrestigeLevel > 0)
	{
		Canvas.SetPos(PerkIconPosX, PerkIconPosY);
		Canvas.DrawTile(KFPRI.CurrentPerkClass.default.PrestigeIcons[PrestigeLevel - 1], PerkIconSize, PerkIconSize, 0, 0, 256, 256);
	}

	if (PrestigeLevel > 0)
	{																//icon slot in image is not centered
		Canvas.SetPos(PerkIconPosX + (PerkIconSize * (1 - PrestigeIconScale)) / 2, PerkIconPosY + PerkIconSize * 0.05f);
		Canvas.DrawTile(KFPRI.GetCurrentIconToDisplay(), PerkIconSize * PrestigeIconScale, PerkIconSize * PrestigeIconScale, 0, 0, 256, 256);
	}
	else
	{
		Canvas.SetPos(PerkIconPosX, PerkIconPosY);
		Canvas.DrawTile(KFPRI.GetCurrentIconToDisplay(), PerkIconSize, PerkIconSize, 0, 0, 256, 256);
	}

	if (KFPRI.PerkSupplyLevel > 0 && KFPRI.CurrentPerkClass.static.GetInteractIcon() != none)
	{
		if (!bDropShadow)
		{
			ClientConfig.HUDHelper.GetSupplierColor(KFPRI, TempColor);
			Canvas.DrawColor = TempColor;
		}

		Canvas.SetPos(SupplyIconPosX, SupplyIconPosY); //offset so that supplier icon shows up on the correct side of the player's health bar
		Canvas.DrawTile(KFPRI.CurrentPerkClass.static.GetInteractIcon(), (PlayerStatusIconSize * 0.75) * ResModifier, (PlayerStatusIconSize * 0.75) * ResModifier, 0, 0, 256, 256);
	}
}

defaultproperties
{
	// These are the KFHUDBase defaults for health/armor, white for regen
	UMHealthColor=(R=95, G=210, B=255, A=192)
	UMRegenHealthColor=(R=255, G=255, B=255, A=192)
	UMArmorColor=(R=0, G=0, B=255, A=192)
}