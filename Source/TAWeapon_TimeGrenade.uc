class TAWeapon_TimeGrenade extends TAWeapon;

DefaultProperties
{
	Components.Remove(GunMesh);
	
	begin object class=UDKSkeletalMeshComponent name=Grenade
		
	end object

	Mesh = none
}
