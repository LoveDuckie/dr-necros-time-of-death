class TAZombieBossController extends AIController;

var TABossZombie BossPawn;
var name _activeState;

var array<TAHero> VisibleHumans;
var array<int> PlayerAggroValues;

Enum ATTACK_TYPE {AIRSLAM, SWEEP, GRAB, GROUNDPOUND, SUMMON, THROW};
var ATTACK_TYPE AttackType;
var float AttackInterval;
var array<float> AttackCooldowns;

var TAHero HumanTarget;

var float AttackRadius;
var float ActiveAttackDuration;
var float AttackStageTimer;

var vector Destination;
var vector traceHitLocation, traceHitNormal, MidDestination;
var bool makePath;

var TAHero GrabTarget;

var TAPlayerCamera gameCamera;

const AIRSLAM_RADIUS = 400;
const AIRSLAM_DAMAGE = 60;
const SWEEP_DAMAGE = 15;
const GROUNDPOUND_DAMAGE = 50;
const GRABIDLE_TIME = 2.f;
const THROW_DAMAGE = 70;

const SUMMON_RADIUS = 16000;

simulated event postbeginplay()
{
	super.postbeginplay();
}

/** we'll spawn the boss after the matinee */
function PossessBoss(TABossZombie bPawn)
{
	Possess(bPawn, false);
	if (Pawn != None)
	{
		BossPawn = TABossZombie(Pawn);
		Letsrock();
	}
}

function LetsRock()
{
	gameCamera = TAGame(WorldInfo.Game).gameCamera;
	Scan();
	Prioritise();
	ChangeState('Moving');
}

