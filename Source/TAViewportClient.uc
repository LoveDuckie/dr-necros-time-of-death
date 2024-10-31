class TAViewportClient extends GameViewportClient;

var array<LocalPlayer> LocalPlayers;

event bool Init(out string OutError)
{
	local bool result;
	result = super.Init(outError);
	return result;
}

exec function DebugCreatePlayer(int ControllerId, optional HeroType pHeroType)
{
	local LocalPlayer lp;
	local string Error;

	`log("CREATED A FOOKING PLAYER "$self);

	if(GamePlayers.Length < 5)
	{
		lp = CreatePlayer(ControllerId, Error, true);
		LocalPlayers.AddItem(lp);
	}

	self.BecomePrimaryPlayer(0);

	`log(Error);

	//SetSplitscreenConfiguration(ESplitScreenType.eSST_NONE);
	//UpdateActiveSplitScreenType();

}


function bool InputKey(int ControllerId, name Key, EInputEvent Event, float AmountDepressed = 1.f, bool bGamepad = FALSE)
{
	if (TAGame(GetCurrentWorldInfo().Game).GameState == TAGame(GetCurrentWorldInfo().Game).EGameState.MainMenu)
	{
		switch(Key)
		{
		case 'XboxTypeS_A':
			TAGame(GetCurrentWorldInfo().Game).GameState = TAGame(GetCurrentWorldInfo().Game).EGameState.InGame;
			ConsoleCommand("open " $ class'TAGame'.const.STARTING_MAP);
			break;
		case 'XboxTypeS_B':
			ConsoleCommand("quit");
			break;
		}
	}
	else if (TAGame(GetCurrentWorldInfo().Game).GameState == TAGame(GetCurrentWorldInfo().Game).EGameState.InGame)
	{
		switch(Key)
		{
			case 'XboxTypeS_Start': //capture the start input for any gamepad that's not already tied to a player, and join them!
				if(AllowJoin())
					DebugCreatePlayer(ControllerId);

				`log("Created player");
				break;
		}
	}

	return true;
}



function UpdateActiveSplitscreenType()
{
	ActiveSplitscreenType = eSST_NONE;
}

/** Returns whether it is acceptable for a new player to dynamically join the game -- (from the GameInfo) -- typically not during a menu level or cinematic */
function bool AllowJoin()
{
	return TAGame(GetCurrentWorldInfo().Game).AllowJoin();
}

/** Adds a new LocalPlayer to the game for the specified Gamepad ID */
event LocalPlayer CreatePlayer(int ControllerId, out string OutError, bool bSpawnActor)
{
	return super.CreatePlayer(ControllerId,OutError,bSpawnActor);
}

/** Finds the index of a LocalPlayer within the GamePlayers array */
function int GetIndexOfLocalPlayer(LocalPlayer LP)
{
	local int PlayerIndex;
	for(PlayerIndex = 0;PlayerIndex < GamePlayers.Length;PlayerIndex++)
	{
		if(GamePlayers[PlayerIndex] == LP)
			return PlayerIndex;
	}

	

	return -1;
}

DefaultProperties
{
	
	Default2PSplitType=eSST_NONE
	Default3PSplitType=eSST_NONE
}
