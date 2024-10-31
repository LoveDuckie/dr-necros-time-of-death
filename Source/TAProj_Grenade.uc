class TAProj_Grenade extends TAWeaponProjectile;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	SetTimer(2.5+FRand()*0.5,false);                  //Grenade begins unarmed
	RandSpin(100000);
}

function Init(vector Direction)
{
	
}

// Called when the grenade is armed.
simulated function Timer()
{
	Explode(Location, vect(0,0,1));
}

// What happens when it hits a brush in the game world.
simulated event HitWall(vector HitNormal, Actor Wall, PrimitiveComponent WallComp)
{
	super.HitWall(HitNormal, Wall, WallComp);
}

// Important for interact
simulated event ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal)
{
	super.ProcessTouch(Other,HitLocation,HitNormal);
}

// For when the grenade interacts with a new type of physics volume
simulated event PhysicsVolumeChange(PhysicsVolume NewVolume)
{
	super.PhysicsVolumeChange(NewVolume);
}

DefaultProperties
{
	ProjExplosionTemplate=ParticleSystem'WP_RocketLauncher.Effects.P_WP_RocketLauncher_RocketExplosion'
	ProjFlightTemplate=ParticleSystem'WP_RocketLauncher.Effects.P_WP_RocketLauncher_Smoke_Trail'
	ExplosionLightClass=class'UTGame.UTRocketExplosionLight'
	DecalWidth=128.0
	DecalHeight=128.0
	MomentumTransfer=50000
	TossZ=+245.0

	MyDamageType=class'UTDmgType_Grenade'
	LifeSpan=0.0

	speed=700
	MaxSpeed=1000.0
	Damage=100.0
	Physics=PHYS_FALLING
	bBounce=true
	CheckRadius=36.0
	bCollideWorld=true
}
