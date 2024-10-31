class TAZombiePawn extends TAPawn placeable;

Enum ZOMBIE_TYPE {ZOMB_STANDARD, ZOMB_RIPPER, ZOMB_TANK};
//Enum ZOMBIE_WAVE_TYPE {INDIANS,ROMANS,AFRO,VICTORIAN,AZTEC};
var (ZombiePawn) ZOMBIE_TYPE ZombieType;

var TAZombieController ZombieController;
var SkeletalMeshComponent ZombieMesh;
var StaticMeshComponent DebugStaticMesh;

/* Sockets that the zombie apparel can click into. */
var array<name> ZombieApparelSockets;

/** Sockets that are going to be used for attaching flames onto them when
 *  they are burning to death from the flame thrower.
 *  */
var array<name> ZombieFlameSockets;

var name ZombieBloodSocket;
var UDKParticleSystemComponent BloodSplatterComponent;
var ParticleSystem BloodSplatterTemplate;

var MaterialInstanceConstant ZombieFadeMaterial;
var Material ZombieOriginalMaterial;

var CylinderCOmponent zombCollisionCylinder;

var SpriteComponent KillPointIndicator;

/** For when the flamethrower is affecting them. */
var bool bIsBurning;
var float BurnTimer;
var TAPlayerController BurnController; //who caused the fire, that went out of control, it's going to burn this city!

var bool bRising;
var float RiseTimer;

var bool bIsDisco;

/** Interval in which burn damage will be applied */
const BURN_DAMAGE_EVERY_SECS = 1.0f;

/** How much burn damage will be applied. */
const BURN_DAMAGE_AMOUNT = 7.0f;

// Stop the flaming effect after 10 seconds
var float CurrentBurnDamageTime;
const BURN_DAMAGE_TIME = 10.0f;

var config float MovementSpeed;
var Vector MoveLocation;

var TAMapSettings MapSettings;

// Confirm whether or not the zombie is dead.
var bool bIsDead;
var float DeAggrotimer;

var TASpawnPortal SpawnPortal;

var TAObjectiveManager ObjectiveManager;

/** Mesh Components for the attires */
var StaticMeshComponent HatItemMesh;
var StaticMeshComponent HandItemMesh;
var StaticMeshComponent ChestItemMesh;
var StaticMeshComponent NeckItemMesh;


var array<UDKParticleSystemComponent> Flames;


simulated event Tick(float DeltaTime)
{
	super.Tick(DeltaTime);

	
	if (bRising)
	{
		RiseTimer -= deltaTime;
		if (RiseTimer <= 0.f)
		{
			bRising = false;
			ZombieController.bCanPlay = true;
		}
	}

	BurningEffect(DeltaTime);
	DeAggrotimer -= deltatime;
	if (DeAggroTimer <= 0.f)
	{
		zombieController.DecreaseAggro();
		DeAggrotimer = 1.f;
	}
	
	if (Health <= 0)
	{
		//Destroy();
	}
}

