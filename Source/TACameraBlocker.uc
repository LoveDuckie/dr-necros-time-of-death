class TACameraBlocker extends BlockingVolume;

simulated event PostBeginPlay()
{
	CollisionComponent.SetScale(1);
}

defaultproperties
{
	bStatic = false;
	bNoDelete = false;


}