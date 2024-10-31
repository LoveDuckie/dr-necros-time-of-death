class TAProj_HealingRay extends TAWeaponProjectile;

simulated function ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal)
{

}

DefaultProperties
{
	MyDamageType=class'TADmgType_HealingRay'
}
