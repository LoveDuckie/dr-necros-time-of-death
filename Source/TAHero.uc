class TAHero extends TAPawn;

// Determine what kind of hero the player is going to be controlling.
enum HeroType
{
	Gary,
	Miles,
	Sara,
	Sarge,
	DrNecro
};

var float MouseLookAim;

var float FollowRadius;

var bool BossDamageRecdThisAttack;

var ParticleSystemComponent HealEffect;

var HeroType PlayerHeroType;
var SkeletalMeshComponent HeroMesh;
var StaticMeshComponent DebugStaticMesh; // used to just get the testing static meshes into the game for now
// For specifying anim nodes to use when firing.
var array<Name> ArmFireAnim;
var array<Name> WeaponFireAnim;

var (TeamAwesome) array<TAHuman> HumansFollowing;
var bool AbilityActive;

var class<TAWeapon> CurrentWeaponAttachmentClass;

var int barricadeCount;
var int turretCount;

var bool bCanInteractScenery;

/** Meshes to be attached to the character. **/
var TAObjectiveArrow ObjectiveAimRing;
var bool bObjectiveArrowEnabled;
var TAObjectiveTrigger TargetObjectiveTrigger;

var StaticMeshComponent PlayerAimRing;
var TATargetRing TargettedRing;
var Actor TargettedRingActor;
var Material followRingMat;

var bool bFollowMe;
var float followAnimTimer;

var bool bHasSetupMesh;
var float TimeSinceHeal;
var int LastCharacterIndex;

var float celebrateTimer;

/** Particle System Component */
var UDKParticleSystemComponent MainParticleComponent;
var ParticleSystem HealingParticleSystem_Template;

var ForceFeedbackWaveForm DamageForceFeedbackWaveForm;
var ForceFeedbackWaveForm KillForceFeedbackWaveForm;

var float RegenTimer;
var float LastRegenTimer;
var float LastDamageTime;
const REGEN_DELAY               = 5.0f;//3.0f;
const REGEN_INCREMENT           = 1;
const REGEN_INCREMENT_INTERVAL  = 0.0125f;

//var name WeaponSocket;

var bool IsBeingHealed;

var bool bIsCelebrating;

var bool bGettingUp;
var float getupTimer;

var TABossZombie bossRef;
var bool bGrabbed;
var bool bThrown;

//var UDKParticleSystemComponent newHeal;

const HUMANS_FOLLOWING_TIME = 1.0f;
var bool ShowingHumansFollowing;
var float CurrentHumansFollowingTime;

simulated function PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	super.PostInitAnimTree(SkelComp);
}

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	
	ObjectiveAimRing = Spawn(class'TAObjectiveArrow',self,'ObjectiveArrow',self.Location);

	FollowRadius = 250.0f;
	TargettedRing = Spawn(class'TATargetRing');
	TargettedRing.SetHidden(true);

	HealEffect.SetTemplate(ParticleSystem'Particle_Effects.Systems.HealingGunParticleSystem');
	HealEffect.bAutoActivate = false;
	HealEffect.DeactivateSystem();
	//HealEffect.bIsActive = true;
	//HealEffect.SetActive(true);
	//HealEffect.ActivateSystem();
}

event Landed( vector HitNormal, actor FloorActor )
{
	local rotator newRot;
	if (bThrown)
	{
		//TAGame(WorldInfo.Game).Broadcast(none, "SMACKED INTO THE FUCKING "$FloorActor$" DIDN'T I?");
		WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'TAAbilities.PickupPuff', floorActor.Location, rotator(HitNormal));
		bThrown = false;
		bGrabbed = false;
		bGettingUp = true;
		getupTimer = 1.f;
		TakeDamage(BossRef.bossController.const.THROW_DAMAGE, BossRef.bossController, Location, vect(0,0,0), class'TADmgType');

		/** RESET ROTATION ON PITCH AND ROLL */
		newRot = Rotation;
		newRot.Pitch = 0;
		newRot.Roll = 0;
		SetRotation(newRot);
	}
}

function PlayFollowAnim()
{
	bFollowMe = true;
	followAnimtimer = 1.f;
}

