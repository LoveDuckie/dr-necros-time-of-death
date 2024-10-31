class TAWeaponProjectile extends UTProjectile;

var bool bShouldDestroy;

// Do something to explode.
simulated function Explode(Vector HitLocation, Vector HitNormal)
{
	super.Explode(HitLocation,HitNormal);
}

simulated function ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal)
{
	local int healthBefore;

	// Make sure that we're attacking a zombie now!
	if (TAZombiePawn(Other) != none)
	{
			if ( Other != Instigator )
			{
				// Determine if the worldinfo is being changed when a new player joins
				if (WorldInfo.MyDecalManager == None)
				{
					`log(self.Name $ ":: WorldInfo no long exists!");
				}

				// ----------------------------------------------------------------------------------
				// Tim: This needs to be done in dervied class, most will not have the same decal!
				// ----------------------------------------------------------------------------------
				/*WorldInfo.MyDecalManager.SpawnDecal
				(
					MaterialInstanceTimeVarying'WP_FlakCannon.Decals.MITV_WP_FlakCannon_Impact_Decal01',
					HitLocation,
					rotator(-HitNormal),
					128, 128,                          
					256,                               
					false,                   
					FRand() * 360,        
					none        
				); */
			}

		healthBefore = TAPawn(Other).Health;

		Other.TakeDamage( Damage, InstigatorController, Location, MomentumTransfer * 
		Normal(Velocity), MyDamageType,, self);

		if (TAProj_Flame(self) == none)
			if (healthBefore > 0 && bShouldDestroy)
				Destroy();
	}
}

simulated event HitWall(vector HitNormal, actor Wall, PrimitiveComponent WallComp)
{	
	// ----------------------------------------------------------------------------------
	// Tim: This needs to be done in dervied class, most will not have the same decal!
	// ----------------------------------------------------------------------------------
	WorldInfo.MyDecalManager.SpawnDecal
	(
		MaterialInstanceTimeVarying'WP_FlakCannon.Decals.MITV_WP_FlakCannon_Impact_Decal01',
		Location, 
		rotator(-HitNormal),
		FMax(32, FRand() * 64), FMax(32, FRand() * 64),                          
		256,                               
		false,                   
		FRand() * 360,        
		none        
	);  
	Destroy();
}

DefaultProperties
{
	Begin Object Name=CollisionCylinder
		CollisionRadius=25
		CollisionHeight=25
    End Object

	Begin Object class=AudioComponent name=ProjSound
		bAutoplay=false;
	End Object
	Components.Add(ProjSound);
    
	MyDamageType=class'TADmgType_Bullet'

	bShouldDestroy = true;

	ProjFlightTemplate=ParticleSystem'TestPackage.Effects.GreenBeam'
	DrawScale=2.8
	//ExplosionSound=SoundCue'A_Vehicle_Manta.SoundCues.A_Vehicle_Manta_Shot'
	SpawnSound=SoundCue'A_Vehicle_Cicada.SoundCues.A_Vehicle_Cicada_MissileEject'
	Damage=25
	MomentumTransfer=50
}
