class TAObjectiveManager extends Actor placeable
									ClassGroup(Common)
									Config(Game)
									hidecategories(Collision,Physics);

/** Contains information */
struct ObjectiveInformation{
	
	/* The associative ID of the objective for all the objective triggers in the game. */
	var string ObjectiveID;

	/* What the player has to do to complete the objective */
	var string ObjectiveDescription;
	
	/* Time required to complete the objective. */
	var float TimeToComplete;

	/* How much time has elapsed since this objective started */
	var float CurrentTimeElapsed;

	/* Is the objective active? */
	var bool IsActive;

	/* How many tasks have the players completed? */
	var int RequiredTaskCompletions;

	/* How many tasks have the players completed? */
	var int CurrentTasksCompleted;

	/* Do we care about a time limit? 
	 * Setting this to true makes the Tick event ignore CurrentTimeElapsed and TimeToComplete conditions */
	var bool TimeRestricted;

	var array<TAObjectiveTrigger> LinkedTriggers;
};

/** Reference to the main game object to access other references. */
var TAGame GameReference;

/** 
 *  Reference so that we can determine when it's appropriate to create objectives
 *  in sync with what zombies exist and what wave they are on
 *  
 *  */
var (Objectives) TAZombieSpawnManager ZombieSpawnManager;

/** For determining between which times that a new objective should generate. */
var (Objectives) float MinRandomTime;
var (Objectives) float MaxRandomTime;

/* Required min & max distances that the objective items have to be. */
var (Objectives) int MaxDistanceFromObjective;
var (Objectives) int MinDistanceFromObjective;

/** How many objectives will be alive at any one given time. */
var (Objectives) int MaxObjectives;

/** How many seconds do we wait until the next objective time is assigned */
var (Objectives) float WaitUntilLastObjective;

var (Objectives) float MinimumDistanceFromObjective;
var (Objectives) float MaximumDistanceFromObjective;

var (Objectives) bool bIsActive;

// Triggers that the objective manager is going to be aware of for activating.
var (Objectives) array<TAObjectiveTrigger> ManagedTriggers;

var int ObjectiveTriggerCount;

var array<ObjectiveInformation> Objectives;
var int ObjectivesCompleted;

var int ObjectiveIndexCount;

/** The time that has to be counted until the next objective can appear. **/
var float RandomInterval;
var float RandomIntervalCounter;

const OBJECTIVE_ID_PREFIX = "objective_";

/** Determine whether or not the player has completed the task. */
function SetObjectiveValue(string pObjectiveID, bool completedTask)
{
	local int i;

	for (i = 0; i < Objectives.Length; i++)
	{
		if (Objectives[i].ObjectiveID == pObjectiveID)
		{
			Objectives[i].CurrentTasksCompleted++;

			// Determine whether or not all the required tasks are completed
			if (Objectives[i].RequiredTaskCompletions <= Objectives[i].CurrentTasksCompleted)
			{
				NotifyCompletedObjective(Objectives[i].ObjectiveID);
			}
		}
	}
}

/** For when the objective has either had its task completed or it has been completed itself. */
function NotifyCompletedTask()
{

}

