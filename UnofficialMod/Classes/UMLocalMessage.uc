//================================================
// UMLocalMessage
//================================================
// Localized message handler for Unofficial Mod
//================================================
// (c) 2018 "Insert Name Here"
//================================================
class UMLocalMessage extends KFLocalMessage
	abstract;

var localized string StartedKickVoteString;
var localized string TooManyFailedKickVotesString;
var localized string KickedForTooManyAttemptsString;
var localized string TraderTimeExtendedString;

enum UMLocalMessageType
{
	UMLMT_StartedKickVote,
	UMLMT_TooManyFailedKickVotes,
	UMLMT_KickedForTooManyAttempts,
	UMLMT_TraderTimeExtended,
	UMLMT_OtherPlayerKilledLargeZed
};

/** Override this to check for player killing large zed */
static function ClientReceive(
	PlayerController P,
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
	local class<KFPawn_Monster> KFPMClass;
	local KFPlayerReplicationInfo KFPRI;
	local KFPlayerController KFPC;
	local GFxObject GFxManager, DataObject;


	if (Switch == UMLMT_OtherPlayerKilledLargeZed)
	{
		if (!class'UnofficialMod.UMClientConfig'.default.bShowOthersLargeZedKills)
			return;

		// Adapted from KFGFxMoviePlayer_HUD.ShowKillMessage()
		KFPMClass = class<KFPawn_Monster>(OptionalObject);
		KFPRI = KFPlayerReplicationInfo(RelatedPRI_1);
		KFPC = KFPlayerController(P);
		
		if (KFPMClass == None || KFPRI == None || KFPC == None || KFPC.MyGFxHUD == None || !KFPC.bShowKillTicker)
			return;
			
		GFxManager = KFPC.MyGFxHUD.GetVariableObject("root");
		DataObject = KFPC.MyGFxHUD.CreateObject("Object");
		
        DataObject.SetBool("humanDeath", false);

        DataObject.SetString("killedName", KFPMClass.static.GetLocalizedName());
        DataObject.SetString("killedTextColor", "");
        // This would normally be left blank,
        // but the Flash HUD puts a space in the
        // kill message, which looks sloppy
        DataObject.SetString("killedIcon", "img://" $ class'KFGame.KFPerk_Monster'.static.GetPerkIconPath());

        DataObject.SetString("killerName", KFPRI.GetHumanReadableName());
        DataObject.SetString("killerTextColor", "");
        DataObject.SetString("killerIcon", "img://" $ KFPRI.CurrentPerkClass.static.GetPerkIconPath());

        GFxManager.SetObject("newBark", DataObject);

		return;
	}

	super.ClientReceive(P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
}

static function string GetString(optional int Switch,
	optional bool bPRI1HUD,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject)
{
	local UMClientConfig UMCC;
	local KFPlayerController KFPC;
	local string InitiatorName;

	switch (Switch)
	{
		case UMLMT_StartedKickVote:
			// Cache these names if needed
			UMCC = class'UnofficialMod.UMClientConfig'.static.GetInstance();
			if( UMCC != none )
			{
				KFPC = KFPlayerController(UMCC.WorldInfo.GetALocalPlayerController());
				if(KFPC != none && KFPC.MyGFxHUD != none)
					KFPC.MyGFxHUD.PendingKickPlayerName = RelatedPRI_1.PlayerName;

				UMCC.LastKickVoteInitiatorName = RelatedPRI_2.PlayerName;
			}

			return RelatedPRI_2.PlayerName @ default.StartedKickVoteString @ RelatedPRI_1.PlayerName;

		case UMLMT_TooManyFailedKickVotes:
			return default.TooManyFailedKickVotesString;

		case UMLMT_KickedForTooManyAttempts:
			// Restore player name from cache if needed
			if (RelatedPRI_1 != None)
				InitiatorName = RelatedPRI_1.PlayerName;
			else
			{
				UMCC = class'UnofficialMod.UMClientConfig'.static.GetInstance();
				if (UMCC != None)
				{
					InitiatorName = UMCC.LastKickVoteInitiatorName;
					UMCC.LastKickVoteInitiatorName = "";
				}
			}

			return InitiatorName @ default.KickedForTooManyAttemptsString;
		case UMLMT_TraderTimeExtended:
			return default.TraderTimeExtendedString;
	}
	
	return "";
}

static function string GetHexColor(int Switch)
{
	switch (Switch)
	{
		case UMLMT_StartedKickVote:
		case UMLMT_TooManyFailedKickVotes:
		case UMLMT_KickedForTooManyAttempts:
		case UMLMT_TraderTimeExtended:
			return class'KFGame.KFLocalMessage'.default.EventColor;
	}

	return class'KFGame.KFLocalMessage'.default.DefaultColor;
}

defaultproperties
{
}