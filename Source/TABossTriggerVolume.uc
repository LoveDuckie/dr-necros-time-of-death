class TABossTriggerVolume extends TriggerVolume;

var bool bStarted;

var(Doors) TAMainDoor leftDoor;
var(Doors) TAMainDoor rightDoor;

var(Gates) TAMainGate leftGate;
var(Gates) TAMainGate rightGate;

var(Spawn) TAPlayerStart newMainSpawn;

var (Humans) array<TAHuman> humansToSendAway;
var bool bHumansStillFleeing; // determine whether or not the humans are still running away from the scene.


event Touch (Actor Other, PrimitiveComponent OtherComp, Object.Vector HitLocation, Object.Vector HitNormal)
{
	local int i;

	if (!bStarted)
	{
		if (TAHero(Other) != none)
		{
			bStarted = true;
			TAGame(WorldInfo.Game).ConsoleCommand("MOVIETEST TABoss_11");
			
			// Make sure that the array is in fact valid.
			if (humansToSendAway.Length > 0)
			{
				// Loop through the humans and send them off.
				for(i = 0; i < humansToSendAway.Length; i++)
				{
					`log("Sending humans to next point.");
					humansToSendAway[i].SendOutOfGame();
				}
			}

			TAGame(WorldInfo.Game).SPawnBoss();
		}
	}

	TAGame(WorldInfo.Game).mainSpawn = newMainSpawn;
}

function CloseMainDoors()
{
	//`log(Closing);
	rightDoor.StartClose(true);
	leftDoor.StartClose(false);
}

function OpenMainDoors()
{
	rightDoor.StartOpen(true);
	leftDoor.StartOpen(false);
}

function CloseMainGates()
{
	//`log(Closing);
	rightGate.StartClose(true);
	leftGate.StartClose(false);
}

function OpenMainGates()
{
	rightGate.StartOpen(true);
	leftGate.StartOpen(false);
}

defaultproperties
{

}