class TAProj_Bullet extends TAWeaponProjectile;


simulated event ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal)
{

	if (TAZombiePawn(Other) != none)
	{
		super.ProcessTouch(Other,HitLocation,HitNormal);
	}
}

function Init(vector Direction)
{
	Velocity = Direction * Speed;
}

simulated function Explode(Vector HitLocation, Vector HitNormal)
{
	super.Explode(HitLocation,HitNormal);
}

DefaultProperties
{   

	Begin Object Name=CollisionCylinder
		CollisionRadius=35
		CollisionHeight=25
    End Object

    
	ProjFlightTemplate=ParticleSystem'TestPackage.Effects.bullet'
	DrawScale=1.0
	//ExplosionSound=SoundCue'A_Vehicle_Manta.SoundCues.A_Vehicle_Manta_Shot'
	SpawnSound=SoundCue'A_Vehicle_Cicada.SoundCues.A_Vehicle_Cicada_MissileEject'
	Damage=15
	MomentumTransfer=50
}
