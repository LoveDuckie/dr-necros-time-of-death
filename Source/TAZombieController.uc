class TAZombieController extends AIController;

var TAZombiePawn zombiePawn;

var string outMessage;
var name ActiveState;

var array<TAPawn> VisibleHumans;
var TAPawn HUmanTarget;
var vector MoveDirection;
var float MovementSpeed;
var float NormalGroundSpeed;
var float AttackDuration;
var float Damage;
var float AttackRadius;
var float Health;

/** wandering vars */
var Vector MoveLocation;
var bool bNeedNewNode;
var Actor TargetNode;

/** used for navmesh navigation */
var Vector Destination;     
var Vector MidDestination;
var Actor CharacterTarget;		// Holds info on the target actor
var bool IsMovingToActor;
var bool bActorReached;


var bool bCanPlay;

var float spawnTimer; //how long after spawning should the zombie become active.

var TABarricade BarricadeToAttack;
var bool bBlockedByBarricade;

var array<int> PlayerAggroValues;
var int CurrentAction; // The current action 
var float TimeWaited;  // The length of time waited for the next action
var float LastAttack;  // Time since the last attack


/* Despawns zombies when they haven't seen their target in a while. */
var float DespawnNoLOSTimer;
var float LastSeenPlayerTimer;
const DESPAWN_NO_LOS_DELAY = 20.0f;

var vector LastLocationForDespawner;
var float LastTimeMovedForDespawner;
const DESPAWN_NO_MOVE_DELAY = 10.0f;

/** Prototype functions for the States */
function Brains();
function Attack();

function CalcNode();

simulated event PostBeginPlay()
{
	super.PostBeginPlay();

	SetTimer(1.f, false);
}

event DecreaseAggro()
{
	local int i;

	for (i = 0; i < 4; ++i)
	{
		if (PlayerAggroValues[i] > 15)
		{
			PlayerAggroValues[i] -= 15;
		}
	}

	Scan();
	Prioritise();
}

function float DifficultyScalar()
{
	local float scalar;
	
	switch (TAGame(WorldInfo.Game).TotalPlayers)
	{
		case 1:
			scalar = 1.f;
			break;
		case 2:
			scalar = 1.3f;
			break;
		case 3:
			scalar = 1.6f;
			break;
		case 4:
			scalar = 2.f;
			break;
	}

	return scalar;
}

/** functions used for pathfinding */

function PossessPawn(TAZombiePawn p)
{
	local vector tempTrans;

	zombiePawn = p;
	Possess(p, false);
	Pawn.SetMovementPhysics();
	spawntimer = 2.f;
	ChangeState('Spawning');
	CalcNode();

	switch (p.ZombieType)
	{
		case ZOMB_STANDARD:
			Pawn.GroundSpeed = 150.f;
			AttackDuration = 0.5f;
			Damage = 10.f;
			AttackRadius = 70.f;
			Pawn.Health = 100.f;
			Pawn.HealthMax = Pawn.Health;

			break;
		case ZOMB_RIPPER:
			Pawn.GroundSpeed = 360.f;
			AttackDuration = 0.5f;
			Damage = 20.f;
			AttackRadius = 70.f;
			Pawn.Health = 50.f;
			Pawn.HealthMax = Pawn.Health;
			
			tempTrans.X = TAZombiePawn(Pawn).ZombieMesh.Translation.X;
			tempTrans.Y = TAZombiePawn(Pawn).ZombieMesh.Translation.Y;
			tempTrans.Z = -50;

			TAZombiePawn(Pawn).ZombieMesh.SetTranslation(tempTrans);
			
			break;
		case ZOMB_TANK:
			Pawn.GroundSpeed = 150.f;
			AttackDuration = 2.f;
			Damage = 30.f;
			AttackRadius = 70.f;
			Pawn.Health = 750.f;
			Pawn.HealthMax = Pawn.Health;
			
			tempTrans.X = TAZombiePawn(Pawn).ZombieMesh.Translation.X;
			tempTrans.Y = TAZombiePawn(Pawn).ZombieMesh.Translation.Y;
			tempTrans.Z = -80;

			TAZombiePawn(Pawn).ZombieMesh.SetTranslation(tempTrans);
			
			break;
	}
	Damage *= DifficultyScalar();
	Pawn.Health *=  DifficultyScalar();
	Pawn.HealthMax *=  DifficultyScalar();
	NormalGroundSpeed = Pawn.GroundSpeed;
}

