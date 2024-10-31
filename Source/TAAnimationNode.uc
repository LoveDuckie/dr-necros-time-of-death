class TAAnimationNode extends AnimNodeSequence;

var() bool bPlayFromStart;
var() bool bPlayOnRelevance;

event OnBecomeRelevant() 
{
	if (bPlayFromStart)  
	{
		SetPosition(0.0f, false);
	}
}

defaultproperties 
{
	bPlayFromStart=true;
	bPlayOnRelevance = true;
	bCallScriptEventOnBecomeRelevant=TRUE
}