class TADmgType extends DamageType;

var 	class<TAWeapon>			DamageWeaponClass;
var     int                     DamageWeaponFireMode;
var     bool                    bCausesBlood;

var        bool            bDirectDamage;
var        bool            bSeversHead;
var        bool            bCauseConvulsions;
var        bool            bUseTearOffMomentum;    // For ragdoll death. Add entirety of killing hit's momentum to ragdoll's initial velocity.
var        bool            bThrowRagdoll;
var        bool            bLeaveBodyEffect;
var        bool            bBulletHit;
var        bool            bVehicleHit;        // caused by vehicle running over you
var        bool            bSelfDestructDamage;

/** Name of animation to play upon death. */
var(DeathAnim)    name    DeathAnim;
/** How fast to play the death animation */
var(DeathAnim)    float    DeathAnimRate;
/** If true, char is stopped and root bone is animated using a bone spring for this type of death. */
var(DeathAnim)    bool    bAnimateHipsForDeathAnim;
/** If non-zero, motor strength is ramped down over this time (in seconds) */
var(DeathAnim)    float    MotorDecayTime;
/** If non-zero, stop death anim after this time (in seconds) after stopping taking damage of this type. */
var(DeathAnim)    float    StopAnimAfterDamageInterval;


DefaultProperties
{
	KDeathUpkick = 15.0f;
	bCausesFracture = true;
	bCausesBlood = true;
}
