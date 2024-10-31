class TAAIController extends AIController;

var TAZombiePawn zombiePawn;

var string outMessage;
var name ActiveState;

var array<TAPawn> VisibleHumans;
var TAPawn HUmanTarget;
var vector MoveDirection;
var float MovementSpeed;
var float AttackDuration;
var float Damage;
var float AttackRadius;
var float Health;

var float TimeModifier; //Used for slowing down

/** wandering vars */
var PathNode TargetNode;
var bool bNeedNewNode;


/** Prototype functions for the States */
function Brains();
function Attack();
function Scan();

simulated event PostBeginPlay()
{
	GotoState('Wandering');
}

function PossessPawn(TAZombiePawn p)
{
	zombiePawn = p;
	Pawn = p;
	ChangeState('Wandering');
}

function ChangeState(name newState)
{
	`Log("STATE CHANGE: "$self$" went from "$ActiveState$" to "$newState);
	ActiveState = newState;
	GotoState(newState);
}

event Tick(float deltaTime);

state() Wandering
{
	event Tick(float deltaTime)
	{
		/** pick a random point to move to, and just wander around ambiently */
		local vector dNorm;
		local float mAngle;
		
		/** move towards the new location */
		/** only move if the target is still visible */
	
		dNorm.x = (Pawn.Location.y - TargetNode.Location.y);
		dNorm.y = (Pawn.Location.x - TargetNode.Location.x);
		dNorm = Normal(dNorm);
		mAngle = atan2(dNorm.x, dNorm.y);
		MoveDirection.X = -cos(mAngle);
		MoveDirection.Y = -sin(mAngle);

		/** reuse dNorm for location */
		dNorm = Pawn.Location;
		dNorm += MoveDirection * MovementSpeed * deltaTime * TimeModifier;
		Pawn.SetLocation(dNorm);

		/** rotate them towards the target */
		Pawn.SetRotation(rotator(MoveDirection));

		if (abs(VSize(TargetNode.Location - Pawn.Location)) < 150.f || TargetNode == none)
		{
			bNeedNewNode = true;
		}
	
	}

	/** Scans the area looking for targets */
	function Scan()
	{
		local TAPawn playerPawn;
		VisibleHumans.Remove(0, VisibleHumans.Length);

		foreach VisibleActors(class'TAPawn', playerPawn)
		{
			if (playerPawn.Health > 0)
			{
				VisibleHumans.AddItem(playerPawn);
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
		for (i = 0; i < VisibleHumans.Length; i++)
		{
			/** calculate a priority value for the humans */
			priorityValue = (VisibleHumans[i].Health * VisibleHumans[i].Followers) / abs(VSize(VisibleHumans[i].Location - Pawn.Location));
			if (priorityValue > maxValue)
			{
				maxValue = priorityValue;
				HumanTarget = VisibleHumans[i];
			}
		}

		if (HumanTarget != none)
		{
			ChangeState('Chasing');
		}
					
	}

	function CalcNode()
	{
		local PathNode node;
		local array<PathNode> nodes;
		foreach VisibleActors(class'PathNode', node, 500)
		{
			nodes.AddItem(node);
		}	

		TargetNode = nodes[RandRange(0, nodes.length)];
		bNeedNewNode = false;
	}

Begin:	
	Scan();
	Prioritise();	
	if (bNeedNewNode)
	{
		CalcNode();
	}
	Sleep(0.25);
	goto 'Begin';
}

state() Chasing
{

	event Tick(float deltaTime)
	{
		local vector dNorm;
		local float mAngle;
		
		/** move towards the new location */
		/** only move if the target is still visible */
		if (HumanTarget != None && CanSee(HumanTarget))
		{
			dNorm.x = (Pawn.Location.y - HUmanTarget.Location.y);
			dNorm.y = (Pawn.Location.x - HUmanTarget.Location.x);
			dNorm = Normal(dNorm);
			mAngle = atan2(dNorm.x, dNorm.y);
			MoveDirection.X = -cos(mAngle);
			MoveDirection.Y = -sin(mAngle);

			/** reuse dNorm for location */
			dNorm = Pawn.Location;
			dNorm += MoveDirection * MovementSpeed * deltaTime * TimeModifier;
			Pawn.SetLocation(dNorm);

			/** rotate them towards the target */
			Pawn.SetRotation(rotator(MoveDirection));

			if (abs(VSize(HumanTarget.Location - Pawn.Location)) < AttackRadius)
			{
				/** Only change to attacking if the target exists and is visible */
				if (HumanTarget != None && CanSee(HumanTarget))
				{
					/** Nom nom nom the target (switch to attacking) */
					ChangeState('Nom');
				}
			}
		}
		else
		{
			ChangeState('Wandering');
		}

		if (!CanSee(HumanTarget) || HumanTarget == none)
		{
			ChangeState('Wandering');
		}
	}
Begin:
	Sleep(5);
	Goto 'Begin';
}

/** Attacking state */
state() Nom
{
	function Brains()
	{
		//WorldInfo.Game.Broadcast(self, "B");
	}

	function Attack()
	{
		HumanTarget.ReceiveDamage(Damage);
		Pawn.Acceleration.Z = 5;
	}

	function Assess()
	{
		if (HumanTarget.Health <= 0)
		{
			ChangeState('Wandering');
		}
	}

Begin:
	Attack();
	sleep(0.1);
	Assess();
	sleep(AttackDuration);
	
	goto 'Begin';
}

defaultproperties
{
	MovementSpeed = 300.f;
	AttackDuration = 1.5f;
	Damage = 5.f;
	AttackRadius = 50.f;
	Health = 100.f;
	TimeModifier = 1.f;

}