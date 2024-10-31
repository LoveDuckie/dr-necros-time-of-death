class TAInputHandler extends PlayerInput within TAPlayerController;

var TAPlayerCamera GameCamera;
var input float aMyAxisLeftX;

var public TAPlayerController PlayerControllerRef;

var PlayerStart playerSpawn;


event PlayerInput(float deltaTime)
{
	super.PlayerInput(deltaTime);
	aMyAxisLeftX += aTurn;
}

exec function Back()
{
	if (TAGame(WorldInfo.Game).GameState == TAGame(WorldInfo.Game).EGameState.MainMenu)
	{
	}
	else if (TAGame(WorldInfo.Game).GameState == TAGame(WorldInfo.Game).EGameState.InGame)
	{
		if (IsActiveInGame)
			Pawn.TakeDamage(TAHero(Pawn).HealthMax, Pawn.Controller, Location, vect(0,0,0), class'TADmgType');
	}
}

// Command: Make the surrounding humans follow the player when this button is pushed
exec function Follow()
{
	local TAHuman human;
	local TAObjectiveTrigger trigger;
	local bool availableHumans;

	trigger = none;

	if (TAGame(WorldInfo.Game).GameState == TAGame(WorldInfo.Game).EGameState.MainMenu)
	{
	}
	else if (TAGame(WorldInfo.Game).GameState == TAGame(WorldInfo.Game).EGameState.InGame)
	{
		if (IsActiveInGame)
		{
			TAHero(Pawn).CurrentHumansFollowingTime = 0;
			TAHero(Pawn).ShowingHumansFollowing = true;
		}

		foreach VisibleActors(class'TAObjectiveTrigger',trigger,100.0f)
		{
			if (trigger.bActiveObjectiveTrigger)
			{
				trigger.Interact(self.PlayerControllerRef.Pawn);
			}
		}

		
		if (trigger == none)
		{

				// First get all the visible humans and see if any of them are available to follow
				foreach VisibleActors(class'TAHuman',human,TAHero(Pawn).FollowRadius,TAHero(Pawn).Location)
				{
					if (TAAIHumanController(human.Controller).Following == none && human.Health > 0)
					{
						availableHumans = true;
						break;
					}
				}

				// Go through the visible humans again to apply our intent
				foreach VisibleActors(class'TAHuman',human,TAHero(Pawn).FollowRadius,TAHero(Pawn).Location)
				{
					// If there are available humans then the intent is to make them follow
					if (availableHumans)
					{
						if (TAAIHumanController(human.Controller).Following == none && human.Health > 0 && TAAIHumanController(human.Controller).CanFollowHero)
						{
							if(TAHero(Pawn).HumansFollowing.Length < TAGame(WorldInfo.Game).FollowCap)
							{
								TAAIHumanController(human.Controller).FollowPlayer(TAHero(Pawn));

								TAPlayerController(Pawn.Controller).SaySpeech(TAPlayerController(Pawn.Controller).HumanFollowSound, TAPlayerController(Pawn.Controller).CHANCE_FOR_HUMAN_FOLLOW_SOUND);

								human.SelectedRing.SetMaterial(0, TAHero(Pawn).followRingMat);
								human.SelectedRing.SetHidden(false);
							}

							TAHero(pawn).PlayFollowAnim();
							
						}
					}
					else // Otherwise, make the following humans unfollow
					{
						if (TAAIHumanController(human.Controller).Following == TAHero(Pawn))
						{
							TAPlayerController(Pawn.Controller).SaySpeech(TAPlayerController(Pawn.Controller).HumanStopFollowSound, TAPlayerController(Pawn.Controller).CHANCE_FOR_HUMAN_STOP_FOLLOW_SOUND);

							TAAIHumanController(human.Controller).UnFollow(TAHero(Pawn));
							human.SelectedRing.SetHidden(true);
						}
					}
				}
		}

	}
}

