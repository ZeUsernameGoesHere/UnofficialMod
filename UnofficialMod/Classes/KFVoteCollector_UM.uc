//================================================
// KFVoteCollector_UM
//================================================
// Custom vote collector for Unofficial Mod
// Changes to kick vote to lessen abuse like
// showing the vote initiator and limiting the
// number of times anyone can initiate a kick vote
//================================================
// (c) 2018 "Insert Name Here"
//================================================
class KFVoteCollector_UM extends KFVoteCollector
	within KFGameReplicationInfo;
	
/** Max failed kick vote attempts ( <= 0 disables this ) */
var int MaxFailedKickVoteAttempts;

/** Kick player for attempting and failing too many kick votes
	(if false, it just prevents them from attempting any more) */
var bool bKickFailedVoteInitiator;

/** Holds failed kick vote attempts */
struct FailedKickVoteInfo extends sVoteInfo
{
	var int FailedAttempts;
};

/** Failed kick vote attempts this session */
var array<FailedKickVoteInfo> FailedKickVotes;

/** Current vote initiator
	Ensures that this player can be properly tracked if
	they leave before failing an attempt to kick vote */
var sVoteInfo CurrentInitiator;

/** Copy/paste modified to show the vote initiator and
	see if they have attempted too many kick votes */
function ServerStartVoteKick(PlayerReplicationInfo PRI_Kickee, PlayerReplicationInfo PRI_Kicker)
{
	local int i;
	local array<KFPlayerReplicationInfo> PRIs;
	local KFGameInfo KFGI;
	local KFPlayerController KFPC, KickeePC;
	local FailedKickVoteInfo FKVI;

	KFGI = KFGameInfo(WorldInfo.Game);
	KFPC = KFPlayerController(PRI_Kicker.Owner);
	KickeePC = KFPlayerController(PRI_Kickee.Owner);

	// Kick voting is disabled
	if(KFGI.bDisableKickVote)
	{
		KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_KickVoteDisabled);
		return;
	}

	// Spectators aren't allowed to vote
	if(PRI_Kicker.bOnlySpectator)
	{
		KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_KickVoteNoSpectators);
		return;
	}

	// Not enough players to start a vote
	if( KFGI.NumPlayers <= 2 )
	{
		KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_KickVoteNotEnoughPlayers);
		return;
	}

	// Maximum number of players kicked per match has been reached
	if( KickedPlayers >= 2 )
	{
		KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_KickVoteMaxKicksReached);
		return;
	}

	// Can't kick admins
	if(KFGI.AccessControl != none)
	{
		if(KFGI.AccessControl.IsAdmin(KickeePC))
		{
			KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_KickVoteAdmin);
			return;
		}
	}

	// Last vote failed, must wait until failed vote cooldown before starting a new vote
	if( bIsFailedVoteTimerActive )
	{
		KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_KickVoteRejected);
		return;
	}

	// Maximum failed kick vote attempts reached for this player
	if (MaxFailedKickVoteAttempts > 0)
	{
		foreach FailedKickVotes(FKVI)
		{
			if (FKVI.PlayerPRI == PRI_Kicker && FKVI.FailedAttempts >= MaxFailedKickVoteAttempts)
			{
				KFPC.ReceiveLocalizedMessage(class'UnofficialMod.UMLocalMessage', UMLMT_TooManyFailedKickVotes);
				return;
			}
		}
	}
	
	// A kick vote is not allowed while another vote is active
	if (bIsSkipTraderVoteInProgress || bIsPauseGameVoteInProgress)
	{
		KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_OtherVoteInProgress);
		return;
	}

	if( !bIsKickVoteInProgress )
	{
		// Clear voter array
		PlayersThatHaveVoted.Length = 0;

		// Cache off these values in case player leaves before vote ends -- no cheating!
		CurrentKickVote.PlayerID = PRI_Kickee.UniqueId;
		CurrentKickVote.PlayerPRI = PRI_Kickee;
		CurrentKickVote.PlayerIPAddress = KickeePC.GetPlayerNetworkAddress();

		// Also cache vote initiator for same reason
		CurrentInitiator.PlayerID = PRI_Kicker.UniqueId;
		CurrentInitiator.PlayerPRI = PRI_Kicker;
		CurrentInitiator.PlayerIPAddress = KFPC.GetPlayerNetworkAddress();

		bIsKickVoteInProgress = true;

		GetKFPRIArray(PRIs);
		for (i = 0; i < PRIs.Length; i++)
		{
			PRIs[i].ShowKickVote(PRI_Kickee, VoteTime, !(PRIs[i] == PRI_Kicker || PRIs[i] == PRI_Kickee));
		}
		// Replace with our own broadcast message showing who initiated the vote
		KFGI.BroadcastLocalized(KFGI, class'UnofficialMod.UMLocalMessage', UMLMT_StartedKickVote, CurrentKickVote.PlayerPRI, CurrentInitiator.PlayerPRI);
		SetTimer( VoteTime, false, nameof(ConcludeVoteKick), self );
		// Cast initial vote
		RecieveVoteKick(PRI_Kicker, true);
	}
	else if (PRI_Kickee == CurrentKickVote.PlayerPRI)
	{
		RecieveVoteKick(PRI_Kicker, false);
	}
	else
	{
		// Can't start a new vote until current one is over
		KFPlayerController(PRI_Kicker.Owner).ReceiveLocalizedMessage(class'KFLocalMessage', LMT_KickVoteInProgress);
	}
}

