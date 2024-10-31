class TABarricade extends TAPlaceableThing placeable;

var Material standardMaterial;
var CylinderComponent BBounds;
var StaticMeshComponent TouchMeshComp;
var StaticMeshComponent BarricadeMesh;

var int BarricadeHealth;

var bool canPlace;

var TABarricadeLocator locator;

simulated event PostBeginPlay()
{
	TOuchMeshCOmp.SetHidden(True);
	BarricadeMesh.SetLightEnvironment(LightEnvironment);
}
//Comment to force update
//Receives damage, if destroyed, destroy...

event Touch (Actor Other, PrimitiveComponent OtherComp, Object.Vector HitLocation, Object.Vector HitNormal)
{
	//TAGame(WorldInfo.Game).Broadcast(self, Other$" just touched my privates");
}

function SetRed()
{
	local Material mat;
	mat = Material'TestPackage.RedBarricade';
	BarricadeMesh.SetMaterial(0, mat);
	//SetPhysics(PHYS_None);
}

function SetBlue()
{
	local Material mat;
	mat = Material'TestPackage.BlueBarricade';
	BarricadeMesh.SetMaterial(0, mat);
}

function SetGreen()
{
	local Material mat;
	mat = Material'TestPackage.GreenBarricade';
	BarricadeMesh.SetMaterial(0, mat);
	
}

function SetStandard()
{
	BarricadeMesh.SetMaterial(0, standardMaterial);
	SetCollision(true,true,true);
	SetPhysics(PHYS_Interpolating);
}

DefaultProperties
{
	//Had an issue with collison after placing the barricade
	bCanStepUpOn=false 
    bCollideActors=true 
    bBlockActors=true    

	Begin Object Class=StaticMeshComponent Name=StaticMC
		StaticMesh=StaticMesh'TA_ENVIRONMENT.Barricade'
		
		RBCollideWithChannels=(Default=TRUE,BlockingVolume=TRUE,GameplayPhysics=FALSE,EffectPhysics=FALSE) 
		        
		CollideActors=true 
        BlockActors=true 
        BlockZeroExtent=true 
        BlockNonzeroExtent=true 
        BlockRigidBody=true 
        Translation=(X=0,Y=0,Z=-95)
		
	End Object
	Components.Add(StaticMC)
	BarricadeMesh = StaticMC;

	Begin Object Class=StaticMeshComponent Name=TouchMesh
		StaticMesh=StaticMesh'ASC_Deco.SM.Mesh.S_ASC_Deco_SM_Trim02'
//		bHidden = true;
//		bVisible = false;
		RBCollideWithChannels=(Default=TRUE,BlockingVolume=TRUE,GameplayPhysics=FALSE,EffectPhysics=FALSE) 
        CollideActors=true 
        BlockActors=true 
        Scale=1.1;
        BlockZeroExtent=true 
        BlockNonzeroExtent=true 
        BlockRigidBody=true 
        
		
	End Object

	Components.Add(TouchMesh);
	TouchMeshComp = TouchMesh;

	Begin Object Name=MyLightEnvironment
		bSynthesizeSHLight=TRUE
		bIsCharacterLightEnvironment=TRUE
		bUseBooleanEnvironmentShadowing=FALSE
		InvisibleUpdateTime=1
		MinTimeBetweenFullUpdates=.2
		AmbientGlow=(R=.01,G=.01,B=.01,A=1)
		AmbientShadowColor=(R=0.15,G=0.15,B=0.15)
	End Object
	Components.Add(MyLightEnvironment)
	LightEnvironment=MyLightEnvironment

	CollisionComponent=StaticMC

	standardMaterial=Material'TA_ENVIRONMENT.Barricade_Diffuse_Mat'
	Health = 500;
}
