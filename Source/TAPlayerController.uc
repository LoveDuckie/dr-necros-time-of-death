class TAPlayerController extends PlayerController;

var bool moveCamF;
var bool moveCamB;
var bool moveCamL;
var bool moveCamR;

var float leftX;
var float leftY;
var float rightX;
var float rightY;

var float FollowRadius;
var float PawnHideTimer;
var bool IsActiveInGame;
var bool IsPlayerInGame;
var TAMapSettings MapSettings;

var float MilesSpinCooldown;

var Actor TraceActor, PrevTraceActor;
var Vector StartTrace, EndTrace;
var vector hitWorld, hitNormal;

var TABarricade barricade;
var bool carrying;
var vector barricadeOffset;
var TATurret turret;
var vector turretOffset;
var bool hasTurretLocators;

var bool IsSelectingCharacter;
var int  CharacterIndex;

var bool bDespawnTimerSet;
const DESPAWN_DELAY = 60.0f;

var bool bStopAttackingTimerSet;

// Time tracking nick nacks.
var float CurrentAbilityTime;
var float AbilityCooldown; // Time at which we can use abilities after.

// Respawning timers.
const RESPAWN_DELAY     = 15.0;
var bool  WaitingForRespawn;
var float RespawnTotalTime;
var float RespawnTimer;

// Sara's beam stuff
var ParticleSystem SaraBeamRed;
var ParticleSystem SaraBeamGreen;
var ParticleSystem SaraBeamNeutral;
var UDKParticleSystemComponent SaraBeam;
var AudioComponent SaraBeamSound;

var AudioComponent SargeAbilitySound;

var float SaraLastHealPointsTime;
var float SaraHealPointsTimer;
const SARA_HEAL_POINTS_INTERVAL = 0.5f;
const SARA_HEAL_POINTS = 20.0f;

// Miles' boomy stuff
var UDKParticleSystemComponent MilesBoom;
var AudioComponent MilesSwingPunchSound;

var bool PlayingFlamethrowerSound;
var float CurrentFlamethrowerSoundTime;
const FLAMETHROWER_SOUND_TIME = 0.2f;


// Ability constants.
const SARGE_TELEPORT_DISTANCE            = 500.0f;
const SARGE_TELEPORT_HIT_DISTANCE_BUFFER = 50.0f;
//const SARGE_ABILITY_RANGE = 200.0f;
const SARGE_ABILITY_DAMAGE = 40.0f;
const SARGE_ABILITY_MOMENTUM = 100000.0f;

const SARGE_ABILITY_COOLDOWN = 4.0f; // Seconds
const SARA_ABILITY_COOLDOWN = 3.0f; // Seconds
const GARY_ABILITY_COOLDOWN  = 10.0f; // Seconds
const MILES_ABILITY_COOLDOWN = 4.0f; // Seconds

const MILES_PUNCH_RANGE = 150.0f;
const MILES_PUNCH_DAMAGE = 30.0f;
const MILES_ABILITY_RANGE = 250.0f;
const MILES_ABILITY_DAMAGE = 40.0f;
const MILES_ABILITY_MOMENTUM = 150000.0f;

const SARA_ABILITY_RANGE = 500.0f;
const SARA_ABILITY_DEPLTION_RATE = 2.0f;
const SARA_ABILITY_DPS = 250.0f;

var bool LeftStickPressed;


var AudioComponent SpeechComponent;

const CHANCE_FOR_HUMAN_FOLLOW_SOUND = 5;
const CHANCE_FOR_HUMAN_STOP_FOLLOW_SOUND = 5;
const CHANCE_FOR_KILL_SOUND = 10;
const CHANCE_FOR_SPAWN_SOUND = 5;

var SoundCue HumanFollowSound;
var SoundCue HumanStopFollowSound;
var SoundCue KillSound;
var SoundCue SpawnSound;



simulated event PostBeginPlay()
{
	local TATurretLocator turretLocator;
	super.PostBeginPlay();

	IsActiveInGame = false;
	IsPlayerInGame = true;
	IsSelectingCharacter = true;
	MapSettings = TAMapSettings(WorldInfo.GetMapInfo());

	ForceFeedbackManagerClassName = "WinDrv.XnaForcefeedbackmanager";

	InitInputSystem();

	// Give it a reference of the player controller.
	TAInputHandler(PlayerInput).PlayerControllerRef = self;
	FollowRadius = 25.0f;

	CurrentAbilityTime = 1;
	AbilityCooldown = 1;

	foreach AllActors(class'TATurretLocator', turretLocator)
	{
		hasTurretLocators = true;
	}
}

