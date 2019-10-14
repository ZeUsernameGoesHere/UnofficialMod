//================================================
// KFTraderDialogManager_UM
//================================================
// Custom Trader Dialog Manager for Unofficial Mod
// Allows players to disable Trader dialog
// either in whole or in part
//================================================
// (c) 2019 "Insert Name Here"
//================================================
class KFTraderDialogManager_UM extends KFTraderDialogManager
	dependson(UMClientConfig);

/** Dialog options grabbed from UMClientConfig */
var UMClientConfig.TraderDialogOptions DialogOptions;

/** NOTE: Check this on each update */
const MAX_TRADER_DIALOG = 275;

/** Override to add in check for disabled Trader dialog
	and to remove all log lines to eliminate log spam */
simulated function PlayDialog(int EventID, Controller C, bool bInterrupt = false)
{
    local KFPawn_Human KFPH;

    if( WorldInfo.NetMode == NM_DedicatedServer )
        return;

	// Check for disabled Trader dialog
	if (DialogOptions.bAll)
		return;

    if (C == none)
        return;

    if(!C.IsLocalController())
        return;

    if(!bEnabled || TraderVoiceGroupClass == none)
        return;

    if(EventID < 0 || EventID >= MAX_TRADER_DIALOG)
        return;

    if(C.Pawn == none || !C.Pawn.IsAliveAndWell())
        return;
        
    if(ActiveEventInfo.AudioCue != none && !bInterrupt)
        return;

    if(DialogIsCoolingDown(EventID))
        return;

    if (!ShouldDialogPlay(EventID))
        return;

    KFPH = KFPawn_Human(C.Pawn);
    if( KFPH != none )
    {
        if (bInterrupt)
        {
            KFPH.StopTraderDialog();
        }

        ActiveEventInfo = TraderVoiceGroupClass.default.DialogEvents[ EventID ];
        KFPH.PlayTraderDialog(ActiveEventInfo.AudioCue);
        SetTimer(ActiveEventInfo.AudioCue.Duration, false, nameof(EndOfDialogTimer));
    }
}

/** Override to add in check for disabled death dialog */
simulated function PlayPlayerDiedLastWaveDialog(KFPlayerController KFPC)
{
	if (!DialogOptions.bDeath)
		super.PlayPlayerDiedLastWaveDialog(KFPC);
}

/** Override to add in check for disabled armor/ammo/grenade dialog */
simulated function PlayOpenTraderMenuDialog(KFPlayerController KFPC)
{
	if (!DialogOptions.bArmorAmmoGrenade)
		super.PlayOpenTraderMenuDialog(KFPC);
}

defaultproperties
{
}