class TAAIHumanController extends AIController;

var TAHero Following;

var TAGame GameReference;

var Vector SpawnPoint;

// For storing the vectors of where the AI has to walk to meanwhile
var Vector Destination;
var Vector MidDestination;
var bool EndGameState;

const SCORE_AMOUNT_ON_SAVE = 300;

var name ActiveState;

var bool MovingToDestination;

var float Health;

var TAHuman HumanPawn;

var Vector SelectedCharMeshOffset;

var float DistanceFromHero;

var Vector WanderingDestination;

var Vector LeastZombieFilledDirection;

var bool CanFollowHero;

const ZOMBIES_NEAR_ME_THRESHOLD = 200.0f;
const ZOMBIES_NEAR_ME_THRESHOLD_PANIC = 350.0f;

const RANDOM_TARGET_MIN_DISTANCE = 50.0f;
const RANDOM_TARGET_MAX_DISTANCE = 256.0f;
const RANDOM_TARGET_COMPLETE_THRESHOLD = 16.0f;

const PANIC_TARGET_DISTANCE = 128.0f;

const IDLE_TIME_MIN = 1.0f;
const IDLE_TIME_MAX = 3.0f;

function SetPawn()
{

}

function PossessPawn(TAHuman p)
{
	HumanPawn = p;

	Pawn = p;
	Pawn.SetMovementPhysics();
		
	if (Pawn.Physics == PHYS_Walking)
	{
		Pawn.SetPhysics(PHYS_Falling);
	}

	ChangeState('Wandering');
}

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	//GoToState('Wandering');
	DistanceFromHero = 200.0f;
}

function bool CanFollow()
{
	return Following == none ? true : false;
}

function UpdateController(float DeltaTime)
{
	super.Tick(DeltaTime);

}

// Change the state and display that we're following the player.
function FollowPlayer(TAHero pPlayer)
{
	// Determine whether or not the human is dead before commanding him to do things
	if (!TAHuman(Pawn).IsInState('Dying') && !EndGameState)
	{
		Following = pPlayer;
		ChangeState('MoveToPoint');

		pPlayer.HumansFollowing.AddItem(TAHuman(Pawn));
	}
}

function UnFollow(TAHero pPlayer)
{

	if (pPlayer == self.Following)
	{
		// wander around.
		Following = none;
		TAHuman(pawn).Following = none;

		pPlayer.HumansFollowing.RemoveItem(TAHuman(Pawn));

		GoToState('Wandering');
	}
	else
	{
		//`log("You are not the following owner " $ pPlayer.Name);
	}
}

function UnFollowPlayer(bool pEndGame)
{  
	if (Following != none)
	{
		
		Following.HumansFollowing.RemoveItem(TAHuman(Pawn));
		GoToState('Wandering');
		Following = none;
		TAHuman(pawn).Following = none;
		
	}
}

function bool ZombiesNearMe(float threshold)
{
	local TAZombiePawn zombiePawn;
	foreach AllActors(class'TAZombiePawn', zombiePawn)
	{
		if (zombiePawn.Health > 0 && VSize(zombiePawn.Location - Pawn.Location) < threshold)
		{
			return true;
		}
	}
	
	/*
	local TAHero zombiePawn;
	foreach AllActors(class'TAHero', zombiePawn)
	{
		if (zombiePawn.Health > 0 && VSize(zombiePawn.Location - Pawn.Location) < threshold)
		{
			return true;
		}
	}*/
	
	return false;
}   

function vector GenerateRandomDestination()
{
	local int       attempts;
	local Vector    target;
	local Vector    randomisation;
	local float     distance;

	while (true)
	{
		if (attempts > 10)
		{
			return vect(0,0,0);
		}

		randomisation.X = (frand() * 2.0f) - 1.0f;
		randomisation.Y = (frand() * 2.0f) - 1.0f;
		distance = RANDOM_TARGET_MIN_DISTANCE + (frand() * RANDOM_TARGET_MAX_DISTANCE);

		target = Pawn.Location + (randomisation * distance);

		if (Pawn.FastTrace(target) == true)
		{
			target = Pawn.Location + (randomisation * (distance * 0.9f));
			break;
		}

		attempts++;
	}

	return target;
}

