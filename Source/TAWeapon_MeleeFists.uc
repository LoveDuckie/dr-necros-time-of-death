class TAWeapon_MeleeFists extends TAWeapon;

simulated event Tick(float DeltaTime)
{
	super.Tick(DeltaTime);
}

simulated function PostBeginPlay()
{
	super.PostBeginPlay();	
}

/** What to do when the weapon is announced to pick up. */
simulated function AttachWeaponTo(SkeletalMeshComponent MeshCpnt, optional name SocketName)
{
	super.AttachWeaponTo(MeshCpnt,SocketName);
}

simulated function DetachWeapon()
{
	super.DetachWeapon();
}

simulated function FireAmmunition()
{
	`log("Fists");
	//super.FireAmmunition();
}

simulated event HitWall(vector HitNormal, actor Wall, PrimitiveComponent WallComp)
{

}

DefaultProperties
{
	Components.Remove(GunMesh);

	FiringSounds.Empty

	begin object class=UDKSkeletalMeshComponent name=Wrench
		SkeletalMesh=SkeletalMesh'TA_WEAPONS.Assualt_Rifle'
		HiddenGame=false
		HiddenEditor=false
		Scale=0.1
		AnimSets(0)=AnimSet'TestPackage.Anims.AssaultRifleAnims'
		bOverrideAttachmentOwnerVisibility=true
		CastShadow=FALSE;
		bCastDynamicShadow=FALSE;
	end object 
	Mesh=Wrench
	Components.Add(Wrench);

	FiringStatesArray(0)=WeaponFiring
	WeaponProjectiles(0)=class'TAProj_Melee'

	MuzzleFlashSocket=MuzzleFlashSocket;

	//MuzzleFlashPSCTemplate = ParticleSystem'TestPackage.FX.Flamethrower_Particle'

	/** TAWeapon Members */
	
	
	ShotsFired = 0;
	bReloadSound = false;
	bFireSound = false;

	/** TAWeapon Animations */
	WeaponIdleAnims(0)=WeaponIdle
	ArmsIdleAnims(0)=WeaponIdle

	FireInterval(0) = 0.0f

	/** Limit the range of the flame thrower and make sure that it hits instantly. */
	WeaponFireTypes(0)=EWFT_Projectile
	WeaponRange=30

	WeaponEquipAnim=WeaponEquip

	WeaponPutDownAnim=WeaponPutDown
	ArmsPutDownAnim=WeaponPutDown

	AmmoCount = 400
	respawnAmmoCount = 400;
}
