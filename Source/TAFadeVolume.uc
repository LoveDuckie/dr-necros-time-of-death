class TAFadeVolume extends TriggerVolume;

var int heroCount;

var() array<StaticMeshActor> fadeTargets;
// so two volumes can work together
var() TAFadeVolume partnerInCrime;

struct MeshMaterialPair
{
	var() StaticMeshActor meshActor;
	var() array<Material> resetMaterials;
	var() array<Material> switchMaterials;
};

var() instanced array<MeshMaterialPair> pairing;

event Touch(Actor Other, PrimitiveComponent OtherComp, Vector HitLocation, VEctor HitNormal)
{
	
	/** only switch if it's a hero */
	if (TAHero(Other) != None)
	{
		/** increase hero count */
		heroCount++;

		/** If working in conjunction with another volume, set their heroCount
			if ours is higher than theirs */
		if (partnerInCrime != none)
		{
			if (heroCount > partnerInCrime.heroCount)
			{
				partnerInCrime.heroCount = heroCount;
			}
		}	

		/** just to be anal about there being a hero in the volume */
		if (TAGame(WorldInfo.Game).TotalPlayers > 0)
		{
			Fade();
		}
	}
}

function Fade()
{
	local int i,j;
	if (heroCount > 0)
	{
		/** Loop through defined meshes */
		for (i = 0; i < pairing.Length; ++i)
		{						
			/** Loop through each material that the mesh has */
			for (j = 0; j < pairing[i].meshActor.StaticMeshComponent.GetNumElements(); ++j)
			{									
				/** Apply the material to the mesh */	
				pairing[i].meshActor.StaticMeshComponent.SetMaterial(j, pairing[i].switchMaterials[j]);
				`log("Setting Material");	
			}		
		}
	}
}

event UnTouch(Actor Other)
{
	local int i,j;

	/** Have we cached the opaque materials? No? Enable it */
	
	/** Only activate if it was a Player */
	if (TAHero(Other) != none)
	{
		heroCount--;
		/** If working with another volume, if our heroCount is higher, set their heroCount
			to our heroCount */
		if (partnerInCrime != none)
		{
			if (heroCount > partnerInCrime.heroCount)
			{
				partnerInCrime.heroCount = heroCount;
			}
		}	

		/** Again, I'm being anal about the hero count */
		/** Only triggers if *all* the heros have left the volume */
		if (heroCOunt <= 0)
		{
			/** Loop the meshes */
			
			/** Loop through defined meshes */
			for (i = 0; i < pairing.Length; ++i)
			{						
				/** Loop through each material that the mesh has */
				for (j = 0; j < pairing[i].meshActor.StaticMeshComponent.GetNumElements(); ++j)
				{								
					/** Apply the material to the mesh */	
					pairing[i].meshActor.StaticMeshComponent.SetMaterial(j, pairing[i].resetMaterials[j]);
					`log("Setting Material");	
				}		
			}
		}
		
	}
}