function vector CalculateLeastZombieFilledDirection()
{
	local Vector    target;
	local Vector    direction;
	local float     angle;
	local float     distance;

	local TAZombiePawn zombiePawn;
	local int numberOfZombies;

	local vector hitLocation;
	local vector hitNormal;

	local int bestAngle;
	local int bestAngleZombieCount;

	distance  = PANIC_TARGET_DISTANCE;
	bestAngle = -1;

	for (angle = 0; angle < 360; angle += 5)
	{
		direction.X = sin(angle * DegToRad);
		direction.Y = cos(angle * DegToRad);
		direction.Z = 0;
		target      = Pawn.Location + (direction * distance);

		//if (Pawn.FastTrace(target) == false)
		//{
		//	continue;
		//}

		if (Pawn.Trace(hitLocation, hitNormal, target, , true) != none)
		{
			continue;
		}

		// Count how many zombies are near this target.
		numberOfZombies = 0;
		/*
		foreach AllActors(class'TAZombiePawn', zombiePawn)
		{
			if (vsize(target - zombiePawn.Location) <= distance)
			{
				numberOfZombies++;
			}
		}
		*/

		foreach AllActors(class'TAZombiePawn', zombiePawn)
		{
			if (vsize(target - zombiePawn.Location) <= 400)
			{
				numberOfZombies += vsize(target - zombiePawn.Location);
			}
		}

		/*
		foreach AllActors(class'TAHero', heroPawn)
		{
			if (vsize(target - heroPawn.Location) <= 512)
			{
				numberOfZombies += vsize(target - heroPawn.Location);
			}
		}
		*/

		// Is this the best angle we've got so far?
		if (bestAngle == -1 || bestAngleZombieCount < numberOfZombies)
		{
			bestAngle = angle;
			bestAngleZombieCount = numberOfZombies;
		}
	}

	if (bestAngle == -1)
	{
		`Log("COULD NOT FIND APPROPRIATE ANGLE :(");
	}

	direction.X = sin(bestAngle * DegToRad);
	direction.Y = cos(bestAngle * DegToRad);
	direction.Z = 0;
	target      = Pawn.Location + (direction * (distance * 0.9f));

	return target;
}

// Wrapper for the gotostate so that I can record
// the name of the state that the player is on.
function ChangeState(name statename)
{
	TAHuman(self.Pawn).StateName = statename;
	//`log(self.Name $ ": Changed to state " $statename);
	GoToState(statename);
}

// Move to the hero
state() MoveToPoint
{
	event Tick(float deltaTime)
	{
		if (Following != none)
		{
			// Ensure that the indicator is being displayed.
			TAHuman(Pawn).SelectedRing.SetHidden(false);
		}
	}

	Begin:
		Sleep(1);
		
		// Change the ground speed so that it's the same as the hero that we're
		// following
		if (Following != none)
		{
			Pawn.GroundSpeed = Following.GroundSpeed;//TAHuman(Pawn).PanicSpeed;
		}
		else
		{
			Pawn.GroundSpeed = TAHuman(Pawn).PanicSpeed;
		}
		Pawn.Acceleration = vect(0,0,0.5f);

		
		while (Pawn != none)
		{
			MoveToward(Following,Following,DistanceFromHero);
		
			//`log(Pawn.Name $ ": is going towards hero");

			// If there are any zombies near by, then go to panicing.

			//if (ZombiesNearMe(ZOMBIES_NEAR_ME_THRESHOLD))
			//{
			//	ChangeState('Panic');
			//}

			// If the pawn has either gotten to the player or can see the player then change to idle.
			if (!CanSee(Following) || Following == none)
			{
				ChangeState('Wandering');
			}
	
		}
	Sleep(0.1);
	Goto 'Begin';
}

// For when the humans are no longer required
state() EndGame
{
	simulated function TerminateHuman()
	{
		Pawn.Destroy();
		Destroy();
	}

	// Generate a path dynamically to the actor.
	function bool GeneratePathToActor(Actor Goal, optional float WithinDistance, optional bool bAllowPartialPath)
	{
		if (NavigationHandle == None)
		{
			`log("NavigationHandle does not equal to anything!");
			return false;
		}

		class'NavMeshPath_Toward'.static.TowardGoal(NavigationHandle,Goal);
		class'NavMeshPath_EnforceTwoWayEdges'.static.EnforceTwoWayEdges(NavigationHandle);
		class'NavMeshGoal_At'.static.AtActor(NavigationHandle, Goal, WithinDistance, bAllowPartialPath);
		
		return NavigationHandle.FindPath();
	}


	simulated event Tick(float DeltaTime)
	{
		if (TAHuman(Pawn) != none)
		{
			// Determine if we have arrived at the end point location
			if (TAHuman(Pawn).EndPointLocation != none)
			{
				if (abs(VSize(TAHuman(Pawn).EndPointLocation.Location - Pawn.Location)) < 5.0f)
				{
					// If so, then terminate them
					`log("Within radius to terminate");
					TerminateHuman();
				}
				else
				{
					Destination = TAHuman(Pawn).EndPointLocation.Location;
					NavigationHandle.SetFinalDestination(Destination);
					GeneratePathToActor(TAHuman(Pawn).EndPointLocation, 5.0f, true);
				}
			}
		}
	}