function PutOnHat(int index)
{
	local StaticMesh hatMesh;
	local StaticMesh neckMesh;
	local StaticMesh handMesh;
	local StaticMesh chestMesh;

	if (self.ZombieType != ZOMB_STANDARD)
	{
		return;
	}

	// Nicer ways to do this, but fuck it.
	switch (index)
	{
	case 0: // ROMAN
		neckMesh = StaticMesh'TA_Hats.Meshes.RomanCape';
		hatMesh = StaticMesh'TA_Hats.Meshes.RomanHelm';         
		break;
	case 1: // AFRO
		chestMesh = StaticMesh'TA_Hats.Meshes.GuitarFlower';
		hatMesh = StaticMesh'TA_Hats.Meshes.AFRO';
		break;
	case 2: // VICTORIAN
		handMesh = StaticMesh'TA_Hats.Meshes.Cane';              // Not working.
	
		if (rand(100) < 50)
		{
			hatMesh = StaticMesh'TA_Hats.Meshes.VicWig';            
		}
		else
		{
			hatMesh = StaticMesh'TA_Hats.Meshes.TopHat';
		}
	
		break;
	case 3: // AZTEC / INDIAN
		if (rand(100) < 50)
		{
			hatMesh = StaticMesh'TA_Hats.Meshes.AZTEC';
		}
		else
		{
			hatMesh = StaticMesh'TA_Hats.Meshes.IndianHat';
		}
		break;
	case 4: // VIKING
		hatMesh = StaticMesh'TA_Hats.Meshes.VikingHelm';     
		neckMesh = StaticMesh'TA_Hats.Meshes.VikingShield';     // Not working.
		break;
	case 5: // SAXON
		hatMesh = StaticMesh'TA_Hats.Meshes.SaxonHelm';     
		handMesh = StaticMesh'TA_Hats.Meshes.SaxonArmour';     
		break;
	}

	if (hatMesh != none && rand(100) < 33)
	{
		hatMesh = none;
	}
	if (handMesh != none && rand(100) < 33)
	{
		handMesh = none;
	}
	if (chestMesh != none && rand(100) < 33)
	{
		chestMesh = none;
	}
	if (neckMesh != none && rand(100) < 33)
	{
		neckMesh = none;
	}


	self.HatItemMesh.SetHidden(hatMesh == none);
	self.HandItemMesh.SetHidden(handMesh == none);
	self.ChestItemMesh.SetHidden(chestMesh == none);
	self.NeckItemMesh.SetHidden(neckMesh == none);

	if (hatMesh != none)
	{
		self.HatItemMesh.SetStaticMesh(hatMesh);
		zombieMesh.AttachComponentToSocket(self.HatItemMesh, ZombieApparelSockets[1]);
	}
	if (handMesh != none)
	{		
		self.HandItemMesh.SetStaticMesh(handMesh);
		zombieMesh.AttachComponentToSocket(self.HandItemMesh, ZombieApparelSockets[2]);
	}
	if (chestMesh != none)
	{
		self.ChestItemMesh.SetStaticMesh(chestMesh);
		zombieMesh.AttachComponentToSocket(self.ChestItemMesh, ZombieApparelSockets[0]);
	}
	if (neckMesh != none)
	{
		self.NeckItemMesh.SetStaticMesh(neckMesh);
		zombieMesh.AttachComponentToSocket(self.NeckItemMesh, ZombieApparelSockets[3]);
	}
}

function RemoveBurningEffects()
{
	local int i;

	for (i = Flames.length -1 ; i >= 0; i--)
	{
		Flames[i].DeactivateSystem();

		Flames.removeItem(Flames[i]);
	}
}

// Set up the effects and the timer to go with it.
simulated function SetBurningEffect(bool BurningValue, Controller BController)
{
	Local UDKParticleSystemComponent newFlame;

	//

	newFlame = new () class'UDKParticleSystemComponent';
	if (newFlame != none && zombieMesh != none)
	{
		newFlame.SetTemplate(ParticleSystem'Particle_Effects.Systems.Zombie_Fire');
		newFlame.SetFOV(UDKSkeletalMeshComponent(zombieMesh).FOV);

		zombieMesh.AttachComponentToSocket(newFlame, ZombieFlameSockets[RandRange(0, ZombieFlameSockets.Length)]);

			
	newFlame.ActivateSystem();

		Flames.additem(newFlame);

		newFlame.ActivateSystem();

		BurnTimer = BURN_DAMAGE_EVERY_SECS; // Apply it instantly
		self.bIsBurning = BurningValue;
		BurnController = TAPlayerController(BController);

		CurrentBurnDamageTime = 0;
	}
		
}
/** To be ran in the Tick function */
simulated function BurningEffect(float DeltaTime)
{
	// Determine if the zombies are burning
	if (bIsBurning)
	{
		// If the interval has arrived, then apply damage and reset timer.
		if (BurnTimer > BURN_DAMAGE_EVERY_SECS)
		{
			/** route the damage through the actual take damage event, so we can cleanup normally */
			TakeDamage(BURN_DAMAGE_AMOUNT, BurnController, Location, vect(0,0,0), class'TADmgType_Fire');
			BurnTimer = 0.0f;
		}
		else
		{
			BurnTimer += DeltaTime;
		}

		CurrentBurnDamageTime += deltaTime;

		if (CurrentBurnDamageTime >= BURN_DAMAGE_TIME)
		{
			bIsBurning = false;
			CurrentBurnDamageTime = 0;

			RemoveBurningEffects();
		}
	}
	else
	{
		// Kinda pointless as zombies should never come out of burning, but you get the drift.
		BurnTimer = 0.0f;
	}
}

event Touch (Actor Other, PrimitiveComponent OtherComp, Object.Vector HitLocation, Object.Vector HitNormal)
{
	//`log("Zombie is touching "$Other);
	if (Other.class.name == 'TABarricade')
	{
		/** tell the controller to start attacking the barricade */
		ZombieController.BarricadeToAttack = TABarricade(Other);
		ZombieController.bBlockedByBarricade = true;
	}
}

