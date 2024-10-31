class TAPawn extends UDKPawn placeable;

var SkeletalMeshComponent PawnMesh;
var array<Material> MeshMaterials;

var DynamicLightEnvironmentComponent LightEnvironment;

var UDKParticleSystemComponent BloodSpurtComponent;
var ParticleSystem BloodSpurtPSCTemplate;

var int Followers;

//var int Ammo;
//var int MaxAmmo;

var bool bIsAttacking;
var bool bIsActive;
var bool bIsReloading;

// Time stuff
var float TimeModifier;
var int TimeBubbles;
var bool AffectedByTimeBubbles;
const NORMAL_TIME_MODIFIER = 1.0f;
var float TimeBubbleModifier;
var bool TargetedByBeam; // If the pawn is targeted by Sara's beam

var SoundCue FootSound;

var bool ShowingHealthBar;
const HEALTH_BAR_TIME = 0.5f;
var float CurrentHealthBarTime;

var bool EnableHealthBar;



var int AttackAudioChance;
var AudioComponent AttackAudioComponent;

var int IdleAudioMaxTime;
var int IdleAudioMinTime;
var int IdleAudioNextTime;
var float IdleAudioTime;
var AudioComponent IdleAudioComponent;

var SoundCue AttackSound;
var SoundCue IdleSound;


simulated function PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	super.PostInitAnimTree(SkelComp);
}

simulated event postBeginPlay()
{
	super.PostBeginPlay();
	MeshMaterials.AddItem(PawnMesh.GetMaterial(0).GetMaterial());
	MeshMaterials.AddItem(Material'NodeBuddies.Materials.NodeBuddy_White1');
	bIsActive = false;

	// Instantiate the component and then set the template
	//self.BloodSpurtComponent = new (Outer) class'UDKParticleSystemComponent';
	//self.BloodSpurtComponent.SetTemplate(BloodSpurtPSCTemplate);
	//self.BloodSpurtComponent.SetDepthPriorityGroup(SDPG_Foreground);
	//self.BloodSpurtComponent.SetFOV(UDKSkeletalMeshComponent(Mesh).FOV);
	//self.BloodSpurtComponent.bAutoActivate=false;
	
	// Attach it to the actor
	//self.Mesh.AttachComponentToSocket(BloodSpurtComponent,'BloodSpurtSocket');

	//InteractiveSpriteComponent.SetHidden(true);
	//InteractiveSpriteComponent.SetScale(0.25f);


	AttackAudioComponent = new class'AudioComponent';
	AttackAudioComponent.SoundCue = AttackSound;

	IdleAudioComponent = new class'AudioComponent';
	IdleAudioComponent.SoundCue = IdleSound;

	AttachComponent(AttackAudioComponent);
	AttachComponent(IdleAudioComponent);

	IdleAudioNextTime = RandRange(1, IdleAudioMaxTime);
}

function TakeFallingDamage()
{
	//do nothing.
}

event Tick(float delta)
{
	super.Tick(delta);

	if (Health > 0)
	{
		IdleAudioTime += delta;

		if (IdleAudioTime >= IdleAudioNextTime)
		{
			PlayIdleSound();
			IdleAudioTime = 0;
			IdleAudioNextTime = RandRange(IdleAudioMinTime, IdleAudioMaxTime);
		}
	}	

	if (ShowingHealthBar)
	{
		CurrentHealthBarTime += delta;
		
		if (CurrentHealthBarTime > HEALTH_BAR_TIME)
		{
			CloseHealthBar();
		}
	}


	if(Weapon != none)
	{
		bIsReloading = TAWeapon(self.Weapon).bReloading;
	}


	TimeModifier = NORMAL_TIME_MODIFIER;

	if (TimeBubbles > 0 && AffectedByTimeBubbles)
		TimeModifier *= TimeBubbleModifier * TimeBubbles;

	if (TargetedByBeam)
		TimeModifier *= TimeBubbleModifier;

	self.CustomTimeDilation = TimeModifier;
	
	if (Controller != none)
		Controller.CustomTimeDilation = TimeModifier;
}

function EnterTimeBubble(TATimeBubble bubble)
{
	TimeBubbles++;
}

function ExitTimeBubble(TATimeBubble bubble)
{
	TimeBubbles--;
}