// Called once when the player has selected a character
function InitCharacter()
{
	local Vector tempSaraBeamLocation;


	if (TAHero(self.Pawn).PlayerHeroType == Gary)
	{
		CurrentAbilityTime = GARY_ABILITY_COOLDOWN;
		AbilityCooldown = GARY_ABILITY_COOLDOWN;

		HumanFollowSound = SoundCue'Speech.Follow.gary_follow';
		HumanStopFollowSound = SoundCue'Speech.StopFollow.gary_stopfollow';
		KillSound = SoundCue'Speech.Kill.gary_kill';
		SpawnSound = SoundCue'Speech.Spawn.gary_spawn';

		//FlamethrowerSound = new class'AudioComponent';
		//FlamethrowerSound.SoundCue = SoundCue'Sounds.Sounds.Flamethrower_Fire';
		//Pawn.AttachComponent(FlamethrowerSound);

		//SpawnSound;
	}
	else if (TAHero(self.Pawn).PlayerHeroType == Miles)
	{
		CurrentAbilityTime = MILES_ABILITY_COOLDOWN;
		AbilityCooldown = MILES_ABILITY_COOLDOWN;

		MilesSwingPunchSound = new class'AudioComponent';
		MilesSwingPunchSound.SoundCue = SoundCue'Sounds.Sounds.Swing';
		Pawn.AttachComponent(MilesSwingPunchSound);

		HumanFollowSound = SoundCue'Speech.Follow.miles_follow';
		HumanStopFollowSound = SoundCue'Speech.StopFollow.miles_stopfollow';
		KillSound = SoundCue'Speech.Kill.miles_kill';
		SpawnSound = SoundCue'Speech.Spawn.miles_spawn';
	}
	else if (TAHero(self.Pawn).PlayerHeroType == Sarge)
	{
		CurrentAbilityTime = SARGE_ABILITY_COOLDOWN;
		AbilityCooldown = SARGE_ABILITY_COOLDOWN;

		HumanFollowSound = SoundCue'Speech.Follow.sarge_follow';
		HumanStopFollowSound = SoundCue'Speech.StopFollow.sarge_stopfollow';
		KillSound = SoundCue'Speech.Kill.sarge_kill';
		SpawnSound = SoundCue'Speech.Spawn.sarge_spawn';

		SargeAbilitySound = new class'AudioComponent';
		SargeAbilitySound.SoundCue = SoundCue'Sounds.SargeAbility_Use';
		Pawn.AttachComponent(SargeAbilitySound);
	}
	else if (TAHero(self.Pawn).PlayerHeroType == Sara)
	{
		CurrentAbilityTime = SARA_ABILITY_COOLDOWN;
		AbilityCooldown = SARA_ABILITY_COOLDOWN;

		SaraBeam = new (self) class'UDKParticleSystemComponent';
		SaraBeam.SetTemplate(SaraBeamNeutral);
		SaraBeam.SetFOV(UDKSkeletalMeshComponent(Pawn.Weapon.Mesh).FOV); // Hmm...
		UDKSkeletalMeshComponent(Pawn.Weapon.Mesh).AttachComponentToSocket(SaraBeam, 'MuzzleFlashSocket');
		UDKSkeletalMeshComponent(Pawn.Weapon.Mesh).GetSocketWorldLocationAndRotation('MuzzleFlashSocket', tempSaraBeamLocation);
		SaraBeam.SetBeamSourcePoint(0, tempSaraBeamLocation, 0);
		SaraBeam.SetActive(false);

		SaraBeamSound = new class'AudioComponent';
		SaraBeamSound.SoundCue = SoundCue'Sounds.Sounds.SaraBeam';
		Pawn.AttachComponent(SaraBeamSound);

		HumanFollowSound = SoundCue'Speech.Follow.sara_follow';
		HumanStopFollowSound = SoundCue'Speech.StopFollow.sara_stopfollow';
		KillSound = SoundCue'Speech.Kill.sara_kill';
		SpawnSound = SoundCue'Speech.Spawn.sara_spawn';
	}

	SpeechComponent = new class'AudioComponent';
	Pawn.AttachComponent(SpeechComponent);
	
	//SaySpeech(SpawnSound, CHANCE_FOR_SPAWN_SOUND); Temporarily disabled so it can't clash with Necro
	TAGame(WorldInfo.Game).NarratorManager.SaySpeech(TAGame(WorldInfo.Game).NarratorManager.SpawnSound);

	DontUseBarricade();
}

function SaySpeech(SoundCue sound, int randomness)
{
	local int chance;

	if (!SpeechComponent.IsPlaying())
	{
		chance = RandRange(1, randomness);

		if (chance == 1)
		{
			SpeechComponent.SoundCue = sound;
			SpeechComponent.Play();
		}
	}
}

// Do something with this to adjust the aim of the character.
simulated event GetPlayerViewpoint(out Vector out_Location, out Rotator out_Rotation)
{
	super.GetPlayerViewPoint(out_Location,out_Rotation);
}

function ResetPawn()
{
	IsActiveInGame = false;
	PawnHideTimer=1.f;

	SetTimer(1.0f, false, 'StopForceFeedback');

	if (bDespawnTimerSet == true)
	{
		ClearTimer('despawnPlayer');
		bDespawnTimerSet = false;
	}
}

function BeginRespawn()
{
	IsSelectingCharacter = true;
	WaitingForRespawn = true; 
	RespawnTotalTime  = RESPAWN_DELAY;
	RespawnTimer      = 0;

	ResetPawn();
}

