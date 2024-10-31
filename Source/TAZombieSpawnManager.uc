// ---------------------------------------------------------------------------------------------
//  When placed in a map this controls the wave-based spawning
//  of zombies within said map.
// ---------------------------------------------------------------------------------------------
class TAZombieSpawnManager extends NavigationPoint
	placeable
	ClassGroup(Common)
	hidecategories(Collision);

/* A reference to the objective managable through the editor */
var (ObjectiveManager) TAObjectiveManager ObjectiveManager;

/* Current wave index of zombie spawns */
var (Spawning) int   WaveIndex;

/* Starting number of zombies to spawn per wave - Affected by difficutly curve.  */
var (Spawning) int   StartZombiesPerWave;

/* For when you just have to party. */
var (DiscoMode) bool bDiscoMode;

/* Initial difficutly curve */
var (Spawning) float WaveStartDifficutlyCurve;

/* How much the difficutly goes up with each player added */
var (Spawning) float WavePlayerDifficutlyCurve;

/* How much the difficutly curve goes up each wave. */
var (Spawning) float PerWaveDifficutlyCurve;

/* Minimum distance between player and spawn point to be able to use it. */
var (Spawning) int   MinDistanceToSpawnPoint;

/* Maximum distance between player and spawn point to be able to use it. */
var (Spawning) int   MaxDistanceToSpawnPoint;

/* Starting "half-time" time (in ticks), the duration between the end of a wave and the start of the next - Affected by difficutly curve.  */
var (Spawning) int   StartHalfTimeDuration;

/* Minimum time between each zombie spawn (in ticks) - Affected by difficutly curve.  */
var (Spawning) int   MinIntervalBetweenSpawns;

/* Maximum time between each zombie spawn (in ticks) - Affected by difficutly curve. */
var (Spawning) int   MaxIntervalBetweenSpawns;

/* Maximum number of zombies on screen at once - Affected by difficutly curve. */
var (Spawning) int   StartMaxZombiesAtOnce;

/* Private variables. */
var float   m_tickCounter;              // How many ticks since we started.
var bool    m_inHalfTime;               // If we are currently in the half time between waves.
var float   m_halfTimeEndTime;          // Time at which we exit half time.
var int     m_zombiesSpawnedThisWave;   // Zombies spawned this wave.
var float   m_zombieSpawnTimer;         // Timer for each zombie spawn.
var int     m_waveHatIndex;             // Index of hat that zombies will wear this wave.

var bool Started;
var bool HalfTimePointsAwarded;

const MAX_HAT_TYPES = 6;

const BOSS_WAVE = 5;
var bool BossWave;

simulated event PostBeginPlay()
{

}

