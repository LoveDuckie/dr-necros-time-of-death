class TABarricadeLocator extends trigger placeable;

var() Rotator barricadeRotation;

var bool hasBarricade;

var TABarricade tempBarricade;

DefaultProperties
{


	Begin Object NAME=Sprite LegacyClassName=PlayerStart_PlayerStartSprite_Class
		Sprite=Texture2D'EnvyEditorResources.S_Player_Blue'
		SpriteCategoryName="PlayerStart"
	End Object

	Begin Object Class=StaticMeshComponent Name=SpawnDirectionPointer
		StaticMesh = StaticMesh'TA_ENVIRONMENT.Barricade'
		Materials[0] = Material'TestPackage.BlueBarricade';
		HiddenGame=true
		HiddenEditor=false
		Rotation = (Roll=0, Pitch=0, Yaw=0);
		Translation = (X=0, Y=0,Z=0);
	End Object

	Components.Add(SpawnDirectionPointer);

//	CollisionType=COLLIDE_BlockNone

 	bCollideWhenPlacing = false
	bEdShouldSnap       = true

	hasBarricade = false;
}
