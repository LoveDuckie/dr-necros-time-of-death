class TAObjectiveTrigger extends DynamicSMActor_Spawnable 
									placeable;

/** 
 *  E_Item -> For when items have to be collected. (Touch event)
 *  E_Switch -> For when the trigger has to be "interacted with". Consists of the player hitting the "X Button"
 *  and activating a lever as such.
 */

enum ETriggerType
{
	E_Switch,
	E_Item,
	E_Special
};

enum ECompletionEffectType
{
	EndOfGame
};

enum ETriggerRewardType
{
	Overshield,
	HumanHealth,
	SpeedBoost,
	EndGameCompletion
};

// Modifiable from outside of the game
var (ObjectiveTrigger) ETriggerType TriggerType;

// For storing all the assets for the different trigger types.
var array<StaticMeshComponent> pTriggerModels;

var SkeletalMeshComponent TriggerSMC;

// Do something with the trigger based on what type it is.
var (ObjectiveTrigger) ECompletionEffectType CompletionTriggerType;

var (ObjectiveTrigger) TAObjectiveTriggerVolume TriggerVolume;

// The mesh that'll appear when completed.
var (ObjectiveTrigger) StaticMesh CompletionStaticMesh;
var (ObjectiveTrigger) StaticMesh ActiveStaticMesh;
var (ObjectiveTrigger) StaticMesh FailedStaticMesh;

var (ObjectiveTrigger) ETriggerRewardType TriggerRewardType;

// Currently ready to be 
var bool bActiveObjectiveTrigger;
var bool bCompletedTask;
var string ObjectiveID;

var (ObjectiveTrigger) array<TAMainGate> MainGates;
var (ObjectiveTrigger) array<TAMainDoor> MainDoors;

var (ObjectiveTrigger) name ActivationAnimation;
var (ObjectiveTrigger) name CompletionAnimation;

/** Reference to the objectivemanager */
var (ObjectiveTrigger) TAObjectiveManager ObjectiveManager;

/** Lays out information regarding  */
var ObjectiveInformation TriggerObjectiveInformation;

/** The exclamation mark that will appear when the objective is active.*/
var (ObjectiveTrigger) StaticMeshComponent ObjectiveAlert;

var int TimesCompleted;

/** Mesh that is used for displaying the mesh */
var (ObjectiveTrigger) StaticMeshComponent TriggerMesh;

var (ObjectiveTrigger) SpriteComponent InteractiveSpriteComponent;

/** Particle effects that are displayed when the trigger is activated and completed */
var (ObjectiveTrigger) ParticleSystem ActivatedPSCTemplate;
var (ObjectiveTrigger) ParticleSystem CompletedPSCTemplate;

var (ObjectiveTrigger) UDKParticleSystemComponent ParticleComponent;

/** What the player has to do */
var (ObjectiveTrigger) string ObjectiveDescription;
var (ObjectiveTrigger) string ObjectiveName;

var (ObjectiveTrigger) float InteractiveSpriteAppearanceDistance;

var int TouchingCount;

var bool ShowingInteractButton;

event PostBeginPlay()
{
//	local Vector ObjectiveAlertLocation;

	super.PostBeginPlay();

	// Setting up the objective alert mesh that is going to be displayed on-top of objective triggers.

	
	ParticleComponent = new (self) class'UDKParticleSystemComponent';


	ObjectiveAlert.SetHidden(false);

}

simulated function ActivateObjectiveTrigger()
{
	self.TriggerMesh.SetStaticMesh(self.ActiveStaticMesh);
}

// Display the appropriate mesh for when the objective trigger has failed.
simulated function FailObjectiveTrigger()
{
	self.TriggerMesh.SetStaticMesh(self.FailedStaticMesh);
}

simulated function PlayActivationEffects()
{
	PlayActivationAnimation();
	ActivateObjectiveTrigger();
}


