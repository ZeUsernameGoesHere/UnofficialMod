//================================================
// UMSystemMessage
//================================================
// System message handler for Unofficial Mod
//================================================
// (c) 2019 "Insert Name Here"
//================================================
class UMSystemMessage extends KFLocalMessage
	abstract;

var localized string DisabledSettingString;
var localized string EnabledSettingString;
var localized string NextSessionString;
var localized string ModNameString;

var localized string WeaponUpgradesString;
var localized string Tier1WeaponsString;
var localized string KF1SyringeString;
var localized string RandomMapObjString;
var localized string FailedKickVotesString;
var localized string KickFailedVoteInitString;
var localized string PerkKnifeSpeedBoostString;
var localized string PerkKnifeSlowerPlayersString;
var localized string PerkKnifeAllPlayersString;
var localized string MidGameJoinerTraderTimeString;
var localized string DefaultUpgradeLevelString;
var localized string AddUpgradeOverrideString;
var localized string RemoveUpgradeOverrideString;
var localized string NoUpgradeOverrideString;
var localized string GameplayWeaponString;
var localized string BloatMinesRemovedString;
var localized string DisableOthersWeaponsPickupString;
var localized string PlayerPickedUpOthersWeaponString;

enum UMSystemMessageType
{
	UMSMT_WeaponUpgrades,
	UMSMT_Tier1Weapons,
	UMSMT_KF1Syringe,
	UMSMT_RandomMapObj,
	UMSMT_FailedKickVotes,
	UMSMT_KickFailedVoteInit,
	UMSMT_PerkKnifeSpeedBoost,
	UMSMT_MidGameJoinerTraderTime,
	UMSMT_DefaultUpgradeLevel,
	UMSMT_AddUpgradeOverride,
	UMSMT_RemoveUpgradeOverride,
	UMSMT_NoUpgradeOverride,
	UMSMT_GameplayWeapon,
	UMSMT_BloatMinesRemoved,
	UMSMT_DisableOthersWeaponsPickup,
	UMSMT_PlayerPickedUpOthersWeapon
};

/** Get our custom string
	NOTE: Switch is encoded as follows:
	Low byte is message type
	Second byte is value */
static function string GetString(
	optional int Switch,
	optional bool bPRI1HUD,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
	local int MsgType, MsgValue;
	local string SettingString, FullString;
	local class<KFWeaponDefinition> WeaponDef;
	local class<KFWeapon> KFWClass;
	
	MsgType = Switch & 255;
	MsgValue = (Switch >> 8) & 65535;
	SettingString = (MsgValue > 0 ? default.EnabledSettingString : default.DisabledSettingString);

	switch (MsgType)
	{
		case UMSMT_WeaponUpgrades:
			FullString = default.WeaponUpgradesString @ SettingString @ default.NextSessionString;
			break;
		case UMSMT_Tier1Weapons:
			FullString = default.Tier1WeaponsString @ SettingString @ default.NextSessionString;
			break;
		case UMSMT_KF1Syringe:
			FullString = default.KF1SyringeString @ SettingString @ default.NextSessionString;
			break;
		case UMSMT_RandomMapObj:
			FullString = default.RandomMapObjString @ SettingString @ default.NextSessionString;
			break;
		case UMSMT_FailedKickVotes:
			FullString = default.FailedKickVotesString @ MsgValue;
			break;
		case UMSMT_KickFailedVoteInit:
			FullString = default.KickFailedVoteInitString @ SettingString;
			break;
		case UMSMT_PerkKnifeSpeedBoost:
			if (MsgValue == 1)
				FullString = default.PerkKnifeSpeedBoostString @ default.PerkKnifeSlowerPlayersString;
			else if (MsgValue == 2)
				FullString = default.PerkKnifeSpeedBoostString @ default.PerkKnifeAllPlayersString;
			else
				FullString = default.PerkKnifeSpeedBoostString @ default.DisabledSettingString;
				
			break;
		case UMSMT_MidGameJoinerTraderTime:
			FullString = Repl(default.MidGameJoinerTraderTimeString, "%x%", MsgValue);
			break;
		case UMSMT_DefaultUpgradeLevel:
		case UMSMT_AddUpgradeOverride:
			// We add the default max upgrade
			// count to fit negative values
			// into 0-255, so subtract it here
			MsgValue -= class'UnofficialMod.UnofficialModMut'.default.MaxWeaponUpgradeCount;
			if (MsgValue == 0)
				SettingString = "NONE";
			else if (MsgValue > 0)
				SettingString = "UP TO" @ MsgValue;
			else
				SettingString = "ALL BUT" @ (-MsgValue);
				
			if (MsgType == UMSMT_DefaultUpgradeLevel)
				FullString = default.DefaultUpgradeLevelString @ SettingString @ default.NextSessionString;
			else // if (MsgType == UMSMT_AddUpgradeOverride)
			{
				WeaponDef = class<KFWeaponDefinition>(OptionalObject);
				FullString = Repl(default.AddUpgradeOverrideString, "%x%", WeaponDef.static.GetItemName()) @ SettingString @ default.NextSessionString;
			}
			
			break;
		case UMSMT_RemoveUpgradeOverride:
			WeaponDef = class<KFWeaponDefinition>(OptionalObject);
			FullString = Repl(default.RemoveUpgradeOverrideString, "%x%", WeaponDef.static.GetItemName()) @ default.NextSessionString;
			break;
		case UMSMT_NoUpgradeOverride:
			WeaponDef = class<KFWeaponDefinition>(OptionalObject);
			FullString = default.NoUpgradeOverrideString @ WeaponDef.static.GetItemName();
			break;
		case UMSMT_GameplayWeapon:
			KFWClass = class<KFWeapon>(OptionalObject);
			FullString = Repl(default.GameplayWeaponString, "%x%", KFWClass.default.ItemName) @ SettingString @ default.NextSessionString;
			break;
		case UMSMT_BloatMinesRemoved:
			FullString = Repl(default.BloatMinesRemovedString, "%x%", MsgValue);
			break;
		case UMSMT_DisableOthersWeaponsPickup:
			FullString = default.DisableOthersWeaponsPickupString @ SettingString;
			break;
		case UMSMT_PlayerPickedUpOthersWeapon:
			KFWClass = class<KFWeapon>(OptionalObject);
			// Chr(208) is Ð (close parallel to dosh symbol)
			FullString = RelatedPRI_1.GetHumanReadableName() @ default.PlayerPickedUpOthersWeaponString @ RelatedPRI_2.GetHumanReadableName() $
				"'s" @ KFWClass.default.ItemName @ "(" $ Chr(208) $ MsgValue $ ")";
			break;
	}
	
	if (FullString != "")
		return default.ModNameString @ FullString;
	
	return "";
}

/** All system messages get the event color */
static function string GetHexColor(int Switch)
{
	return class'KFGame.KFLocalMessage'.default.EventColor;
}

defaultproperties
{
}