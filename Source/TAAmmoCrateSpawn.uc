class TAAmmoCrateSpawn extends trigger placeable;

var TAAmmoCrate Crate;

var float CurrentRespawnTime;
const RESPAWN_COOLDOWN = 30.0f;

var bool ShowingSpawnBar;

function Create()
{
	Crate = Spawn(class'TAAmmoCrate',,,Location);
	Crate.Spawner = self;
}

function Update(float deltaTime)
{
	// If there isn't a crate waiting
	if (Crate == None)
	{
		CurrentRespawnTime += deltaTime;
		ShowingSpawnBar = true;
	}
	else
	{
		ShowingSpawnBar = false;
	}	

	if (CurrentRespawnTime > RESPAWN_COOLDOWN)
	{
		Create();
		CurrentRespawnTime = 0;
		ShowingSpawnBar = false;
	}
}

DefaultProperties
{
	Begin Object NAME=Sprite LegacyClassName=PlayerStart_PlayerStartSprite_Class
		Sprite=Texture2D'EnvyEditorResources.S_Player_Red'
		SpriteCategoryName="PlayerStart"
	End Object

 	bCollideWhenPlacing = false
	bEdShouldSnap       = true
}