// ---------------------------------------------------------------------------------------------
//  Once per frame invokation - we do all our spawn logic in here.
// ---------------------------------------------------------------------------------------------
event Tick(float deltaTime)
{
	local float waveDifficultyCurve;
	local int   waveZombieCount;
	local float waveHalfTimeDuration;
	local float waveMinIntervalBetweenSpawns;
	local float waveMaxIntervalBetweenSpawns;
	local float waveMaxZombies;

	local TAZombiePawn          zombie;
	local TAPlayerController    pc;
	local int                   currentZombieCount;
	local int                   currentPlayerCount;
	local int                   currentPlayerAnyStateCount;

	local int activePlayers;

	/** only update when not in boss fight */
	if (!TAGame(WorldInfo.Game).bFightingBoss)
	{
		// Count how many zombies currently exist.
		currentZombieCount = 0;
		foreach AllActors(class'TAZombiePawn', zombie)
		{
			if (zombie.bIsDead == false)
			{
				currentZombieCount++;
			}
		}

		// Count how many players currently exist.
		currentPlayerCount = 0;
		currentPlayerAnyStateCount = 0;
		foreach AllActors(class'TAPlayerController', pc)
		{
			if (pc.IsPlayerInGame == true && pc.IsActiveInGame == true)
			{
				currentPlayerCount++;
			}

			if (pc.IsPlayerInGame == true)
			{
				currentPlayerAnyStateCount++;
			}
		}

		// Update tick counter.
		m_tickCounter += deltaTime;

		// Work out the various settings based on the current difficutly curve.
		waveDifficultyCurve             = WaveStartDifficutlyCurve  + (WaveIndex * PerWaveDifficutlyCurve);
		waveZombieCount                 = StartZombiesPerWave       * waveDifficultyCurve;
		waveHalfTimeDuration            = StartHalfTimeDuration;//     / waveDifficultyCurve;
		waveMinIntervalBetweenSpawns    = MinIntervalBetweenSpawns  / waveDifficultyCurve;
		waveMaxIntervalBetweenSpawns    = MaxIntervalBetweenSpawns  / waveDifficultyCurve;
		waveMaxZombies                  = (StartMaxZombiesAtOnce * (waveDifficultyCurve * 0.5f))  * (WavePlayerDifficutlyCurve * currentPlayerAnyStateCount);

		// Awwwwh no alive players, reset tiem!
		if (currentPlayerCount == 0 && !Started)
		{
			WaveIndex                   = default.WaveIndex;
			m_tickCounter               = 0;
			m_inHalfTime                = false;
			m_halfTimeEndTime           = 0;
			m_zombiesSpawnedThisWave    = 0;
			m_zombieSpawnTimer          = 0;

			TAGame(WorldInfo.Game).GameHud.SetWave("Prepare Yourself");
			return;
		}

		if (Started == false)
		{
			m_inHalfTime      = true;
			m_halfTimeEndTime = m_tickCounter + waveHalfTimeDuration;
		}
		Started = true;

		// Update based on current state.
		if (m_inHalfTime == true)
		{		

			if (WaveIndex == 0)
			{
				TAGame(WorldInfo.Game).GameHud.SetWave("Starting In: " $ int(m_halfTimeEndTime - m_tickCounter + 1));
			}
			else
			{
				TAGame(WorldInfo.Game).GameHud.SetWave("Half Time: " $ int(m_halfTimeEndTime - m_tickCounter + 1));
			}

			if (!HalfTimePointsAwarded && WaveIndex != 0)
			{
				if (TAGame(WorldInfo.Game).RemainingHumans > 0)
				{
						// Get the number of active players first
						foreach AllActors(class'TAPlayerController', pc)
						{
							if (pc.IsActiveInGame)
								activePlayers++;
						}

						foreach AllActors(class'TAPlayerController', pc)
						{
							if (pc.IsPlayerInGame == true && pc.IsActiveInGame == true)
							{
								TAGame(WorldInfo.Game).AddScore(LocalPlayer(pc.Player).ControllerId, 10.0f * WaveIndex * TAGame(WorldInfo.Game).RemainingHumans / activePlayers, "Human Bonus");
							}
						}
				}

				HalfTimePointsAwarded = true;
			}

			// Half time over?
			if (m_tickCounter > m_halfTimeEndTime)
			{
				WaveIndex++;

				m_waveHatIndex = rand(MAX_HAT_TYPES);
				//m_waveHatIndex = 1;
				if (m_waveHatIndex == 1) 
				{					
					bDiscoMode = true;
				}
				else
				{
					bDiscoMode = false;
				}

				m_inHalfTime = false;
				m_zombiesSpawnedThisWave = 0;

				

				`log("Half time over, begining wave " $ (WaveIndex) $ ".");
			}
		}
		else if (WaveIndex == BOSS_WAVE && !BossWave)
		{
			StopCelebrating();
			BossWave = true;

			TAGame(WorldInfo.Game).GameHud.SetWave("Prepare Yourself");
			TAGame(WorldInfo.Game).BossVolume.OpenMainDoors();
			TAGame(WorldInfo.Game).NarratorManager.SaySpeech(TAGame(WorldInfo.Game).NarratorManager.BossBeforeSound);
		}
		else if (!BossWave)
		{
			StopCelebrating();

			TAGame(WorldInfo.Game).GameHud.SetWave("Wave " $ (WaveIndex));
			HalfTimePointsAwarded = false;

			// Wave over?
			if (m_zombiesSpawnedThisWave >= waveZombieCount)
			{
				if (currentZombieCount <= 0)
				{	
					`log("Zombies dead, entering half time, duration " $ waveHalfTimeDuration $ " ticks.");

					StartCelebrating();

					TAGame(WorldInfo.Game).GameHud.PushtoFeed("Wave ", string(WaveIndex + 1), " Completed", "0xFFFFFF", "0xFFFFFF", "0xFFFFFF");


					if (!m_inHalfTime)
					{
							TAGame(WorldInfo.Game).NarratorManager.SaySpeech(TAGame(WorldInfo.Game).NarratorManager.WaveCompleteSound);
					}


					if (WaveIndex == BOSS_WAVE - 1) // Go straight to the boss wave if it is next
						WaveIndex++;
					else
					{
						m_inHalfTime      = true;
						m_halfTimeEndTime = m_tickCounter + waveHalfTimeDuration;
					}
				}
			}

			// Nope, get working.
			else
			{
				// Enough space left to spawn a new zombie?
				if (currentZombieCount < waveMaxZombies)
				{
					// Time up for another spawn?
					if (m_tickCounter > m_zombieSpawnTimer)
					{
						SpawnZombie();
						m_zombieSpawnTimer = m_tickCounter + RandRange(waveMinIntervalBetweenSpawns, waveMaxIntervalBetweenSpawns);
					}
				}
			}
		}
	}
	else
	{
		TAGame(WorldInfo.Game).GameHud.SetWave("Boss Fight");
	}
}

