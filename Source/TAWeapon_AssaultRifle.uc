class TAWeapon_AssaultRifle extends TAWeapon;

simulated function PostBeginPlay()
{
	super.PostBeginPlay();

	self.MuzzleFlashPSC.SetScale(5.0f);

}


simulated event Tick(float DeltaTime)
{
	super.Tick(DeltaTime);
}

simulated function DetachWeapon()
{
	super.DetachWeapon();
}

simulated function AttachWeaponTo(SkeletalMeshComponent MeshCpt, optional name SocketName)
{
	super.AttachWeaponTo(MeshCpt, SocketName);
}

simulated function FireAmmunition()
{
	super.FireAmmunition();

}

DefaultProperties
{
	Components.Remove(GunMesh);

	begin object class=SkeletalMeshComponent name=RifleMesh
		SkeletalMesh=SkeletalMesh'TA_WEAPONS.Assualt_Rifle'
		HiddenGame=FALSE 
		HiddenEditor=FALSE
		Scale=1.0
		AnimSets(0)=none
		bOverrideAttachmentOwnerVisibility=true
		Animations=MeshSequenceA
		CastShadow=FALSE;
		bCastDynamicShadow=FALSE;
	end object
	Mesh=RifleMesh
	Components.Add(RifleMesh);

	WeaponProjectiles(0)=class'TAProj_Bullet'


	MuzzleFlashSocket=MuzzleFlashSocket
	//MuzzleFlashPSCTemplate=ParticleSystem'VH_Manta.Effects.PS_Manta_Gun_MuzzleFlash'
	//MuzzleFlashPSCTemplate=ParticleSystem'TestPackage.Mesh.AssaultRifle_MuzzleFlash'
	WeaponFireTypes(0)=EWFT_Projectile

	/** Weapon Properties */
	bReloadable=true
	ReloadTime = 2f;


	FireInterval(0) = 0.10f
	Spread(0)=0.2f;
	MaxAmmoCount = 600; //300
	AmmoCount = 400; //200
	ClipSize = 60; //30

	respawnAmmoCount = 400; //200

	WeaponRange = 4000;
}