/* Called when the hero has to have its skeletalmesh setup */
function SetupMesh()
{
	InvManager.DiscardInventory(); //reset the weapons
	switch(PlayerHeroType)
	{
		case GARY: // Gary
			HeroMesh.SetSkeletalMesh(SkeletalMesh'TA_Characters.Gary');
			HeroMesh.SetAnimTreeTemplate(AnimTree'TA_Characters.Gary_AnimTree');
			HeroMesh.AnimSets[0] = AnimSet'TA_Characters.Gary_Anims';
			
			GroundSpeed=340.0;
			AirSpeed=340.0;

			InvManager.CreateInventory(class'TeamAwesome.TAWeapon_Flamethrower');

			PlayerAimRing.SetMaterial(0, Material'TA_ENVIRONMENT.AimMaterial_Gary');
			TargettedRing.TargetMesh.SetMaterial(0, Material'TA_ENVIRONMENT.AimMaterial_Gary');
			followRingMat = Material'TA_ENVIRONMENT.AimMaterial_Gary';
			//anims are to be completed
			break;
		case MILES: // Miles
			HeroMesh.SetSkeletalMesh(SkeletalMesh'TA_Characters.Miles');			
			HeroMesh.SetAnimTreeTemplate(AnimTree'TA_Characters.Miles_AnimTree');
			HeroMesh.AnimSets[0] = AnimSet'TA_Characters.Miles_Anims';
			HeroMesh.MorphSets[0] = MorphTargetSet'TA_Characters.Miles_MorphTargetSet';

			GroundSpeed=240.0;
			AirSpeed=240.0;		

			InvManager.CreateInventory(class'TeamAwesome.TAWeapon_MeleeFists');

			PlayerAimRing.SetMaterial(0, Material'TA_ENVIRONMENT.AimMaterial_Miles');
			TargettedRing.TargetMesh.SetMaterial(0, Material'TA_ENVIRONMENT.AimMaterial_Miles');	
			followRingMat = Material'TA_ENVIRONMENT.AimMaterial_Miles';
			break;
		case SARA: // Sara
			
			HeroMesh.SetSkeletalMesh(SkeletalMesh'TA_Characters.Sara');
			HeroMesh.SetAnimTreeTemplate(AnimTree'TA_Characters.Sara_AnimTree');
			HeroMesh.AnimSets[0] = AnimSet'TA_Characters.Sara_Anims';
			
			GroundSpeed=340.0;
			AirSpeed=340.0;

			InvManager.CreateInventory(class'TeamAwesome.TAWeapon_HealingGun');
			//InvManager.CreateInventory(class'TeamAwesome.TAWeapon_AssaultRifle');
			PlayerAimRing.SetMaterial(0, Material'TA_ENVIRONMENT.AimMaterial_Sara');
			TargettedRing.TargetMesh.SetMaterial(0, Material'TA_ENVIRONMENT.AimMaterial_Sara');
			followRingMat = Material'TA_ENVIRONMENT.AimMaterial_Sara';
			//anims to be completed 
			break;
		case SARGE: // Sarge
			Heromesh.SetSkeletalMesh(SkeletalMesh'TA_Characters.Sarge');
			HeroMesh.SetAnimTreeTemplate(AnimTree'TA_Characters.Sarge_AnimTree');
			HeroMesh.AnimSets[0] = AnimSet'TA_Characters.Sarge_Anims';
			
			GroundSpeed=240.0;
			AirSpeed=240.0;

			InvManager.CreateInventory(class'TeamAwesome.TAWeapon_AssaultRifle');
			PlayerAimRing.SetMaterial(0, Material'TA_ENVIRONMENT.AimMaterial_Sarge');
			TargettedRing.TargetMesh.SetMaterial(0, Material'TA_ENVIRONMENT.AimMaterial_Sarge');
			followRingMat = Material'TA_ENVIRONMENT.AimMaterial_Sarge';

			//anims to be completed 
			break;
	}		
	HeroMesh.SetScale(1.5f);			
}

