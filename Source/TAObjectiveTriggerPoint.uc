class TAObjectiveTriggerPoint extends NavigationPoint;


/*
 * Simple class that is used for determining where objective triggers are going to point for the player.
 */
DefaultProperties
{
	Begin Object NAME=CollisionCylinder
		CollisionRadius=+00040.000000
		CollisionHeight=+00080.000000
	End Object

	Begin Object NAME=Sprite LegacyClassName=PlayerStart_PlayerStartSprite_Class
		Sprite=Texture2D'EnvyEditorResources.S_Player_Blue'
		SpriteCategoryName="PlayerStart"
	End Object

 	bCollideWhenPlacing = false
	bEdShouldSnap       = true
}
