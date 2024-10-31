class TAProj_Flame extends TAWeaponProjectile;



// Determine if we're affecting a zombie or not.
simulated event ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal)
{

	if (TAZombiePawn(Other) != none)
	{
		// Burrrrnnn muahahahha!
		TAZombiePawn(Other).SetBurningEffect(true, TAHero(Owner.Owner).Controller);
	}

	super.ProcessTouch(Other,HitLocation,HitNormal);
}

simulated event HitWall(Vector HitNormal, Actor Wall, PrimitiveComponent WallComp)
{
	// Overriding to stop the splat effect

	//Destroy();
}

DefaultProperties
{
	ExplosionSound=none
	ProjFlightTemplate= None;//ParticleSystem'Particle_Effects.Systems.Zombie_Fire'
	speed=5000.0
	MaxSpeed=5000.0
	Damage=2
	DamageRadius=50.0
	MomentumTransfer=0
	MyDamageType=class'TADmgType_Fire'
	LifeSpan=0.2f
	bShouldDestroy=false
}
