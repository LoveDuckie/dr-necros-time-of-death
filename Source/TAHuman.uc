class TAHuman extends TAPawn;

var SkeletalMeshComponent HumanMesh;

var config float MovementSpeed;

var float NormalSpeed;
var float PanicSpeed;


/** For when the humans go to get "Destroyed" when the boss zombie comes out to play **/
var (HumanController) TAHumanEndPoint EndPointLocation;

var (HumanController) float MaxDistanceAwayFromExit;

var TAAIHumanController HumanController;

var StaticMeshComponent SelectedRing;

/** For displaying button icon on top of human head. */
var SpriteComponent InteractiveSpriteComponent;

// For exposing to DisplayAll
var TAHero Following;
var name StateName;

// Regen timing.
var float RegenTimer;
var float LastRegenTimer;
var float LastDamageTime;
const REGEN_DELAY               = 5.0f;//3.0f;
const REGEN_INCREMENT           = 1;
const REGEN_INCREMENT_INTERVAL  = 0.025f;

var bool ShowingInteractButton;

// Do something once the game is launched.
simulated event PostBeginPlay()
{
	HumanController = Spawn(class'TAAIHumanController');
	HumanController.Possess(self,false);

	SelectedRing.SetHidden(true);

	bIsActive = true;

	/** determine whether to spawn a male or female human - andrew */
	if (RandRange(0, 10) < 5)
	{
		Mesh.SetSkeletalMesh(SkeletalMesh'TA_Characters.HumanMale');
	}
	else
	{
		Mesh.SetSkeletalMesh(SkeletalMesh'TA_Characters.HumanFemale');
	}

	Mesh.SetAnimTreeTemplate(AnimTree'TA_Characters.Human_AnimTree');
	Mesh.AnimSets[0] = AnimSet'TA_Characters.Human_Anims';
	Mesh.SetScale(1.5f);

	InteractiveSpriteComponent = new (self) class'SpriteComponent';
	InteractiveSpriteComponent.SetSprite(Texture2D'Sprites.facebutton_x');
	InteractiveSpriteComponent.SetHidden(true);
	InteractiveSpriteComponent.SetScale(0.25f);
	
	self.Mesh.AttachComponentToSocket(InteractiveSpriteComponent,'Notify');
//	InteractiveComponent.bAcceptsLights = false;

	SetPhysics(PHYS_Walking);
}

