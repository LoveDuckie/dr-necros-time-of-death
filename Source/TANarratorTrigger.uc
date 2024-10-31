class TANarratorTrigger extends TriggerVolume;

var() SoundCue SoundCue;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
}

simulated event Tick(float DeltaTime)
{
	super.Tick(DeltaTime);
}

simulated event Touch(Actor Other, PrimitiveComponent OtherComp, Vector HitLocation, Vector HitNormal)
{
	super.Touch(Other,OtherComp,HitLocation,HitNormal);

	//TAGame(WorldInfo.Game).Broadcast(self, "TOUCHED " $ self);

	if (TAHero(Other) != none)
	{
		TAGame(WorldInfo.Game).NarratorManager.TriggerTouched(SoundCue);
	}
}

DefaultProperties
{

}