function Respawn()
{				
	local PlayerStart playerSpawn;

	WaitingForRespawn = false;
	RespawnTimer = 0;

	//if (!IsPlayerInGame)
	//{
	//	return;
	//}

	foreach AllActors(class'PlayerStart', playerSpawn)
	{
		if(playerSpawn.bEnabled == true)
		{
			pawn.SetLocation(playerSpawn.Location);
		}
	}

	IsSelectingCharacter = false;
	TAPawn(Pawn).bIsActive = true;
	TAPawn(Pawn).SetHidden(false);
	TAPawn(Pawn).Health = 100;
	TAPawn(Pawn).SetPhysics(PHYS_Walking);
	TAPlayerController(Pawn.Controller).IsPlayerInGame = true;
	TAPlayerController(Pawn.Controller).IsActiveInGame = true;
	
	InitCharacter();
	TAWeapon(Pawn.Weapon).AmmoCount = TAWeapon(Pawn.Weapon).respawnAmmoCount;
	
	//TAGame(WorldInfo.Game).GameHud.ScaleformHUD.PushtoFeed(string(TAHero(Pawn).PlayerHeroType), " killed", "", "0x00FF00", "0xFFFFFF", "0xFFFFFF");
}

function ProcessMove(float deltaTime, vector newAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
{
	super.ProcessMove(deltaTime, newAccel, DoubleClickMove, DeltaRot);

	Pawn.Acceleration = newAccel;
}

function BeginForceFeedback(ForceFeedbackWaveForm waveform)
{
	self.ClientPlayForceFeedbackWaveform(waveform);
}

function StopForceFeedback()
{
	self.ClientStopForceFeedbackWaveform();
}

// Override the function that is required for firing weaponry
exec function StartFire(optional byte FireModeNum)
{
	local TAZombiePawn closestZ;

	if (IsActiveInGame)
	{
		//ClientPlayForceFeedbackWaveform( BeamWeaponFireWaveForm );
		
		if (TAHero(self.Pawn).PlayerHeroType == Sara)
		{
			//TAHero(Pawn).bIsAttacking = true;
			super.StartFire(1);

			super.StopFire(1);
			//TAHero(Pawn).bIsAttacking = false;
		}
		else if (TAHero(self.Pawn).PlayerHeroType == Miles)
		{
			TAHero(Pawn).bIsAttacking = true;

			if (bStopAttackingTimerSet == true)
			{
				ClearTimer('StopAttacking');
			}
			SetTimer(0.5f, false, 'StopAttacking');
			bStopAttackingTimerSet = true;

			MilesSwingPunchSound.Play();

			BeginForceFeedback(TAHero(Pawn).DamageForceFeedbackWaveForm);
			
			closestZ = TAZombiePawn(GetNearestVisibleTargetWithinRange(MILES_PUNCH_RANGE, true, false));
			if (closestZ != none)
				closestZ.TakeDamage(MILES_PUNCH_DAMAGE, self, Pawn.Location, 25*Normal(Pawn.Velocity), class'TADmgType_Fists');
		}
		else
		{
			TAHero(Pawn).bIsAttacking = true;

			super.StartFire(FireModeNum);
		}
	}
}

function UseObjective()
{
	local TAObjectiveTrigger localTrigger;


	`log(self.name $ " :: AButton() has been called");
		
	// Loop through all the triggers that are in the game
	// determine that the triggers close enough to the player before using it
	
	foreach AllActors(class'TAObjectiveTrigger',localTrigger)
	{
		`log(localTrigger.Name $ " is the name of the trigger");

		// Determine that it's within distance.
		if (abs(VSize(localTrigger.Location - Pawn.Location)) < localTrigger.InteractiveSpriteAppearanceDistance)
		{
			`log("Can interact with the trigger");
			localTrigger.Interact(self.Pawn);
		}
	}
}

function StopAttacking()
{
	TAHero(Pawn).bIsAttacking = false;
	bStopAttackingTimerSet = false;
}

// For when the gun has stopped firing.
exec function StopFire(optional byte FireModeNum)
{
	if (IsActiveInGame)
	{
		if (bStopAttackingTimerSet == true)
		{
			ClearTimer('StopAttacking');
		}
		if (TAHero(Pawn).PlayerHeroType == MILES)
		{
			SetTimer(0.5f, false, 'StopAttacking');
		}
		else
		{
			StopAttacking();
		}

		super.StopFire(FireModeNum);
	}
}

// Override the function that is required for firing weaponry
exec function StartAltFire(optional byte FireModeNum)
{
	if (IsActiveInGame)
	{
		// Determine that it's Sara that we're dealing with.
		if (TAHero(self.Pawn).PlayerHeroType == Sara)
		{
			//TAHero(Pawn).bIsAttacking = true;
			TAHero(Pawn).AbilityActive = true;
		}
		else
		{
			if (CurrentAbilityTime < AbilityCooldown)
				return;

			CurrentAbilityTime = 0;

			if (CharacterIndex == 0) // Gary
			{
				UseGaryAbility();
			}
			else if (CharacterIndex == 1) // Miles
			{
				UseMilesAbility();
			}
			else if (CharacterIndex == 3) // Sarge
			{
				UseSargeAbility();
			}
		}
	}
}

// For when the gun has stopped firing.
exec function StopAltFire(optional byte FireModeNum)
{
	if (IsActiveInGame)
	{
		if (TAHero(self.Pawn).PlayerHeroType == Sara)
		{
			//TAHero(Pawn).bIsAttacking = false;
			TAHero(Pawn).AbilityActive = false;
		}
	}
}

exec function NextWeapon()
{
	if (IsActiveInGame)
	{
		super.NextWeapon();
	}
	else
	{

	}
}

// For throwing one grenade only.
exec function ThrowGrenade()
{
	
}

// For using objects in the environment.
exec function Use()
{

}

// Miles ability is to knock back enemies around him and stun them for a short time period.
function UseMilesAbility()
{
	local TAZombiePawn tempZ;

	TAHero(Pawn).AbilityActive = true;
	MilesSpinCooldown = 1.f;
	Pawn.Acceleration.X = 0;
	Pawn.Acceleration.Y = 0;

	WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'Particle_Effects.Systems.MilesPlumberRageEffects', Pawn.Location - vect(0,0,80));

	foreach AllActors(class'TAZombiePawn', tempZ)
	{
		if (tempZ.Health > 0 && VSize(Pawn.Location - tempZ.Location) < MILES_ABILITY_RANGE)
			tempZ.TakeDamage(MILES_ABILITY_DAMAGE, self, Pawn.Location, Normal(tempZ.Location - Pawn.Location) * MILES_ABILITY_MOMENTUM, class'TADmgType');
	}

	TAGame(WorldInfo.Game).NarratorManager.SaySpeech(TAGame(WorldInfo.Game).NarratorManager.MilesAbilitySound);
}

// Garys ability is a slow-down time grenade.
function UseGaryAbility()
{
	// Boot out a pretty time grenade.
	TAWeapon(Pawn.Weapon).ProjectileSpecialTypeFire(class'TAProj_TimeGrenade');

	TAGame(WorldInfo.Game).NarratorManager.SaySpeech(TAGame(WorldInfo.Game).NarratorManager.GaryAbilitySound);
}

// Saras ability is the revolver gun.
function UseSaraAbility(float deltaTime)
{
	local vector x, y, z;
	local Actor tracedActor;
	local float abilityRatio;

	SaraHealPointsTimer += deltaTime;

	abilityRatio = CurrentAbilityTime / AbilityCooldown;

	GetAxes(Pawn.Rotation, x, y, z);

	
	BeginForceFeedback(TAHero(Pawn).DamageForceFeedbackWaveForm);
			
			
	tracedActor = GetNearestVisibleTargetWithinRange(SARA_ABILITY_RANGE);
	
	
	//tracedActor = Trace(loc, norm, Pawn.Location + (x * SARA_ABILITY_RANGE), Pawn.Location, true);
	
	// Set the initial beam location
	SaraBeam.SetTemplate(SaraBeamNeutral);
	SaraBeam.SetVectorParameter('LinkBeamEnd', Pawn.Location + (X * SARA_ABILITY_RANGE));
	SaraBeam.SetBeamDistance(0, SARA_ABILITY_RANGE);

	if (tracedActor != none)
	{
		if (TAZombiePawn(tracedActor) != none)
		{
			TAZombiePawn(tracedActor).TargetedByBeam = true;

			SaraBeam.SetVectorParameter('LinkBeamEnd', tracedActor.Location);
			SaraBeam.SetBeamDistance(0, VSize(tracedActor.Location - Pawn.Location));

			SaraBeam.SetTemplate(SaraBeamRed);
			tracedActor.TakeDamage(SARA_ABILITY_DPS * deltaTime * abilityRatio, self, Pawn.Location, vect(0, 0, 0), class'TADmgType_HealingRay');

		}		
		else if (TAHero(tracedActor) != none)
		{
			if (TAPlayerController(TAHero(tracedActor).Controller).IsActiveInGame)
			{
				TAHero(tracedActor).TargetedByBeam = true;

				SaraBeam.SetVectorParameter('LinkBeamEnd', tracedActor.Location);
				SaraBeam.SetBeamDistance(0, VSize(tracedActor.Location - Pawn.Location));

				SaraBeam.SetTemplate(SaraBeamGreen);
				if (TAHero(tracedActor).Health < TAHero(tracedActor).HealthMax)
				{
					tracedActor.HealDamage(SARA_ABILITY_DPS * deltaTime * abilityRatio, self, class'TADmgType');
					`log("Attempting to show");
					TAHero(tracedActor).SetHealingEffect();

					// Add heal points.
					if (SaraHealPointsTimer - SaraLastHealPointsTime >= SARA_HEAL_POINTS_INTERVAL)
					{
						SaraLastHealPointsTime = SaraHealPointsTimer;
						TAGame(WorldInfo.Game).AddScore(LocalPlayer(Player).ControllerId, SARA_HEAL_POINTS);
					}
				}

			}
		}	
	}
}

