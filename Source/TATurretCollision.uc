class TATurretCollision extends StaticMeshActor placeable;

var StaticMeshComponent barrelMesh;

var Material standardMaterial;

var DynamicLightEnvironmentComponent LightEnvironment;

simulated function PostBeginPlay()
{
	
}

function DoThisShit()
{
	
	//barrelMesh.SetHidden(true);
	barrelMesh.SetLightEnvironment(LightEnvironment);
	barrelMesh.SetMaterial(0, standardMaterial);
}

DefaultProperties
{

	bCollideActors=true 
    bBlockActors=true

Begin Object class=StaticMeshComponent name=Mesh
	StaticMesh=StaticMesh'phystest_resources.RemadePhysBarrel'
	Scale=0.75
	CollideActors=true 
    BlockActors=true 
    BlockZeroExtent=true 
    BlockNonzeroExtent=true 
    BlockRigidBody=true 
	bAcceptsDynamicDecals=FALSE
End Object

	CollisionComponent=Mesh
	Components.Add(Mesh)
	bStatic=false
	bNoDelete = false

	barrelMesh=Mesh

	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bSynthesizeSHLight=TRUE
		bIsCharacterLightEnvironment=TRUE
		bUseBooleanEnvironmentShadowing=FALSE
		InvisibleUpdateTime=1
		MinTimeBetweenFullUpdates=.2
		AmbientGlow=(R=.01,G=.01,B=.01,A=1)
		AmbientShadowColor=(R=0.15,G=0.15,B=0.15)
	End Object
	Components.Add(MyLightEnvironment)

	standardMaterial=Material'TestPackage.Bar_Mat'
	LightEnvironment=MyLightEnvironment
}