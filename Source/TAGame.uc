class TAGame extends SimpleGame;

/** Enums and other stuff */
Enum EGameState {MainMenu, InGame, Paused, GameOver};
var EGameState GameState;

enum EGameOverState
{
	TextEntry,
	Sending,
	Succeeded,
	Failed,
};
var EGameOverState GameOverState;
var int GameOverRank;

/** Settings and Config */
var TAMapSettings MapSettings;
var WorldInfo CurrentWorldInfo;

/** Accessing leaderboard data from the web */
var TALeaderboardLink LeaderboardAccess;
var TALeaderboardGet LeaderboardGet;

/** References to Controllers */
var array<TAPlayerController> PlayerControllers;
var TAPlayerCamera GameCamera;

var TAHUD GameHUD;

var array<LocalPlayer> players;

var bool AllowedJoin;
var bool movecamF;

var DecalManager WorldDecalManager;

var bool OtherPlayersCreated;

var TASpawnLocator SpawnLocator;

var TABarricadeCrateSpawn barCrateSpawn;
var int barricadeCount;
var bool barricadeSpawnTimerSet;

var TATurretCrateSpawn turCrateSpawn;
var int turretCount;
var bool turretSpawnTimerSet;

var TAAmmoCrateSpawn ammoCrateSpawn;
var int ammoCount;
var bool ammoSpawnTimerSet;

var PlayerStart mainSpawn;

var int Score_PlayerDeaths;

var int ZombiesKilled;
var int ObjectivesCompleted;
var int Deaths;
var array<int> Scores;
// ***************************
// THE HUD LATCHES ONTO THESE
// UPDATE THEM ACCORDINGLY
// ***************************
var int TotalHumans;
var int RemainingHumans;
var bool SetTotalHumans;
var int TotalPlayers;

var int FollowCap;

/** Basic variable utilised for when there is a cutscene of sorts. */
var bool bCanPlayerJoinLeave;
var bool bFightingBoss;
var TABossZombie BossZombie;

var int MaxFollowCount;

var TAObjectiveManager ObjectiveManagerReference;
var TANarratorManager NarratorManager;
var TAAudioManager AudioManager;

const STARTING_MAP = "TA-MapPreview2";

var bool GameOverWin;
var string GameOverName;
const GAME_OVER_NAME_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";

var float SubmitScoreTime;
const SUBMIT_SCORE_TIMEOUT = 5.0f;

var TABossTriggerVolume BossVolume;

event PreBeginPlay()
{
	super.PreBeginPlay();


	GameOverState = EGameOverState.TextEntry;
	GameOverName = Mid(GAME_OVER_NAME_CHARS, 0, 1); // Needs to be at least 1 character from the const

	audioManager = new class'TAAudioManager';
	audioManager.InitAudio();

	NarratorManager = new class'TANarratorManager';
	NarratorManager.Init(self);

	//WorldInfo.MyDecalManager.Destroy();
	//WorldInfo.MyDecalManager = Spawn(class'TADecalManager');

	if (LeaderboardAccess == none)
	{
		LeaderboardAccess = Spawn(class'TALeaderboardLink');
		LeaderboardGet = Spawn(class'TALeaderboardGet');
		// Testing whether or not the leaderboard link works properly.
		//LeaderboardAccess.PostScore(500,500,500,500,500,500,true,500,500,500,500,2,1,"AIDS");	
	}

	TotalHumans = 0;
	RemainingHumans = 0;

	Scores.insert(0, 4);

	if (WorldInfo.GetMapName(true) == "TA-MainMenu")
	{
		GameState = EGameState.MainMenu;
	}
	else
	{
		GameState = EGameState.InGame;

	}
}

exec function OpenDoor()
{
	BossVolume.OpenMainDoors();
}

exec function OpenGate()
{
	BossVolume.OpenMainGates();
}

function GameOver()
{
	GameState = EGameState.GameOver;
	GameHUD.ScaleformHUD.ShowGameOver(true, false, GameOverName, int(GameOverState), GameOverRank);

	if (GameOverWin)
		NarratorManager.SaySpeech(NarratorManager.GameOverWonSound);
	else
		NarratorManager.SaySpeech(NarratorManager.GameOverLostSound);
}

