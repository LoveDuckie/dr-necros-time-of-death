class TAMeleeFists extends TAWeapon;

var float m_HitRadius;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();

	m_HitRadius = 250.0f;
}

// Replace the spawning of projectiles.
simulated function FireAmmunition()
{
	local TAZombiePawn localpawn;

	super.FireAmmunition();

	/** Discover all nearby enemies and then affect them in some kind of way */
	foreach VisibleActors(class'TAZombiePawn',localpawn,m_HitRadius)
	{
		
	}

}

DefaultProperties
{
	// We don't want a mesh for this.
	
	Components.Remove(GunMesh);

	bMeleeWeapon = true;
	
}
