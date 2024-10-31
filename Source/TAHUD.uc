class TAHUD extends HUD;

var TAScaleformHUD ScaleformHUD;
var TAScaleformMainMenu ScaleformMainMenu;

const SHOW_BAR_DISTANCE = 1500.0f;

event PostBeginPlay()
{
	local TAPlayerController playerController;

	if (TAGame(WorldInfo.Game).GameHUD == None)
	{
		super.PostBeginPlay();
		TAGame(WorldInfo.Game).GameHUD = self;
		Init();
	}
	else
	{
		// Make sure all player controllers use this hud.
		foreach WorldInfo.AllControllers(class'TAPlayerController', playerController)
		{
			playerController.myHUD = TAGame(WorldInfo.Game).GameHUD;
		}
	}
}

// Initializes the HUD
function Init()
{
	if (TAGame(WorldInfo.Game).GameState == TAGame(WorldInfo.Game).EGameState.MainMenu)
	{
		ShowMainMenu();
		CloseHUD();

		TAGame(WorldInfo.Game).LeaderboardGet.Index = 0;
		TAGame(WorldInfo.Game).LeaderboardGet.Count = 15;
		TAGame(WorldInfo.Game).LeaderboardGet.SortField = "Rank";
		TAGame(WorldInfo.Game).LeaderboardGet.SortDirection = "asc";

		TAGame(WorldInfo.Game).LeaderboardGet.RequestData();
	}
	else
	{
		CloseMainMenu();
		ShowHUD();

		TAGame(WorldInfo.Game).NarratorManager.SaySpeech(TAGame(WorldInfo.Game).NarratorManager.IntroSound);
	}
}

function bool HeroNear(Actor a)
{
	local TAHero hero;

	foreach WorldInfo.AllPawns(class'TAHero', hero)
	{
		if (TAPlayerController(hero.Controller).IsActiveInGame)
			if (VSize(hero.Location - a.Location) < SHOW_BAR_DISTANCE)
				return true;
	}

	return false;
}

// Draws the hud according to the current game state
function DrawHUD()
{
	local TATurretCrateSpawn tcSpawn;
	local TABarricadeCrateSpawn bcSpawn;
	local TAAmmoCrateSpawn acSpawn;
	local TAObjectiveTrigger oTrigger;
	local TAHuman hum;
	local TAPawn tp;
	local TAHero p;
	local array<TAPlayerController> playerControllers;
	local TAPlayerController playerController;
	local LocalPlayer localPlayer;

	if (TAGame(WorldInfo.Game).GameState == TAGame(WorldInfo.Game).EGameState.MainMenu)
	{
		// Update the HUD using all of the player controllers
		if (ScaleformMainMenu != none)
			ScaleformMainMenu.Update(TAGame(WorldInfo.Game));
	}
	else
	{
		foreach WorldInfo.AllPawns(class'TAPawn', tp)
		{
			if (tp.ShowingHealthBar && HeroNear(tp))
			{
				UpdateDynamicHealthBar(string(tp.name), tp.HatSocketLocation(), tp.Health * 1.0 / tp.HealthMax);
			}
			else
			{
				RemoveDynamicHealthBar(string(tp.name));
			}
		}

		foreach WorldInfo.AllActors(class'TATurretCrateSpawn', tcSpawn)
		{
			if (tcSpawn.ShowingSpawnBar && HeroNear(tcSpawn))
			{
				UpdateDynamicSpawnBar(string(tcSpawn.name), tcSpawn.Location, tcSpawn.CurrentRespawnTime * 1.0 / tcSpawn.RESPAWN_COOLDOWN, "TURRET");
			}
			else
			{
				RemoveDynamicSpawnBar(string(tcSpawn.name));
			}
		}

		foreach WorldInfo.AllActors(class'TABarricadeCrateSpawn', bcSpawn)
		{
			if (bcSpawn.ShowingSpawnBar && HeroNear(bcSpawn))
			{
				UpdateDynamicSpawnBar(string(bcSpawn.name), bcSpawn.Location, bcSpawn.CurrentRespawnTime * 1.0 / bcSpawn.RESPAWN_COOLDOWN, "BARRICADE");
			}
			else
			{
				RemoveDynamicSpawnBar(string(bcSpawn.name));
			}
		}

		foreach WorldInfo.AllActors(class'TAAmmoCrateSpawn', acSpawn)
		{
			if (acSpawn.ShowingSpawnBar && HeroNear(acSpawn))
			{
				UpdateDynamicSpawnBar(string(acSpawn.name), acSpawn.Location, acSpawn.CurrentRespawnTime * 1.0 / acSpawn.RESPAWN_COOLDOWN, "AMMO");
			}
			else
			{
				RemoveDynamicSpawnBar(string(acSpawn.name));
			}
		}

		foreach WorldInfo.AllPawns(class'TAHuman', hum)
		{
			if (hum.ShowingInteractButton)
			{
				UpdateDynamicInteractButton(string(hum.name), hum.HatSocketLocation(), 1);
			}
			else
			{
				RemoveDynamicInteractButton(string(hum.name));
			}
		}


		foreach WorldInfo.AllPawns(class'TAHero', p)
		{
			if (p.ShowingHumansFollowing)
			{
				UpdateDynamicHumansFollowing(string(p.name), p.HatSocketLocation(), p.HumansFollowing.length, TAGame(WorldInfo.Game).FollowCap);
			}
			else
			{
				RemoveDynamicHumansFollowing(string(p.name));
			}
		}




		foreach WorldInfo.AllActors(class'TAObjectiveTrigger', oTrigger)
		{
			if (oTrigger.ShowingInteractButton)
			{
				UpdateDynamicInteractButton(string(oTrigger.name), oTrigger.Location, 0);
			}
			else
			{
				RemoveDynamicInteractButton(string(oTrigger.name));
			}
		}


		// Call the calculate bounds function on all cameras. Required
		// to be in this class so that the camera can access the canvas class.
		TAGame(WorldInfo.Game).GameCamera.CalculateBounds(Canvas);

		// Get all of the player controllers in the level
		playerControllers.insert(0, 4);
		foreach WorldInfo.AllPawns(class'TAHero', p)
		{
			playerController = TAPlayerController(p.Controller);
			localPlayer = LocalPlayer(playerController.Player);
			playerControllers[localPlayer.ControllerId] = playerController;
		}

		// Update the HUD using all of the player controllers
		if (ScaleformHUD != none)
			ScaleformHUD.Update(TAGame(WorldInfo.Game), PlayerControllers);
	}
}




