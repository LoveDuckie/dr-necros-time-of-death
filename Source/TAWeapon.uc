class TAWeapon extends UDKWeapon
					config(Weapon);

/** Member stuff */
var DynamicLightEnvironmentComponent LightEnvironment;

/** Sound stuff */
var AudioComponent WeaponAudioComponent;

/** Sound cues */
var array<SoundCue> FiringSounds;
var SoundCue ReloadSound;
var SoundCue WeaponPutDownSnd;

var int ClipSize; // Max amount of ammo allowed in a clip
var bool bReloadable; // Is it reloadable?
var bool bReloading; // Are we currently reloading?
var bool bRestrictAmmo; // Does ammo even play a part in this?

var float ReloadTime; // Amount of time required for reload (1.0f = 1 second)
var int AmmoUseAmount; // Amount of ammo that is used on every shot.

var name CurrentStateName; // Variable for exposing the current state that the weapon is in.

/** Allow the reload sound to play?  */
var bool bReloadSound;
var bool bFireSound;
var bool bCauseMuzzleFlash;

var bool bSemiAutomatic;

// For placing recoil animations on the weapons in the game.
var ProtectedWrite transient GameSkelCtrl_Recoil RecoilSkelControl;

/** MUZZLEFLASH MEMBERS */

/** Muzzle Flash Light */
var class<UDKExplosionLight> MuzzleFlashLightClass;
var UDKExplosionLight MuzzleFlashLight;

/** Muzzle Flash Particle System */
var UDKParticleSystemComponent MuzzleFlashPSC;
var bool bMuzzleFlashPSCLoops;

/** Normal Fire and Alt Fire Templates */
var ParticleSystem	MuzzleFlashPSCTemplate, MuzzleFlashAltPSCTemplate;
var name MuzzleFlashSocket;
var () float MuzzleFlashDuration;
var bool bMuzzleFlashAttached;

var class<TAWeapon> AttachmentClass;


/** Animations */

var(Animations) array<name>WeaponFireAnims;
var(Animations) array<name>ArmFireAnim;
var(Animations) array<name>ArmsAnimSet;

/** Idle Animations */
var(Animations) array<name>WeaponIdleAnims;
var(Animations) array<name>ArmsIdleAnims;

/** Animation to play when the weapon is Put Down */
var(Animations) name	WeaponPutDownAnim;
var(Animations) name	ArmsPutDownAnim;

/** Animation to play when the weapon is Equipped */
var(Animations) name	WeaponEquipAnim;
var(Animations) name	ArmsEquipAnim;

/** Fire force feedback waveform **/
var ForceFeedbackWaveForm FireShakeWaveform;

var int MaxAmmoCount;

var int respawnAmmoCount;


/** Counting used to determine when to reload. 
 *  
 *  How many reounds in the clip have been fired?
 *  */
var int ShotsFired;

simulated function PlayReloadSound()
{
	// Make sure that we're allowed to make a reload sound first.
	if (bReloadSound)
	{
		WeaponAudioComponent.SoundCue = ReloadSound;
		WeaponAudioComponent.Play();
	}
}

simulated function PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	super.PostInitAnimTree(SkelComp);

}


simulated function PlayFireSound()
{
	if (bFireSound)
	{
		self.PlaySound(FiringSounds[0],,,,self.Location);
	}
	
}

simulated function AttachMuzzleFlash()
{
	local SkeletalMeshcomponent SKMesh;

	bMuzzleFlashAttached = true;
	SKMesh = SkeletalMeshComponent(Mesh);

	// Make sure that the muzzle flash that we are attaching to is valid.
	if (SKMesh != none)
	{
		if ( (MuzzleFlashPSCTemplate != none) || (MuzzleFlashAltPSCTemplate != none) )
		{
			MuzzleFlashPSC = new(Outer) class'UDKParticleSystemComponent';
			MuzzleFlashPSC.bAutoActivate = false;
			MuzzleFlashPSC.SetDepthPriorityGroup(SDPG_Foreground);
			MuzzleFlashPSC.SetFOV(UDKSkeletalMeshComponent(SKMesh).FOV);
			SKMesh.AttachComponentToSocket(MuzzleFlashPSC, MuzzleFlashSocket);
		}
	}
}

