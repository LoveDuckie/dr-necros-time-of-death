class TAPlayerCamera extends Camera;


var TACameraAverageMarker AverageMarker;
// Map settings reference, we use this to get per-map camera settings.
var TAMapSettings MapSettings;

// Actors that are hidden by transparency.
struct TransparencyActor
{
	var Actor Actor;
	var float Opacity;
	var bool  BlockingCamera;
};
var array<TransparencyActor> TransparentActors;
const TRANSPARENCY_ACTOR_INCREMENT = 0.05f;
const TRANSPARENCY_ACTOR_OPACITY_MIN = 0.25f;

// Current "zoom-level" / distance from ground.
var float CameraDistance;

var Vector  centerPosition;

/** shaking */
var bool bCameraShake;
var float cameraShakeTimer;
var vector cameraShakePosition;

var Material solidMaterial;
var Material fadeMaterial;

var bool bFirstPass;

// Invoked before the game starts - we grab map information during this.
simulated event PostBeginPlay()
{	
	MapSettings = TAMapSettings(WorldInfo.GetMapInfo());

	// Setting references up for the game camera.
	if (TAGame(WorldInfo.Game).GameCamera == None)
	{
		TAGame(WorldInfo.Game).GameCamera = self;

	}
	AverageMarker = SPawn(class'TACameraAverageMarker');
	ConsoleCommand("ShowHUD");
	bFirstPass = true;
}

function CameraShake(float duration)
{
	bCameraShake = true;
	cameraShakeTimer = duration;
}

event tick(Float deltaTime)
{
	if (bCameraShake)
	{		
		cameraShakePosition.X = (FRand() * 300.f) * (FRand() < 0.5 ? -1 : 1) * cameraShakeTimer;
		cameraShakePosition.Y = (FRand() * 300.f) * (FRand() < 0.5 ? -1 : 1) * cameraShakeTimer;

		cameraShakeTimer -= deltaTime;
		if (cameraShakeTimer <= 0.f)
		{
			bCameraShake = false;
			cameraShakePosition = vect(0,0,0);
		}
	}
}

// Works out if all players are inside the screen boundries.
function bool PlayersOutOfScreenBounds(Canvas canvas, float buffer)
{
	local TAHero  hero;
	local Vector  heroScreenSpaceLocation;
	local Vector  minScreenSpace;
	local Vector  maxScreenSpace;
	local bool    bPlayersOutOfBounds;

	// Work out screen space locations of all players.
	foreach WorldInfo.AllPawns(class'TAHero', hero)
	{
		if (hero.Controller == none || TAPlayerController(hero.Controller).IsPlayerInGame == false || TAPlayerController(hero.Controller).IsActiveInGame == false)
		{
			continue;
		}

		heroScreenSpaceLocation = canvas.Project(hero.Location);

		if (heroScreenSpaceLocation.X < minScreenSpace.X || minScreenSpace.X == 0)
		{
			minScreenSpace.X = heroScreenSpaceLocation.X;
		}
		if (heroScreenSpaceLocation.X > maxScreenSpace.X || maxScreenSpace.X == 0)
		{
			maxScreenSpace.X = heroScreenSpaceLocation.X;
		}
		if (heroScreenSpaceLocation.Y < minScreenSpace.Y || minScreenSpace.Y == 0)
		{
			minScreenSpace.Y = heroScreenSpaceLocation.Y;
		}
		if (heroScreenSpaceLocation.Y > maxScreenSpace.Y || maxScreenSpace.Y == 0)
		{
			maxScreenSpace.Y = heroScreenSpaceLocation.Y;
		}
	}

	// Players outside the bounds?
	bPlayersOutOfBounds = false;
	if (minScreenSpace.X < buffer || 
		minScreenSpace.Y < buffer ||
		maxScreenSpace.X > canvas.SizeX - buffer ||
		maxScreenSpace.Y > canvas.SizeY - buffer)
	{
		bPlayersOutOfBounds = true;
	}   

	return bPlayersOutOfBounds;	
}

// Invoked after rendering the camera. We use this to work our hero positions 
// and deproject them into screen space. This is used by the camera system.
function CalculateBounds(Canvas canvas)
{
	local float  zoomSpeed;
	local float  zoomPercent;
	local float  zoomMultiplier;
	local TAHero hero;
	local int    heroCount;

	// Don't zoom in or out if no heros are playing.
	foreach WorldInfo.AllPawns(class'TAHero', hero)
	{
		if (hero.Controller == none || TAPlayerController(hero.Controller).IsPlayerInGame == false || TAPlayerController(hero.Controller).IsActiveInGame == false)
		{
			continue;
		}
		heroCount++;
	}

	if (heroCount <= 0)
	{
		return;
	}

	// Work out zoom speed.
	// It increases the further we get away
	// Otherwise it looks jerky (close camera + large zoom speed = jerky, far away camera + large zoom speed = smooth, etc).
	zoomPercent     = (CameraDistance - MapSettings.CameraMinCameraDistance) / (MapSettings.CameraMaxCameraDistance - MapSettings.CameraMinCameraDistance);
	zoomMultiplier  = fmax(0.4f, fmin(1.0f, zoomPercent * 1.5f));
	zoomSpeed       = MapSettings.CameraZoomSpeed * zoomMultiplier;

	// Zoom Out
	if (PlayersOutOfScreenBounds(canvas, MapSettings.CameraZoomInPixelBuffer) == true)
	{
		CameraDistance = fmin(MapSettings.CameraMaxCameraDistance, CameraDistance + zoomSpeed);
	}

	// Zoom In
	else if (PlayersOutOfScreenBounds(canvas, MapSettings.CameraZoomOutPixelBuffer) == false)
	{
		CameraDistance = fmax(MapSettings.CameraMinCameraDistance, CameraDistance - zoomSpeed);
	}
}