function Bump(Actor other,PrimitiveComponent OtherComp, vector HitNormal)
{
	local TABarricade b;

	//reset
	if (!zombieController.bBlockedByBarricade)
	{
		zombieController.bBlockedByBarricade = false;
		foreach CollidingActors(class'TABarricade', b, 200)
		{
			zombieCOntroller.bBlockedByBarricade = true;
			zombieCOntroller.BarricadeToAttack = b;
			//TAGame(WorldInfo.Game).Broadcast(self, "EHRMAHGERD, "$self$" ERS TERCHERN "$b);
		}
	}
}

/** Timer will be activated after death to get the kill point indiactor to hide. */
simulated function HideKillPointIndicator()
{
	self.KillPointIndicator.SetHidden(true);
}

simulated event PostBeginPlay()
{
	local int randResult;
	local array<ZOMBIE_TYPE> eligibleSpawns;
	local rotator newRot;

	KillPointIndicator = new () class'SpriteComponent';
	KillPointIndicator.SetSprite(Texture2D'Sprites.score_plus_one');
	KillPointIndicator.SetHidden(true);
	
	// Attach it to the head of the zombie.
//	self.Mesh.AttachComponentToSocket(KillPointIndicator,HatSocket);

	eligibleSpawns.AddItem(ZOMB_STANDARD);

	/** set the reference to the map settings */
	MapSettings = TAMapSettings(WorldInfo.GetMapInfo());

	if (TAGame(WorldInfo.Game).bFightingBoss)
	{
		ZombieType = ZOMB_STANDARD;
		bRising = true;		
	}
	else
	{
	/** we need to randomise the chance that the zombie could be a tank or a ripper */
		randResult = int(FRand() * 100.f);

		/** roll to check if the spawn can be a tank */
		if (randResult < MapSettings.ChanceToSpawnTank)
		{
			eligibleSpawns.AddItem(ZOMB_TANK);
		}

		// generate a new random number
		randResult = int(FRand() * 100.f);

		/** roll to check if we can spawn a ripper */
		if (randResult < MapSettings.ChanceToSpawnRipper)
		{
			eligibleSpawns.AddItem(ZOMB_RIPPER);
		}

		/** Randomise a type out of all of the eligible spawns */
		ZombieType = eligibleSpawns[int(FRand() * eligibleSpawns.length)];

		SpawnPortal = Spawn(class'TASpawnPortal',,,Location);

		SpawnPortal.SetRotation(self.Rotation);

		newRot = Rotation;
		newRot.Yaw += 32768;
		SpawnPortal.SetRotation(newRot);
		SetRotation(newRot);

		//spin the zombie around so it's facing the actual direction of the spawn portal. 
		SpawnPortal.MaxScale = (ZombieType == ZOMB_TANK ? 5.f : 1.5f);
	}

	SetupMesh();
	SetPhysics(PHYS_Walking);
	/** when we spawn a zombie, assign it a controller */
	ZombieController = Spawn(class'TAZombieController');
	ZombieController.PossessPawn(self);	

	if (TAGame(WorldInfo.Game).bFightingBoss)
	{
		ZombieController.bCanplay = false;
		RiseTimer = 2.99f;
		ZombieController.ChangeState('WaNDERING');
		WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'TAAbilities.PickupPuff', Location, Rotation);
	}

	super.postbeginplay();
}

function Die()
{
	bIsDead = true;		
	zombCollisionCylinder.SetCylinderSize(1,1);	
	Health = -1;
	PlayDying(class'TADmgType', vect(0,0,0));
}

