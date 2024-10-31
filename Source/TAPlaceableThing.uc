class TAPlaceableThing extends TAPawn;

event TakeDamage(int DamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	Health -= DamageAmount;

	if (Health <= 0)
	{
		switch (self.class.name)
		{
			case 'TABarricade':
				TAGame(WorldInfo.Game).barricadeCount--;
				break;
			case 'TATurret':
				TATurret(self).turretCollision.Destroy();
				break;

		}
		WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'Particle_Effects.Systems.Explosion00', Location, Rotation);
		Destroy();
	}
}

defaultproperties
{
	Components.Empty //clear the component List.

}