simulated function ActivateObjectiveTrigger(string pObjectiveTriggerName)
{
	local int i, j;
	local ObjectiveInformation newObjective;
	local TAHero tempHeroObject;
	local string NewObjectiveID;
	
	NewObjectiveID = OBJECTIVE_ID_PREFIX $ string(ObjectiveIndexCount);

	// Disable any remaining and existing objective triggers in the map
	// before doing anything else.
	DisableTriggers();

	// Loop through the triggers can find the objective trigger that we are after.
	for (i = 0; i < self.ManagedTriggers.Length; i++)
	{
		if (ManagedTriggers[i].ObjectiveName == pObjectiveTriggerName)
		{
			`log("Found objective trigger, now activating!");
				newObjective.CurrentTasksCompleted = 0;
				newObjective.CurrentTimeElapsed = 0;
				newObjective.IsActive = true;
				newObjective.ObjectiveID = NewObjectiveID; // Have the new manager generate an ID
				newObjective.TimeRestricted = false;
				newObjective.TimeToComplete = 5.0f;

				`log(OBJECTIVE_ID_PREFIX $ string(ObjectiveIndexCount) $" :: is the objective ID (objective manager)");
				
				// Set the usage id for the trigger and activate it.
				ManagedTriggers[i].ObjectiveID = NewObjectiveID;
				ManagedTriggers[i].bActiveObjectiveTrigger = true;
				ManagedTriggers[i].TriggerObjectiveInformation = newObjective;
				ManagedTriggers[i].ActivateObjectiveTrigger();

				Objectives.AddItem(newObjective);

				GameReference.GameHUD.AddObjective(OBJECTIVE_ID_PREFIX $ string(ObjectiveIndexCount),ManagedTriggers[i].ObjectiveDescription);
				
				if (ManagedTriggers[i].ObjectiveName == "endgame")
				{
					if (ManagedTriggers[i].MainGates.Length > 0)
					{
						for (j = 0; j < ManagedTriggers[i].MainGates.Length; j++)
						{
							if (ManagedTriggers[i].MainGates[j] != none)
							{
								if (j == 0)
								{
									ManagedTriggers[i].MainGates[j].StartOpen(false);
								}
								else
								{
									ManagedTriggers[i].MainGates[j].StartOpen(true);
								}
								
							}
						}
					}
				}

				// Loop through the heros and enable their rings.
				foreach AllActors(class'TAHero',tempHeroObject)
				{
					tempHeroObject.ShowObjectiveRing(ManagedTriggers[i]);
					tempHeroObject.TargetObjectiveTrigger = ManagedTriggers[i];
				}

				ObjectiveIndexCount++;

				break;
		}
	}
}

/** For when the players have completed the objective. */
function NotifyCompletedObjective(string pObjectiveID)
{
	local int i;

	// Ensure that our reference to the game is not null.
	if (GameReference != none)
	{

		`log("GameReference is NOT none and the objectiveID is " $ pObjectiveID);
		// Remove the objective now that it has been completed.
		GameReference.GameHUD.RemoveObjective(pObjectiveID);

		for(i = 0; i < Objectives.Length; i++)
		{
			if (Objectives[i].ObjectiveID == pObjectiveID)
			{
				Objectives.Remove(i,1);
			}
		}
	}
	else
	{
		`log("GameRefernce is apparently equal to none :S");
	}

	// Increase the number detailing the amount of objectives that have been completed.
	ObjectivesCompleted++;
}

/** When the players have failed the objective. */
function NotifyFailedObjective(string pObjectiveID)
{
	local TAObjectiveTrigger localTrigger;

	// Determine whether or not we have a reference to the game object.
	if (GameReference != none)
	{
		GameReference.GameHUD.RemoveObjective(pObjectiveID);

		foreach AllActors(class'TAObjectiveTrigger',localTrigger)
		{
			if (localTrigger.ObjectiveID == pObjectiveID)
			{
				localTrigger.bActiveObjectiveTrigger = false;
				
				// Remove the objective from the HUD
				GameReference.GameHUD.RemoveObjective(localTrigger.ObjectiveID);

				localTrigger.ObjectiveID = "";

			}
		}
	}
}

