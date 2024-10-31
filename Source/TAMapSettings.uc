class TAMapSettings extends MapInfo;

/*** Name of the game */
var (Meta) string GameName;
/*** Current version of the game */
var (Meta) string GameVersion;

/*** Camera rotation [fixed] */
var (Camera) rotator CameraRotation;
/*** Distance away from screen sides before zoom in. */
var (Camera) float CameraZoomInPixelBuffer;
/*** Distance away from screen sides before zoom out. */
var (Camera) float CameraZoomOutPixelBuffer;
/*** Minimum distance of camera from level. */
var (Camera) float CameraMinCameraDistance;
/*** Maximum distance of camera from level. */
var (Camera) float CameraMaxCameraDistance;
/*** Speed at which camera zooms out. */
var (Camera) float CameraZoomSpeed;
/*** Maximum distance between players. */
var (Camera) float CameraMaxDistanceBetweenPlayers;

/*** The percentage chance to spawn a tank when a zombie is spawned */
var (Zombies) float ChanceToSpawnTank;
/*** The percentage chance to spawn a ripper when a zombie is spawned */
var (Zombies) float ChanceToSpawnRipper;
var (WeaponData) instanced array<TAWeapon> WeaponData;

defaultproperties
{
	CameraZoomInPixelBuffer         = 175.0f;
	CameraZoomOutPixelBuffer        = 200.0f;
	CameraMinCameraDistance         = 600.0f//400.0f;
	CameraMaxCameraDistance         = 1800.0f;//750.0f;
	CameraZoomSpeed                 = 9.0f;
	CameraMaxDistanceBetweenPlayers = 1700.0f;//700.0f;
}

