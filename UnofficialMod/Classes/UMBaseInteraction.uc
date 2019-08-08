//================================================
// UMBaseInteraction
//================================================
// Base Interaction for Unofficial Mod
//================================================
// (c) 2018 "Insert Name Here"
//================================================
class UMBaseInteraction extends Interaction
	abstract;
	
/** Owning PlayerController */
var KFPlayerController OwningKFPC;

/** UMClientConfig instance */
var UMClientConfig ClientConfig;

/** Game console (used for displaying messages) */
var Console GameConsole;

/** Display console message */
function ConsoleMsg(string Message)
{
	if (GameConsole == None)
		GameConsole = class'Engine.Engine'.static.GetEngine().GameViewport.ViewportConsole;
		
	if (GameConsole != None)
		GameConsole.OutputTextLine(Message);
	else
		`warn("[Unofficial Mod]" $ Message);
}

defaultproperties
{
}