function AddAggro(Controller target, int DamageTaken)
{
	local int i;
	i = int(TAHero(target.Pawn).PlayerHeroType);

	PlayerAggroValues[i] += DamageTaken;
	Scan();
	Prioritise();
}

function ChangeState(name newState)
{
	ActiveState = newState;
	GotoState(newState);
}

function Scan()
{

	local TAPawn playerPawn;

	if (bCanPlay)
	{
		VisibleHumans.Remove(0, VisibleHumans.Length);

		foreach AllActors(class'TAPawn', playerPawn)
		{
			if (playerPawn.class.name != 'TAZombiePawn' && playerPawn.Health > 0 && playerPawn.bIsActive)
			{
				VisibleHumans.AddItem(playerPawn);
			}
		}
	}
}

/** From the scan results, prioritises which human or player to head for and attack */
function Prioritise()
{
	local float priorityValue, maxValue;
	local int i;

	maxValue = -10.f;
	if (bCanPlay)
	{	
		priorityValue = 0;

		if (HumanTarget == None || Humantarget.class.name != 'TATurret') //if on a turret, focus on it
		{
			HumanTarget = none;

			if (VisibleHumans.Length > 0)
			{
				if (zombiePawn.Zombietype == ZOMB_TANK) //goes for players
				{

					for (i = 0; i < VisibleHumans.Length; i++) //up for anything
					{
						if (VisibleHumans[i].class.name == 'TAHero')
						{
							priorityValue = 5.f + ((VisibleHumans[i].Health) / abs(VSize(VisibleHumans[i].Location - Pawn.Location)));
							priorityValue *= PlayerAggroValues[int(TAHero(VisibleHumans[i]).PlayerHeroType)];
							if (priorityValue > maxValue)
							{
								maxValue = priorityValue;
								HumanTarget = VisibleHumans[i];
							}
						}
					}

					
				}
				else if (zombiePawn.ZombieType == ZOMB_RIPPER) //goes for HP
				{
					if (!FindTurretToEat())
					{					
						if (VisibleHumans[i].class.name == 'TAHuman')
						{
							for (i = 0; i < VisibleHumans.Length; i++) //up for anything
							{		
								/** calculate a priority value for the humans */
								priorityValue = (VisibleHumans[i].Health) / abs(VSize(VisibleHumans[i].Location - Pawn.Location));
								if (priorityValue > maxValue)
								{
									maxValue = priorityValue;
									HumanTarget = VisibleHumans[i];
								}
							}
						}

						if (HumanTarget == None) //NO humans found, focus on players
						{
							for (i = 0; i < VisibleHumans.Length; i++) //up for anything
							{
								if (VisibleHumans[i].class.name == 'TAHero')
								{
									priorityValue = (VisibleHumans[i].Health) / abs(VSize(VisibleHumans[i].Location - Pawn.Location));
									priorityValue *= PlayerAggroValues[int(TAHero(VisibleHumans[i]).PlayerHeroType)];
									if (priorityValue > maxValue)
									{
										maxValue = priorityValue;
										HumanTarget = VisibleHumans[i];
									}
								}
							}
						}
					}
					
				}
				else
				{
					if (!FindTurretToEat())
					{					
						for (i = 0; i < VisibleHumans.Length; i++) //up for anything
						{
							/** calculate a priority value for the humans */
							priorityValue = (VisibleHumans[i].Health * VisibleHumans[i].Followers) / abs(VSize(VisibleHumans[i].Location - Pawn.Location));
							if (VisibleHumans[i].class.name == 'TAHero')
							{
								priorityValue *= PlayerAggroValues[int(TAHero(VisibleHumans[i]).PlayerHeroType)];
							}
							if (priorityValue > maxValue)
							{
								maxValue = priorityValue;
								HumanTarget = VisibleHumans[i];
							}
						}
					}
					
				}
			}

			//if we have a target,chase it.
			if (HUmantarget == none)
			{
				// no target? Go to camera marker.
				Humantarget =  TAGame(WorldInfo.Game).GameCamera.AverageMarker;
			}

			ChangeState('Chasing');
			
		}
	}
				
}

