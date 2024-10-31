// ---------------------------------------------------------------------------------------------
//  Spawns a time bubble in which zombies are slowed down.
// ---------------------------------------------------------------------------------------------
class TATimeBubble extends Actor notplaceable;

const MAX_SCALE             = 1.5f;
const MIN_SCALE             = 0.1f;
const GROW_SCALAR           = 1.07f;
const SHRINK_SCALAR         = 0.7f;
const DELAY_BEFORE_SHRINK   = 6.0f;

var StaticMeshComponent BubbleMesh;
var bool  bInitialGrow;
var bool  bFinalShrink;

var ParticleSystemComponent BubbleParticleSystem;

simulated event PostBeginPlay()
{	
	bInitialGrow = true;
	bFinalShrink = false;
	BubbleMesh.SetScale(0.1f);

	BubbleParticleSystem.SetTemplate(ParticleSystem'Particle_Effects.Systems.SlowSphere');
	BubbleParticleSystem.SetScale(6.5f);
	BubbleParticleSystem.ActivateSystem();

	BubbleMesh.SetHidden(true);
}

event Tick(float deltaTime)
{
	
	if (bInitialGrow == true)
	{
		BubbleMesh.SetScale(fmin(MAX_SCALE, BubbleMesh.Scale * GROW_SCALAR));
		if (BubbleMesh.Scale >= MAX_SCALE)
		{
			bInitialGrow = false;
			SetTimer(DELAY_BEFORE_SHRINK);
		}
	}

	if (bFinalShrink == true)
	{
		BubbleMesh.SetScale(fmax(MIN_SCALE, BubbleMesh.Scale * SHRINK_SCALAR));
		if (BubbleMesh.Scale <= MIN_SCALE)
		{
			Destroy();
		}
	}
	
}

function Timer()
{
	bFinalShrink = true;
}

event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
{
	if (TAPawn(Other) != none)
	{
		TAPawn(Other).EnterTimeBubble(self);
	}
}

event UnTouch(Actor Other)
{
	if (TAPawn(Other) != none)
	{
		TAPawn(Other).ExitTimeBubble(self);
	}
}

defaultproperties
{
	Begin Object Class=StaticMeshComponent Name=PMesh
		StaticMesh = StaticMesh'TAAbilities.timebubble';
		Scale = 1.0;
		Rotation=(Roll=0, Pitch=0, Yaw=0)
	End Object

	Begin Object CLass=ParticleSystemComponent Name=BubbleParticleComponent

	End Object
	BubbleParticleSystem = BubbleParticleComponent;
	Components.Add(BubbleParticleComponent);
	Components.Add(PMesh);
	BubbleMesh = PMesh;

	bCollideActors = true    
    bBlockActors   = false

	CollisionComponent = PMesh;
//	CollisionType = Collision_NOCollision;
}