simulated function CompleteObjectiveEffects()
{
	/*
	HealEffect.bIsActive = true;
	HealEffect.SetActive(true);
	HealEffect.ActivateSystem();*/

	//WorldInfo.MyEmitterPool.SpawnEmitter(
}

event bool HealDamage(int damage, Controller inst, class<DamageType> type)
{
	local bool success;

	success = super.HealDamage(damage, inst, type);

	if (Health > HealthMax)
		Health = HealthMax;

	if (!IsBeingHealed)
	{
		IsBeingHealed = true;

		//SetHealingEffect();
		//HealingParticleComponent.SetActive(true);
		//HealingParticleComponent.ActivateSystem();
	}
	else
	{
		//SetHealingEffect();
	}

	return success;
}

simulated function SetHealingEffect()
{
	//
	//newHeal.DeactivateSystem();

	local UDKParticleSystemComponent newHeal;

	newHeal = new () class'UDKParticleSystemComponent';
	if (newHeal != none)
	{
		newHeal.SetTemplate(ParticleSystem'Particle_Effects.Systems.HealingGunParticleSystem');
		//newHeal.SetFOV(UDKSkeletalMeshComponent(HeroMesh).FOV);

		//HeroMesh.AttachComponentToSocket(newHeal, 'HatSocket');
	}
			HealEffect.ActivateSystem();
	newHeal.ActivateSystem();
	`log("should show");
	//BurnTimer = 3.f;
	//self.bIsBurning = BurningValue;
	//BurnController = TAPlayerController(BController);
}

/** Determine where we want the arrow to point to. **/ 
simulated function EnableObjectiveArrow(Vector pLocation)
{

}

simulated function SetHealingParticle(bool h)
{
	// Determine whether or not the player is being healed and from there do something about it.
	if (h)
	{
		IsBeingHealed = h;
		self.MainParticleComponent.SetTemplate(self.HealingParticleSystem_Template);
		self.MainParticleComponent.ActivateSystem();
		self.MainParticleComponent.SetFOV(UDKSkeletalMeshComponent(Mesh).FOV);
	}
}

function TakeFallingDamage()
{
	//do nothing.
}

/** Can't do anything */
simulated function WeaponAttachmentChanged()
{
	
}

simulated function WeaponFired(Weapon InWeapon, bool bViaReplication, optional Vector HitLocation)
{
	super.WeaponFired(InWeapon,bViaReplication,HitLocation);
}

event TakeDamage(int DamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	local int i;
	local int playerScore;

	if (bIsActive)
	{
		//TAGAme(WorldInfo.Game).broadcast(none, "TAKING "$DamageAmount$" DAMAGE");
		if(DamageType != class'TADmgType_MilesAbility')
		{
			TAGame(WorldInfo.Game).GameHud.ScaleformHUD.SetCharacterState(LocalPlayer(TAPlayerController(Controller).Player).ControllerId, 1);
			TAGame(WorldInfo.Game).GameHud.ScaleformHUD.TakeDamage(LocalPlayer(TAPlayerController(Controller).Player).ControllerId);

			LastDamageTime = RegenTimer;

			if (Health - DamageAmount <= 0) //need to do this here, as super. will destroy pawn.
			{
				ShowingHumansFollowing = false;

				WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'TAAbilities.BloodSplat', Location);				
				for (i = 0; i < max(1, FRand() * 10); i++)
				{
					WorldInfo.MyDecalManager.SpawnDecal
					(
						MaterialInstanceTimeVarying'TAAbilities.BloodSplatter',
						Location, 
						rotator(vect(0, 0, -728)), // 90o to face downwards.
						FMax(128, FRand() * 256), FMax(128, FRand() * 256),                          
						256,                               
						false,                   
						FRand() * 360,        
						none        
					);  
				}

				TAGame(WorldInfo.Game).GameHud.ScaleformHUD.PushtoFeed(string(PlayerHeroType), " was killed", "", "0x00FF00", "0xFFFFFF", "0xFFFFFF");
				Health = 0;
				bIsActive = false;

				TAPlayerController(Controller).BeginForceFeedback(KillForceFeedbackWaveForm);

				playerScore = TAGame(WorldInfo.Game).Scores[LocalPlayer(TAPlayerController(Controller).Player).ControllerId];

				if (playerScore > 0)
					TAGame(WorldInfo.Game).AddScore(LocalPlayer(TAPlayerController(Controller).Player).ControllerId, - FCeil(playerScore / 2.0), "Dead");
				TargettedRing.SetHidden(true); // Hide the target ring as we are now dead and shouldn't be targeting anything

				//Have to go backwards through the array as Unfollow delets the human from it.
				for(i = HumansFollowing.Length; i >= 0; i--)
				{
					TAAIHumanController(HumansFollowing[i].Controller).UnFollow(self);
				}

				TAGame(WorldInfo.Game).NarratorManager.SaySpeech(TAGame(WorldInfo.Game).NarratorManager.HeroDeadSound);
				

				TAGame(WorldInfo.Game).Deaths++;
				TAPlayerController(Controller).ResetPawn();
				TAPlayerController(Controller).BeginRespawn();
			}
			else
			{
				super.TakeDamage(DamageAmount,EventInstigator,HitLocation,Momentum,DamageType, HitInfo, DamageCauser);

				for (i = 0; i < max(1, FRand() * 5); i++)
				{
					WorldInfo.MyDecalManager.SpawnDecal
					(
						MaterialInstanceTimeVarying'TAAbilities.BloodSplatter',
						Location, 
						rotator(vect(0, 0, -728)), // 90o to face downwards.
						FMax(64, FRand() * 150), FMax(64, FRand() * 150),                          
						256,                               
						false,                   
						FRand() * 360,        
						none        
					);  
				}
				WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'TAAbilities.BloodSplat_Small', Location);

				TAPlayerController(Controller).BeginForceFeedback(DamageForceFeedbackWaveForm);
			}	
		}
	}
    

}
event Tick(float DeltaTime)
{
	//local LocalPlayer lp;
	local TAPlayerController pc;
	local rotator newRot;
//	local TAWeapon temporaryWeapon;
	pc = TAPlayerController(Controller);

	if (followAnimtimer > 0.f)
	{
		followAnimtimer -= deltatime;
		if (followAnimtimer <= 0.f)
		{
			bFollowMe = false;
		}
	}

	if (ShowingHumansFollowing)
	{
		CurrentHumansFollowingTime += deltaTime;
	
		if (CurrentHumansFollowingTime >= HUMANS_FOLLOWING_TIME)
		{
			CurrentHumansFollowingTime = 0;
			ShowingHumansFollowing = false;
		}
	}



	if (bIsCelebrating)
	{
		celebrateTimer -= deltaTime;
		if (celebrateTimer <= 0.f)
		{
			bIsCelebrating = false;
		}
	}

	if (bGrabbed)
	{
		SetLocation(bossRef.grabPos);
		Setrotation(bossRef.grabRot);
	}
	else if (bGettingUp)
	{
		getupTimer -= deltaTime;
		if (getupTimer <= 0.f)
		{
			bGettingUp = false;
		}
		newRot = Rotation;
		newRot.Pitch = 0;
		newRot.Roll = 0;
		SetRotation(newRot);
	}
	else
	{
		if (bThrown)
		{
			/** spin */

		}
		// Regen health?
		RegenTimer += DeltaTime;
		if (RegenTimer - LastDamageTime > REGEN_DELAY)
		{
			if (RegenTimer - LastRegenTimer > REGEN_INCREMENT_INTERVAL)
			{
				HealDamage(REGEN_INCREMENT, Controller, class'TADmgType');
				if (Health > HealthMax)
					Health = HealthMax;		
				LastRegenTimer = RegenTimer;
			}
		}

		if (TimeSinceHeal < 3.f)
		{
			TimeSinceHeal += deltaTime;
		}
		else
		{
			HealEffect.DeactivateSystem();
			//TimeSinceHeal = 0;
			//IsBeingHealed = false;
		}

		super.Tick(DeltaTime);

		if (bHasSetupMesh == false || LastCharacterIndex != pc.CharacterIndex)
		{
			// Set hero type based on controller id.
			switch (pc.CharacterIndex)
			{
				case 0: PlayerHeroType = GARY; break;
				case 1: PlayerHeroType = MILES;  break;
				case 2: PlayerHeroType = SARA;  break;
				case 3: PlayerHeroType = SARGE; break;
			}

			SetupMesh();
			FollowRadius = 250.0f;

			LastCharacterIndex = pc.CharacterIndex;
			bHasSetupMesh = true;
		}

		if (bIsActive)
		{
			if (TargettedRingActor != none)
			{
				TargettedRing.SetLocation(TargettedRingActor.Location);
			}
		}
	}

	Acceleration *= 0.5f;
}

simulated function HideObjectiveRing()
{
	self.ObjectiveAimRing.SetHidden(true);
}

simulated function ShowObjectiveRing(TAObjectiveTrigger pTargetTrigger)
{
	self.ObjectiveAimRing.SetHidden(false);
	self.ObjectiveAimRing.TargetObjectiveTrigger = pTargetTrigger;
}


//returns the display friendly version of the hero type
function string HeroDisplayName()
{
	switch (PlayerHeroType)
	{
		case Miles:
			return "Miles";
			break;
		case Gary:
			return "Gary";
			break;
		case Sara:
			return "Sara";
			break;
		case Sarge:
			return "Sarge";
			break;
	}
}

//simulated event GetActorEyesViewPoint(out Vector out_Location, out Rotator out_Rotation)
//{
//	super.GetActorEyesViewPoint(out_Location,out_Rotation);
//}

/** For weapons that require locking onto other people */
simulated function Rotator GetAdjustedAimFor(Weapon W, Vector StartFireLoc)
{
	return super.GetAdjustedAimFor(W,StartFireLoc);
}


function UpdateRotation(float DeltaTime)
{

}

simulated function ProcessViewRotation( float DeltaTime, out rotator out_ViewRotation, out Rotator out_DeltaRot )
{
	super.ProcessViewRotation(DeltaTime,out_ViewRotation,out_DeltaRot);
}


simulated singular event Rotator GetBaseAimRotation()
{
   local rotator   POVRot, tempRot;

   tempRot = Rotation;
   tempRot.Pitch = 0;
   SetRotation(tempRot);
   POVRot = Rotation;
   POVRot.Pitch = MouseLookAim;

   //AimNode.AngleOffset.Y = POVRot.Pitch/16000;
   return POVRot;
}

simulated event Vector GetPawnViewLocation()
{
	return self.Location;
}

simulated event Rotator GetPawnViewRotation()
{
	return self.Rotation;
}

/** Do some animation when the player dies. */
simulated function PlayDying(class<DamageType> DamageType, Vector HitLoc)
{
	super.PlayDying(DamageType,HitLoc);

	//Mesh.FindAnimNode('').PlayAnim(false,1,1);
}

/** Play some noise when the character dies */
simulated function PlayDyingSound()
{
	super.PlayDyingSound();

}

function AddDefaultInventory()
{
	if (InvManager != none)
	{
		/** All the custom weapons */

	}
	else
	{
		`log("InventoryManager is null :(");
	}

	super.AddDefaultInventory();
}

