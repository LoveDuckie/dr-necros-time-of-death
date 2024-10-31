class TATurret extends TAPlaceableThing placeable;

var float ScanRadius;

var SkeletalMeshComponent turretBarrel, turretStand;
var int roll, pitch, yaw;
var bool fireTimerSet, rotateRight;

var UDKParticleSystemComponent MuzzleFlashPSC;
var ParticleSystem MuzzleFlashPSCTemplate;

var TAZombiePawn target;

var Material standardMaterial;
var SkeletalMeshComponent MinigunTurretHead;


var bool canPlace;
var bool placed;

var bool bIsFiring;

var StaticMeshComponent barrelComp;

var TATurretLocator locator;

var TAPlayerController MyPlayerController;

var AudioComponent FireSound;

var TATurretCollision turretCollision;

simulated function PostBeginPlay()
{
	barrelComp.SetHidden(true);

	MuzzleFlashPSC = new () class'UDKParticleSystemComponent';
	
	// Ensure that the particle system component is OK
	if (MuzzleFlashPSC != none)
	{
		if (MuzzleFlashPSCTemplate != none)
		{
			// Set the template.
			MuzzleFlashPSC.SetTemplate(MuzzleFlashPSCTemplate);
			MuzzleFlashPSC.SetFOV(UDKSkeletalMeshComponent(MinigunTurrethead).FOV);
			MinigunTurrethead.AttachComponentToSocket(MuzzleFlashPSC,'BulletSpawn');
		}

	}

	FireSound = new class'AudioComponent';
	FireSound.SoundCue = SoundCue'Sounds.Sounds.MachineGun_Fire';
	AttachComponent(FireSound);
}

simulated event Tick(float DeltaTime)
{
	local rotator barrelRotation;
	local vector dNorm;

	local float dx, dy;
	if(!fireTimerSet && placed == true)
	{
		SetTimer(0.06f, true, 'Fire');
		fireTimerSet = true;
	}
	if (target == none)
	{
		barrelRotation.Yaw = yaw;
		if(rotateRight)
		{
			yaw += 100;
			if(yaw >= 10000)
			{
				rotateRight = !rotateRight;
			}

		}
		else
		{
			yaw -= 100;
			if(yaw <= -10000)
			{
				rotateRight = !rotateRight;
			}
		}
	}
	else
	{
		dy=target.Location.Y-Location.Y;
		dx=target.Location.X-Location.X;

		dNorm.x = dy;
		dNorm.y = dx;
		dNorm = Normal(dNorm);
		//`log(Atan2(dy, dx));
		barrelRotation.Yaw = Atan2(dNorm.x, dNorm.y) * RadToUnrRot;
		barrelRotation.Yaw -= Rotation.Yaw; //mak the barrel match up properly
		if(target.bIsDead)
		{
			target = none;
		}
	}

	bIsFiring = (target != none);
	
	turretBarrel.SetRotation(barrelRotation);
}

function rotator AddSpread(rotator BaseAim)
{
	local vector X, Y, Z;
	local float CurrentSpread, RandY, RandZ;

	CurrentSpread = 0.5f;

	// Add in any spread.
	GetAxes(BaseAim, X, Y, Z);
	RandY = FRand() - 0.5;
	RandZ = Sqrt(0.5 - Square(RandY)) * (FRand() - 0.5);
	return rotator(X + RandY * CurrentSpread * Y + RandZ * CurrentSpread * Z);
}

function Fire()
{
	local TAWeaponProjectile bullet;
	local vector SocketLocation;
	local Rotator actualDirection;

	actualDirection = turretBarrel.Rotation;
	actualDirection.Yaw += Rotation.Yaw;

	actualDirection = AddSpread(actualDirection);

	CanTargetEnemy();
	//`log("Firing");
	if(target != none)
	{
		if (!target.bIsDead)
		{
			if((VSize(Location - target.Location)) <= ScanRadius)
			{
				//`log("Not none");
				MinigunTurretHead.GetSocketWorldLocationAndRotation('BulletSpawn',SocketLocation);
				bullet = Spawn( class'TAProj_WeakBullet', self,, SocketLocation, actualDirection);
				bullet.InstigatorController = MyPlayerController;
				bullet.Init(Vector(actualDirection));
				fireTimerSet = false;
				MuzzleFlashPSC.ActivateSystem(); // Fire the muzzle flash!

				FireSound.Play();
			}
			else
			{
				target = none;
			}
		}
		else
		{
			target = none;
		}
	}
}