exec function RSButton_Next()
{
	if (TAGame(WorldInfo.Game).GameState == TAGame(WorldInfo.Game).EGameState.MainMenu)
	{
		TAGame(WorldInfo.Game).LeaderboardGet.Index += TAGame(WorldInfo.Game).LeaderboardGet.Count;
		if (TAGame(WorldInfo.Game).LeaderboardGet.Index >= TAGame(WorldInfo.Game).LeaderboardGet.MaxPages * TAGame(WorldInfo.Game).LeaderboardGet.Count)
			TAGame(WorldInfo.Game).LeaderboardGet.Index = (TAGame(WorldInfo.Game).LeaderboardGet.MaxPages * TAGame(WorldInfo.Game).LeaderboardGet.Count) - TAGame(WorldInfo.Game).LeaderboardGet.Count;

		TAGame(WorldInfo.Game).LeaderboardGet.RequestData();

	}
	else if (TAGame(WorldInfo.Game).GameState == TAGame(WorldInfo.Game).EGameState.InGame)
	{
		if (TAPlayerController(Pawn.Controller).IsSelectingCharacter)
		{
			// Advance character index.
			PlayerControllerRef.CharacterIndex++;
			if (PlayerControllerRef.CharacterIndex > 3)
			{
				PlayerControllerRef.CharacterIndex = 0;
			}
		}
	}
}

exec function RSButton_Previous()
{
	if (TAGame(WorldInfo.Game).GameState == TAGame(WorldInfo.Game).EGameState.MainMenu)
	{
		TAGame(WorldInfo.Game).LeaderboardGet.Index -= TAGame(WorldInfo.Game).LeaderboardGet.Count;
		if (TAGame(WorldInfo.Game).LeaderboardGet.Index < 0)
			TAGame(WorldInfo.Game).LeaderboardGet.Index = 0;

		TAGame(WorldInfo.Game).LeaderboardGet.RequestData();
	}
	else if (TAGame(WorldInfo.Game).GameState == TAGame(WorldInfo.Game).EGameState.InGame)
	{
		if (TAPlayerController(Pawn.Controller).IsSelectingCharacter)
		{
			// Advance character index.
			PlayerControllerRef.CharacterIndex--;
			if (PlayerControllerRef.CharacterIndex < 0)
			{
				PlayerControllerRef.CharacterIndex = 3;
			}
		}
	}
}

exec function SuperQuit()
{
	if (TAGame(WorldInfo.Game).GameState == TAGame(WorldInfo.Game).EGameState.MainMenu)
	{
		ConsoleCommand("quit");
	}
	else if (TAGame(WorldInfo.Game).GameState == TAGame(WorldInfo.Game).EGameState.InGame)
	{

	}
	else if (TAGame(WorldInfo.Game).GameState == TAGame(WorldInfo.Game).EGameState.GameOver)
	{
		if (TAGame(WorldInfo.Game).GameOverState == TAGame(WorldInfo.Game).EGameOverState.TextEntry)
		{
			TAGame(WorldInfo.Game).GameOverName = Mid(TAGame(WorldInfo.Game).GameOverName, 0, Len(TAGame(WorldInfo.Game).GameOverName) - 1);
			if (TAGame(WorldInfo.Game).GameOverName == "")
				TAGame(WorldInfo.Game).GameOverName = Mid(TAGame(WorldInfo.Game).GAME_OVER_NAME_CHARS, 0, 1);
		}
		else if (TAGame(WorldInfo.Game).GameOverState == TAGame(WorldInfo.Game).EGameOverState.Succeeded)
		{
			ConsoleCommand("open TA-MainMenu");
		}
		else if (TAGame(WorldInfo.Game).GameOverState == TAGame(WorldInfo.Game).EGameOverState.Failed)
		{
			ConsoleCommand("open TA-MainMenu");
		}

		TAGame(WorldInfo.Game).GameOver();
	}
}

exec function Barricade()
{
	if (TAGame(WorldInfo.Game).GameState == TAGame(WorldInfo.Game).EGameState.MainMenu)
	{
		
	}
	else if (TAGame(WorldInfo.Game).GameState == TAGame(WorldInfo.Game).EGameState.InGame)
	{
		UseBarricade();
	}
}

