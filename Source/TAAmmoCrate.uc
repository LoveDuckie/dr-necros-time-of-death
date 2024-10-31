class TAAmmoCrate extends DynamicSMActor placeable;

var TAAmmoCrateSpawn Spawner;
var float PrimaryAmmoToAddScalar, SecondaryAmmoToAddScalar;

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

event Touch(Actor Other, PrimitiveComponent OtherComp, Object.Vector HitLocation, Object.Vector HitNormal)
{
	local int toAddAmmo;

	local TAHero hero;
	local TAHero tempHero;
	hero = TAHero(Other);

	if (hero != none)
	{
		foreach AllActors(class'TAHero', tempHero)
		{
			if(tempHero.bIsActive && tempHero.PlayerHeroType != tempHero.HeroType.Miles)
			{
				if(hero == tempHero)
				{
					toAddAmmo = TAWeapon(TempHero.Weapon).MaxAmmoCount * PrimaryAmmoToAddScalar;
					tempHero.Weapon.AddAmmo(toAddAmmo);

					if (TAWeapon(TempHero.Weapon).AmmoCount > TAWeapon(TempHero.Weapon).MaxAmmoCount)
						tempHero.Weapon.AddAmmo(TAWeapon(TempHero.Weapon).MaxAmmoCount -TAWeapon(TempHero.Weapon).AmmoCount);
				}
				else
				{
					toAddAmmo = TAWeapon(TempHero.Weapon).MaxAmmoCount * SecondaryAmmoToAddScalar;
					tempHero.Weapon.AddAmmo(toAddAmmo);

					if (TAWeapon(TempHero.Weapon).AmmoCount > TAWeapon(TempHero.Weapon).MaxAmmoCount)
						tempHero.Weapon.AddAmmo(TAWeapon(TempHero.Weapon).MaxAmmoCount - TAWeapon(TempHero.Weapon).AmmoCount);
				}
			}
		}

		WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'TAAbilities.PickupPuff', Location);

		Spawner.Crate = none;

		self.Destroy();
	}
}

DefaultProperties
{
	Begin Object Name=StaticMeshComponent0
		StaticMesh=StaticMesh'TA_ENVIRONMENT.PickupAmmo'
		Scale=2.f
		Translation=(X=32,Y=32,Z=32)
	End Object
	Components.Add(StaticMeshComponent0);

	CollisionComponent=StaticMeshComponent0
	CollisionType=COLLIDE_BlockAll

	PrimaryAmmoToAddScalar = 0.5f
	SecondaryAmmoToAddScalar = 0.25f

	bCollideActors = true
}