// Sarges ability is to warp forward from current location.
function UseSargeAbility()
{
	local Vector teleportPosition;
	local Vector traceHitLocation;
	local Vector traceHitNormal;
	local TAZombiePawn zombie;

	// Work out resulting position.
	teleportPosition = Pawn.Location + (Normal(Pawn.Velocity) * SARGE_TELEPORT_DISTANCE);

	// Trace ray forwards.
	if (Trace(traceHitLocation, traceHitNormal, teleportPosition, Pawn.Location) != none)
	{
		teleportPosition = Pawn.Location + (Normal(Pawn.Velocity) * (VSize(Pawn.Location - traceHitLocation) - SARGE_TELEPORT_HIT_DISTANCE_BUFFER));
	}

	// Spawn start spawner.
	WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'Particle_Effects.Systems.teleport_b', Pawn.Location);

	// Spawn end spawner.
	WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'Particle_Effects.Systems.teleport_a', teleportPosition);

	// Forcefeedback, bitches
	BeginForceFeedback(TAHero(Pawn).DamageForceFeedbackWaveForm);



	// Hurt any zombie in the teleport ray
	foreach TraceActors(class'TAZombiePawn', zombie, traceHitLocation, traceHitNormal, teleportPosition, Pawn.Location)
	{
		if (zombie.Health > 0)
			zombie.TakeDamage(SARGE_ABILITY_DAMAGE, self, Pawn.Location, Normal(zombie.Location - Pawn.Location) * SARGE_ABILITY_MOMENTUM, class'TADmgType');
	}


	// Move forwards.
	Pawn.SetLocation(teleportPosition);


	// Hurt any zombies near us.
	//foreach AllActors(class'TAZombiePawn', zombie)
	//{
	//	if (zombie.Health > 0 && VSize(Pawn.Location - zombie.Location) < SARGE_ABILITY_RANGE)
	//		zombie.TakeDamage(SARGE_ABILITY_DAMAGE, self, Pawn.Location, Normal(zombie.Location - Pawn.Location) * SARGE_ABILITY_MOMENTUM, class'TADmgType');
	//}

	TAGame(WorldInfo.Game).NarratorManager.SaySpeech(TAGame(WorldInfo.Game).NarratorManager.SargeAbilitySound);

