class TALabDoorTriggerVolume extends TriggerVolume;

var(LabDoors) TALabDoor FirstDoor;
var(LabDoors) TALabDoor OptionalDoor;

var int pawnCount;

event Touch (Actor Other, PrimitiveComponent OtherComp, Object.Vector HitLocation, Object.Vector HitNormal)
{
	if(TAPawn(Other) != none)
	{
		//`log("Enter" $ pawnCount);
		pawnCount++;
		//`log("Entered");

		if(pawnCount == 1)
		{
			FirstDoor.StartOpen();
			if(OptionalDoor != none)
			{
				OptionalDoor.StartOpen();
			}
		}
	}
}

event UnTouch (Actor Other)
{
	if(TAPawn(Other) != none)
	{
		//`log("Exit" $ pawnCount);
		pawnCount--;
		//`log("Exited");

		if(pawnCount <= 0)
		{
			FirstDoor.StartClose();
			if(OptionalDoor != none)
			{
				OptionalDoor.StartClose();
				pawnCount = 0;
			}
		}
		if(pawnCount < 0)
		{
			pawnCount = 0;
		}
	}
}

DefaultProperties
{
	pawnCount = 0;
}