function CanTargetEnemy()
{
	local TAZombiePawn localpawn;
	local TAZombiePawn closest;

	// Get the closest zombie
	foreach AllActors(class'TAZombiePawn', localpawn)
	{
		if (closest == none)
		{
			if (localpawn.Health > 0 && VSize(Location - localpawn.Location) < 750)
			{
				closest = localpawn;
			}
		}
		else if (VSize(Location - localpawn.Location) < VSize(Location - closest.Location))
		{
			if (localpawn.Health > 0)
			{
				closest = localpawn;
			}
		}
	}

	if (closest != none)
	{
		if (target == none)
			target = closest;
		else
			if (target.Health <= 0)
				target = closest;
	}
}

function SetRed()
{
	local Material mat;
	mat = Material'TestPackage.RedBarricade';
	Mesh.SetMaterial(0, mat);
	//SetPhysics(PHYS_None);
}

function SetBlue()
{
	local Material mat;
	mat = Material'TestPackage.BlueBarricade';
	Mesh.SetMaterial(0, mat);
}

function SetGreen()
{
	local Material mat;
	mat = Material'TestPackage.GreenBarricade';
	Mesh.SetMaterial(0, mat);
	SetPhysics(PHYS_Interpolating);
}

function SetStandard()
{
	Mesh.SetMaterial(0, standardMaterial);
}

DefaultProperties
{
	bCanStepUpOn=false 
	//RBCollideWithChannels=(Default=TRUE,BlockingVolume=TRUE,GameplayPhysics=FALSE,EffectPhysics=FALSE) 
    //bCollideActors=true 
    //bBlockActors=true 
    bWorldGeometry=false
    bPathColliding=true
    bCollideWorld=true 
    BlockRigidBody=true 
    Physics=PHYS_None
    bNoEncroachCheck=true
    bProjTarget=true

	/** Apply the tweo parts of the turret here as separate objects. */
	begin object class=UDKSkeletalMeshComponent name=TurretHead
		SkeletalMesh=SkeletalMesh'TA_WEAPONS.MiniGun_Head'
		BlockZeroExtent=true 
        BlockNonzeroExtent=true 
        BlockRigidBody=true
		Translation=(X=0,Y=0,Z=-105)
	end object

	MinigunTurretHead = TurretHead

	begin object class=UDKSkeletalMeshComponent name=TurretBase
		SkeletalMesh=SkeletalMesh'TA_WEAPONS.MiniGun_LEGS'
		Translation=(X=0,Y=0,Z=-105)
	end object

	begin object class=StaticMeshComponent name=barrel
		StaticMesh=StaticMesh'phystest_resources.RemadePhysBarrel'
		bAcceptsDynamicDecals=FALSE
//		bVisible=false;
//		bHidden=true;
//		Translation=(X=0,Y=0,Z=-64)
	end object



	/** END EDITOR HIGHLIGHTING */

	Components.Add(TurretHead);
	Components.Add(TurretBase);
	Components.Add(barrel);

	CollisionComponent=barrel
	turretBarrel = TurretHead
	turretStand = TurretBase
	ScanRadius=750f



	CollisionType=COLLIDE_BlockAll
	Begin Object Name=CollisionCylinder
		CollisionRadius=+0021.000000
		CollisionHeight=+00096.000000
	End Object

	CylinderComponent=CollisionCylinder


	roll = 0;
	pitch = 0;
	yaw = 0;

	MuzzleFlashPSCTemplate = ParticleSystem'TestPackage.Effects.DefaultMuzzleFlash2'

	rotateRight = true;
	placed = false;

	Mesh = TurretHead
	standardMaterial=Material'TA_WEAPONS.MiniGun_MAT'

	BarrelComp = barrel

	Health=25
}