// For Luc, with love, James
// Dear James, Your code makes me want to vomit. Love, Luc.
function DoLeaderboardStuff()
{
	local int score;

	score = Scores[0] + Scores[1] + Scores[2] + Scores[3];

	LeaderboardAccess.PostScore(score, ZombiesKilled, Deaths, 0, 0, 0, 0, GameOverWin, 0, 0, 0, 0, RemainingHumans, ObjectivesCompleted, GameOverName);
}

exec function SpawnBoss()
{
	local vector spawnLoc;
	spawnLoc = vect(-1169, 1382,0);
	BossZombie = Spawn(class'TABossZombie',,,spawnLoc);
	BossZombie.ObjectiveManager = ObjectiveManagerReference;
	bFightingBoss = true;

	NarratorManager.SaySpeech(NarratorManager.BossSpawnSound);
}

//Change the scores of the individual players. This will be used for fancy HUD stuff.
function AddScore(int controllerID, int score, Optional string msg)
{
	if(GameState != EGameState.GameOver)
	{
		Scores[controllerID] += score;

		GameHUD.ScaleformHUD.AddScore(controllerID, score);

		//This character just got some score! Put them into the FUCK YEAH avatar frame
		GameHud.ScaleformHUD.SetCharacterState(controllerId, 2);

		if (msg != "")
		{
			if (score > 0)
				GameHud.ScaleformHUD.PushToScoreFeed(controllerID, msg $ " +" $ score, "0x00ff00");
			else
				GameHud.ScaleformHUD.PushToScoreFeed(controllerID, msg $ " " $ score, "0xff0000");
		}
		else
		{
			if (score > 0)
				GameHud.ScaleformHUD.PushToScoreFeed(controllerID, "+" $ score, "0x00ff00");
			else
				GameHud.ScaleformHUD.PushToScoreFeed(controllerID, string(score), "0xff0000");
		}
	}
}

exec function KillHumans()
{
	local TAHuman hum;

	foreach AllActors(class'TAHuman', hum)
	{
		hum.Health = 0;	
	}
}

event Tick(float DeltaTime)
{
	local TAViewportClient viewport;
	local TAPlayerController pc;
	local TAHuman hum;
	local TAZombieSpawnManager zMan;

	if (GameState == EGameState.MainMenu)
	{
		AudioManager.StartMainMusic();

	}
	else
	{
		if (bFightingBoss)
		{
			AudioManager.StartBossMusic();
		}
		else
		{
			foreach AllActors(class'TAZombieSpawnManager', zMan)
			{
				if (zMan.m_inHalfTime || !zMan.Started || zMan.BossWave)
					AudioManager.StartAmbienceMusic();
				else
					Audiomanager.StartBattleMusic(zMan.bDiscoMode);
					
				
			}
		}

		NarratorManager.Tick(deltaTime);
	}

	SpawnLocator.LocateNearestSpawn(GameCamera);

	// This is fucking retarded, but if we put this code in PostBeginPlay we end up with 2 PlayerControllers
	// being generated for each actual player.
	if (OtherPlayersCreated == false && GameState == EGameState.InGame)
	{
		// Create players for all controllers except for 0 (which is done automatically in Engine::GameInfo::Login).
		// Pretty dam sure there is a better way to access the GameViewport class to call this function, but 
		// hell if I can work it out.
		viewport = TAViewportClient(class'UIRoot'.static.GetCurrentUIController().Outer);
		viewport.DebugCreatePlayer(1);
		viewport.DebugCreatePlayer(2);
		viewport.DebugCreatePlayer(3);
		OtherPlayersCreated = true;

		//NarratorManager.SaySpeech(NarratorManager.IntroSound);
		//PlaySound(SoundCue'Sounds.VO.Intro');		
	}

	UpdateCrateSpawns(deltaTime);

	RemainingHumans = 0;
	// Get the count of all the humans on the level
	foreach AllActors(class'TAHuman', hum)
	{
		if (hum.Health > 0)
			RemainingHumans++;
	}

	// Game over yet?
	if (GameState == EGameState.InGame && OtherPlayersCreated == true)
	{
		if (RemainingHumans <= 0 && !bFightingBoss)
		{
			GameState = EGameState.GameOver;
			GameOver();
		}
	}
	else if (GameState == EGameState.GameOver && GameOverState == EGameOverState.Sending)
	{
		SubmitScoreTime += deltaTime;
		
		if (SubmitScoreTime >= SUBMIT_SCORE_TIMEOUT)
		{
			SubmitScoreTime = 0;
		
			LeaderboardAccess.Close();

			GameOverState = EGameOverState.Failed;
			GameOver();
		}
	}

	if (!SetTotalHumans)
	{
		TotalHumans = RemainingHumans;
		SetTotalHumans = true;
	}


	TotalPlayers = 0;

	foreach AllActors(class'TAPlayerController', pc)
	{
		if (pc.IsActiveInGame)
		{
			TotalPlayers++;
		}
	}
	if(TotalPlayers != 0)
	{
		FollowCap = TotalHumans/TotalPlayers;
	}
	//`log(FollowCap);
}