simulated function TriggerTouched(Actor Other, PrimitiveComponent OtherComp, Vector HitLocation, Vector HitNormal)
{
	local TAHero tempHeroObject;

	// Determine that it's the special trigger that we want to do

	if (TAHero(Other) != none)
	{
		if (self.TriggerType == E_Special)
		{
			switch(self.CompletionTriggerType)
			{
				case EndOfGame:
					ObjectiveManager.DisableTriggers();

					TAGame(WorldInfo.Game).GameOverWin = true;
					TAGame(WorldInfo.Game).GameOver();
					
					// Loop through the heros and turn off the arrow.
					foreach AllActors(class'TAHero',tempHeroObject)
					{
						tempHeroObject.HideObjectiveRing();
						tempHeroObject.TargetObjectiveTrigger = none;
					}

					self.ObjectiveManager.NotifyCompletedObjective(self.TriggerObjectiveInformation.ObjectiveID);
				
				break;
			}
		}
	}
}

simulated function PlayCompletionEffects()
{
	local TAHuman localHuman;

	switch(TriggerRewardType)
	{
		case HumanHealth:
			foreach AllActors(class'TAHuman',localHuman)
			{
				// Something to restore for now.
				localHuman.Health = localHuman.HealthMax;

				// Spawn the healing particle effect where the huamn is to display that they have been healed.
				WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'Particle_Effects.Systems.HealingGunParticleSystem',
													localHuman.Location,
													localHuman.Rotation,
													localHuman);
			}
		break;

		case Overshield:
			
			// James will have to determine what has to be done with this.

		break;

		case EndGameCompletion:
				
		break;
	}

	PlayCompletionAnimation();
}

simulated function PlayCompletionParticle()
{

}

simulated function PlayActivationParticle()
{

}

/** Played on the trigger skeletal mesh when the objective is completed */
simulated function PlayCompletionAnimation()
{

}

/** Played when the trigger has been set for activation. */
simulated function PlayActivationAnimation()
{
	
}

// Called when the player or hero interacts with the objective trigger object.
function Interact(Pawn other)
{
	local TAHero tempHeroObject;

	// Determine that it's the hero that interacted.
	if (TAHero(other) != none)
	{
		`log(self.TriggerObjectiveInformation.ObjectiveID $ " :: is the objective ID (called from objectivetrigger)");

		// Determine that it's the right trigger type and that
		// the objective is active.
		if (self.TriggerType == E_Switch && self.bActiveObjectiveTrigger)
		{
			`log(self.Name $ " :: Completed task was set to " $ bCompletedTask);

			self.bCompletedTask = bCompletedTask == false ? true : false;
			self.bActiveObjectiveTrigger = false;

			`log(self.Name $ " :: Completed task is set to " $ bCompletedTask);
			`log(self.Name $ " :: Objective ID from objinfo is " $ self.TriggerObjectiveInformation.ObjectiveID);

			self.TriggerMesh.SetStaticMesh(self.CompletionStaticMesh);

			self.ObjectiveManager.NotifyCompletedObjective(self.TriggerObjectiveInformation.ObjectiveID);
			
			TAGame(WorldInfo.Game).GameHud.ScaleformHUD.PushtoFeed(string(TAHero(other).PlayerHeroType), " completed ", ObjectiveDescription, "0x00FF00", "0xFFFFFF", "0xFFFF00");
			TAHero(other).CompleteObjectiveEffects();

			TAGame(WorldInfo.Game).AddScore(LocalPlayer(TAPlayerController(other.Controller).Player).ControllerId, 100, "Objective");
			
			PlayCompletionEffects();


			if (ObjectiveName == "cryo")
				TAGame(WorldInfo.Game).NarratorManager.SaySpeech(TAGame(WorldInfo.Game).NarratorManager.CryoObjectiveCompleteSound);


			TAGame(WorldInfo.Game).ObjectivesCompleted++;

			// Loop through the heros and turn off the arrow.
			foreach AllActors(class'TAHero',tempHeroObject)
			{
				tempHeroObject.HideObjectiveRing();
				tempHeroObject.TargetObjectiveTrigger = none;
			}
		}
	}

}

