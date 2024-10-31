class TATurretLocator extends trigger placeable;

var() Rotator turretRotation;

var bool hasTurret;
var TATurret tempTurret;

DefaultProperties
{


	Begin Object NAME=Sprite LegacyClassName=PlayerStart_PlayerStartSprite_Class
		Sprite=Texture2D'EnvyEditorResources.S_Player_Blue'
		SpriteCategoryName="PlayerStart"
	End Object

	/** EDITOR HIGHLIGHTING */

	Begin Object Class=StaticMeshComponent Name=SpawnDirectionPointer
		StaticMesh = StaticMesh'CastleEffects.TouchToMoveArrow'
		HiddenGame=true
		HiddenEditor=false

		Rotation = (Roll=0, Pitch=-16384, Yaw=32768);
		Translation = (X=150, Y=0,Z=0);
	End Object

	begin object class=UDKSkeletalMeshComponent name=TurretHeadEditor
		SkeletalMesh=SkeletalMesh'TA_WEAPONS.MiniGun_Head'
		Materials[0] = Material'TestPackage.BlueBarricade';
		BlockZeroExtent=true 
        BlockNonzeroExtent=true 
        BlockRigidBody=true 

        HiddenGame=true
		HiddenEditor=false
	end object

	begin object class=UDKSkeletalMeshComponent name=TurretBaseEditor
		SkeletalMesh=SkeletalMesh'TA_WEAPONS.MiniGun_LEGS'
		Materials[0] = Material'TestPackage.BlueBarricade';

		HiddenGame=true
		HiddenEditor=false
	end object

	Components.Add(SpawnDirectionPointer);
	Components.Add(TurretBaseEditor);
	Components.Add(TurretHeadEditor);

//	CollisionType=COLLIDE_BlockNone

 	bCollideWhenPlacing = false
	bEdShouldSnap       = true

	hasTurret = false;
}
