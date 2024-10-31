class TAProj_Melee extends TAWeaponProjectile;

function Init(vector direction)
{
	super.Init(direction);
	SetHidden(true);
}

// Determine if we're affecting a zombie or not.
simulated event ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal)
{
	super.ProcessTouch(Other,HitLocation,HitNormal);
}

DefaultProperties
{

	ProjFlightTemplate= ParticleSystem'TestPackage.Effects.bullet'
	speed=1000.0
	MaxSpeed=1000.0
	Damage=30
	DamageRadius=100.0
	MomentumTransfer=0
	MyDamageType=class'TADmgType_Fists'
	LifeSpan=0.05

	ExplosionSound=None
	SpawnSound=None
}
