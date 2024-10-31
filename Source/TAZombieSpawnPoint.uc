// ---------------------------------------------------------------------------------------------
//  Used in conjunction with the TAZombieSpawnManager to spawn
//  zombies in waves at set points around the map.
// ---------------------------------------------------------------------------------------------
class TAZombieSpawnPoint extends NavigationPoint
	placeable
	ClassGroup(Common)
	hidecategories(Collision);

/* If the player is closer than this distance this spawn point will be blocked. */
const MIN_BLOCK_DISTANCE = 128.0f;

/* If set to true, then this spawn point will not be used */
var (Spawning) bool   bIsBlocked;

// ---------------------------------------------------------------------------------------------
//  Once per frame invokation - we do here is check our blocked state.
// ---------------------------------------------------------------------------------------------
event Tick(float deltaTime)
{
	local float closestHeroDistance;
	local float distance;
	local TAHero hero;

	// Find closest hero.
	foreach AllActors(class'TAHero', hero)
	{
		distance = vsize(hero.Location - self.Location);

		if (closestHeroDistance == 0 || distance < closestHeroDistance)
		{
			closestHeroDistance = distance;
		}
	}

	// Make ourselves blocked if player is on top of us?
	bIsBlocked = (closestHeroDistance < MIN_BLOCK_DISTANCE);
}

// ---------------------------------------------------------------------------------------------
// This class does exactly jack and shit. All the real work goes on in TAZombieSpawnManager,
// this class is just used to mark positions for zombies to spawn at.
// ---------------------------------------------------------------------------------------------
DefaultProperties
{
	Begin Object NAME=CollisionCylinder
		CollisionRadius=+00040.000000
		CollisionHeight=+00080.000000
	End Object

	Begin Object Class=StaticMeshComponent Name=SpawnDirectionPointer
		StaticMesh = StaticMesh'CastleEffects.TouchToMoveArrow'
		HiddenGame=true
		HiddenEditor=false

		Rotation = (Roll=0, Pitch=-16384, Yaw=32768);
		Translation = (X=150, Y=0,Z=0);
	End Object

	Components.Add(SpawnDirectionPointer);

	Begin Object NAME=Sprite LegacyClassName=PlayerStart_PlayerStartSprite_Class
		Sprite=Texture2D'Sprites.zombie_spawn_locator'
		SpriteCategoryName="Crowd"
	End Object

 	bCollideWhenPlacing = false
	bEdShouldSnap       = true
	bStatic             = false
	bBlocked = true

	bIsBlocked          = false

}
