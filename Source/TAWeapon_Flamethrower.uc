class TAWeapon_Flamethrower extends TAWeapon;


simulated function PostBeginPlay()
{
	super.PostBeginPlay();

}

simulated event Tick(float DeltaTime)
{
	super.Tick(DeltaTime);

}

/** What to do when the weapon is announced to pick up. */
simulated function AttachWeaponTo(SkeletalMeshComponent MeshCpnt, optional name SocketName)
{
	super.AttachWeaponTo(MeshCpnt,SocketName);
}

simulated function FireAmmunition()
{
	super.FireAmmunition();
}




simulated event CauseMuzzleFlash()
{	
	super.CauseMuzzleFlash();

	TAPlayerController(TAHero(Owner).Controller).PlayingFlamethrowerSound = true;
}


simulated function HandleFinishedFiring()
{
	super.HandleFinishedFiring();

	TAPlayerController(TAHero(Owner).Controller).PlayingFlamethrowerSound = false;
}





DefaultProperties
{
	Components.Remove(GunMesh);

	begin object class=UDKSkeletalMeshComponent name=Flamethrower
		SkeletalMesh=SkeletalMesh'TA_WEAPONS.Flame_Trower'
		HiddenGame=false
		HiddenEditor=false
		Scale=1.5
		AnimSets(0)=AnimSet'TestPackage.Anims.AssaultRifleAnims'
		bOverrideAttachmentOwnerVisibility=true
		CastShadow=FALSE;
		bCastDynamicShadow=FALSE;
	end object 
	Mesh=Flamethrower
	Components.Add(Flamethrower);

	FiringStatesArray(0)=WeaponFiring
	WeaponProjectiles(0)=class'TAProj_Flame'

	MuzzleFlashSocket=MuzzleFlashSocket;

	MuzzleFlashPSCTemplate = ParticleSystem'TestPackage.FX.Flamethrower_Particle'

	/** TAWeapon Members */
	
	ReloadTime = 2.0f;
	ShotsFired = 0;
	bReloadSound = true;
	bFireSound = false;

	/** TAWeapon Animations */
	WeaponIdleAnims(0)=WeaponIdle
	ArmsIdleAnims(0)=WeaponIdle

	FireInterval(0) = 0.15f

	/** Limit the range of the flame thrower and make sure that it hits instantly. */
	WeaponFireTypes(0)=EWFT_Projectile
	WeaponRange=2500

	WeaponEquipAnim=WeaponEquip

	WeaponPutDownAnim=WeaponPutDown
	ArmsPutDownAnim=WeaponPutDown
	MaxAmmoCount = 500;//400
	AmmoCount = 400;//300
	ClipSize = 100;//200;

	respawnAmmoCount = 400;//300;
}