SargeAbilitySound.Play();
}

	/*
Miles:
Plumber Rage - Knock nearby enemies around him and stun them for a short period of time. Area of Effect type of attack.

Gary - Specialist Class
Rapid decay / aging - has a particular grenade or weapon that can speed up the aging process of a zombie or rapid decay so to speak so that they die.

Sara - Medic Class
Reverse the effects of damage “done over time” - uses particular item that does that within a certain radius of her position

Sarge - Soldier Class
Time Enhance - Ability to speed up his attack and move speed for a short period of time.
Flash forward - “travel through time” to a space slightly further in front of the direction that he is facing.
*/

function DontUseBarricade()
{
	if (!IsActiveInGame)
		return;

		barricade.Destroy();
		carrying = false;


		turret.Destroy();
		carrying = false;

}

function UseBarricade()
{
	local TAHero hero;
	local vector  X,Y,Z;

	local TABarricadeCrateSpawn bSpawn;
	local TATurretCrateSpawn tSpawn;

	if (!IsActiveInGame)
		return;

	GetAxes(pawn.Rotation,X,Y,Z);
	hero = TAHero(Pawn);
	
	if (!carrying && hero.barricadeCount > 0)
	{
		barricade = Spawn(Class'TABarricade',,,pawn.Location + 100.f * X);
		
		if (barricade != none)
		{
			barricade.SetRed();
			carrying = true;
		}
	}
	else if (carrying && hero.barricadeCount > 0)
	{
		if (barricade != none && barricade.canPlace == true)
		{
			hero.barricadeCount--;
			//barricade.bBlockActors = true;
			barricade.SetStandard();
			barricade.SetPhysics(PHYS_Interpolating);
			barricade.locator.hasBarricade = true;
			carrying = false;
			
			foreach AllActors(class'TABarricadeCrateSpawn', bSpawn)
			{
				if (bSpawn.Controller == self)
				{
					bSpawn.Controller = none;
					bSpawn.Barricade = barricade;
				}
			}

			barricade = none;
		}
	}

	if (!carrying && hero.turretCount > 0)
	{
		turret = Spawn(Class'TATurret',,,pawn.Location);


		if (turret != none)
		{
			turret.MyPlayerController = self;
			carrying = true;
			turret.SetRed();
		}
	}
	else if (carrying && hero.turretCount > 0)
	{
		if (turret != none && turret.canPlace == true)
		{
			hero.turretCount--;
			turret.SetStandard();
			turret.placed = true;
			carrying = false;
			turret.locator.hasTurret = true;

			foreach AllActors(class'TATurretCrateSpawn', tSpawn)
			{
				if (tSpawn.Controller == self)
				{
					tSpawn.Controller = none;
					tSpawn.Turret = turret;
				}
			}
			//`log("394756349765294756948569348756");
			turret.turretCollision = Spawn(Class'TATurretCollision',,,turret.Location);
			turret.turretCollision.DoThisShit();
			turret = none;
		}
	}
}