// Invoked each frames - Calculates the correct position/rotation/etc we need to use for this camera.
function UpdateViewTarget(out TViewTarget OutVT, float DeltaTime)
{
	local TAHero                hero;
	local bool                  centerCameraOnMarker;
	local TAHuman               human;
	local TAPlayerController    playerController;
	local int                   heroCount;
	local int                   playerControllerCount;
	local Vector                cameraPosition;
	local Rotator               cameraRotation;
	local TACameraStartMarker   marker;

	centerPosition.X = 0;
	centerPosition.Y = 0;
	centerPosition.Z = 0;

	// Calculate the point in the middle of the players that we will be aiming at.
	foreach WorldInfo.AllPawns(class'TAHero', hero)
	{
		if (hero.Controller == none || TAPlayerController(hero.Controller).IsPlayerInGame == false || TAPlayerController(hero.Controller).IsActiveInGame == false)
		{
			continue;
		}

		centerPosition += (hero.bGrabbed ? hero.bossRef.Location : hero.Location);
		heroCount++;
	}

	// Any players in game.
	foreach WorldInfo.AllControllers(class'TAPlayerController', playerController)
	{
		if (playerController.IsPlayerInGame == true && playerController.IsSelectingCharacter == false)
		{
			playerControllerCount++;
		}
	}

	// No heros spawned? Just do a pretty top-down view.
	if (heroCount <= 0)
	{
		centerCameraOnMarker = true;

		// If there are players in game, and we are just all respawning, center on middle of humans.
		if (playerControllerCount > 0)
		{
			centerPosition.X = 0;
			centerPosition.Y = 0;
			centerPosition.Z = 0;
			heroCount = 0;

			foreach WorldInfo.AllPawns(class'TAHuman', human)
			{
				if (human.Health > 0)
				{
					centerPosition += human.Location;
					heroCount++;
				}
			}

			if (heroCount > 0)
			{
				centerCameraOnMarker = false;
			}
		}

		// Else nobody is in game so just show pretty screen of front door :3
		if (centerCameraOnMarker == true)
		{
			foreach WorldInfo.AllActors(class'TACameraStartMarker', marker)
			{
				OutVT.POV.FOV = DefaultFOV;
				if (bFirstPass) //terrrain hack
				{
					OutVT.POV.Location = vect(8000,8000,8000);
					bFirstPass = false;
				}
				OutVT.POV.Location = marker.Location;
				OutVT.POV.Rotation = marker.Rotation;	

				//HideStaticBasedOnCamLocation(marker.Location);

				return;
			}



			cameraRotation.Pitch = (-45  * DegToUnrRot);
			cameraRotation.Yaw   = 0;
			cameraRotation.Roll  = 0;
			cameraPosition       = vect(-1500, -1550, 3000);

			OutVT.POV.FOV = DefaultFOV;

			OutVT.POV.Location = cameraPosition;
			OutVT.POV.Rotation = cameraRotation;	

			//HideStaticBasedOnCamLocation(cameraPosition);

			return;
		}
	}

	// Average the position to get the actual center.
	centerPosition /= heroCount;

	AverageMarker.SetLocation(centerPosition);

	// Work out camera rotation.
	cameraRotation.Pitch = (MapSettings.CameraRotation.Pitch * DegToUnrRot);
	cameraRotation.Yaw   = (MapSettings.CameraRotation.Yaw   * DegToUnrRot);
	cameraRotation.Roll  = (MapSettings.CameraRotation.Roll  * DegToUnrRot);

	// Move the camera back from the position.
	cameraPosition = centerPosition - (Vector(cameraRotation) * CameraDistance);

	// Setup the output view target.	
	OutVT.POV.FOV = DefaultFOV;	
	OutVT.POV.Location = cameraPosition + cameraShakePosition;
	OutVT.POV.Rotation = cameraRotation;	
}



// Default settings of all fields.
DefaultProperties
{
	DefaultFOV          = 90.f
	CameraDistance      = 600.0f;
	CameraStyle = ThirdPerson;
}