// When the trigger has been touched.
event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
{
	if (TAHero(other) != none)
	{
		if (self.TriggerType == E_Item && self.bActiveObjectiveTrigger)
		{

			self.bCompletedTask = bCompletedTask == false ? true : false;
			
			ObjectiveManager.SetObjectiveValue(self.ObjectiveID,true);

			`log (TAHero(other).PlayerHeroType $ ":: touched the switch!");

			// Ensure that the mesh that we are switching to is there.
			if (CompletionStaticMesh != none)
			{
				self.TriggerMesh.SetStaticMesh(self.CompletionStaticMesh);
			}
		}
		else if (self.TriggerType == E_Special && self.bActiveObjectiveTrigger)
		{
			
			// Ensure that the mesh that we are switching to is there.
			if (CompletionStaticMesh != none)
			{
				self.TriggerMesh.SetStaticMesh(self.CompletionStaticMesh);
			}
		}
	}
}

simulated function RotateObjectiveAlert()
{
	local Rotator ObjectiveAlertRotator;

	ObjectiveAlertRotator = ObjectiveAlert.GetRotation();
	ObjectiveAlertRotator.Yaw += 100.0f;
	ObjectiveAlert.SetRotation(ObjectiveAlertRotator);
}

/** Update how the objective alert symbol appears. */
simulated function UpdateObjectiveAlert()
{
	RotateObjectiveAlert();

	// Based on whether or not the objective is active, deactivate the trigger.
	if (self.bActiveObjectiveTrigger)
	{
		ObjectiveAlert.SetHidden(false);
	}
	else
	{
		ObjectiveAlert.SetHidden(true);
	}
}

/** Update every tick */
event Tick(float DeltaTime)
{
	local TAHero h;

	UpdateObjectiveAlert();
	
	ShowingInteractButton = false;
	// Only make the icon appear if the trigger type is a switch.
	if (self.bActiveObjectiveTrigger && self.TriggerType == E_Switch)
	{
		foreach AllActors(class'TAHero', h)
		{
			if (VSize(Location - h.Location) < InteractiveSpriteAppearanceDistance)
			{
				ShowingInteractButton = true;
				break;
			}
		}
	}	
}

DefaultProperties
{
	bCollideActors = true;
	bStatic = false;

	TimesCompleted = 0

	begin object class=CylinderComponent name=CollisionRadius
		CollisionRadius=+00128.000000
		CollisionHeight=+00128.000000
	end object
	Components.Add(CollisionRadius);
	CollisionComponent=CollisionRadius

	// Simple way of identifying the objective trigger in the editor.
	begin object class=SpriteComponent name=SpriteComponent1
		Sprite=Texture2D'Sprites.objective_trigger_icon'
		HiddenGame=true
		HiddenEditor=false
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
		Translation=(X=0,Y=0,Z=750)
	end object
	Components.Add(SpriteComponent1);

	begin object Class=StaticMeshComponent Name=StaticMeshComponent2
		StaticMesh=StaticMesh'TA_ENVIRONMENT.EXCLAMATION_MARK'
		BlockRigidBody=false
		LightEnvironment=MyLightEnvironment
		bUsePrecomputedShadows=FALSE
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		CollideActors=false
		BlockActors=false
		Scale3D=(X=1.0,Y=1.0,Z=1.0)
		HiddenEditor=false
		HiddenGame=true
	end object
	Components.Add(StaticMeshComponent2);
	ObjectiveAlert=StaticMeshComponent2

	InteractiveSpriteAppearanceDistance = 250.0f;

	bNoDelete=false

	// Default properties
	begin object Class=StaticMeshComponent Name=StaticMeshComponent1
		BlockRigidBody=false
		LightEnvironment=MyLightEnvironment
		bUsePrecomputedShadows=FALSE
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		CollideActors=false
		BlockActors=false
		Scale3D=(X=1.0,Y=1.0,Z=1.0)
	end object
	Components.Add(StaticMeshComponent1);
	StaticMeshComponent=StaticMeshComponent1
	TriggerMesh = StaticMeshComponent1
}