/** For when the zombie takes damage from a projectile -- Check out TAWeaponProjectile for when the collision is made. */
event TakeDamage(int DamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	local int i;
	local int milesRandom;
	local AudioComponent BluntDamageSound;

	// APply some force if Miles is hitting the zombie
	if (DamageType == class'TADmgType_Fists')
	{
		if (Health - DamageAmount <= 0)
		{
			BluntDamageSound = new class'AudioComponent';
			BluntDamageSound.SoundCue = SoundCue'Sounds.Sounds.Punch2';
			AttachComponent(BluntDamageSound);

			BluntDamageSound.Play();
		}
		else
		{
			BluntDamageSound = new class'AudioComponent';
			BluntDamageSound.SoundCue = SoundCue'Sounds.Sounds.Punch';
			AttachComponent(BluntDamageSound);
			BluntDamageSound.Play();
		}


		Momentum = Vector(TAPlayerController(EventInstigator).Pawn.Rotation) * 60000;
	}

	// If we are about to die
	if (Health - DamageAmount <= 0)
	{
		TAPlayerController(EventInstigator).SaySpeech(TAPlayerController(EventInstigator).KillSound, TAPlayerController(EventInstigator).CHANCE_FOR_KILL_SOUND);
		TAGame(WorldInfo.Game).ZombiesKilled++;

		// The boss is dead
		if (TABossZombie(self) != none)
		{
			//TAGame(WorldInfo.Game).GameOverWin = true;
			//TAGame(WorldInfo.Game).GameOver();
		}
	}
	else if (Health - DamageAmount <= HealthMax * 1.0 / 2)
	{
		if (TABossZombie(self) != none)
		{
			TAGame(WorldInfo.Game).NarratorManager.SaySpeech(TAGame(WorldInfo.Game).NarratorManager.BossInjuredSound);
		}
	}

	//only take damage if we are still alive.
	if (Health > 0)
	{
		super.TakeDamage(DamageAmount,EventInstigator,HitLocation,Momentum,DamageType,HitInfo,DamageCauser);

		zombieController.AddAggro(EventInstigator, DamageAmount);
		// Deduct the health

		if (Health <= 0)
		{
			// Only want it set once.
			
			bIsDead = true;		
			zombCollisionCylinder.SetCylinderSize(1,1);	
			
			if (TABossZombie(self) == none)
			{
				switch(self.ZombieType)
				{
					case ZOMBIE_TYPE.ZOMB_RIPPER:
						TAGame(WorldInfo.Game).GameHud.ScaleformHUD.PushtoFeed(string(TAHero(EventInstigator.Pawn).PlayerHeroType), " killed a ", "Ripper", "0x00FF00", "0xFFFFFF", "0xFF0000");
						TAGame(WorldInfo.Game).AddScore(LocalPlayer(TAPlayerController(EventInstigator).Player).ControllerId, 20);
					break;

					case ZOMBIE_TYPE.ZOMB_STANDARD:
						TAGame(WorldInfo.Game).GameHud.ScaleformHUD.PushtoFeed(string(TAHero(EventInstigator.Pawn).PlayerHeroType), " killed a ", "Zombie", "0x00FF00", "0xFFFFFF", "0xFF0000");
						TAGame(WorldInfo.Game).AddScore(LocalPlayer(TAPlayerController(EventInstigator).Player).ControllerId, 10);
					break;

					case ZOMBIE_TYPE.ZOMB_TANK:
						TAGame(WorldInfo.Game).GameHud.ScaleformHUD.PushtoFeed(string(TAHero(EventInstigator.Pawn).PlayerHeroType), " killed a ", "Tank", "0x00FF00", "0xFFFFFF", "0xFF0000");
						TAGame(WorldInfo.Game).AddScore(LocalPlayer(TAPlayerController(EventInstigator).Player).ControllerId, 20);

	//						PlayAnim();
					break;
				}
			}
			else
			{
					TABossZombie(self).Die();
					TAGame(WorldInfo.Game).GameHud.ScaleformHUD.PushtoFeed(string(TAHero(EventInstigator.Pawn).PlayerHeroType), " killed ", "FrankenZombie", "0x00FF00", "0xFFFFFF", "0xFF0000");
					TAGame(WorldInfo.Game).AddScore(LocalPlayer(TAPlayerController(EventInstigator).Player).ControllerId, 1000);

			}
	
			if (DamageType == class'TADmgType_Fists')
			{
				milesRandom = RandRange(0,3);

				if (milesRandom == 0)
				{
					WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'Particle_Effects.Systems.BamEffect', Location);
				}
				else if (milesRandom == 1)
				{
					WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'Particle_Effects.Systems.KaboomEffect', Location);
				}
				else if (milesRandom == 2)
				{
					WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'Particle_Effects.Systems.PowEffect', Location);
				}
			}
			else if (DamageType != class'TADmgType_Fire' && DamageType != class'TADmgType_HealingRay')
			{
				WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'TAAbilities.BloodSplat_Green', Location);
				for (i = 0; i < max(1, FRand() * 10); i++)
				{
					WorldInfo.MyDecalManager.SpawnDecal
					(
						MaterialInstanceTimeVarying'TAAbilities.BloodSplatter_Green',
						Location, 
						rotator(vect(0, 0, -728)), // 90o to face downwards.
						FMax(128, FRand() * 256), FMax(128, FRand() * 256),                          
						256,                               
						false,                   
						FRand() * 360,        
						none        
					);  
				}
			}
			
		}
		else
		{
			if (DamageType == class'TADmgType_Fists')
			{
				milesRandom = RandRange(0,3);

				if (milesRandom == 0)
				{
					WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'Particle_Effects.Systems.BamEffect', Location);
				}
				else if (milesRandom == 1)
				{
					WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'Particle_Effects.Systems.KaboomEffect', Location);
				}
				else if (milesRandom == 2)
				{
					WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'Particle_Effects.Systems.PowEffect', Location);
				}
			}
			else if (DamageType != class'TADmgType_Fire' && DamageType != class'TADmgType_HealingRay')
			{
				for (i = 0; i < max(1, FRand() * 5); i++)
				{
					WorldInfo.MyDecalManager.SpawnDecal
					(
						MaterialInstanceTimeVarying'TAAbilities.BloodSplatter_Green',
						Location, 
						rotator(vect(0, 0, -728)), // 90o to face downwards.
						FMax(64, FRand() * 150), FMax(64, FRand() * 150),                          
						256,                               
						false,                   
						FRand() * 360,        
						none        
					);  
				}

				WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'TAAbilities.BloodSplat_Green_Small', HitLocation);
			}

		}
	}
}

