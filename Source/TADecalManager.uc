class TADecalManager extends UTDecalManager;

// For determining how the particles are going to appear.

function bool CanSpawnDecals()
{
	return true;

	//return (!class'Engine'.static.IsSplitScreen() && Super.CanSpawnDecals());
}

DefaultProperties
{

}
