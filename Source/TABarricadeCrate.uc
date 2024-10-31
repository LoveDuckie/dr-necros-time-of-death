class TABarricadeCrate extends DynamicSMActor placeable;

var StaticMeshComponent Mesh;
var Material standardMaterial;
var TABarricadeCrateSpawn Spawner;

simulated event PostBeginPlay()
{
}

event Tick(float deltaTime)
{
	local rotator newRot;

	newRot = Rotation;
	newRot.Yaw += 65535 / 2.0 * deltaTime;
	SetRotation(newRot);
}

event Touch (Actor Other, PrimitiveComponent OtherComp, Object.Vector HitLocation, Object.Vector HitNormal)
{
	local TAHero hero;
	hero = TAHero(Other);

	if (hero != none && hero.turretCount == 0 && hero.barricadeCount == 0)
	{
		Spawner.Controller = TAPlayerController(hero.Controller);

		hero.barricadeCount++;
		WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'TAAbilities.PickupPuff', Location);
		self.Destroy();
	}
}

DefaultProperties
{
	Begin Object Name=StaticMeshComponent0
		StaticMesh=StaticMesh'TA_ENVIRONMENT.PickupBarricade'
		Scale=2.f
		Translation=(X=32,Y=32,Z=32)
	End Object
	Mesh = StaticMeshComponent0;
	Components.Add(StaticMeshComponent0);

	CollisionComponent=StaticMeshComponent0

	CollisionType=COLLIDE_BlockAll

	standardMaterial=Material'TA_ENVIRONMENT.PickupBarricade_MAT'

	bCollideActors = true
}