function ChangeAnim(int type)
{
	
}

// Go to this state when they are dying.
State Dying
{
	event Timer()
	{
		Destroy();	
	}

	begin:
		SetTimer(5,false);
}


function SetupMesh()
{
	switch (ZombieType)
	{
		case ZOMB_STANDARD:	
			SetFadeMaterial(Material'TA_CharacterTextures.Textures.BasicZombie');
			ZombieMesh.AnimSets[0] = AnimSet'TA_Characters.NormalZombie_Anims';
			ZombieMesh.SetAnimTreeTemplate(AnimTree'TA_Characters.NormalZombie_AnimTree');			
			ZombieMesh.SetScale(1.5f);
			CylinderComponent.SetCylinderSize(21 * 1.5f, 48 * 1.5f);
			Health = 100;
			HealthMax=100;
			ZombieController.Damage = 10;
		break;

		case ZOMB_RIPPER:
			SetFadeMaterial(Material'TA_CharacterTextures.RipperMesh_Diffuse_Mat');
			ZombieMesh.SetSkeletalMesh(SkeletalMesh'TA_Characters.Ripper');
			ZombieMesh.AnimSets[0] = AnimSet'TA_Characters.Ripper_Anims';
			ZombieMesh.SetScale(1.3f);
			ZombieMesh.SetAnimTreeTemplate(AnimTree'TA_Characters.RipperZombie_AnimTree');	
			CylinderComponent.SetCylinderSize(21 * 1.3f, 48 * 1.3f);	
			Health=50;
			HealthMax=50;
			ZombieController.Damage = 20;
		break;

		case ZOMB_TANK:		
			ZombieMesh.SetSkeletalMesh(SkeletalMesh'TA_Characters.TankZombie');
			SetFadeMaterial(Material'TA_CharacterTextures.Textures.TankZombie');
			ZombieMesh.SetScale(1.5f);
			ZombieMesh.AnimSets[0] = AnimSet'TA_Characters.TankZombie_Anims';
			ZombieMesh.SetAnimTreeTemplate(AnimTree'TA_Characters.TankZombie_AnimTree');	
			CylinderComponent.SetCylinderSize(21 * 1.3f, 48 * 1.3f);		
			Health=750;
			HealthMax=750;
			ZombieController.Damage =30;
		break;
	}	
}

function SetFadeMaterial(Material baseMaterial)
{
	if (!TAGame(WorldInfo.Game).bFightingBoss)
	{
		ZombieFadeMaterial = new (None)class'MaterialInstanceConstant';	
		ZombieFadeMaterial.SetParent(ZombieMesh.GetMaterial(0));	
		ZombieMesh.SetMaterial(0, ZombieFadeMaterial);
		ZombieFadeMaterial.SetScalarParameterValue('PortalAlpha', 0.f);
	}
}

function SetOpaqueMaterial()
{

}


simulated function PlayDying(class<DamageType> DamageType, Vector HitLoc)
{
	super.PlayDying(DamageType, HitLoc);
}

simulated function PlayDyingSound()
{
	super.PlayDyingSound();
}


