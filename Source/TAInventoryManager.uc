class TAInventoryManager extends InventoryManager config(Game);

/** Holds the last weapon used */
var Weapon PreviousWeapon;
 
event PostBeginPlay()
{
	super.PostBeginPlay();
}

simulated event Tick(float DeltaTime)
{
	super.Tick(DeltaTime);

}


simulated function NextWeapon()
{

	`log(self.Name $ ":: InventoryManager has been called from NextWeapon()");
	super.NextWeapon();
}
DefaultProperties
{
	bMustHoldWeapon=true
	PendingFire(0)=0
	PendingFire(1)=0
	bDebug=true
}

