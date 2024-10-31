class TATurretCrateSpawn extends trigger placeable;

var TATurretCrate Crate;
var TAPlayerController Controller;
var TATurret Turret;

var float CurrentRespawnTime;
const RESPAWN_COOLDOWN = 30.0f;

var bool ShowingSpawnBar;

function Create()
{
	Crate = Spawn(class'TATurretCrate',,,Location);
	Crate.Spawner = self;
}

function Update(float deltaTime)
{
	// If there isn't a crate waiting, a hero isn't carrying it and it isn't already placed

	if (Turret != none)
	{
		if (Turret.Health < 0)
			Turret = None;
	}

	if (Crate == None && Controller == None && Turret == None)
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