function UpdateCrateSpawns(float deltaTime)
{
	local TAAmmoCrateSpawn a;
	local TABarricadeCrateSpawn b;
	local TATurretCrateSpawn t;

	foreach AllActors(class'TAAmmoCrateSpawn', a)
	{
		a.Update(deltaTime);
	}

	foreach AllActors(class'TABarricadeCrateSpawn', b)
	{
		b.Update(deltaTime);
	}

	foreach AllActors(class'TATurretCrateSpawn', t)
	{
		t.Update(deltaTime);
	}
}

simulated event PostBeginPlay()
{
	local TAObjectiveManager localmanager;

	local PlayerStart playerSpawn;
	local TABossTriggerVolume tempBossVolume;
	local TAAIHumanController tempHumanController;
	super.PostBeginPlay();
	/** Initial initialisation goes here, and pulling any settings from Map Info */
	MapSettings = TAMapSettings(WorldInfo.GetMapInfo());

	`log("Gameinfo working");

	SpawnLocator = Spawn(class'TASpawnLocator');

	// Loop through the environment and find the ObjectiveManager
	foreach AllActors(class'TAObjectiveManager',localmanager)
	{
		// Determine if there is a reference in this instance of objective manager.
		// If not, then set it to this one.
		if (localmanager.GameReference == none)
		{
			localmanager.GameReference = self;
			ObjectiveManagerReference = localmanager;
		}
	}

	foreach AllActors(class'PlayerStart', playerSpawn)
	{
		if(playerSpawn.bEnabled && playerSpawn.bPrimaryStart)
		{
			mainSpawn = playerSpawn;
		}
	}
	foreach AllActors(class'TABossTriggerVolume', tempBossVolume)
	{
		bossVolume = tempBossVolume;
		break;
	}

	// Loop through the humans in the game and then set a reference to the game object.
	foreach AllActors(class'TAAIHumanController', tempHumanController)
	{
		tempHumanController.GameReference = self;
	}
}

function bool AllowJoin()
{
	return true;
}

exec function TAButtonPressed(string button)
{
	//WorldInfo.Game.Broadcast(self, button);
}

defaultproperties
{
	DefaultPawnClass = class'TeamAwesome.TAHero'
	PlayerControllerClass = class'TeamAwesome.TAPlayerController'

	HUDType = class'TeamAwesome.TAHUD'
	//bUseClassicHUD = true

	PlayerReplicationInfoClass=class'UTGame.UTPlayerReplicationInfo'
	GameReplicationInfoClass=class'UTGame.UTGameReplicationInfo'
	
	bRestartLevel=false
	bDelayedStart=false
	bUseSeamlessTravel=true
	AllowedJoin=true

	barricadeSpawnTimerSet = false;
	turretSpawnTimerSet = false;
}