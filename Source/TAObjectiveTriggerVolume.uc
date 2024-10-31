class TAObjectiveTriggerVolume extends TriggerVolume placeable;

var bool bIsTriggered;

var (ObjectiveTrigger) TAObjectiveTrigger LinkedTrigger;

simulated event Tick(float DeltaTime)
{
	super.Tick(DeltaTime);
}

simulated event Touch(Actor Other, PrimitiveComponent OtherComp, Vector HitLocation, Vector HitNormal)
{
	super.Touch(Other,OtherComp,HitLocation,HitNormal);

	`log(self.Name $ " :: has been touched for ObjectiveTrigger -> " $ LinkedTrigger.Name);

	// Only do this if the trigger that is linked to this volume is in fact active.
	if (LinkedTrigger.bActiveObjectiveTrigger)
	{
		LinkedTrigger.TriggerTouched(Other,OtherComp,HitLocation,HitNormal);
	}
}

DefaultProperties
{
}