// Set up the weapons for the given hero.
simulated function SetupWeapons()
{
	
}

DefaultProperties
{
	begin object class=AudioComponent name=HeroSounds
		//SoundCue=
	end object
	Components.Add(HeroSounds);

	bCanJump = false

	MouseLookAim = 0;

	bBlocksTeleport = false
	bBlockActors = false // required so we can spawn heros next to heros.

	bCanInteractScenery = true

	CollisionType=COLLIDE_BlockAll
	Begin Object Name=CollisionCylinder
		CollisionRadius=+0021.000000
		CollisionHeight=+00096.000000
	End Object

	CylinderComponent=CollisionCylinder
	
	bJumpCapable = false;

	bStopAtLedges = false;

	WalkingPct=+0.4
	CrouchedPct=+0.4
	BaseEyeHeight=38.0
	EyeHeight=25.0
	//GroundSpeed=440.0
	//AirSpeed=440.0
	GroundSpeed=240.0
	AirSpeed=800.0

	WaterSpeed=220.0
	AccelRate=2048.0
	
	JumpZ=550.0
	CrouchHeight=29.0
	
	CrouchRadius=21.0
	WalkableFloorZ=0.78

	Buoyancy=+000.99000000
	UnderWaterTime=+00020.000000
	bCanStrafe=True
	bCanSwim=true
	//RotationRate=(Pitch=20000,Yaw=20000,Roll=20000)
	MaxLeanRoll=2048
	AirControl=+0.35
	bCanCrouch=true
	bCanClimbLadders=True
	bCanPickupInventory=True // Already enabled for inventory pickup.
	SightRadius=+12000.0
	MaxStepHeight=26.0
	MaxJumpHeight=49.0

	Begin Object Class=StaticMeshComponent Name=SMC0
		Rotation=(Roll=0, Pitch=0, Yaw=-16384);
	End Object

	Components.Add(SMC0);
	DebugStaticMesh = SMC0;



	Begin Object Class=StaticMeshComponent Name=AimRing
		StaticMesh = StaticMesh'TA_ENVIRONMENT.PlayerAimRing'
		Rotation=(Roll=0, Pitch=0, Yaw=-16384);
		Translation=(X=0, Y=0, Z=-95);
		bAcceptsDynamicDecals=FALSE
	End Object

	Components.Add(AimRing);
	PlayerAimRing = AimRing;

	Begin Object Class=ParticleSystemComponent Name=HealingEffect
		
	End Object

	HealEffect = HealingEffect;
	COmponents.Add(HealingEffect);
	
	begin object class=AnimNodeSequence name=BlankAnim

	end object

	Begin Object Class=SkeletalMeshComponent name=SkeletalMeshComponent0
		SkeletalMesh = SkeletalMesh'TA_Characters.Sarge'
		bCacheAnimSequenceNodes=FALSE
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		bOwnerNoSee=false
		CastShadow=true
		BlockRigidBody=TRUE
		bUpdateSkelWhenNotRendered=false
		bIgnoreControllersWhenNotRendered=TRUE
		bUpdateKinematicBonesFromAnimation=true
		bCastDynamicShadow=true
		RBChannel=RBCC_Untitled3
		RBCollideWithChannels=(Untitled3=true)
		LightEnvironment=MyLightEnvironment
		bOverrideAttachmentOwnerVisibility=true
		bAcceptsDynamicDecals=FALSE
		AnimSets(0)=AnimSet'TA_Characters.Sarge_Anims'
		AnimTreeTemplate=AnimTree'TA_Characters.Sarge_AnimTree'
		Translation=(X=0,Y=0,Z=-95)
	End Object
	Mesh=SkeletalMeshComponent0
	Components.Add(SkeletalMeshComponent0);

	HeroMesh = SkeletalMeshComponent0;
	
	HealingParticleSystem_Template = ParticleSystem'Particle_Effects.Systems.HealingGunParticleSystem'

	// Get rid of the zombie mesh from the inherited class.
	Components.Remove(ZMesh);

	InventoryManagerClass=class'TeamAwesome.TAInventoryManager'

	LastCharacterIndex = -1

	Begin Object Class=ForceFeedbackWaveform Name=ForceFeedbackWaveform7
	    Samples(0)=(LeftAmplitude=80,RightAmplitude=80,LeftFunction=WF_LinearDecreasing,RightFunction=WF_LinearDecreasing,Duration=0.200)
	End Object
	DamageForceFeedbackWaveForm = ForceFeedbackWaveform7;

	Begin Object Class=ForceFeedbackWaveform Name=ForceFeedbackWaveform8
	    Samples(0)=(LeftAmplitude=100,RightAmplitude=100,LeftFunction=WF_LinearDecreasing,RightFunction=WF_LinearDecreasing,Duration=1.000)
	End Object
	KillForceFeedbackWaveForm = ForceFeedbackWaveform8;

	TimeBubbleModifier = 2

	EnableHealthBar = false;

	BossDamageRecdThisAttack = false;
}
