/** Determine where the humans are going to run to when the boss is activated **/
class TAHumanEndPoint extends NavigationPoint placeable;
	
DefaultProperties
{
		begin object class=SpriteComponent name=EditorSpriteIndicator
			Sprite=Texture2D'sprites.human_end_point'
			HiddenGame=true
			HiddenEditor=false
		end object
		Components.Add(EditorSpriteIndicator);
}