Begin:
	Pawn.GroundSpeed=600.0f;
	if (NavigationHandle.PointReachable(Destination))
	{
		MoveTo(Destination);
	}
	else
	{
		if (NavigationHandle.GetNextMoveLocation(MidDestination,Pawn.GetCollisionRadius()))
		{
			if (!NavigationHandle.SuggestMovePreparation(MidDestination, self))
			{
				Destination.Z = Pawn.Location.Z;
				Pawn.SetRotation(Rotator(MidDestination - Pawn.Location));
				MoveTo(MidDestination);
			}
		}
	}
	
	Sleep(0.3f);
	Goto 'Begin';
}

state Idle
{
	event Tick(float deltaTime)
	{
		// Zombies near me? PANIC
		//if (ZombiesNearMe(ZOMBIES_NEAR_ME_THRESHOLD))
		//{
		//	ChangeState('Panic');
		//	return;
		//}

		// Make sure that the hero that we're following is not in fact null.
		if (Following != none)
		{
			// Make sure that the human is within distance of the player before doing anything else.
			if (abs(VSize(Following.Location - self.Pawn.Location)) > DistanceFromHero)
			{
				ChangeState('MoveToPoint');				
			}
		}

		// Quick inline condition that determines whether or not to display the selected ring.
		Following == none ? TAHuman(Pawn).SelectedRing.SetHidden(true) : TAHuman(Pawn).SelectedRing.SetHidden(true);
	}

	Begin:
		Sleep(IDLE_TIME_MIN + (frand() * IDLE_TIME_MAX));
		ChangeState('Wandering');
}

auto state() Wandering
{
	event Tick(float deltaTime)
	{
		// Zombies near me? PANIC
		if (ZombiesNearMe(ZOMBIES_NEAR_ME_THRESHOLD))
		{
			ChangeState('Panic');
			return;
		}

		// Make sure that the hero that we're following is not in fact null.
		if (Following != none)
		{
			// Make sure that the human is within distance of the player before doing anything else.
			if (abs(VSize(Following.Location - self.Pawn.Location)) > DistanceFromHero)
			{
				ChangeState('MoveToPoint');				
			}
		}
	}

	Begin:
		WanderingDestination = GenerateRandomDestination();
		if (WanderingDestination == vect(0, 0, 0))
		{
			ChangeState('Idle');
		}
		Pawn.GroundSpeed = TAHuman(Pawn).NormalSpeed;
		while (true)
		{   
			if (vsize(Pawn.Location - WanderingDestination) < RANDOM_TARGET_COMPLETE_THRESHOLD)
			{
				break;
			}

			MoveTo(WanderingDestination);

			Sleep(0.1f);
		}
		Acceleration = vect(0, 0, 0);
		ChangeState('Idle');
}

state Panic
{
Begin:
	Pawn.GroundSpeed = TAHuman(Pawn).PanicSpeed; 
	
	while (ZombiesNearMe(ZOMBIES_NEAR_ME_THRESHOLD_PANIC))
	{
		LeastZombieFilledDirection = CalculateLeastZombieFilledDirection();
		MoveTo(LeastZombieFilledDirection);

		Sleep(0.05f);
	}

	Pawn.GroundSpeed = TAHuman(Pawn).NormalSpeed;
	
	Acceleration = vect(0, 0, 0);
	ChangeState('Idle');
}

DefaultProperties
{
	// Determine whether or not the human should be able to follow a hero.
	CanFollowHero = true;

	NavigationHandleClass=class'NavigationHandle'
}