function UpdateDynamicInteractButton(string id, vector loc, int button)
{
	loc = Canvas.Project(loc);

	ScaleformHUD.UpdateDynamicInteractButton(id, loc.x * (1280.0 / Canvas.SizeX), loc.y * (720.0 / Canvas.SizeY), button);
}

function RemoveDynamicInteractButton(string id)
{
	ScaleformHUD.RemoveDynamicInteractButton(id);
}



function UpdateDynamicHumansFollowing(string id, vector loc, int following, int total)
{
	loc = Canvas.Project(loc);

	ScaleformHUD.UpdateDynamicHumansFollowing(id, loc.x * (1280.0 / Canvas.SizeX), loc.y * (720.0 / Canvas.SizeY), following, total);
}

function RemoveDynamicHumansFollowing(string id)
{
	ScaleformHUD.RemoveDynamicHumansFollowing(id);
}


function UpdateDynamicHealthBar(string id, vector loc, float health)
{
	loc = Canvas.Project(loc);

	ScaleformHUD.UpdateDynamicHealthBar(id, loc.x * (1280.0 / Canvas.SizeX), loc.y * (720.0 / Canvas.SizeY), health);
}

function RemoveDynamicHealthBar(string id)
{
	ScaleformHUD.RemoveDynamicHealthBar(id);
}

function UpdateDynamicSpawnBar(string id, vector loc, float spawn, string description)
{
	loc = Canvas.Project(loc);

	ScaleformHUD.UpdateDynamicSpawnBar(id, loc.x * (1280.0 / Canvas.SizeX), loc.y * (720.0 / Canvas.SizeY), spawn, description);
}

function RemoveDynamicSpawnBar(string id)
{
	ScaleformHUD.RemoveDynamicSpawnBar(id);
}




// Show the HUD
exec function ShowHUD()
{
	if (ScaleformHUD == none)
	{
		ScaleformHUD = new class'TAScaleformHUD';
		ScaleformHUD.SetTimingMode(TM_Real);
		ScaleformHUD.Init();
		ScaleformHUD.SetViewScaleMode(SM_ExactFit);
		ScaleformHUD.SetPriority(0);
	}
}

// Close the HUD
exec function CloseHUD()
{
	if (ScaleformHUD != none)
	{
		ScaleformHUD.Close(true);
		ScaleformHUD = none;
	}
}

// Shows a speech bubble on the screen using the given character and speech text
exec function ShowSpeech(int character, string speech)
{
	if (ScaleformHUD != none)
	{
		ScaleformHUD.ShowSpeech(character, speech);
	}
}

// Closes the speech bubble
exec function CloseSpeech()
{
	if (ScaleformHUD != none)
	{
		ScaleformHUD.CloseSpeech();
	}
}

// Sets the text for the current wave field
exec function SetWave(string wave)
{
	if (ScaleformHUD != none)
	{
		ScaleformHUD.SetWave(wave);
	}
}

// Adds an objective
exec function AddObjective(string key, string description)
{
	if (ScaleformHUD != none)
	{
		ScaleformHUD.AddObjective(key, description);
	}
}

// Removes an objective
exec function RemoveObjective(string key)
{
	if (ScaleformHUD != none)
	{
		ScaleformHUD.RemoveObjective(key);
	}
}

// Pushes a new item to the feed. The 3 colors are uint strings, eg "0xff0000"
exec function PushToFeed(string part1, string part2, string part3, string color1, string color2, string color3)
{
	if (ScaleformHUD != none)
	{
		ScaleformHUD.PushToFeed(part1, part2, part3, color1, color2, color3);
	}
}

// Shows the main mennu
exec function ShowMainMenu()
{
	if (ScaleformMainMenu == none)
	{
		ScaleformMainMenu = new class'TAScaleformMainMenu';
		ScaleformMainMenu.SetTimingMode(TM_Real);
		ScaleformMainMenu.Init();
		ScaleformMainMenu.SetViewScaleMode(SM_ExactFit);
		ScaleformMainMenu.SetPriority(0);
	}
}

// Closes the main menu if it exists
exec function CloseMainMenu()
{
	if (ScaleformMainMenu != none)
	{
		ScaleformMainMenu.Close(true);
		ScaleformMainMenu = none;
	}
}

defaultproperties
{
	
}