function StartCelebrating()
{
	local TAHero tempPawn;

	foreach AllActors(class'TAHero', tempPawn)
	{
		tempPawn.bIsCelebrating = true;
		tempPawn.celebrateTimer = 1.f;
	}
}

function StopCelebrating()
{
	local TAHero tempPawn;

	foreach AllActors(class'TAHero', tempPawn)
	{
		tempPawn.bIsCelebrating = false;
	}
}

// ---------------------------------------------------------------------------------------------
//  Spawns a zombie at one of the spawn points closest to the players.
// ---------------------------------------------------------------------------------------------
function SpawnZombie()
{
	local TAZombieSpawnPoint        spawnPoint;
	local TAHero                    hero;
	local array<TAZombieSpawnPoint> availableSpawnPoints;
	local float                     distance;
	local bool 						bAbortSpawn;
	local TAZombiePawn 				zombiePawn;
		
	`log("Attempting to spawn new zombie ...");

	// Find spawn points close enough to all heros.
	foreach AllActors(class'TAHero', hero)
	{
		foreach AllActors(class'TAZombieSpawnPoint', spawnPoint)
		{
			if (spawnPoint.bIsBlocked == true)
			{
				continue;
			}

			distance = vsize(hero.Location - spawnPoint.Location);
			if (distance >= MinDistanceToSpawnPoint && distance <= MaxDistanceToSpawnPoint)
			{
				// We add the spawn points multiple times for each hero they are close to.
				// This weights the spawn points so there is a higher chance we will
				// choose one close to multiple players, not just close to a single player.
				availableSpawnPoints.AddItem(spawnPoint);
			}
		}
	}

	// No spawn points available? Choose first one.
	if (availableSpawnPoints.Length == 0)
	{	
		`log("Could not find spawn point for zombie in range, looking for first zombie ...");

		foreach AllActors(class'TAZombieSpawnPoint', spawnPoint)
		{
			availableSpawnPoints.AddItem(spawnPoint);
			break;
		}

		if (availableSpawnPoints.Length == 0)
		{
			`log("Could not find any possible spawn point for zombie, spawn aborted.");
			return;
		}
	}

	// Choose a spawn point.
	spawnPoint = availableSpawnPoints[RandRange(0, availableSpawnPoints.Length - 1)];
	foreach AllActors(class'TAZombiePawn', zombiePawn)
	{
		if (VSize(zombiePawn.Location - spawnPoint.Location) < 150)
		{
			bAbortSpawn = true;
			break;
		}
	}

	if (!bAbortSpawn)
	{
		// Spawn zombie at spawn point.
		zombiePawn = Spawn(class'TAZombiePawn',,,spawnPoint.Location, spawnPoint.Rotation);
		zombiePawn.PutOnHat(m_waveHatIndex);

		// Assign the reference to the newly spawned zombie.
		if (ObjectiveManager != none)
		{
			zombiePawn.ObjectiveManager = ObjectiveManager;
		}

		// Increment spawn counter.
		m_zombiesSpawnedThisWave++;

		// Find out whether it's DISCO TIME!
		if (m_waveHatIndex == 1)
		{
			zombiePawn.bIsDisco = true;			
		}
		

		`log("Spawned zombie at " $ spawnPoint.Location $ ", spawned this wave " $ m_zombiesSpawnedThisWave);
	}
	else
	{
		`log("Zombie in Vicinity of " $ spawnPoint $ ", ");
	}
}

// ---------------------------------------------------------------------------------------------
//  Default values of all properties.
// ---------------------------------------------------------------------------------------------
DefaultProperties
{
	Begin Object NAME=Sprite LegacyClassName=SpawnManager_SpawnManagerSprite_Class
		Sprite=Texture2D'Sprites.zombie_spawn_manager'
		SpriteCategoryName="Crowd"
	End Object

 	bCollideWhenPlacing = false
	bEdShouldSnap       = true
	bStatic             = false;
	bBlocked = true

	WaveIndex                       = 0;
	StartZombiesPerWave             = 20;//12;
	WaveStartDifficutlyCurve        = 1.0f;
	PerWaveDifficutlyCurve          = 0.5f; 
	MinDistanceToSpawnPoint         = 700;
	MaxDistanceToSpawnPoint         = 1800;
	StartHalfTimeDuration           = 15.0;
	MinIntervalBetweenSpawns        = 0.25;//0.5;
	MaxIntervalBetweenSpawns        = 1.0;//4.0;
	StartMaxZombiesAtOnce           = 12;//8;
	WavePlayerDifficutlyCurve       = 2; 

	Started = false;
}
