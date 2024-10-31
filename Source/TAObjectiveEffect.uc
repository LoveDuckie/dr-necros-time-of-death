class TAObjectiveEffect extends DynamicSMActor_Spawnable 
								placeable
								hidecategories(Collision);

enum EffectType
{
	E_Light,
	E_Door,
	E_Explosion
};

var (ObjectiveEffect) TAObjectiveTrigger TriggerActor;
var (ObjectiveEffect) EffectType TypeOfEffect;

/** Activate the effect of the trigger */
function Activate(TAObjectiveTrigger other)
{
	// Ensure that the task is completed first before doing something
	if (other.bCompletedTask)
	{
		// Spawn some kind of effect in regards to the type that has been assigned to it.
		switch(TypeOfEffect)
		{
			case EffectType.E_Door:
				
			break;

			case EffectType.E_Explosion:
				
			break;

			case EffectType.E_Light:
				
			break;
		}
	}
}

event PostBeginPlay()
{

}

DefaultProperties
{

}
