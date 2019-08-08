//================================================
// UMWaveInfoInteraction
//================================================
// Custom Interaction for Unofficial Mod
// Renders wave info for players in menus
// (very useful for those who join in
// the middle of a multiplayer game)
//================================================
// (c) 2018 "Insert Name Here"
//================================================
class UMWaveInfoInteraction extends UMBaseInteraction;

/** Current Canvas.SizeX/Y
	Used to scale/position wave info box */
var Vector2D CanvasSize;

/** Current location and size for wave info */
var Vector2D WaveInfoLoc, WaveInfoSize;

/** Text scale */
var float TextScale;

/** Render our info */
event PostRender(Canvas C)
{
	local KFGameReplicationInfo KFGRI;
	local string WaveInfoText;
	local FontRenderInfo FRI;
	local float FontScale, TextWidth, TextHeight, TextOffsetY;
	local int ExtraTraderTime;

	// First conditions
	if (OwningKFPC == None || !OwningKFPC.WorldInfo.GRI.bMatchHasBegun || OwningKFPC.WorldInfo.GRI.bMatchIsOver ||
		OwningKFPC.WorldInfo.GRI.bRoundIsOver || OwningKFPC.MyGFxManager == None ||
		!OwningKFPC.MyGFxManager.bMenusOpen || !OwningKFPC.MyGFxManager.bMenusActive ||
		KFGFxMenu_Trader(OwningKFPC.MyGFxManager.CurrentMenu) != None)
		return;
		
	if (CanvasSize.X != C.SizeX || CanvasSize.Y != C.SizeY)
		RecalcLocAndSize(C);
		
	// Build the wave string
	KFGRI = KFGameReplicationInfo(OwningKFPC.WorldInfo.GRI);
	if (KFGRI.bEndlessMode)
		WaveInfoText = "(" $ KFGRI.WaveNum $ ")";
	else
		WaveInfoText = "(" $ KFGRI.WaveNum $ "/" $ KFGRI.GetFinalWaveNum() $ ")";
		
	if (KFGRI.bTraderIsOpen)
	{
		WaveInfoText @= ("TRADER:" @ GetTimeString(KFGRI.GetTraderTimeRemaining()));

		// Add additional time if we can extend Trader time
		// and we are still in the lobby (as this isn't
		// really relevant if we have already spawned in)
		if (KFPawn_Customization(OwningKFPC.Pawn) != None && ClientConfig.CanExtendTraderTimeFor(OwningKFPC.Pawn))
		{
			ExtraTraderTime = Min(ClientConfig.MidGameJoinerTraderTime, ClientConfig.MaxTraderTime - KFGRI.RemainingTime);
			WaveInfoText @= ("(+" $ GetTimeString(ExtraTraderTime) $ ")");
		}
	}
	else
	{
		// Check if this is an endless objective wave
		if (KFGRI.IsEndlessWave() && KFGRI.ObjectiveInterface != None && !KFGRI.ObjectiveInterface.IsComplete())
			WaveInfoText @= ("OBJ:" @ KFGRI.ObjectiveInterface.GetProgressText());
		else if (KFGRI.IsBossWave())
			WaveInfoText @= "BOSS";
		else
			WaveInfoText @= ("ZEDS:" @ KFGRI.AIRemaining);
	}
	
	// Setup the font and scaling
	FRI = C.CreateFontRenderInfo(true);
	FontScale = class'KFGame.KFGameEngine'.static.GetKFFontScale() * TextScale;
	C.Font = class'KFGame.KFGameEngine'.static.GetKFCanvasFont();
	C.TextSize(WaveInfoText, TextWidth, TextHeight, FontScale, FontScale);
	TextOffsetY = (WaveInfoSize.Y - TextHeight) * 0.5;

	// Draw the info box
	C.SetDrawColor(0, 0, 0, 255);
	C.SetPos(WaveInfoLoc.X, WaveInfoLoc.Y);
	C.DrawTile(Texture2D'EngineResources.WhiteSquareTexture', WaveInfoSize.X, WaveInfoSize.Y, 0, 0, 32, 32);
	
	// And the text
	C.SetDrawColor(255, 255, 255, 255);
	C.SetPos(WaveInfoLoc.X + (0.04 * WaveInfoSize.X), WaveInfoLoc.Y + TextOffsetY);
	C.DrawText(WaveInfoText, , FontScale, FontScale, FRI);
}

/** Calculates location and size of the wave info box
	so we're only calculating this when the resolution
	changes instead of every frame */
function RecalcLocAndSize(Canvas C)
{
	local float RatioX, RatioY;

	CanvasSize.X = C.SizeX;
	CanvasSize.Y = C.SizeY;
		
	RatioX = C.SizeX / 1920.0;
	RatioY = C.SizeY / 1080.0;
	
	WaveInfoLoc.X = default.WaveInfoLoc.X * RatioX;
	WaveInfoLoc.Y = default.WaveInfoLoc.Y * RatioY;
	WaveInfoSize.X = default.WaveInfoSize.X * RatioX;
	WaveInfoSize.Y = default.WaveInfoSize.Y * RatioY;
}

/** Get time string for given seconds */
function string GetTimeString(int TotalSeconds)
{
	local int Minutes, Seconds;
	
	Minutes = TotalSeconds / 60;
	Seconds = TotalSeconds % 60;
	
	if (Seconds >= 10)
		return (Minutes $ ":" $ Seconds);
	
	return (Minutes $ ":0" $ Seconds);
}

/** Function to modify wave info text scale for testing */
/*exec function UMWaveInfoTextScale(float Scale)
{
	TextScale = FClamp(Scale, 0.5, 5.0);
}*/

defaultproperties
{
	// Defaults for 1920x1080
	WaveInfoLoc=(X=1456, Y=704)
	WaveInfoSize=(X=250, Y=48)
	TextScale=1.35
}