function ChangeState(name newState)
{
	`log("Boss changing state to:"$newState);
	//TAGame(WorldInfo.Game).Broadcast(none, "Boss changing state to: "$newState$" from "$_activeState);
	GotoState(newState);
	_activeState = newState;
}

function AddAggro(Controller target, int DamageTaken)
{
	local int i;
	i = int(TAHero(target.Pawn).PlayerHeroType);
	PlayerAggroValues[i] += DamageTaken;	
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
}

function Scan()
{
	local TAHero playerPawn;	
	VisibleHumans.Remove(0, VisibleHumans.Length);

	foreach AllActors(class'TAHero', playerPawn)
	{
		if (playerPawn.bIsActive)
		{
			VisibleHumans.AddItem(playerPawn);
			playerPawn.bossRef = Bosspawn;
		}
	}	
}

/** From the scan results, prioritises which human or player to head for and attack */
function Prioritise()
{
	local float priorityValue, maxValue;
	local int i;
		
	priorityValue = 0;	
	HumanTarget = none;

	if (VisibleHumans.Length > 0)
	{		
		for (i = 0; i < VisibleHumans.Length; i++) //up for anything
		{				
			priorityValue = (VisibleHumans[i].Health) / abs(VSize(VisibleHumans[i].Location - Pawn.Location));
			priorityValue *= PlayerAggroValues[int(VisibleHumans[i].PlayerHeroType)];
			if (priorityValue > maxValue)
			{
				maxValue = priorityValue;
				HumanTarget = VisibleHumans[i];
			}
		}		
	}			
}

/** Sets the interval before the attack can be used again */
function SetCooldown(ATTACK_TYPE t)
{
	switch (t)
	{		
	}
}

function CoolAttack(float deltaTime)
{
	local int i;

	for (i = 0; i < AttackCooldowns.Length; ++i)
	{
		AttackCooldowns[i] -= deltaTime;
		if (AttackCooldowns[i] <= 0.f)
		{
			AttackCooldowns[i] = 0.f;
		}
	}
}

function Die()
{
	if (GrabTarget != None)
	{
		/** IF WE HAVE a grab target, drop it */
		GrabTarget.bGrabbed = false;
		GrabTarget.SetLocation(BossPawn.Location + (vector(BossPawn.Rotation) * 300));
	}
}

event Tick(float deltaTime)
{
	CoolAttack(deltaTime);
	if (AttackInterval > 0.f)
	{
		AttackInterval -= deltaTime;
	}

	if (ActiveAttackDuration > 0.f)
	{
		ActiveAttackDuration -= deltaTime;
	}

}

function ATTACK_TYPE AvailableAttacks()
{
	local array<ATTACK_TYPE> attackPool;
	local ATTACK_TYPE finalAttack;
	local int i;

	for (i = 0; i < AttackCooldowns.Length; ++i)
	{
		if (AttackCooldowns[i] <= 0.f)
		{
			attackPool.AddItem(ATTACK_TYPE(i));
		}
	}

	/**randomise the attack */
	
	BossPawn.bIsAttacking = true;
	BossPawn.GroundSpeed = 0.f;
	if (attacktype == GRAB)
	{
		finalAttack = THROW;
	}
	else
	{
		finalAttack = attackPool[RandRange(0, attackPool.Length-1)];
	}
	Attackinterval = int(FRand() * 3) + 2.f;
	switch(finalAttack)
	{
		case AIRSLAM:
			AttackCooldowns[AIRSLAM] = 20.f;
			ActiveAttackDuration = 1.6667f;
			BossPawn.bAirSlamAttack = true;
			break; 
		case SWEEP: 
			AttackCooldowns[SWEEP] = 15.f;
			ActiveAttackDuration = 1.6667f;
			BossPawn.bFloorSwipeAttack = true;
			break;
		case GRAB:
			AttackCooldowns[GRAB] = 15.f;
			ActiveAttackDuration = 1.f;
			BossPawn.bGrabbing = true;
			Attackinterval = 3.f;
			break;
		case GROUNDPOUND:
			AttackCooldowns[GROUNDPOUND] = 7.5f;
			ActiveAttackDuration = 1.f;
			BossPawn.bGroundPoundAttack = true;
			break;
		case SUMMON:
			AttackCooldowns[SUMMON] = 5.f;
			ActiveAttackDuration = 3.75f;
			BossPawn.bSummoning = true;
			break;		
		case THROW:
			BossPawn.bGrabbingidle = false;
			Bosspawn.bThrowing = true;
			ActiveAttackDuration = 2.f;
			break;			
	}
	
	//TAGame(Worldinfo.Game).BroadCast(none, "changing attack to "$finalAttack);
	return finalAttack;
}

function ResetAttackBools()
{
	local int i;

	for (i = 0; i < VisibleHumans.Length; ++i)
	{
		VisibleHumans[i].BossDamageRecdThisAttack = false;
	}
	BossPawn.bIsAttacking = false;
	BossPawn.bBasicAttack = false;
	BossPawn.bAirSlamAttack = false;
	BossPawn.bFloorSwipeAttack = false;
	BossPawn.bGroundPoundAttack = false;
	BossPawn.bPunchLeftAttack = false;

	if (BossPawn.bGrabbing)
	{
		BossPawn.bGrabbingIdle = true;
	}
	else
	{
		BossPawn.bGrabbingidle = false;
	}
	
	BossPawn.bGrabbing = false;
	bosspawn.bThrowing = false;

	BossPawn.GroundSpeed = 650.f;
	AttackStageTimer = 0;
}

auto state() Moving
{

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

		//return true;
		if (hitTarget != none)
		{
			return (hitTarget.class.name == HUmantarget.class.name);			
		}	
		return true;	
	}	

Begin:
	BossPawn.bIsAttacking = false;	

	if (HumanTarget != None)
	{
		Destination = Humantarget.Location;			
		NavigationHandle.SetFinalDestination(Destination);
		GeneratePathToActor(Humantarget, AttackRadius * 0.9f, true);
	}

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
	}
	else
	{
		makePath = true;
	}

	if (SafeSight())
	{		
		if (NavigationHandle.PointReachable(Destination))
		{
			if (abs(VSize(HumanTarget.Location - Pawn.Location)) > AttackRadius * 0.8f)
			{
				MoveToward(HumanTarget, HumanTarget, AttackRadius * 0.8f);
			}
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

	if (AttackInterval <= 0.f && abs(VSize(HumanTarget.location - Pawn.Location)) <= AttackRadius)
	{		
		AttackType = AvailableAttacks();				
		ChangeState('Attacking');
	}

	Sleep(0.3f);
	Scan(); //incase people joined
	Prioritise();
	goto 'Begin';
}

state() Attacking
{
	local int i;
	local bool slamDamageDealt;
	local bool resetHits;
	local bool bSummoned;
	local bool bGrabbed;
	local bool soundPlayed;
	local bool bThrown;

	local TAGraveMarker grave;

	event tick(float deltaTime)
	{
		AttackStageTimer += deltaTime;
		switch (AttackType)
		{
			case THROW:
				if (AttackStageTimer > 0.4f && !bThrown)
				{
					/** work out trajectory to throw player */
					bthrown = true;
					GrabTarget.bGrabbed = false;
					GrabTarget.bThrown = true;
					GrabTarget.Velocity = vector(BossPawn.Rotation) * 5000.f * vect(1,1,0.5f);
					`log("[BOSS] Throwing "$Grabtarget);
					if (!soundPlayed)
					{
						TABossZombie(Pawn).PlayAttackSound();
						soundPlayed = true;
						GrabTarget = none;
					}
				}
				break;
			case GRAB:
				if (AttackStageTimer >= 0.39f && AttackStageTimer <= 0.52f) //right fist
				{
					if (!soundPlayed)
					{
						TABossZombie(Pawn).PlayAttackSound();
						soundPlayed = true;
					}
					if (!bGrabbed)
					{
						for (i = 0; i < VisibleHumans.Length; ++i)
						{
							if (!bGrabbed)
							{
								if (abs(VSize(VisibleHumans[i].Location - BossPawn.rPos)) <= 500.f)
								{							
									bGrabbed = true;
									Grabtarget = VisibleHumans[i];		
									GrabTarget.bGrabbed = true;						
								}
							}
						}
					}
				}
				break;
			case SUMMON:
				if (AttackStageTimer >= 1.6f && !bSummoned)
				{
					if (!soundPlayed)
					{
						PlaySound(SoundCue'Sounds.Boss.RiseCue');
						soundPlayed = true;
					}
					/** locate all graves within radius, spawn zombies */
					foreach AllActors(class'TAGraveMarker', grave)
					{
						if (abs(VSize(grave.location - bossPawn.Location)) < SUMMON_RADIUS)
						{
							Spawn(class'TAZombiePawn',,,grave.location, grave.rotation);
						}
					}
					bSummoned = true;
				}
				break;
			case AIRSLAM:
				/** AoE */
				if (!soundPlayed)
				{
					TABossZombie(Pawn).PlayAttackSound();
					soundPlayed = true;
				}
				if (AttackStageTimer > 0.813f && !slamDamageDealt)
				{
					slamDamageDealt = true;
					gameCamera.CameraShake(1.f);
					//Pawn.PlaySound(SoundCue'Sounds.Boss.Airslam_Impact');
					for (i = 0; i < VisibleHumans.Length; ++i)
					{
						if (abs(VSize(VisibleHumans[i].Location - Pawn.Location)) < AIRSLAM_RADIUS)
						{
							`log("[BOSS] Dealing AIRSLAM_DAMAGE to "$VisibleHumans[i]);
							VisibleHumans[i].TakeDamage(AIRSLAM_DAMAGE, self, Pawn.Location, 15000*Normal(VisibleHumans[i].Velocity) * vect(0,0,1), class'TADmgType');
						}
					}
				}
				break;
			
			case SWEEP:
				if (AttackStageTimer >= 0.3f && AttackStageTimer <= 0.6f) //left fist
				{
					if (!soundPlayed)
					{
						TABossZombie(Pawn).PlayAttackSound();
						soundPlayed = true;
					}
					for (i = 0; i < VisibleHumans.Length; ++i)
					{
						if (abs(VSize(VisibleHumans[i].Location - BossPawn.lPos)) <= 300.f)
						{
							if (!VisibleHumans[i].BossDamageRecdThisAttack)
							{
								`log("[BOSS] Dealing SWEEP_DAMAGE to "$VisibleHumans[i]);
								VisibleHumans[i].TakeDamage(SWEEP_DAMAGE, self, Pawn.Location, 15000*Normal(BossPawn.lPos - BossPawn.lPosPrev) * vect(1,1,1.05f), class'TADmgType');
								VisibleHumans[i].BossDamageRecdThisAttack = true;
							}
						}
					}
				}

				// allows for two hits from sweep.
				if (AttackStageTimer > 0.6f && !resetHits)
				{
					for (i = 0; i < VisibleHumans.Length; ++i)
					{
						VisibleHumans[i].BossDamageRecdThisAttack = false;
					}
					soundPlayed = false;
					resetHits = true;
				}

				if (AttackStageTimer >= 0.9f && AttackStageTimer <= 1.2f) //right fist
				{
					//TAGame(WorldInfo.Game).Broadcast(none, "rDistance: "$abs(VSize(VisibleHumans[i].Location - BossPawn.rPos)));
					for (i = 0; i < VisibleHumans.Length; ++i)
					{
						if (abs(VSize(VisibleHumans[i].Location - BossPawn.rPos)) <= 300.f)
						{
							if (!VisibleHumans[i].BossDamageRecdThisAttack)
							{
								`log("[BOSS] Dealing SWEEP_DAMAGE to "$VisibleHumans[i]);
								VisibleHumans[i].TakeDamage(SWEEP_DAMAGE, self, Pawn.Location, 15000*Normal(BossPawn.rPos - BossPawn.rPosPrev) * vect(1,1,1.05f), class'TADmgType');
								VisibleHumans[i].BossDamageRecdThisAttack = true;
							}
						}
					}
				}
				
				/** distance checks to fist */
				break;
			case GROUNDPOUND:
				/** small AoE from fists */
				if (!soundPlayed)
				{
					TABossZombie(Pawn).PlayAttackSound();
					soundPlayed = true;
				}
				if (AttackStageTimer >= 0.37f && !slamDamageDealt)
				{
					slamDamageDealt = TRUE;
					for (i = 0; i < VisibleHumans.Length; ++i)
					{
						if (abs(VSize(VisibleHumans[i].Location - BossPawn.Location)) < 350.f)
						{
							if (!VisibleHumans[i].BossDamageRecdThisAttack)
							{
								`log("[BOSS] Dealing GROUNDPOUND_DAMAGE to "$VisibleHumans[i]);
								VisibleHumans[i].TakeDamage(GROUNDPOUND_DAMAGE, self, Pawn.Location, 15000*Normal(VisibleHumans[i].Velocity) * vect(0,0,1), class'TADmgType');
								VisibleHumans[i].BossDamageRecdThisAttack = true;
							}
						}
					}
				}					
				break;
		}
	}

	Begin:		
		slamDamageDealt = false;	
		goto 'loop';

	Loop:			
		if (AttackStageTimer > ActiveAttackDuration)
		{	
			ResetAttackBools();
			if (AttackType == GRAB)
			{
				BossPawn.bGrabbingIdle = true;
			}
			ChangeState('Moving');
		}
		sleep(0.1);
		goto 'loop';
}

state() Dying
{

}

defaultproperties
{
	PlayerAggroValues(0)=1;
	PlayerAggroValues(1)=1;
	PlayerAggroValues(2)=1;
	PlayerAggroValues(3)=1;

	AttackCooldowns(0)=0;
	AttackCooldowns(1)=0;
	AttackCooldowns(2)=0;
	AttackCooldowns(3)=0;
	AttackCooldowns(4)=0;


	AttackRadius = 300.0000;
	AttackInterval = 4;

	NavigationHandleClass=class'NavigationHandle'
}