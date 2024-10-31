class TALabDoor extends DynamicSMActor placeable;

var(Direction) bool north, south, east, west;
var bool opening, closing;
var vector tempPosition, startPosition;
var int desiredChange, positionChange, moveAmount;

simulated event PostBeginPlay()
{
	tempPosition = self.Location;
	startPosition = self.Location;
}

simulated event Tick(float deltatime)
{
	if(closing && !opening)
	{
		tempPosition = self.Location;
		if(south)
		{
			tempPosition.X += moveAmount;
		
			self.SetLocation(tempPosition);
			if(self.Location.X == (startPosition.X))
			{
				closing = false;
			}
			if(self.Location.X > (startPosition.X))
			{
				tempPosition.X = (startPosition.X);
				self.SetLocation(tempPosition);
			}
		}
		if(north)
		{
			tempPosition.X -= moveAmount;
		
			self.SetLocation(tempPosition);
			if(self.Location.X == (startPosition.X))
			{
				closing = false;
			}
			if(self.Location.X < (startPosition.X))
			{
				tempPosition.X = (startPosition.X);
				self.SetLocation(tempPosition);
			}
		}
		if(west)
		{
			tempPosition.Y += moveAmount;
		
			self.SetLocation(tempPosition);
			if(self.Location.Y == (startPosition.Y))
			{
				closing = false;
			}
			if(self.Location.Y > (startPosition.Y))
			{
				tempPosition.Y = (startPosition.Y);
				self.SetLocation(tempPosition);
			}
		}
	}
	else if(opening)
	{
		tempPosition = self.Location;
		if(south)
		{
			tempPosition.X -= moveAmount;
		
			self.SetLocation(tempPosition);
			if(self.Location.X == (startPosition.X - desiredChange))
			{
				opening = false;
			}
			if(self.Location.X < (startPosition.X - desiredChange))
			{
				tempPosition.X = (startPosition.X - desiredChange);
				self.SetLocation(tempPosition);
			}
		}
		else if(north)
		{
			tempPosition.X += moveAmount;
		
			self.SetLocation(tempPosition);
			if(self.Location.X == (startPosition.X + desiredChange))
			{
				opening = false;
			}
			if(self.Location.X > (startPosition.X + desiredChange))
			{
				tempPosition.X = (startPosition.X + desiredChange);
				self.SetLocation(tempPosition);
			}
		}
		else if(west)
		{
			tempPosition.Y -= moveAmount;
		
			self.SetLocation(tempPosition);
			if(self.Location.Y == (startPosition.Y - desiredChange))
			{
				opening = false;
			}
			if(self.Location.Y < (startPosition.Y - desiredChange))
			{
				tempPosition.Y = (startPosition.Y - desiredChange);
				self.SetLocation(tempPosition);
			}
		}
	}
}

function StartClose()
{
	closing = true;
	opening = false;
}

function StartOpen()
{
	opening = true;
	closing = false;
}

DefaultProperties
{
	Begin Object Class=StaticMeshComponent Name=DoorMeshComp
		StaticMesh=StaticMesh'TA_ENVIRONMENT.lab.LAB_Door'
		RBCollideWithChannels=(Default=TRUE,BlockingVolume=TRUE,GameplayPhysics=FALSE,EffectPhysics=FALSE) 
        CollideActors=true 
        BlockActors=true 
        Scale=1.0;
        BlockZeroExtent=true 
        BlockNonzeroExtent=true 
        BlockRigidBody=true 
		CastShadow=FALSE
	End Object
	Components.Add(DoorMeshComp);
	

	positionChange = 0
	desiredChange = 200
	moveAmount = 20
	opening = false
	closing = false
}