exec function AButton()
{
	if (TAGame(WorldInfo.Game).GameState == TAGame(WorldInfo.Game).EGameState.MainMenu)
	{
		ConsoleCommand("open " $ class'TAGame'.const.STARTING_MAP);
	}
	else if (TAGame(WorldInfo.Game).GameState == TAGame(WorldInfo.Game).EGameState.InGame)
	{
		AttemptRespawn();
		UseObjective();
	}
	else if (TAGame(WorldInfo.Game).GameState == TAGame(WorldInfo.Game).EGameState.GameOver)
	{
		if (TAGame(WorldInfo.Game).GameOverState == TAGame(WorldInfo.Game).EGameOverState.TextEntry)
		{
			TAGame(WorldInfo.Game).GameOverName = TAGame(WorldInfo.Game).GameOverName $ Mid(TAGame(WorldInfo.Game).GAME_OVER_NAME_CHARS, 0, 1);
			if (Len(TAGame(WorldInfo.Game).GameOverName) > 3)
			{
				TAGame(WorldInfo.Game).GameOverName = Mid(TAGame(WorldInfo.Game).GameOverName, 0, 3);

				// This is where we update the leaderboard shit.
				// TAGame(WorldInfo.Game).GameOverName now represents the name to use

				TAGame(WorldInfo.Game).GameOverState = TAGame(WorldInfo.Game).EGameOverState.Sending;

				TAGame(WorldInfo.Game).DoLeaderboardStuff();
			
			}
		}
		else if (TAGame(WorldInfo.Game).GameOverState == TAGame(WorldInfo.Game).EGameOverState.Succeeded)
		{
			ConsoleCommand("open TA-MainMenu");
		}
		else if (TAGame(WorldInfo.Game).GameOverState == TAGame(WorldInfo.Game).EGameOverState.Failed)
		{
			TAGame(WorldInfo.Game).GameOverState = TAGame(WorldInfo.Game).EGameOverState.Sending;

			TAGame(WorldInfo.Game).DoLeaderboardStuff();
		}

		TAGame(WorldInfo.Game).GameOver();
	}
}

exec function CancelBarricade()
{
	if (TAGame(WorldInfo.Game).GameState == TAGame(WorldInfo.Game).EGameState.MainMenu)
	{

	}
	else if (TAGame(WorldInfo.Game).GameState == TAGame(WorldInfo.Game).EGameState.InGame)
	{
		DontUseBarricade();
	}
}



exec function StartButton()
{
	if (TAGame(WorldInfo.Game).GameState == TAGame(WorldInfo.Game).EGameState.MainMenu)
	{
		ConsoleCommand("open " $ class'TAGame'.const.STARTING_MAP);
	}
	else if (TAGame(WorldInfo.Game).GameState == TAGame(WorldInfo.Game).EGameState.InGame)
	{
		AttemptRespawn();
	}
}

function AttemptRespawn()
{
	local TAPlayerController pc;
	local bool foundCharacterIndex;
	local bool doRespawn;
	local TAFadeVolume volume;

	if (TAPlayerController(Pawn.Controller).IsSelectingCharacter)
	{
		if (TAPlayerController(Pawn.Controller).WaitingForRespawn && TAPlayerController(Pawn.Controller).RespawnTimer >= TAPlayerController(Pawn.Controller).RespawnTotalTime)
		{
			doRespawn = true;
		}
		else if (!TAPlayerController(Pawn.Controller).WaitingForRespawn)
		{
			doRespawn = true;
		}

		if (doRespawn)
		{
			foundCharacterIndex = false;
			foreach WorldInfo.AllControllers(class'TAPlayerController', pc)
			{
				if (pc.IsActiveInGame && pc.CharacterIndex == PlayerControllerRef.CharacterIndex)
				{
					foundCharacterIndex = true;
					break;
				}
			}

			if (!foundCharacterIndex)
			{
				TAPlayerController(Pawn.Controller).Respawn();

				foreach ALlActors(class'TAFadeVolume',volume)
				{
					/** Fade will only work if there are hero's in the volume, so this is safe to do */
					volume.Fade();
				}
			}
		}
	}
}

exec function TABroadcast(int val)
{
	//`Log(string(val));
}

exec function Shoot()
{

}

simulated event PostRender(Canvas canvas)
{
	super.PostRender(canvas);

	
}

defaultproperties
{
	bUsingGamepad = true;
}