function Actor GetNearestVisibleTargetWithinRange(float range, bool findZombies = true, bool findHeroes = true)
{
	local Actor tracedActor;
	local TAPawn tempActor;

	foreach AllActors(class'TAPawn', tempActor)
	{
		if (CanSee(tempActor) && tempActor != Pawn && TAHuman(tempActor) == none)
		{
			if (tempActor.Health > 0)
			{
				if (TAZombiePawn(tempActor) != none && findZombies || TAHero(tempActor) != none && findHeroes)
				{
					if (TAHero(tempActor) != none)
					{
						if (!TAPlayerController(TAHero(tempActor).Controller).IsActiveInGame)
						{
							continue;
						}
					}
				
					if (tracedActor == none && VSize(Pawn.Location - tempActor.Location) < range)
					{
						tracedActor = tempActor;
					}
					else if (tracedActor != none && VSize(Pawn.Location - tempActor.Location) < VSize(Pawn.Location - tracedActor.Location))
					{
						tracedActor = tempActor;
					}
				}
			}
		}
	}
		
	return tracedActor;
}

function int IndexOf(string s, string c)
{
	local int i;

	for (i = 0; i < Len(s); i++)
	{
		if (Mid(s, i, 1) == c)
			return i;
	}

	return -1;
}

event PlayerTick(float deltaTime)
{
	local Rotator _rotation;
	local Vector  heroNewPosition;
	local Vector  heroNewPositionX;
	local Vector  heroNewPositionY;
	local TAHero  hero;
	local float   currentRadius;
	local float   heroRadius;
	local float   heroRadiusX;
	local float   heroRadiusY;
	local TAZombiePawn tempTraceZombie;
	local TAHero tempTraceHero;

	local Rotator tempBarRot;

	local vector  X,Y,Z;

	local string gameOverName;
	local string gameOverCurrentChar;
	local int gameOverCurrentCharIndex;
	//local string gameOverNextChar;

	local AudioComponent newFlameThrowerSound;
	
	if (Pawn == none)
		return;

	leftX = PlayerInput.aStrafe;
	leftY = PlayerInput.aBaseY;
	rightX = PlayerInput.aTurn;
	rightY = PlayerInput.aLookUp * -1;
	leftX =  (leftX < -1.f ? -1.f   : (leftX >  1.f ? 1.f : leftX));
	leftY =  (leftY < -1.f ? -1.f   : (leftY >  1.f ? 1.f : leftY));
	rightX = (rightX < -1.f ? -1.f  : (rightX > 1.f ? 1.f : rightX));
	rightY = (rightY < -1.f ? 1.f   : (rightY > 1.f ? 1.f : rightY));

	// This big chunk of ugly-ass code handles changing the characters on the
	// team name when the game over screen is shown
	if (TAGame(WorldInfo.Game).GameState == TAGame(WorldInfo.Game).EGameState.GameOver)
	{
		if (!LeftStickPressed)
		{
			gameOverName = TAGame(WorldInfo.Game).GameOverName;
			gameOverCurrentChar = Mid(gameOverName, Len(gameOverName) - 1, 1);
			gameOverCurrentCharIndex = IndexOf(TAGame(WorldInfo.Game).GAME_OVER_NAME_CHARS, gameOverCurrentChar);
			if (leftY >= 0.5f)
			{
				if (gameOverCurrentCharIndex + 1 >= Len(TAGame(WorldInfo.Game).GAME_OVER_NAME_CHARS))
					gameOverName = Mid(gameOverName, 0, Len(gameOverName) - 1) $ Mid(TAGame(WorldInfo.Game).GAME_OVER_NAME_CHARS, 0, 1);				
				else
					gameOverName = Mid(gameOverName, 0, Len(gameOverName) - 1) $ Mid(TAGame(WorldInfo.Game).GAME_OVER_NAME_CHARS, gameOverCurrentCharIndex + 1, 1);

				TAGame(WorldInfo.Game).GameOverName = gameOverName;
				TAGame(WorldInfo.Game).GameOver();

				LeftStickPressed = true;
			}
			else if (leftY <= -0.5f)
			{
				if (gameOverCurrentCharIndex - 1 < 0)
					gameOverName = Mid(gameOverName, 0, Len(gameOverName) - 1) $ Mid(TAGame(WorldInfo.Game).GAME_OVER_NAME_CHARS, Len(TAGame(WorldInfo.Game).GAME_OVER_NAME_CHARS) - 1, 1);		
				else
					gameOverName = Mid(gameOverName, 0, Len(gameOverName) - 1) $ Mid(TAGame(WorldInfo.Game).GAME_OVER_NAME_CHARS, gameOverCurrentCharIndex - 1, 1);	
				
				TAGame(WorldInfo.Game).GameOverName = gameOverName;
				TAGame(WorldInfo.Game).GameOver();

				LeftStickPressed = true;
			}
		}
		else
		{
			if (leftY < 0.5f && leftY > -0.5f)
				LeftStickPressed = false;
		}

		Pawn.Acceleration.X = 0;
		Pawn.Acceleration.Y = 0;
		return;
	}

	// Wait for the respawn?
	if (WaitingForRespawn == true)
	{
		RespawnTimer += deltatime;
	}


	if (PlayingFlamethrowerSound)
	{
		CurrentFlamethrowerSoundTime += deltatime;

		if (CurrentFlamethrowerSoundTime >= FLAMETHROWER_SOUND_TIME)
		{
			newFlameThrowerSound = new class'AudioComponent';
			newFlameThrowerSound.SoundCue = SoundCue'Sounds.Sounds.Flamethrower_Fire';
			Pawn.AttachComponent(newFlameThrowerSound);
			newFlameThrowerSound.Play();

			CurrentFlamethrowerSoundTime = 0;
		}
	}





	if (TAHero(Pawn).PlayerHeroType == Miles && TAHero(Pawn).AbilityActive)
	{
		MilesSpinCooldown -= deltaTime;
		if (MilesSpinCooldown <= 0.f)
		{
			TAHero(pawn).AbilityActive = false;
		}

		Pawn.Acceleration.X = 0;
		Pawn.Acceleration.Y = 0;
	}

	if (TAHero(self.Pawn).PlayerHeroType == Sara && TAHero(Pawn).AbilityActive)
	{
		CurrentAbilityTime -= deltaTime * SARA_ABILITY_DEPLTION_RATE;
	
		if (CurrentAbilityTime < 0)
			CurrentAbilityTime = 0;
	}
	else
	{
		CurrentAbilityTime += deltaTime;
	
		if (CurrentAbilityTime > AbilityCooldown)
			CurrentAbilityTime = AbilityCooldown;
	}

	GetAxes(pawn.Rotation,X,Y,Z);
	if (IsActiveInGame && IsPlayerInGame && Pawn.Health > 0 && TAGame(WorldInfo.Game).GameState != TAGame(WorldInfo.Game).EGameState.GameOver)
	{
		// Set acceleration speed.

		if (TAHero(Pawn).PlayerHeroType == Miles && TAHero(Pawn).AbilityActive)
		{			
			Pawn.Acceleration.X = 0;
			Pawn.Acceleration.Y = 0;
		}
		else
		{
			if (!TAHero(Pawn).bGrabbed)
			{
				Pawn.Acceleration.X = leftY;
				Pawn.Acceleration.Y = leftX;
			}
			
		}
		PrevTraceActor = TraceActor;




		//TraceActor = Trace(hitWorld, hitNormal, Pawn.Location + (X * TAWeapon(Pawn.Weapon).WeaponRange), Pawn.Location, true);
		TraceActor = none;

		if (TAHero(self.Pawn).PlayerHeroType == Sara) // IF SARA BITCH
		{
			TraceActor = GetNearestVisibleTargetWithinRange(SARA_ABILITY_RANGE);
		}
		else if (TAHero(self.Pawn).PlayerHeroType == Miles) // IF MILES BITCH
		{
			TraceActor = GetNearestVisibleTargetWithinRange(MILES_PUNCH_RANGE, true, false);
		}
		else
		{
			// Get the closest trace zombie
			foreach TraceActors(class'TAZombiePawn', tempTraceZombie, hitWorld, hitNormal, Pawn.Location + (X * TAWeapon(Pawn.Weapon).WeaponRange), Pawn.Location)
			{
				if (tempTraceZombie.Health > 0)
				{
					if (TraceActor == none)
						TraceActor = tempTraceZombie;
					else if (VSize(tempTraceZombie.Location - Pawn.Location) < VSize(TraceActor.Location - Pawn.Location))
						TraceActor = tempTraceZombie;
				}
			}
		}



		EndTrace =  Pawn.Location + (X * TAWeapon(Pawn.Weapon).WeaponRange);
		StartTrace = Pawn.Location;

		if (TraceActor == none)
		{
			TAHero(Pawn).TargettedRing.SetHidden(true);
			TAHero(Pawn).TargettedRingActor = none;
		}
		else //if (TraceActor.Class.Name == 'TAZombiePawn') //temporarily commented out to test it with sara
		{
			TAHero(Pawn).TargettedRing.SetHidden(false);
			TAHero(Pawn).TargettedRingActor = TraceActor;
		}

		// No movement recently?
		if (Pawn.Acceleration.X != 0 || Pawn.Acceleration.Y != 0)
		{
			if (bDespawnTimerSet == true)
			{
				ClearTimer('despawnPlayer');
				bDespawnTimerSet = false;
			}
		}
		else
		{
			if (bDespawnTimerSet == false)
			{
				SetTimer(DESPAWN_DELAY, true, 'despawnPlayer');    
				bDespawnTimerSet = true;
			}
		}

		// Check that moving in this direction won't cause us to move out of the minimum
		// radius to other players.
		heroNewPosition         =  Pawn.Location + Pawn.Acceleration;
		heroNewPositionX        =  Pawn.Location;
		heroNewPositionX.X      += Pawn.Acceleration.X;
		heroNewPositionY        =  Pawn.Location;
		heroNewPositionY.Y      += Pawn.Acceleration.Y;

		foreach AllActors(class'TAHero', hero)
		{
			if (hero.Controller == none || TAPlayerController(hero.Controller).IsPlayerInGame == false || TAPlayerController(hero.Controller).IsActiveInGame == false)
			{
				continue;
			}

			currentRadius   = VSize(Pawn.Location - hero.Location);
			heroRadius      = VSize(heroNewPosition - hero.Location);
			heroRadiusX     = VSize(heroNewPositionX - hero.Location);
			heroRadiusY     = VSize(heroNewPositionY - hero.Location);

			// If we have moved outside the radius, then stop acceleration.
			if (heroRadius > MapSettings.CameraMaxDistanceBetweenPlayers && heroRadius >= currentRadius)
			{
				if (heroRadiusX < currentRadius && heroRadiusX < heroRadiusY)
				{
					Pawn.Acceleration.Y = 0;
				}
				else if (heroRadiusY < currentRadius && heroRadiusY < heroRadiusX)
				{
					Pawn.Acceleration.X = 0;
				}
				else
				{
					Pawn.Acceleration.X = 0;		
					Pawn.Acceleration.Y = 0;		
				}
			}
		}

		// Set player rotation.
		// Prevent rotation snapping to a default
		if (rightX != 0 || rightY != 0)
		{
			_rotation.Yaw = (atan2(rightX, rightY) * 32768 / PI);
			Pawn.ClientSetRotation(_rotation);
		}



		if (TAHero(self.Pawn).PlayerHeroType == Sara)
		{
			// Untarget all stuff - currently used for time dilation
			foreach AllActors(class'TAZombiePawn', tempTraceZombie)
			{
				tempTraceZombie.TargetedByBeam = false;
			}

			foreach AllActors(class'TAHero', tempTraceHero)
			{
				tempTraceHero.TargetedByBeam = false;
			}

			// If sara is using her ability
			if (TAHero(Pawn).AbilityActive)
			{
				// Enable the beam
				SaraBeam.SetActive(true);
				SaraBeam.ActivateSystem();

				SaraBeamSound.SetFloatParameter('Pitch', (1 + (CurrentAbilityTime / AbilityCooldown)) / 2);
				SaraBeamSound.SetFloatParameter('Volume', (1 + (CurrentAbilityTime / AbilityCooldown)) / 2);
	
				if (!SaraBeamSound.IsPlaying()) // Hopefully only gets called once
				{
					SaraBeamSound.FadeIn(0, 1.0f);

					TAGame(WorldInfo.Game).NarratorManager.SaySpeech(TAGame(WorldInfo.Game).NarratorManager.SaraAbilitySound);
				}
				

				UseSaraAbility(deltaTime);
			}
			else
			{
				// Disable the beam
				SaraBeam.SetActive(false);
				SaraBeam.DeactivateSystem();

				SaraBeamSound.FadeOut(0, 0.0f);
			}
		}
	}
	else
	{
		Pawn.Acceleration.X = 0;		
		Pawn.Acceleration.Y = 0;
		
		if (PawnHideTimer <= 0.f)
		{
			Pawn.SetHidden(true);
		}
		else
		{
			PawnHideTimer -= deltaTime;
		}
		
		if (SaraBeam != none)
		{
			SaraBeam.SetActive(false);
			SaraBeam.DeactivateSystem();
			SaraBeamSound.FadeOut(0, 0.0f);
		}
	}

	if (carrying && barricade != none)
	{
		tempBarRot = pawn.Rotation;
		tempBarRot.Yaw += 16384;

		barricade.SetGreen();
		barricade.SetLocation(pawn.Location + (100*X));
		barricade.SetRotation(tempBarRot);
		barricade.SetCollision(false,false,false);
		barricade.canPlace = true;
	}

	if (carrying && turret != none)
	{
		turret.SetGreen();
		turret.SetLocation(pawn.Location + (100*X));
		turret.SetRotation(pawn.Rotation);
		turret.SetCollision(false,false,false);
		turret.canPlace = true;
	}
}

