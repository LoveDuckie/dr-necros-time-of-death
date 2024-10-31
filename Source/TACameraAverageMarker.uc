class TACameraAverageMarker extends TAPawn;

/** this class is merely for the sake of zombie pathfinding if it can't find anyone */
simulated event postBeginPlay() {}
simulated event Tick(float deltaTime) {}


defaultproperties
{
	Components.Empty;
	CollisionCOmponent = none
}