/** Copy/paste modified to check for vote initiator to
	prevent them from initiating a kick vote too many
	times and kick them if the config option is set */
reliable server function ConcludeVoteKick()
{
	local array<KFPlayerReplicationInfo> PRIs;
	local int i, NumPRIs;
	local KFGameInfo KFGI;
	local KFPlayerController KickedPC;
	local int KickVotesNeeded;

	KFGI = KFGameInfo(WorldInfo.Game);

	if(bIsKickVoteInProgress)
	{
		GetKFPRIArray(PRIs);

		for (i = 0; i < PRIs.Length; i++)
		{
			PRIs[i].HideKickVote();			
		}

		NumPRIs = PRIs.Length;

		// Current Kickee PRI should not count towards vote percentage
		if( PRIs.Find(CurrentKickVote.PlayerPRI) != INDEX_NONE )
		{
			NumPRIs--;
		}

		KickVotesNeeded = FCeil(float(NumPRIs) * KFGI.KickVotePercentage);
		KickVotesNeeded = Clamp(KickVotesNeeded, 1, NumPRIs);

		if( YesVotes >= KickVotesNeeded )
		{
			// See if kicked player has left
			if( CurrentKickVote.PlayerPRI == none || CurrentKickVote.PlayerPRI.bPendingDelete )
			{
				for( i = 0; i < WorldInfo.Game.InactivePRIArray.Length; i++ )
				{
					if( WorldInfo.Game.InactivePRIArray[i].UniqueId == CurrentKickVote.PlayerID )
					{
						CurrentKickVote.PlayerPRI = WorldInfo.Game.InactivePRIArray[i];
						break;
					}
				}
			}


			if(KFGI.AccessControl != none)
			{
				KickedPC = ( (CurrentKickVote.PlayerPRI != none) && (CurrentKickVote.PlayerPRI.Owner != none) ) ? KFPlayerController(CurrentKickVote.PlayerPRI.Owner) : none;
				KFAccessControl(KFGI.AccessControl).KickSessionBanPlayer(KickedPC, CurrentKickVote.PlayerID, KFGI.AccessControl.KickedMsg);
			}
			//tell server to kick target PRI
			KFGI.BroadcastLocalized(KFGI, class'KFLocalMessage', LMT_KickVoteSucceeded, CurrentKickVote.PlayerPRI);

			// Increment number of kicked players this session
			KickedPlayers++;
		}
		else
		{
			//Set timer so that votes cannot be spammed
			bIsFailedVoteTimerActive=true;
			SetTimer( KFGI.TimeBetweenFailedVotes, false, nameof(ClearFailedVoteFlag), self );
			KFGI.BroadcastLocalized(KFGI, class'KFLocalMessage', LMT_KickVoteFailed, CurrentKickVote.PlayerPRI);
			
			// Add vote initiator if needed
			// NOTE: We now check this regardless
			// because server admin may change max
			// failed kick vote attempts mid-game
			// using UMAdminExecInteraction
			// See if vote initiator has left
			if( CurrentInitiator.PlayerPRI == none || CurrentInitiator.PlayerPRI.bPendingDelete )
			{
				for( i = 0; i < WorldInfo.Game.InactivePRIArray.Length; i++ )
				{
					if( WorldInfo.Game.InactivePRIArray[i].UniqueId == CurrentInitiator.PlayerID )
					{
						CurrentInitiator.PlayerPRI = WorldInfo.Game.InactivePRIArray[i];
						break;
					}
				}
			}

			i = FailedKickVotes.Find('PlayerPRI', CurrentInitiator.PlayerPRI);
			if (i != INDEX_NONE)
				FailedKickVotes[i].FailedAttempts++;
			else
			{
				FailedKickVotes.Add(1);
				i = FailedKickVotes.Length - 1;
				FailedKickVotes[i].PlayerID = CurrentInitiator.PlayerID;
				FailedKickVotes[i].PlayerPRI = CurrentInitiator.PlayerPRI;
				FailedKickVotes[i].PlayerIPAddress = CurrentInitiator.PlayerIPAddress;
				FailedKickVotes[i].FailedAttempts = 1;
			}

			if (MaxFailedKickVoteAttempts > 0)
			{
				// Kick player if they attempted and failed too many kick votes
				if (bKickFailedVoteInitiator && FailedKickVotes[i].FailedAttempts >= MaxFailedKickVoteAttempts && KFGI.AccessControl != None)
				{
					KickedPC = ((CurrentInitiator.PlayerPRI != None) && (CurrentInitiator.PlayerPRI.Owner != None)) ? KFPlayerController(CurrentInitiator.PlayerPRI.Owner) : None;
					KFAccessControl(KFGI.AccessControl).KickSessionBanPlayer(KickedPC, CurrentInitiator.PlayerID, KFGI.AccessControl.KickedMsg);
					
					KFGI.BroadcastLocalized(KFGI, class'UnofficialMod.UMLocalMessage', UMLMT_KickedForTooManyAttempts, CurrentInitiator.PlayerPRI);
					// Increment kicked players
					KickedPlayers++;
				}
			}
		}

		bIsKickVoteInProgress = false;
		CurrentKickVote.PlayerPRI = none;
		CurrentKickVote.PlayerID = class'PlayerReplicationInfo'.default.UniqueId;
		CurrentInitiator.PlayerPRI = None;
		CurrentInitiator.PlayerID = class'PlayerReplicationInfo'.default.UniqueId;
		yesVotes = 0;
		noVotes = 0;
	}
}

defaultproperties
{
	MaxFailedKickVoteAttempts=2
}