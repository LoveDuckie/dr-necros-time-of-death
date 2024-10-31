class TATargetRing extends Actor;

var StaticmeshComponent TargetMesh;

defaultproperties
{
	Begin Object Class=StaticMeshComponent Name=TargettedRing
		StaticMesh = StaticMesh'TA_ENVIRONMENT.PlayerTargetRing'
		Rotation=(Roll=0, Pitch=0, Yaw=-16384);
		Translation=(X=0, Y=0, Z=-75);
		bAcceptsDynamicDecals=FALSE
	End Object

	Components.Add(TargettedRing);
	TargetMesh = TargettedRing;
}