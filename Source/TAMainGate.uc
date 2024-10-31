/** Script for the main door at the beginning of main world **/
class TAMainGate extends DynamicSMActor placeable;

var() StaticMesh SetMesh;

var StaticMeshComponent DoorMesh;

var Rotator newRotation;

var int rotationChange;

var bool rotate;

var int targetRotation;

var bool leftGate, closing, opening;

simulated event PostBeginPlay()
{
	newRotation = Rotation;

	SetPhysics(PHYS_Interpolating);
}

simulated event Tick(float deltatime)
{
	if(closing)
	{
		if(rotate == true)
		{
			newRotation.Yaw += rotationChange;
			self.SetRotation(newRotation);
		}
		if(Rotation.Yaw <= -16384 && !leftGate)
		{
			rotate = false;
			closing = false;
		}
		else if(Rotation.Yaw >= 16384 && leftGate)
		{
			rotate = false;
			closing = false;
		}
	}
	if(opening)
	{
		if(rotate == true)
		{
			newRotation.Yaw += rotationChange;
			self.SetRotation(newRotation);
		}
		if(Rotation.Yaw >= -3000 && !leftGate)
		{
			rotate = false;
			opening = false;
		}
		else if(Rotation.Yaw <= 3000 && leftGate)
		{
			rotate = false;
			opening = false;
		}
	}
}

function StartClose(bool Left)
{
	closing = true;
	leftGate = Left;
	if(Left)
	{
		rotationChange = 200;
		targetRotation = 16384;
	}
	else
	{
		rotationChange = -200;
	}
	rotate = true;
}

function StartOpen(bool Left)
{
	opening = true;
	leftGate = Left;
	if(Left)
	{
		rotationChange = -200;
	}
	else
	{
		rotationChange = 200;
	}
	rotate = true;
}

DefaultProperties
{
	
	bBlockActors=true;
	bCollideActors=true;

	Begin Object Class=StaticMeshComponent Name=DoorMeshComp
		StaticMesh=StaticMesh'TA_ENVIRONMENT.outside.Outer_Gate'
		RBCollideWithChannels=(Default=TRUE,BlockingVolume=TRUE,GameplayPhysics=FALSE,EffectPhysics=FALSE) 
        CollideActors=true 
        BlockActors=true 
        Scale=1.0;
        BlockZeroExtent=true 
        BlockNonzeroExtent=true 
        BlockRigidBody=true 
	End Object

	Components.Add(DoorMeshComp);
	DoorMesh = DoorMeshComp;

	CollisionComponent=DoorMeshComp

	rotate = false;
	closing = false;
	opening = false;
}