/**
 * Remove/Detach the muzzle flash components
 */
simulated function DetachMuzzleFlash()
{
	local SkeletalMeshComponent SKMesh;

	bMuzzleFlashAttached = false;
	SKMesh = SkeletalMeshComponent(Mesh);
	if (  SKMesh != none )
	{
		if (MuzzleFlashPSC != none)
			SKMesh.DetachComponent( MuzzleFlashPSC );
	}
	MuzzleFlashPSC = None;
}

/** Taken from the UTWeapon class temporarily */
simulated function SetSkin(Material NewMaterial)
{
	local int i,Cnt;

	if ( NewMaterial == None )
	{
		// Clear the materials
		if ( default.Mesh.Materials.Length > 0 )
		{
			Cnt = Default.Mesh.Materials.Length;
			for (i=0;i<Cnt;i++)
			{
				Mesh.SetMaterial( i, Default.Mesh.GetMaterial(i) );
			}
		}
		else if (Mesh.Materials.Length > 0)
		{
			Cnt = Mesh.Materials.Length;
			for ( i=0; i < Cnt; i++ )
			{
				Mesh.SetMaterial(i, none);
			}
		}
	}
	else
	{
		// Set new material
		if ( default.Mesh.Materials.Length > 0 || Mesh.GetNumElements() > 0 )
		{
			Cnt = default.Mesh.Materials.Length > 0 ? default.Mesh.Materials.Length : Mesh.GetNumElements();
			for ( i=0; i < Cnt; i++ )
			{
				Mesh.SetMaterial(i, NewMaterial);
			}
		}
	}
}

/**
 * Remove/Detach the muzzle flash weapon from the skeletalmesh
 */
simulated function DetachWeaponFrom()
{
	local TAHero P;

	DetachComponent( Mesh );

	SetSkin(None);

	P = TAHero(Instigator);
	
	/** Copied from the UTWeapon class, probably unnecessary */
	if (P != None)
	{
		if (Role == ROLE_Authority && P.CurrentWeaponAttachmentClass == AttachmentClass)
		{
			P.CurrentWeaponAttachmentClass = None;
			if (Instigator.IsLocallyControlled())
			{
				P.WeaponAttachmentChanged();
			}
		}
	}

	SetBase(None);
	SetHidden(True);
	DetachMuzzleFlash();
	Mesh.SetLightEnvironment(None);
}

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	
	self.WeaponAudioComponent = new class'AudioComponent';

	if (!HasAmmo(0))
	{
		self.AddAmmo(150);
	}

	if (self.MuzzleFlashPSC != none)
	{
		self.MuzzleFlashPSC.bAutoActivate = false;
	}

	/** Tell the hud the max ammo count of the gun */
//    TAHero(Owner).MaxAmmo = AmmoCount;
}

simulated function ConsumeAmmo(byte FireModeNum)
{
	super.ConsumeAmmo(FireModeNum);

	// Ensure that we have "ammo in the clip" before firing.
	// And by ammo in the clip, I mean that we haven't exceeded the amount of shots fired
	// aka the "clip"
	if (HasClipAmmo(0) && !bReloading)
	{
		self.ShotsFired += AmmoUseAmount;
		self.AmmoCount -= AmmoUseAmount;
		//`Log("######################## ammo count: " $ AmmoUseAmount $ " = " $ self.AmmoCount);
	}

}

simulated event bool IsFiring()
{
	// Determine whether or not we're firing the gun
	//`log(self.Name $ ": currently is firing");

	return super.IsFiring();
}

simulated event Tick(float DeltaTime)
{
	// For debugging purposes.
	self.CurrentStateName = self.GetStateName();

	/** Discover whether or not the player is dead. If they are then return the weapon to active. */
	/** Luc: Gets rid of the bug where the weapon stays firing even though the player is dead. */
	if (!TAHero(Owner).bIsActive)
	{
		self.GotoState('Active');
	}
}

simulated event CauseMuzzleFlashLight()
{

}

