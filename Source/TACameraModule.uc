class TACameraModule extends Object
	abstract
	config(Camera);
	

var transient TAPlayerCamera PlayerCamera;

function Init();

function OnBecomeActive( TACameraModule oldCamera );
function OnBecomeInActive ( TACameraModule newCamera);

function UpdateCamera(Pawn P, TAPlayerCamera CameraActor, float deltaTime, out TViewTarget OutVT);

simulated function BecomeViewTarget (TAPlayerController PC);

function ZoomIn();

function ZoomOut();

defaultproperties
{
}
