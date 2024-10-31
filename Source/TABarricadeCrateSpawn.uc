class TABarricadeCrateSpawn extends trigger placeable;

var TABarricadeCrate Crate;
var TAPlayerController Controller;
var TABarricade Barricade;

var float CurrentRespawnTime;
const RESPAWN_COOLDOWN = 10.0f;

var bool ShowingSpawnBar;

function Create()
{
	Crate = Spawn(class'TABarricadeCrate',,,Location);
	Crate.Spawner = self;
}

function Update(float deltaTime)
{
	// If there isn't a crate waiting, a hero isn't carrying it and it isn't already placed

	if (Barricade != none)
	{
		if (Barricade.Health < 0)
		{
			Barricade.Destroy();
			Barricade = None;
		}
	}

	if (Crate == None && Controller == None && Barricade == None)
	{
		CurrentRespawnTime += deltaTime;
		ShowingSpawnBar = true;
	}
	else
	{
		CurrentRespawnTime = 0;
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
		Sprite=Texture2D'EnvyEditorResources.S_Player_Blue'
		SpriteCategoryName="PlayerStart"
	End Object

 	bCollideWhenPlacing = false
	bEdShouldSnap       = true
}