function bool FindTurretToEat()
{
	local TATurret turret;
	local int distance;

	distance = 750.0f;

	foreach AllActors(class'TATurret', turret)
	{
		
		if (abs(vsize(turret.location - zombiePawn.location)) < distance)
		{
			distance = abs(vsize(turret.location - zombiePawn.location));
			HumanTarget = turret;			
		}
		
	}

	if (HumanTarget != None)
	{		
		ChangeState('chasing');
		return true;
	}
	
	return false;
	
}

//prototype
event Tick(float deltaTime);

auto state() Spawning
{
	local MaterialInstanceConstant matTemp;
	event Tick(float deltaTime)
	{
		LastAttack += deltaTime;
		spawnTimer -= deltaTime;
		zombiePawn.ZombieFadeMaterial.SetScalarParameterValue('PortalAlpha', 1.f - (spawntimer / 2.f));
		if (spawnTimer <= 0.f)
		{
			bCanPlay = true;
			matTemp = new class'MaterialInstanceConstant';
			matTemp.SetParent(zombiePawn.zombieMesh.GetMaterial(0));
			matTemp.GetMaterial().BlendMode = BLEND_Opaque;
			zombiePawn.zombieMesh.SetMaterial(0, matTemp);		

			zombiePawn.SpawnPortal.bShrinking = true;
			ChangeState('Wandering');
		}

	}
}

state() Wandering
{
	event Tick(float deltaTime)
	{		
		/** wander in a general irection, if close to a wall, change direction */
		self.CustomTimeDilation = TAZombiePawn(Pawn).TimeModifier;
		Pawn.CustomTimeDilation = TAZombiePawn(Pawn).TimeModifier;
		super.tick(deltatime);
	}

	/** Scans the area looking for targets */
		

begin:
	if (bCanplay)
	{
		Scan();
		Prioritise();		
	}
	Sleep(0.25f);
	goto 'Begin';
}