event TakeDamage(int DamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{	
	ShowHealthBar();

	// Apply some force if we are getting hit by a tank
	if (TAZombieController(EventInstigator) != none)
	{
		// If we are miles, take less knockback from the tank
		if (TAZombiePawn(TAZombieController(EventInstigator).Pawn).ZombieType == TAZombiePawn(TAZombieController(EventInstigator).Pawn).ZOMBIE_TYPE.ZOMB_TANK)
		{
			if (TAHero(self) != none)
			{
				if (TAHero(self).PlayerHeroType == TAHero(self).HeroType.Miles)
					Momentum = Vector(TAZombieController(EventInstigator).Pawn.Rotation) * 40000;
				else
					Momentum = Vector(TAZombieController(EventInstigator).Pawn.Rotation) * 80000;
			}
			else
				Momentum = Vector(TAZombieController(EventInstigator).Pawn.Rotation) * 80000;
		}

		
	}

	if (Health - DamageAmount > 0 && EnableHealthBar)
		ShowHealthBar();
	else
		CloseHealthBar();

	super.TakeDamage(DamageAmount,EventInstigator,HitLocation,Momentum,DamageType,HitInfo,DamageCauser);
}

function PlayDyingSound()
{
	super.PlayDyingSound();
}


/** Make the pawn receive damage */
function ReceiveDamage(float dmg)
{
	PawnMesh.SetMaterial(0, MeshMaterials[1]);
	Health -= dmg;
	if (Health <= 0)
	{
		PawnMesh.SetHidden(true);
	}
	/** flash the materials so that it looks like a hit */

	/** play a sound */
	//PlaySound(SoundCue'A_Character_BodyImpacts.BodyImpacts.A_Character_RobotImpact_GibMedium_Cue');
	PawnMesh.SetMaterial(0, MeshMaterials[0]);
}

function AddDefaultInventory()
{
	//if (InvManager != none)
	//{
	//	InvManager.CreateInventory(class'TeamAwesome.TAWeapon'); //InvManager is the pawn's InventoryManager
	//}
	//else
	//{
	//	`log("InventoryManager is null :(");
	//}

	super.AddDefaultInventory();
}


simulated event PlayFootStepSound(int FootDown)
{
	//PlaySound(FootSound, false, true,,, true);
}

function Vector HatSocketLocation()
{
	local Vector loc;
	local Rotator rot;

	Mesh.GetSocketWorldLocationAndRotation('HatSocket', loc, rot);

	return loc;
}

function ShowHealthBar()
{
	CurrentHealthBarTime = 0;
	ShowingHealthBar = true;
}

function CloseHealthBar()
{
	CurrentHealthBarTime = 0;
	ShowingHealthBar = false;		
}

function PlayAttackSound()
{
	local int chance;

	if (AttackAudioComponent != none)
	{
		if (!AttackAudioComponent.IsPlaying())
		{
			chance = RandRange(1, AttackAudioChance);

			if (chance == 1)
			{
				IdleAudioComponent.Stop();
				AttackAudioComponent.Play();
			}
		}
	}
}

function PlayIdleSound()
{
	if (IdleAudioComponent != none)
	{
		if (!IdleAudioComponent.IsPlaying() && !AttackAudioComponent.IsPlaying())
		{
			IdleAudioComponent.Play();
		}
	}
}

defaultproperties
{
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bSynthesizeSHLight=TRUE
		bIsCharacterLightEnvironment=TRUE
		bUseBooleanEnvironmentShadowing=FALSE
		InvisibleUpdateTime=1
		MinTimeBetweenFullUpdates=.2
	End Object
	Components.Add(MyLightEnvironment)
	LightEnvironment=MyLightEnvironment

	Begin Object class=SkeletalMeshComponent name=ZMesh
		SkeletalMesh = SkeletalMesh'KismetGame_Assets.Anims.SK_SnakeGib'
		blockActors =false
	End Object

	BloodSpurtPSCTemplate = ParticleSystem'TestPackage.Effects.BloodHit_far';

	//ControllerClass=class'TeamAwesome.TAAIController'
	CollisionType = COLLIDE_TouchAll
	PawnMesh = ZMesh;
	COmponents.Add(ZMesh);

	Followers = 1;
	Health = 100;

	TimeBubbleModifier = 1
	AffectedByTimeBubbles = false;

	FootSound = SoundCue'A_Character_Footsteps.FootSteps.A_Character_Footstep_StoneCue';

	EnableHealthBar = true;


	AttackAudioChance = 1;
	IdleAudioMaxTime = 10;
	IdleAudioMinTime = 2;
}