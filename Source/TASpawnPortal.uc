class TASpawnPortal extends Actor notplaceable;

var bool bGrowing;
var bool bShrinking;
var float NewScale;
var float MaxScale;

var UDKParticleSystemComponent PortalRingEffect;
var StaticMeshComponent PortalRingBase;
var StaticMeshComponent PortalRingMesh;

const BASE_SCALE = 2.f;
const SHRINK_TIME = 0.5f;

var float CurrentShrinkTime;

var float openTime; //make sure that we can shut this regardless

simulated event PostBeginPlay()
{
	newScale = 0.f;
	bGrowing = true;
}

/** just to check that it's being spawned */
event Tick(float deltaTime)
{
	local float aNewScale;

	openTime += deltaTime;

	if (openTime > 6.f && !bShrinking)
	{
		bShrinking = true;
	}

	if (bGrowing)
	{
		CurrentShrinkTime += deltaTime;

		aNewScale = CurrentShrinkTime;
		aNewScale /= SHRINK_TIME;
		aNewScale *= BASE_SCALE;	

		SetScales(aNewScale);
		if (CurrentShrinkTime > SHRINK_TIME)
		{
			CurrentShrinkTime = 0;
			bGrowing = false;
		}
	}

	if (bShrinking)
	{
		CurrentShrinkTime += deltaTime;

		aNewScale = SHRINK_TIME - CurrentShrinkTime;
		aNewScale /= SHRINK_TIME;
		aNewScale *= BASE_SCALE;

		//aNewScale = (SRHINK_TIME - CurrentShrinkTime) / SHRINK_TIME * BASE_SCALE;

		SetScales(aNewScale);
		if (CurrentShrinkTime > SHRINK_TIME)
			Destroy();
	}
}

function SetScales(float nScale)
{
	PortalRingEffect.SetScale(nScale);
	PortalRingBase.SetScale(nScale * 0.8f);
	PortalRingMesh.SetScale(nScale);
}

defaultproperties
{
	CollisionComponent = None;

	Begin Object Class=StaticMeshComponent Name=PortalMain
		StaticMesh = StaticMesh'Particle_Effects.Meshes.TimePortal'
		Rotation = (Roll=0,Pitch=0,Yaw=16384)
		Translation=(X=80, Y=0, Z=-80);
	End Object
	Components.Add(PortalMain);
	PortalRingMesh = PortalMain;

	Begin Object Class=StaticMeshComponent Name=PortalRing
		StaticMesh = StaticMesh'Particle_Effects.Meshes.OuterRingShape';
		Translation = (X=0, Y=0, Z=-80);
	End Object
	Components.Add(PortalRing);
	PortalRingBase = PortalRing;

	Begin Object Class=UDKParticleSystemComponent Name=PortalCloud
		Template = ParticleSystem'Particle_Effects.Systems.Time_Portal';
		Translation = (X=0,Y=0,Z=-80);
	End Object
	Components.Add(PortalCloud);
	PortalRingEffect = PortalCloud;

}