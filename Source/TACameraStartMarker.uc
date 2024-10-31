// ---------------------------------------------------------------------------------------------
//  Determines the location and rotation of the camera that is shown when new players 
//  are currently active in the map.
// ---------------------------------------------------------------------------------------------
class TACameraStartMarker extends NavigationPoint
	placeable
	ClassGroup(Common)
	hidecategories(Collision);

DefaultProperties
{
	Begin Object NAME=Sprite LegacyClassName=SpawnManager_SpawnManagerSprite_Class
		Sprite=Texture2D'EditorResources.Proj_IconMasked'
		SpriteCategoryName=""
	End Object

 	bCollideWhenPlacing = false
	bEdShouldSnap       = true
	bStatic             = false;

}