function despawnPlayer()
{
	TAGame(WorldInfo.Game).GameHud.PushtoFeed(string(TAHero(Pawn).PlayerHeroType), " is idle", "", "0x00FF00", "0xFFFFFF", "0xFFFFFF");
	Pawn.TakeDamage(TAHero(Pawn).HealthMax, Pawn.Controller, Location, vect(0,0,0), class'TADmgType');
	
	//ResetPawn();

	//TAPawn(Pawn).bIsActive = false;
	//TAPawn(Pawn).SetHidden(true);
	//TAPawn(Pawn).Health = 0;
	//IsPlayerInGame = true;
	//IsSelectingCharacter = true;
	//IsActiveInGame = false;

	//StopForceFeedback();
}

defaultproperties
{
	CameraClass = class'TeamAwesome.TAPlayerCamera';
	InputClass = class'TeamAwesome.TAInputHandler';
	barricadeOffset = (X = 0,Y = 50,Z = 0);
	turretOffset = (X = 0,Y = 50,Z = 0);

	SaraBeamRed = ParticleSystem'TestPackage.Effects.Beam_Red'
	SaraBeamGreen = ParticleSystem'TestPackage.Effects.Beam_Green'
	SaraBeamNeutral = ParticleSystem'TestPackage.Effects.Beam_Neutral'
}	
