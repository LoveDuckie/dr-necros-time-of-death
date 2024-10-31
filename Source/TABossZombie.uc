class TABossZombie extends TAZombiePawn;

/** attacking bools - so the AnimTree knows which animation to play */
var bool bBasicAttack;
var bool bAirSlamAttack;
var bool bFloorSwipeAttack;
var bool bGroundPoundAttack;
var bool bPunchLeftAttack;
var bool bSummoning;

var bool bGrabbing;
var bool bThrowing;
var bool bGrabbingIdle;

var TAZombieBossController bossController;
var SkeletalMeshComponent BossMesh;

var CylinderComponent LHitBox;
var CylinderComponent RHitBox;

var vector lPos, lPosPrev;
var vector rPos, rPosPrev;

var vector grabPos;
var rotator grabRot;

var rotator rRot;
simulated event postbeginplay()
{
	bossController = Spawn(class'TAZombieBossController');
	bossController.PossessBoss(Self);

	SetPhysics(PHYS_Walking);
	// Need to override this shit so we dont have to call super.postbeginplay or breaky things happen	
	AttackAudioComponent = new class'AudioComponent';
	AttackAudioComponent.SoundCue = AttackSound;

	IdleAudioComponent = new class'AudioComponent';
	IdleAudioComponent.SoundCue = IdleSound;

	AttachComponent(AttackAudioComponent);
	AttachComponent(IdleAudioComponent);

	IdleAudioNextTime = RandRange(1, IdleAudioMaxTime);
}

function Die()
{
	bossCOntroller.Die();
}

simulated function SetLastObjective()
{
	// Determine that the reference is OK before assigning the last objective.
	if (ObjectiveManager != none)
	{
		ObjectiveManager.ActivateObjectiveTrigger("endgame"); // Manually activate the special end objective
	}
}

event TakeDamage(int DamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	super.TakeDamage(DamageAmount,EventInstigator, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);

	// Determine that the zombie boss is dead
	if (bIsDead)
	{
		`log("SetTimer SetLastObjective called!");
		SetTimer(2.0f,false,'SetLastObjective');
	}
}

simulated event tick (float deltatime)
{
	super.Tick(deltatime);

	lPosPrev = lPos;
	rPosPrev = rPos;

	BossMesh.GetSocketWorldLocationAndRotation('LeftHitBox',lPos);
	BossMesh.GetSocketWorldLocationAndRotation('RightHitBox',rPos, rRot);
	BossMesh.GetSocketWorldLocationAndRotation('GrabSocket',grabPos, grabRot);
}

defaultproperties
{
	ControllerClass=class'TeamAwesome.TAZombieBossController'

	//CylinderComponent=CollisionCylinder

	BEgin Object Name=SkeletalMeshComponent0
		SkeletalMesh=SkeletalMesh'TA_Characters.BossZombie'
		AnimSets[0] = AnimSet'TA_Characters.BossZombie_Anims'
		AnimTreeTemplate = AnimTree'TA_Characters.BossZombie_AnimTree'
		Scale = 1.5
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
		Translation=(X=0,Y=0,Z=-200)
	End Object

	BossMesh = SkeletalMeshComponent0

	/** Add the fist hit boxes */	

	Begin Object Class=CylinderComponent Name=RightHitBox
		CollisionRadius =+ 1
		CollisionHeight =+ 1.000
		bDrawNonColliding = true;
		CollideActors = true;
		BlockActors = false;
	End Object

	Begin Object Class=CylinderComponent Name=LeftHitBox
		CollisionRadius =+ 1
		CollisionHeight =+ 1
		bDrawNonColliding = true;
		CollideActors = true;
		BlockActors = false;
	End Object

	//Mass = 25000
	Mass = 25000

	Begin Object Name=CollisionCylinder
		CollisionRadius=+0025.000000
		CollisionHeight=+200.000000
	End Object

	Components.Add(RightHitBox);
	Components.Add(LeftHitBox);

	LHitBox = LeftHitBox;
	RHitBox = RightHitBox;

	/** stats */

	GroundSpeed = 400; //faster than anything else, well, because, he's bigger.

	Health = 5000;
	HealthMax = 5000;

	AttackSound = SoundCue'Sounds.ATTACK.BossAttack';
	IdleSound = SoundCue'Sounds.Idle.BossIdle';
} 