class TAObjectiveArrow extends DynamicSMActor_Spawnable;

/** Members **/
var StaticMeshComponent ObjectiveAimRing;
var TAObjectiveTrigger TargetObjectiveTrigger;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();

	self.SetHidden(true);

		
}

event Tick(float DeltaTime)
{
	
	local Vector OwnerLocation;
	local Rotator TargetRotation;
	super.Tick(DeltaTime);
	
	if (Owner != none)
	{
		//`log("Owner is safe.");
		OwnerLocation = Owner.Location;
		self.SetLocation(OwnerLocation);

		if (!TAHero(Owner).bIsActive)
		{
			self.SetHidden(true);
		}
	}
	
	// Rotate the arrow if the target is not equal to none.
	if (TargetObjectiveTrigger != none)
	{
		TargetRotation = Rotator(TargetObjectiveTrigger.Location - Location);
		TargetRotation.Pitch = 0; // Stop it from tilting awkwardly and then falling into the flaw.
		self.SetRotation(TargetRotation);
	}

}

DefaultProperties
{
	Begin Object Class=StaticMeshComponent name=ObjectiveRing
		StaticMesh = StaticMesh'TA_ENVIRONMENT.ObjectiveArrow'
		Rotation=(Roll=0, Pitch=0, Yaw=-16384);
		Translation=(X=0, Y=0, Z=-95);
		Scale3D=(X=3,Y=3,Z=3);
		bAcceptsDynamicDecals=FALSE
	End Object

	Components.Add(ObjectiveRing);
	ObjectiveAimRing=ObjectiveRing
	StaticMeshComponent=ObjectiveRing
}