/** Display the muzzle flash and set up a time for it to turn off again. */
simulated event CauseMuzzleFlash()
{
	local SkeletalMeshComponent SkelMesh;

	if (Owner == None || Owner.WorldInfo.NetMode == NM_DedicatedServer)
	{
		return;
	}

	// Assign the skeletalmeshcomponent to the base mesh
	SkelMesh = SkeletalMeshComponent(self.Mesh);

	// Ensure that the skeletalmesh is valid and the socket does infact exist
	if (SkelMesh != none && SkelMesh.GetSocketByName(MuzzleFlashSocket) != none)
	{
		if (MuzzleFlashPSCTemplate != none)
		{
			if (MuzzleFlashPSC == none)
			{
				MuzzleFlashPSC = new () class'UDKParticleSystemComponent';
				if (MuzzleFlashPSC != none)
				{
					MuzzleFlashPSC.SetTemplate(MuzzleFlashPSCTemplate);
					MuzzleFlashPSC.SetFOV(UDKSkeletalMeshComponent(SkelMesh).FOV);

					SkelMesh.AttachComponentToSocket(MuzzleFlashPSC, MuzzleFlashSocket);
				}
			}


				MuzzleFlashPSC.ActivateSystem();
			
		}
	}
	else
	{
		`log(self.Name $ ": SkeletalMesh or Socketname for MuzzleFlash was null");
	}

}

/** Determine whether or not the gun should continue firing. */
simulated function bool ShouldRefire()
{
	PlayFireSound();

	if (!HasClipAmmo(CurrentFireMode))
	{
		GoToState('Active');
		BeginReload();
		return false;
	}

	return StillFiring(CurrentFireMode);
}

simulated function HandleFinishedFiring()
{
	super.HandleFinishedFiring();

	if (!HasClipAmmo(0))
	{
		BeginReload();
	}

}

simulated state WeaponFiring
{
	simulated event Tick(float DeltaTime)
	{
		super.Tick(DeltaTime);

		if (Owner != none)
		{
			// Determine that it is a hero that is holding the weapon
			// and they arei n the game.
			if (TAHero(Owner) != none && !TAHero(Owner).bIsActive)
			{
				GoToState('Active');
				self.StopFire(0);
			}
		}
	}
}


simulated function int AddAmmo(int Amount)
{
	local int originalCount;
	originalCount = self.AmmoCount;

	self.AmmoCount += Amount;

	if (originalCount <= 0)
	{
		ReloadAction();
	}

	return AmmoCount;
}

/** Overriding for the sake of giving it some stupid fucking functionality. */
simulated function bool HasAmmo(byte FireModeNum, optional int Amount)
{
	//super.HasAmmo(FireModeNum,Amount);

	return self.AmmoCount > 0;
}

/** Determine if there is any ammo in the current clip */
simulated function bool HasClipAmmo(byte FireModeNum, optional int Amount)
{
	return self.ShotsFired < self.ClipSize;
}

/** Get current location of where the projectiles should be fired. */
simulated function vector GetPhysicalFireStartLoc(optional vector AimDir)
{
	Local SkeletalMeshComponent AttachedMesh;
	local vector SocketLocation;

	AttachedMesh = SkeletalMeshComponent(Mesh);
	
	AttachedMesh.GetSocketWorldLocationAndRotation(MuzzleFlashSocket,SocketLocation);
	return SocketLocation;
}

simulated event SetPosition(UDKPawn Holder)
{
    local SkeletalMeshComponent compo;
    local SkeletalMeshSocket socket;
    local Vector FinalLocation;

    compo = Holder.Mesh;
    if (compo != none)
    {
		socket = compo.GetSocketByName('WeaponPoint');
		if (socket != none)
		{
			FinalLocation = compo.GetBoneLocation(socket.BoneName);
		}
    }
    //And we probably should do something similar for the rotation :)
    SetLocation(FinalLocation);

}

/** Display some kind of muzzle flash or the like. */
simulated function PlayFireEffects( byte FireModeNum, optional vector HitLocation )
{
	super.PlayFireEffects(FireModeNum,HitLocation);


	// Make sure that we have some weapon fire animations.
	if (WeaponFireAnims.Length > 0 
		&& UDKSkeletalMeshComponent(self.Mesh).Animations != none)
	{
		// Determine what animation is being asked to be called.
		`log(self.Name $ ": " $ WeaponFireAnims[0]);
		PlayWeaponAnimation(self.WeaponFireAnims[0],GetFireInterval(FireModeNum));		
	}
	
	CauseMuzzleFlash();
}