defaultproperties
{
	ControllerClass=class'TeamAwesome.TAZombieController'

	Components.Remove(ZMesh);

	bCanJump = false

	bBlocksTeleport = false
	bBlockActors = true

	CollisionType=COLLIDE_BlockAll
	Begin Object Name=CollisionCylinder
		CollisionRadius=+0021.000000
		CollisionHeight=+00096.000000
	End Object

	CylinderComponent=CollisionCylinder

	bJumpCapable = false;

	/* All the sockets that things can be attached to. */
	ZombieApparelSockets(0)=ChestItem
	ZombieApparelSockets(1)=HatSocket
	ZombieApparelSockets(2)=RightBurnSocketTwo
	ZombieApparelSockets(3)=NeckBurnSocket

	//ZombieHats(AZTEC)=StaticMesh'TA_Hats.Meshes.Aztec'

	WalkingPct=+0.4
	CrouchedPct=+0.4
	BaseEyeHeight=38.0
	EyeHeight=38.0
	//GroundSpeed=250.0
	//AirSpeed=440.0
	GroundSpeed=200.0
	AirSpeed=200.0

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
	RotationRate=(Pitch=20000,Yaw=20000,Roll=20000)
	MaxLeanRoll=2048
	AirControl=+0.35
	bCanCrouch=true
	bCanClimbLadders=True
	bCanPickupInventory=True // Already enabled for inventory pickup.
	SightRadius=+24000.0
	MaxStepHeight=26.0
	MaxJumpHeight=49.0

	/** For determining where the flames are going to appear during burning. */
	ZombieFlameSockets(0)=RightBurnSocket
	ZombieFlameSockets(1)=LeftBurnSocket
	ZombieFlameSockets(2)=NeckBurnSocket
	ZombieFlameSockets(3)=LeftburnSocketTwo
	ZombieFlameSockets(4)=RightBurnSocketTwo
	ZombieFlameSockets(5)=Penis
	ZombieFlameSockets(6)=LeftFootBurn
	ZombieFlameSockets(7)=RightFootBurn

	Begin Object Class=AudioComponent name=SoundComponent
		
	End Object

	Begin Object Class=StaticMeshComponent name=SMC0
		//StaticMesh = StaticMesh'TA_Hats.Meshes.IndianHat'
		Rotation=(Roll=0, Pitch=0, Yaw=0);
		Translation=(X=0, Y=0, Z=0);
		bAcceptsDynamicDecals=FALSE
	end object
	HatItemMesh = SMC0

	Begin Object Class=StaticMeshComponent name=SMC1
		//StaticMesh = StaticMesh'TA_Hats.Meshes.IndianHat'
		Rotation=(Roll=0, Pitch=0, Yaw=0);
		Translation=(X=0, Y=0, Z=0);
		bAcceptsDynamicDecals=FALSE
	end object
	HandItemMesh = SMC1

	Begin Object Class=StaticMeshComponent name=SMC2
		//StaticMesh = StaticMesh'TA_Hats.Meshes.IndianHat'
		Rotation=(Roll=0, Pitch=0, Yaw=0);
		Translation=(X=0, Y=0, Z=0);
		bAcceptsDynamicDecals=FALSE
	end object
	ChestItemMesh = SMC2

	Begin Object Class=StaticMeshComponent name=SMC3
		//StaticMesh = StaticMesh'TA_Hats.Meshes.IndianHat'
		Rotation=(Roll=0, Pitch=0, Yaw=0);
		Translation=(X=0, Y=0, Z=0);
		bAcceptsDynamicDecals=FALSE
	end object
	NeckItemMesh = SMC3

	Begin Object Class=SkeletalMeshComponent name=SkeletalMeshComponent0
		SkeletalMesh     = SkeletalMesh'TA_Characters.NormalZombie'		
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
		Translation=(X=0,Y=0,Z=-80)
	End Object
	ZombieMesh = SkeletalMeshComponent0
	Mesh = SkeletalMeshComponent0
	Components.Add(SkeletalMeshComponent0);

	//Collisioncomponent = SkeletalMeshComponent0;

	TimeBubbleModifier = 0.5f
	AffectedByTimeBubbles = true

	FootSound = SoundCue'A_Character_Footsteps.FootSteps.A_Character_Footstep_DirtCue';

	AttackSound = SoundCue'Sounds.ATTACK.ZombieAttack';
	IdleSound = SoundCue'Sounds.Idle.ZombieIdle';
}