event Tick(float DeltaTime)
{
	local int i;
	local TAHero temporaryHeroObject;
	local TAObjectiveTrigger objtrigger;
	local bool PlayersActive;

	super.Tick(DeltaTime);

	PlayersActive = false;

	// Determine whether or not there is a hero in the game
	// that is playing and active. If so, then set to true and snap out of the loop
	foreach AllActors(class'TAHero',temporaryHeroObject)
	{
		if (temporaryHeroObject.bIsActive)
		{
			PlayersActive = true;

			break;
		}
	}

	// Determine that there are players active in the level.
	if (PlayersActive && 
		TAGame(WorldInfo.Game).bFightingBoss != true && 
		ZombieSpawnManager.Started)
	{

		/* Loop through the objectives and see if we have run out of time  */
		for (i = 0; i < Objectives.Length; i++)
		{
			// Add time elapsed to the objectives.
			Objectives[i].CurrentTimeElapsed += DeltaTime;

			/** Have our heroes run out of time? Notify failure and terminate objective. */
			if (Objectives[i].CurrentTimeElapsed > Objectives[i].TimeToComplete && Objectives[i].TimeRestricted)
			{
				// TODO: Get this looping through the ManagedTriggers array instead.
				foreach AllActors(class'TAObjectiveTrigger', objtrigger)
				{
					// Find all related objective triggers to this objective.	
					if (objtrigger.ObjectiveID == Objectives[i].ObjectiveID)
					{
						`log(self.name $ " :: Changing objective ID to null :l ");
						objtrigger.bActiveObjectiveTrigger = false;
						objtrigger.ObjectiveID = "";
						objtrigger.bCompletedTask = false;

						// Remove the objective from the HUD
						NotifyFailedObjective(Objectives[i].ObjectiveID);

						Objectives.Remove(i,1);
					}
				}
			}
			else
			{
				// If the elapsed time has not exceeded, then simply add more time onto the counter.
				Objectives[i].CurrentTimeElapsed += DeltaTime;
			}
		}

		// Ensure that an interval has been set.
		if (RandomInterval != 0)
		{
			//`log("RandomInterval is not 0");

			// If we have met the timer required for generating a new objective...
			if (RandomIntervalCounter > RandomInterval)
			{
				// Ensure that we're not enabling more objectives than necessary
				if (Objectives.Length < MaxObjectives)
				{
					`log("Initiate objective has been called.");

					InitiateObjective();

					// Reset the counter.
					RandomIntervalCounter = 0;
					RandomInterval = RandRange(self.MinRandomTime,self.MaxRandomTime);
				}
			}
			else
			{
				// If there are enough objectives to be called, then call another one
				if (Objectives.Length < MaxObjectives)
				{
					RandomIntervalCounter += DeltaTime;
				}
			}
		}

	}
	else
	{
		// If there are no active players and there are active objectives running, remove them.
		RandomIntervalCounter = 0;

		//DisableTriggers();
	}
	
}

simulated function Update()
{
	
}

// Disable all the objective triggers within the game.
simulated function DisableTriggers()
{
	local int i;
	local int j;

	`log("Disable triggers being called");

	// Loop through the triggers and disable them
	for (i = 0; i < ManagedTriggers.Length; i++)
	{
		if (ManagedTriggers[i].bActiveObjectiveTrigger)
		{
			// Deactivate the triggers.
			ManagedTriggers[i].bActiveObjectiveTrigger = false;

			// Loop through the objectives and find ones that are active.
			for (j = 0; j < Objectives.Length; j++)
			{
				if (Objectives[j].ObjectiveID == ManagedTriggers[i].ObjectiveID && ManagedTriggers[i].TriggerType != E_Special)
				{
					// Remove the information from the array

					// Was doing it wrong all along :<
					Objectives.Remove(j,1);
					ManagedTriggers[i].bActiveObjectiveTrigger = false;
					
					GameReference.GameHUD.RemoveObjective(ManagedTriggers[i].ObjectiveID);
				}
			}
		}
	}
}

simulated function bool IsObjectiveActive()
{
	local int i;

	if (Objectives.Length > 0)
	{
		// Loop through the objectives and determine if one is active.
		for (i = 0; i < Objectives.Length; i++)
		{
			return Objectives[i].IsActive;
		}
	}

	return false;
}

// Find the next active objective trigger;
simulated function TAObjectiveTrigger ReturnActiveTrigger()
{
	local int i;

	if (ManagedTriggers.Length > 0)
	{
		for (i = 0; i < ManagedTriggers.Length; i++)
		{
			if (ManagedTriggers[i] != none)
			{
				if (ManagedTriggers[i].bActiveObjectiveTrigger)
				{
					return ManagedTriggers[i];
				}
			}
		}
	}
}


// When the conditions are determined -- set up a new objective
function InitiateObjective()
{
	local ObjectiveInformation newObjective;
	local string tempString;
	local int randomObjectiveIndex;
	local TAHero tempHeroObject;

	`log(self.Name $ " :: initiate objective started.");

	// Generate a random index to use.
	randomObjectiveIndex = Abs(RandRange(0,self.ManagedTriggers.Length));

	// Ensure that we're not assigning to an objective that's already been assigned to.
	while (ManagedTriggers[randomObjectiveIndex].bActiveObjectiveTrigger || ManagedTriggers[randomObjectiveIndex].TriggerType == E_Special)
	{
		randomObjectiveIndex = Abs(RandRange(0,self.ManagedTriggers.Length));
	}

	`log(randomObjectiveIndex $ " is the new index to assign");

	if (GameReference != none)
	{
		tempString = OBJECTIVE_ID_PREFIX $ string(ObjectiveIndexCount);

		newObjective.CurrentTasksCompleted = 0;
		newObjective.CurrentTimeElapsed = 0;
		newObjective.IsActive = true;
		newObjective.ObjectiveID = tempString; // Have the new manager generate an ID
		newObjective.TimeRestricted = false;
		newObjective.TimeToComplete = 5.0f;

		`log(OBJECTIVE_ID_PREFIX $ string(ObjectiveIndexCount) $" :: is the objective ID (objective manager)");

		// Add the trigger to the association
		newObjective.LinkedTriggers.AddItem(ManagedTriggers[randomObjectiveIndex]);

		// Set the usage id for the trigger and activate it.
		ManagedTriggers[randomObjectiveIndex].ObjectiveID = tempString;
		ManagedTriggers[randomObjectiveIndex].bActiveObjectiveTrigger = true;
		ManagedTriggers[randomObjectiveIndex].TriggerObjectiveInformation = newObjective;
		ManagedTriggers[randomObjectiveIndex].ActivateObjectiveTrigger();

		Objectives.AddItem(newObjective);

		GameReference.GameHUD.AddObjective(OBJECTIVE_ID_PREFIX $ string(ObjectiveIndexCount),ManagedTriggers[randomObjectiveIndex].ObjectiveDescription);

		if (ManagedTriggers[randomObjectiveIndex].ObjectiveName == "cryo")
			TAGame(WorldInfo.Game).NarratorManager.SaySpeech(TAGame(WorldInfo.Game).NarratorManager.CryoObjectiveSound);
		else if (ManagedTriggers[randomObjectiveIndex].ObjectiveName == "book")
			TAGame(WorldInfo.Game).NarratorManager.SaySpeech(TAGame(WorldInfo.Game).NarratorManager.BookObjectiveSound);
		else if (ManagedTriggers[randomObjectiveIndex].ObjectiveName == "cake" || ManagedTriggers[randomObjectiveIndex].ObjectiveName == "kitchen")
			TAGame(WorldInfo.Game).NarratorManager.SaySpeech(TAGame(WorldInfo.Game).NarratorManager.KitchenObjectiveSound);

		// Loop through the heros and enable their rings.
		foreach AllActors(class'TAHero',tempHeroObject)
		{
			tempHeroObject.ShowObjectiveRing(ManagedTriggers[randomObjectiveIndex]);
			tempHeroObject.TargetObjectiveTrigger = ManagedTriggers[randomObjectiveIndex];
		}

		ObjectiveIndexCount++;
	}
}

// Game starts and a random interval is generated for the first objective
// to start.
simulated function PostBeginPlay()
{
	local TAZombieSpawnManager spawnmanager;
	local TAObjectiveTrigger objtrigger;

	super.PostBeginPlay();

	ObjectiveTriggerCount = 0;

	`log(self.Name $ " :: POSTBEGINPLAY() objectivemanager");
	
	if (self.GameReference == none)
	{
		`log("GameReference is equal to none");
	}

	foreach AllActors(class'TAObjectiveTrigger',objtrigger)
	{
		// Generate a list of objective triggers to use.
		ManagedTriggers.AddItem(objtrigger);
		objtrigger.ObjectiveManager = self;
		ObjectiveTriggerCount++;
	}

	// Only do stuff if the manager has been set to active.
	if (bIsActive)
	{	

		// Generate a new interval.
		RandomInterval = RandRange(MinRandomTime,MaxRandomTime);

	}

	/** Just incase the ObjectiveManagers reference to the ZombieSpawnManager is NOT done in the Editor. */
	if (ZombieSpawnManager == none)
	{
		foreach AllActors(class'TAZombieSpawnManager', spawnmanager)
		{
			if (self.ZombieSpawnManager == none)
			{
				self.ZombieSpawnManager = spawnmanager;
			}
		}
	}
}

DefaultProperties
{
	ObjectiveIndexCount = 0;

	// For displaying where in the game world the objectivemanager is going to be
	begin object class=SpriteComponent name=EditorIcon
		Sprite=Texture2D'Sprites.objective_manager'
		HiddenGame=true
		HiddenEditor=false
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
	end object
	Components.Add(EditorIcon);

}
