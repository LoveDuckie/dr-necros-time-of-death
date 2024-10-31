class TAWeapon_HealingGun extends TAWeapon;

var name MuzzleFlashSocketRevolver;
var SkeletalMeshComponent RevolverSecondaryMesh;
var UDKParticleSystemComponent RevolverMuzzleFlash;

simulated function PostBeginPlay()
{
	super.PostBeginPlay();

	RevolverSecondaryMesh = new (self) class'SkeletalMeshComponent';
	RevolverSecondaryMesh.SetSkeletalMesh(SkeletalMesh'TA_WEAPONS.Revolver_Gun');

	RevolverMuzzleFlash = new (self) class'UDKParticleSystemComponent';
	RevolverMuzzleFlash.SetTemplate(MuzzleFlashAltPSCTemplate);
	RevolverMuzzleFlash.SetFOV(UDKSkeletalMeshComponent(RevolverSecondaryMesh).FOV);
	RevolverMuzzleFlash.bAutoActivate = false;
	RevolverMuzzleFlash.DeactivateSystem();

	RevolverSecondaryMesh.AttachComponentToSocket(RevolverMuzzleFlash,MuzzleFlashSocketRevolver);
}


simulated event Tick(float DeltaTime)
{
	super.Tick(DeltaTime);
}

simulated function DetachWeapon()
{
	super.DetachWeapon();

	RevolverSecondaryMesh.SetHidden(true);
}

simulated function AttachWeaponTo(SkeletalMeshComponent MeshCpt, optional name SocketName)
{
	RevolverSecondaryMesh.SetHidden(false);

	if (TAHero(Owner) != none)
		TAHero(Owner).Mesh.AttachComponentToSocket(RevolverSecondaryMesh,'WeaponPointTwo');

	super.AttachWeaponTo(MeshCpt, SocketName);
}

simulated function FireAmmunition()
{
	super.FireAmmunition();
}

/** Override from the likes of TAWeapon and do it our own way */
simulated event CauseMuzzleFlash()
{	

	super.CauseMuzzleFlash();
	`log("CurrentFiremode is " $ CurrentFireMode);

	if (CurrentFireMode == 1)
	{

		
		RevolverMuzzleFlash.ActivateSystem();
		
		if (!IsTimerActive(nameof(DisableMuzzleFlash)))
		{
			SetTimer(0.5f,false,'DisableMuzzleFlash');
		}
	}
}

// Disable the muzzle flash as a part of the timer function above.
simulated function DisableMuzzleFlash()
{
	RevolverMuzzleFlash.DeactivateSystem();
}

simulated function Vector GetPhysicalFireStartLoc(optional vector AimDir)
{
	local vector socketLocation;

	if (CurrentFireMode == 1)
		RevolverSecondaryMesh.GetSocketWorldLocationAndRotation(MuzzleFlashSocketRevolver, socketLocation);

	return socketLocation;
}

simulated function Projectile ProjectileFire()
{
	return super.ProjectileFire();
}

DefaultProperties
{
	Components.Remove(GunMesh);

	begin object class=UDKSkeletalMeshComponent name=HealingGunMesh
		SkeletalMesh=SkeletalMesh'TA_WEAPONS.Health_gun'
		//Animations=MeshSequenceA
		HiddenGame=FALSE 
		HiddenEditor=FALSE
		Scale=1.0
		bOverrideAttachmentOwnerVisibility=true
		CastShadow=FALSE;
		//bCastDynamicShadow=FALSE;
	end object
	Components.Add(HealingGunMesh);
	Mesh = HealingGunMesh
	MuzzleFlashSocket=MuzzleFlashSocket;
	MuzzleFlashSocketRevolver=MuzzleFlashSocket02;

	// Set the templates for the weaponry to be used.
	MuzzleFlashPSCTemplate = ParticleSystem'TestPackage.Effects.MuzzleFlash_LinkGun2'
	MuzzleFlashAltPSCTemplate = ParticleSystem'TestPackage.Effects.MuzzleFlash_LinkGun'

	// Revolver properties
	FireInterval(1)=0f;
	WeaponFireTypes(1)=EWFT_Projectile
	FiringStatesArray(1)=WeaponFiring
	WeaponProjectiles(1)=class'TAProj_StrongBullet'
	WeaponRange=500
	ClipSize = 16;//12
	AmmoCount = 96;//64
	MaxAmmoCount = 128;//;96;

	respawnAmmoCount = 96;//;64;

	bReloadable=true
	ReloadTime = 2f;

	ReloadSound = SoundCue'Sounds.Sounds.Rifle_Reload'
	FiringSounds(0)= SoundCue'Sounds.Pistol_Fire'
	FiringSounds(1)= SoundCue'Sounds.Pistol_Fire'
}