state() Chasing
{

	local bool makePath;
	local vector traceHitLocation, traceHitNormal;

	event Tick(float deltaTime)
	{
		LastAttack += deltaTime;
		DespawnNoLOSTimer += deltaTime;
		
		if (HumanTarget != none)
		{
			if (abs(VSize(HumanTarget.Location - Pawn.Location)) < AttackRadius)
			{				
				/** Nom nom nom the target (switch to attacking) */
				ChangeState('Nom');	
			}			
			else
			{
				zombiePawn.bIsAttacking = false;
				Destination = Humantarget.Location;			
				NavigationHandle.SetFinalDestination(Destination);
				GeneratePathToActor(Humantarget, AttackRadius * 0.9f, true);
			}
		}
		else
		{
			/** GENERATE A PATH TO THE AVERAGE LOCATION OF THEN PLAYERS */			
			Destination = Humantarget.Location;			
			NavigationHandle.SetFinalDestination(Destination);
			GeneratePathToActor(Humantarget, AttackRadius * 0.9f, true);
		}		

		self.CustomTimeDilation = TAZombiePawn(Pawn).TimeModifier;
		Pawn.CustomTimeDilation = TAZombiePawn(Pawn).TimeModifier;
	}

	function bool GeneratePathToActor(Actor Goal, optional float WithinDistance, optional bool bAllowPartialPath)
	{
		if (NavigationHandle == None)
		{
			return false;
		}
		NavigationHandle.ClearConstraints();

		class'NavMeshPath_Toward'.static.TowardGoal(NavigationHandle, Goal);
		class'NavMeshPath_EnforceTwoWayEdges'.static.EnforceTwoWayEdges(NavigationHandle);
		class'NavMeshGoal_At'.static.AtActor(NavigationHandle, Goal, WithinDistance, bAllowPartialPath);

		return NavigationHandle.FindPath();
	}

	function bool SafeSight()
	{
		local TAPawn hitTarget;
		hitTarget = TAPawn(Trace(traceHitLocation, traceHitNormal, Pawn.Location, HUmantarget.Location));
		if (hitTarget != none)
		{
			return (hitTarget.class.name == HUmantarget.class.name);			
		}

		return true;		
	}

	Begin:

		if (LastSeenPlayerTimer == 0)
		{
			LastSeenPlayerTimer = DespawnNoLOSTimer;
		}

		if (bBlockedByBarricade)
		{
			BarricadeToAttack.ReceiveDamage(Damage);
			zombiePawn.bIsAttacking = true;
			Sleep(AttackDuration);			

			if (BarricadeToAttack == none)
			{
				bBlockedByBarricade = false;
				zombiePawn.bIsAttacking = false;
			}
		}

		/** do a trace if we can see, to see if we have to go round an obstacle */

		if (CanSee(HUmantarget))
		{
			/** trace */
			if (SafeSight())
			{
				Movetoward(HumanTarget, Humantarget);				
				makePath = false;
			}
			else
			{
				makePath = true;
			}
			LastSeenPlayerTimer = DespawnNoLOSTimer;
		}
		else
		{
			makePath = true;
		}

		if (HUmantarget.class.name == 'TACameraAverageMarger' || abs(VSize(Pawn.Location - HUmanTarget.Location)) > 1000.f)
		{
			makePath = true;
		}

		if (makePath)
		{
			
			if (NavigationHandle.PointReachable(Destination))
			{
				MoveTo(Destination);
			}
			else
			{

				if (NavigationHandle.GetNextMoveLocation(MidDestination, Pawn.GetCollisionRadius()))
				{
					if (!NavigationHandle.SuggestMovePreparation(MidDestination, self))
					{	
						Destination.Z = Pawn.Location.Z;
						Pawn.SetRotation(Rotator(MidDestination - Pawn.Location));
						MoveTo(MidDestination);						
					}
				}	
			}
		}

		
		// If we haven't see the human for a really long time, despawn - something
		// probably went wrong, better than having an indefinite wave.
		if (Location != LastLocationForDespawner)
		{
			LastLocationForDespawner = Location;
			LastTimeMovedForDespawner = DespawnNoLOSTimer;
		}


	Sleep(0.3f);
	Scan();
	Prioritise();
	Goto 'Begin';
}

/** Attacking state */
state() Nom
{
	event Tick(float deltaTime)
	{	
		LastAttack += deltaTime;
		TimeWaited += deltaTime;

		if (CurrentAction == 0 && LastAttack > AttackDuration)
		{
			Attack();	
			CurrentAction = 1;
			TimeWaited = 0;
		}
		else if (CurrentAction == 1 && TimeWaited > 0.1f)
		{
			Assess();		
			CurrentAction = 0;
			TimeWaited = 0;
		}
	}

	function Brains()
	{
		//WorldInfo.Game.Broadcast(self, "B");
	}

	Function BeginState(name PreviousStateName)
	{
		Pawn.ZeroMovementVariables();
	}

	function Attack()
	{
		LastAttack = 0;

		zombiePawn.bIsAttacking = true;
		HumanTarget.TakeDamage(Damage, self, Pawn.Location, 25*Normal(Pawn.Velocity), class'TADmgType');

		zombiePawn.PlayAttackSound();	
	}

	function Assess()
	{
		if (HumanTarget.Health <= 0)
		{
			zombiePawn.bIsAttacking = false;
			HumanTarget = none;
			ChangeState('Wandering');
		}

		if (abs(VSize(HumanTarget.Location - Pawn.Location)) > AttackRadius)
		{
			zombiePawn.bIsAttacking = false;
			ChangeState('Chasing');
		}
	}

Begin:
	CurrentAction = 0;
	TimeWaited = 0;
}

defaultproperties
{
	MovementSpeed = 100.f;
	AttackDuration = 1.5f;
	Damage = 5.f;
	AttackRadius = 100.f;
	Health = 100.f;

	PlayerAggroValues(0) = 1
	PlayerAggroValues(1) = 1
	PlayerAggroValues(2) = 1
	PlayerAggroValues(3) = 1

	bNeedNewNode = true;

	NavigationHandleClass=class'NavigationHandle'

}