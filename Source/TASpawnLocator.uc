class TASpawnLocator extends Actor;

function LocateNearestSpawn(TAPlayerCamera GameCamera)
{
		local TAPlayerStart playerSpawn;
		local TAPlayerStartOutside playerSpawnOutside;
		local TAPlayerStart nearestPlayerSpawn;
		local TAPlayerStartOutside nearestPlayerSpawnOutside;
		local Vector playerAverage;
		local int distance;
		local int shortestDistance;
		local TAPlayerController pc;
		local bool livingPlayer;

		livingPlayer = false;
		
		foreach AllActors(class'TAPlayerController', pc)
		{
			if (TAHero(pc.Pawn).bIsActive)
			{
				livingPlayer = true;
			}
		}

		//if(TAHero(pc.Pawn).bIsActive == true)
		if(!TAGame(WorldInfo.Game).bFightingBoss)
		{
			if(livingPlayer)
			{
				//livingPlayer = true;
				shortestDistance = 20000;
				playerAverage = GameCamera.centerPosition;

				foreach AllActors(class'TAPlayerStart', playerSpawn)
				{					
					distance = VSize(playerSpawn.Location - playerAverage);
					playerSpawn.bPrimaryStart = false;
					playerSpawn.bEnabled = false;
					if(distance < shortestDistance)
					{
						shortestDistance = distance;
						nearestPlayerSpawn = playerSpawn;
					}
				}
				//`log("Closest is"$nearestPlayerSpawn);
				nearestPlayerSpawn.bEnabled = true;
				nearestPlayerSpawn.bPrimaryStart = true;
				//break;
			}
			else
			{
				foreach AllActors(class'TAPlayerStart', playerSpawn)
				{
					playerSpawn.bPrimaryStart = false;
					playerSpawn.bEnabled = false;
				}
				TAGame(WorldInfo.Game).mainSpawn.bEnabled = true;
				TAGame(WorldInfo.Game).mainSpawn.bPrimaryStart = true;
			}
		}
		else
		{
			//`log("eoeoeoeoeoeoeo");
			if(livingPlayer)
			{
			//livingPlayer = true;
			shortestDistance = 20000;
			playerAverage = GameCamera.centerPosition;

			foreach AllActors(class'TAPlayerStartOutside', playerSpawnOutside)
			{					
				distance = VSize(playerSpawnOutside.Location - playerAverage);
				playerSpawnOutside.bPrimaryStart = false;
				playerSpawnOutside.bEnabled = false;
				if(distance < shortestDistance)
				{
					shortestDistance = distance;
					nearestPlayerSpawnOutside = playerSpawnOutside;
				}
			}
			//`log("Closest is"$nearestPlayerSpawn);
			nearestPlayerSpawnOutside.bEnabled = true;
			nearestPlayerSpawnOutside.bPrimaryStart = true;
			//break;
			}
			else
			{
				foreach AllActors(class'TAPlayerStartOutside', playerSpawnOutside)
				{
					playerSpawn.bPrimaryStart = false;
					playerSpawn.bEnabled = false;
				}
				TAGame(WorldInfo.Game).mainSpawn.bEnabled = true;
				TAGame(WorldInfo.Game).mainSpawn.bPrimaryStart = true;
			}
		}
		//`log(nearestPlayerSpawn);
		//`log(nearestPlayerSpawn.bEnabled);
}

DefaultProperties
{

}