/** Display the weapon being put away */
simulated function PlayWeaponPutDown()
{
	// Ensure that the animation has been defined.
	if (WeaponPutDownAnim != '')
		PlayWeaponAnimation(WeaponPutDownAnim,PutDownTime);
}

simulated function StopFireEffects(byte FireModeNum)
{
	super.StopFireEffects(FireModeNum);
	StopMuzzleFlash();
}

simulated event StopMuzzleFlash()
{
	ClearTimer('MuzzleFlashTimer');
	MuzzleFlashTimer();

	if ( MuzzleFlashPSC != none )
	{
		MuzzleFlashPSC.DeactivateSystem();
	}
}

simulated event MuzzleFlashTimer()
{
	if (MuzzleFlashPSC != none && (!bMuzzleFlashPSCLoops) )
	{
		MuzzleFlashPSC.DeactivateSystem();
	}
}

/* What happens during the period in which it is being equipped */
simulated function TimeWeaponEquipping()
{
	// Attach to the arm mesh.
    AttachWeaponTo(Instigator.Mesh,'WeaponPoint');
    super.TimeWeaponEquipping();
}


simulated function FireAmmunition()
{
	super.FireAmmunition();

//	TAHero(Owner).Ammo = self.AmmoCount;
}


/** Before telling the inventory that we're about to fire, check that we have ammo. */
simulated function StartFire(byte FireModeNum)
{
	/** Determine if there is any ammo in the clip before reloading */
	if (HasClipAmmo(0))
	{
		super.StartFire(FireModeNum);
		//self.ShotsFired += self.AmmoUseAmount;
	}
	else
	{
		/** Determine if we have any ammo, period. */
		if (HasAmmo(0))
		{
			//GoToState('WeaponReloading');
			BeginReload();
		}
	}
}

simulated state WeaponReloading
{
	simulated event Tick(float DeltaTime)
	{
		
	}

Begin:

}

