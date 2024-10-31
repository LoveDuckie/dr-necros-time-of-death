class TAProj_StrongBullet extends TAWeaponProjectile;


simulated event ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal)
{
	super.ProcessTouch(Other,HitLocation,HitNormal);
}

simulated function Explode(Vector HitLocation, Vector HitNormal)
{
	super.Explode(HitLocation,HitNormal);
}

DefaultProperties
{   

	Begin Object Name=CollisionCylinder
		CollisionRadius=25
		CollisionHeight=25
    End Object

	ProjFlightTemplate=ParticleSystem'TestPackage.Effects.bullet'
	DrawScale=1.0
	//ExplosionSound=SoundCue'A_Vehicle_Manta.SoundCues.A_Vehicle_Manta_Shot'
	SpawnSound=SoundCue'A_Vehicle_Cicada.SoundCues.A_Vehicle_Cicada_MissileEject'
	Damage=20
	MomentumTransfer=50
}