simulated function SendOutOfGame()
{
	`log("Changing state of the humans");


	//// Determine whether it's really worth generating a path or not to get rid of them
	//if (VSize(self.EndPointLocation.Location - self.Location) > MaxDistanceAwayFromExit)
	//{
	//	// Clean up the controller before destroying the pawn.
	//	Controller.Destroy();
	//	Destroy();
	//}
	//else
	//{
	//	self.SelectedRing.SetHidden(true);

	//	// Change the state of the humans so that they start running towards the gate.
	//}


	//TAAIHumanController(Controller).Following = none;
	//Controller.Destroy();
	//Destroy();

	if (!TAAIHumanController(Controller).EndGameState)
	{
		TAAIHumanController(Controller).Following = none;
		TAAIHumanController(Controller).EndGameState = true;
		TAAIHumanController(Controller).GotoState('EndGame');
	}
}

event TakeDamage(int DamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{	
	local int i;

	// Ignore miles ability damage
	if (DamageType == class'TADmgType_MilesAbility')
		return;

	super.TakeDamage(DamageAmount,EventInstigator,HitLocation,Momentum,DamageType,HitInfo,DamageCauser);

	LastDamageTime = RegenTimer;

	if (Health < 0)
	{
		bIsActive = false;

		if (TAAIHumanController(Controller).Following != none)
			TAAIHumanController(Controller).UnFollow(TAAIHumanController(Controller).Following);
		
		switch(TAZombiePawn(EventInstigator.Pawn).ZombieType)
			{
				case TAZombiePawn(EventInstigator.Pawn).ZOMBIE_TYPE.ZOMB_RIPPER:
					TAGame(WorldInfo.Game).GameHud.ScaleformHUD.PushtoFeed("Ripper", " killed a", " Human", "0xFF0000", "0xFFFFFF", "0x00FF00");
					break;

				case TAZombiePawn(EventInstigator.Pawn).ZOMBIE_TYPE.ZOMB_STANDARD:
					TAGame(WorldInfo.Game).GameHud.ScaleformHUD.PushtoFeed("Zombie", " killed a", " Human", "0xFF0000", "0xFFFFFF", "0x00FF00");
					break;

				case TAZombiePawn(EventInstigator.Pawn).ZOMBIE_TYPE.ZOMB_TANK:
					TAGame(WorldInfo.Game).GameHud.ScaleformHUD.PushtoFeed("Tank", " killed a", " Human", "0xFF0000", "0xFFFFFF", "0x00FF00");
					break;
			}
	}

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
}

/** Determine whether or not to display the icon. */
simulated function SetDisplayInteraction(bool DisplayInteractionIcon)
{
	ShowingInteractButton = DisplayInteractionIcon;

	// Determine whether or not to display the interaction icon.
	//if (DisplayInteractionIcon)
	//{
		//self.InteractiveSpriteComponent.SetHidden(false);
	//}
	//else
	//{
		//self.InteractiveSpriteComponent.SetHidden(true);
	//}
}

// Do this on every tick.
event Tick(float DeltaTime)
{
	local TAHero localpawn;
	super.Tick(DeltaTime);
	

	if (HumanController != none)
		HumanController.UpdateController(DeltaTime);

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

	// If we're not following anyone then hide the ring.
	if (TAAIHumanController(Controller).Following == none)
	{
		self.SelectedRing.SetHidden(true);
	}

	// Make sure that the human is not currently dying.
	if (!self.IsInState('Dying'))
	{
		if (TAAIHumanController(Controller).Following == none)
		{

			// Loop through all visible actors.
			foreach AllActors(class'TAHero',localpawn)
			{   
				//`log("looping");

				// Determine whether or not the pawn is valid
				if (TAPlayerController(localpawn.Controller).IsActiveInGame && (abs(VSize(localpawn.Location - self.Location)) < 250.0f) && TAAIHumanController(self.Controller).Following == none)
				{
					ShowingInteractButton = true;
					break;
				}
				else
				{
					ShowingInteractButton = false;
				}
			}

		}
		else
		{
			ShowingInteractButton = false;
		}
	}
	else
	{
		ShowingInteractButton = false;
	}

}

DefaultProperties
{
	ControllerClass=class'TeamAwesome.TAAIHumanController'

	CollisionType=COLLIDE_BlockAll
	Begin Object Name=CollisionCylinder
		CollisionRadius=+0021.000000
		CollisionHeight=+00048.000000
		BlockZeroExtent=false
	End Object
	CylinderComponent=CollisionCylinder

	begin object class=StaticMeshComponent name=selectedRing
		StaticMesh=StaticMesh'TA_ENVIRONMENT.PlayerHumanRing'
		Translation=(X=0,Y=0,Z=-42)
		bAcceptsDynamicDecals=FALSE
	End Object
	Components.Add(selectedRing);
	SelectedRing = selectedRing;

	GroundSpeed = 500.0f;
	NormalSpeed = 200.0f;
	PanicSpeed  = 300.0f;

	bCanStrafe=True
	bCanSwim=true
	bStatic=False
	bMovable=True

	bCanJump = false
	bJumpCapable = false;
	bAvoidLedges=true
	bStopAtLedges = false;
	
	MaxStepHeight=26.0
	MaxJumpHeight=49.0
	WalkableFloorZ=0.78

	Components.Remove(ZMesh);

	Health = 100.0f;
	HealthMax = 100.0f;


	Begin Object class=SkeletalMeshComponent name=SkeletalMeshComponent0		
		PhysicsAsset=PhysicsAsset'TestPackage.Mesh.CharacterPhys'
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
		Translation=(X=0,Y=0,Z=-42)
	End Object

	Components.Add(SkeletalMeshComponent0);
	Mesh=SkeletalMeshComponent0

	MaxDistanceAwayFromExit = 1000.0f;
}