/** RELOADING STUFF */
simulated function BeginReload()
{
	bReloading = true;
	
	if (IsInState('WeaponFiring'))
	{
		ClearTimer(nameof(RefireCheckTimer));
		TimeWeaponFiring(CurrentFireMode);

		GoToState('WeaponReloading');
	}

	// Ensure that the relaod timer is not already active.
	if (!IsTimerActive(nameof(ReloadAction)))
	{
		`log("Beginning reload timer.");

		SetTimer(ReloadTime,false,nameof(ReloadAction));
		PlayReloadSound();
	}
}

simulated function ReloadAction()
{

	if ((self.AmmoCount - self.ShotsFired) >= ClipSize)
	{
		self.ShotsFired = 0;
	}
	else
	{
		self.ShotsFired = ClipSize - self.AmmoCount;
	}

	bReloading = false;

	`log("End of reload timer.");

	// Ensure that the variable has been set properly
	if (!bReloading)
	{
		GoToState('Active');
	}
}

simulated function DetachWeapon()
{
	super.DetachWeapon();
////    SetOwner(none);
//    SetHardAttach(false);
//    SetBase(none);
////    //Socket = none;
//    SetHidden(true);
//   Destroy();

	self.Mesh.SetHidden(true);

}

simulated function BeginFire(byte FireModeNum)
{
	super.BeginFire(FireModeNum);
}

simulated state Active
{
	simulated function BeginState(name PreviousStateName)
	{
		OnAnimEnd(none, 0.f,0.f);
		super.BeginState(PreviousStateName);

	}

	simulated function BeginFire( Byte FireModeNum )
	{
		super.BeginFire(FireModeNum);
	}

	simulated event OnAnimEnd(AnimNodeSequence SeqNode, float PlayedTime, float ExcessTime)
	{
		local int IdleIndex; // For randomisation process of choosing a random idle animation.

		if (WeaponIdleAnims.Length > 0)
		{
			// Play a random idle animation for the weapon
			IdleIndex = Rand(WeaponIdleAnims.Length);
			
			PlayWeaponAnimation(WeaponIdleAnims[IdleIndex],0.0,true);
		}
	}

	simulated function PlayWeaponAnimation(Name Sequence, float fDesiredDuration, optional bool bLoop, optional SkeletalMeshComponent SkelMesh)
	{
		if (UDKSkeletalMeshComponent(self.Mesh).Animations !=  none && UDKSkeletalMeshComponent(self.Mesh).AnimSets[0] != none)
		{
			`log (self.Name $ " Playing weapon animation for " $ Sequence $ " in state based PlayWeaponAnimation");

			Global.PlayWeaponAnimation(Sequence,fDesiredDuration,bLoop,SkelMesh);

			// Just in case onanimend has been set to work.
			ClearTimer('OnAnimEnd');

			if (!bLoop)
			{
				SetTimer(fDesiredDuration,false,'OnAnimEnd');
			}
		}
	}
};

/** For running the animation for the weapon sequence. */
simulated function PlayWeaponAnimation(name Sequence, float fDesiredDuration, optional bool bLoop, optional SkeletalMeshComponent SkelMesh)
{
	local SkeletalMeshComponent SKMesh;

	SKMesh = SkeletalMeshComponent(self.Mesh);

	// Determine that the mesh is not null.
	if (SKMesh != none)
	{
		if (SKMesh.Animations != none && SKMesh.AnimSets[0] != none)
		{
			`log(self.Name $ ": attempting to play the animation now.");

			SKMesh.PlayAnim(Sequence,fDesiredDuration,bLoop);
		}
	}
	//super.PlayWeaponAnimation(Sequence,fDesiredDuration,bLoop,SkelMesh);
}

// For when we attach the weapon to the skeletal mesh component that we want.
simulated function AttachWeaponTo( SkeletalMeshComponent MeshCpnt, optional Name SocketName )
{
	self.Mesh.SetHidden(false);
	
	if (MeshCpnt != none && !MeshCpnt.IsComponentAttached(Mesh,SocketName))
	{
		MeshCpnt.AttachComponentToSocket(Mesh,SocketName);
	}
	else
	{
		`log(self.name $ "(WARNING!!!!!) TAWeapon: Unable to attach -- MeshCpnt is null");
	}
}


simulated function Projectile ProjectileFire()
{
	//return super.ProjectileFire();

	local vector		StartTrace, RealStartLoc, AimDir;
	local vector socketLoc;
	local rotator socketRot;

	local Projectile	SpawnedProjectile;

	StartTrace = Instigator.GetWeaponStartTraceLocation();
	AimDir = Vector(GetAdjustedAim( StartTrace ));

	// this is the location where the projectile is spawned.
	RealStartLoc = GetPhysicalFireStartLoc(AimDir);

	if( StartTrace != RealStartLoc )
	{

		SpawnedProjectile = Spawn(GetProjectileClass(), Self,, RealStartLoc);
		if( SpawnedProjectile != None && !SpawnedProjectile.bDeleteMe )
		{
			if (self.class.name == 'TAWeapon_AssaultRifle')
			{
				SkeletalMeshComponent(Mesh).GetSocketWorldLocationAndRotation(MuzzleFlashSocket, socketLoc, socketRot);
				SpawnedProjectile.Velocity = vector(socketRot) * SpawnedProjectile.Speed;
				SpawnedProjectile.Init( vector(socketRot) );
			}
			else
			{
				SpawnedProjectile.Init( AimDir );
			}
		}

		if (self.Owner != none)
		{
			TAPlayerController(TAHero(self.Owner).Controller).BeginForceFeedback(FireShakeWaveform);
		}
		SpawnedProjectile.SetRotation(rotator(SpawnedProjectile.Velocity));
		IncrementFlashCount();
		// Return it up the line
		return SpawnedProjectile;
	}
}


simulated function Projectile ProjectileSpecialTypeFire(class<Projectile> type)
{
	local vector		StartTrace, RealStartLoc, AimDir, socketLoc;
	local rotator 		socketRot;
	local Projectile	SpawnedProjectile;

	StartTrace = Instigator.GetWeaponStartTraceLocation();
	AimDir = Vector(GetAdjustedAim( StartTrace ));

	// this is the location where the projectile is spawned.
	RealStartLoc = GetPhysicalFireStartLoc(AimDir);

	if( StartTrace != RealStartLoc )
	{

		SpawnedProjectile = Spawn(type, Self,, RealStartLoc);
		if( SpawnedProjectile != None && !SpawnedProjectile.bDeleteMe )
		{
			SpawnedProjectile.Init( AimDir );
		}

		if (self.Owner != none)
		{
			TAPlayerController(TAHero(self.Owner).Controller).BeginForceFeedback(FireShakeWaveform);
		}

		if (self.class.name == 'TAWeapon_AssaultRifle')
		{
			SkeletalMeshComponent(Mesh).GetSocketWorldLocationAndRotation(MuzzleFlashSocket, socketLoc, socketRot);
			SpawnedProjectile.Velocity = vector(socketRot) * SpawnedProjectile.Speed;
			SpawnedProjectile.Init( vector(socketRot) );
		}
		else
		{
			SpawnedProjectile.Velocity = AimDir * SpawnedProjectile.Speed;
		}

		SpawnedProjectile.SetRotation(rotator(SpawnedProjectile.Velocity));

		// Return it up the line
		return SpawnedProjectile;
	}
}

// Going to override this later.
simulated function InstantFire()
{
	super.InstantFire();
}

simulated function bool TryPutdown()
{
	return super.TryPutDown();
}

defaultproperties
{
	/** Sounds regarding how the rifle is meant to sound */
	ReloadSound = SoundCue'Sounds.Sounds.Rifle_Reload'
	FiringSounds(0)= SoundCue'Sounds.Sounds.Rifle_Fire'

	/** Determine if we really do want a muzzle flash */
	bCauseMuzzleFlash=true

	Begin Object class=AnimNodeSequence Name=MeshSequenceA
		bCauseActorAnimEnd=true
	End Object

	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bSynthesizeSHLight=TRUE
		bIsCharacterLightEnvironment=TRUE
		bUseBooleanEnvironmentShadowing=FALSE
		InvisibleUpdateTime=1
		MinTimeBetweenFullUpdates=.2
		AmbientGlow=(R=.01,G=.01,B=.01,A=1)
		AmbientShadowColor=(R=0.15,G=0.15,B=0.15)
	End Object
	Components.Add(MyLightEnvironment)
	LightEnvironment=MyLightEnvironment

	bSemiAutomatic=false;

	Begin Object class=UDKSkeletalMeshComponent Name=GunMesh
		SkeletalMesh=SkeletalMesh'TestPackage.Mesh.LinkGun3P'
		HiddenGame=FALSE 
		HiddenEditor=FALSE
		Scale=2.0
		AnimSets(0)=AnimSet'TestPackage.Anims.AssaultRifleAnims'
		bOverrideAttachmentOwnerVisibility=true
		CastShadow=FALSE;
		bCastDynamicShadow=FALSE;
		//Animations=MeshSequenceA
	end object
	Mesh=GunMesh
	Components.Add(GunMesh)
	//PickupMesh=GunMesh

	FiringStatesArray(0)=WeaponFiring
    WeaponFireTypes(0)=EWFT_Projectile
	WeaponProjectiles(0)=class'UTProj_Grenade'	
	WeaponRange=5000

	/** Muzzle Flash Stuff. */
	MuzzleFlashSocket=MussleFlashSocket
	MuzzleFlashDuration = 0.33f;
	MuzzleFlashPSCTemplate = ParticleSystem'TestPackage.Effects.MuzzleFlash_LinkGun'
	bMuzzleFlashPSCLoops=true

	FireInterval(0) = 0.25f

	Spread(0)=0f;

	/** TAWeapon Members */
	AmmoUseAmount = 1;
	bReloadable = true;
	ClipSize = 30;
	ReloadTime = 1.0f;
	ShotsFired = 0;
	bReloadSound = true;
	bFireSound = true;

	/** TAWeapon Animations */
	WeaponIdleAnims(0)=WeaponIdle
	ArmsIdleAnims(0)=WeaponIdle

	WeaponEquipAnim=WeaponEquip

	WeaponPutDownAnim=WeaponPutDown
	ArmsPutDownAnim=WeaponPutDown

	Begin Object Class=ForceFeedbackWaveform Name=ForceFeedbackWaveform7
	    Samples(0)=(LeftAmplitude=70,RightAmplitude=70,LeftFunction=WF_LinearDecreasing,RightFunction=WF_LinearDecreasing,Duration=0.200)
	End Object
	FireShakeWaveform = ForceFeedbackWaveform7;

	respawnAmmoCount = 0;
}