class TAScaleformHUD extends GFxMoviePlayer;

var GFxObject Test; 

var array<GFxObject> Players;

function Init(optional LocalPlayer locPlay)
{
	super.Init(locPlay);

	Start();
	Advance(0.0f);

	Test = GetVariableObject("_root.test1");

	Players.additem(GetVariableObject("_root.filter1.player1"));
	Players.additem(GetVariableObject("_root.filter1.player2"));
	Players.additem(GetVariableObject("_root.filter1.player3"));
	Players.additem(GetVariableObject("_root.filter1.player4"));
}

// Updates the scaleform using the given player controllers
function Update(TAGame game, array<TAPlayerController> playerControllers)
{
	local int index, index2;
	local TAPlayerController pc, pc2;
	local GFxObject playeri;
	local bool disableCharacter;
	local bool isDead;

	foreach Players(playeri, index)
	{
		EnablePlayer(index, false, 0);
	}	

	foreach playerControllers(pc, index)
	{
		if (pc != none)
		{
			if (pc.WaitingForRespawn && pc.RespawnTimer < pc.RespawnTotalTime)
			{
				EnablePlayer(index, pc.IsPlayerInGame && pc.IsActiveInGame, 2);

				SetRespawn(index, int(pc.RespawnTotalTime - pc.RespawnTimer) + 1);
			}
			else if (pc.IsSelectingCharacter)
				EnablePlayer(index, pc.IsPlayerInGame && pc.IsActiveInGame, 1);
			else
				EnablePlayer(index, pc.IsPlayerInGame && pc.IsActiveInGame, 0);


			SetHealth(index, TAHero(pc.Pawn).Health * 1.0 / 100);
			//SetAmmo(index, TAHero(pc.Pawn).Ammo);
			SetAmmo(index, TAWeapon(TAHero(pc.Pawn).Weapon).AmmoCount);

			SetAbility(index, pc.CurrentAbilityTime * 1.0 / pc.AbilityCooldown);

			// If someone is active in the game already with this characterindex and it aint this player then SHIT!!!
			disableCharacter = false;
			foreach playerControllers(pc2, index2)
			{
				if (pc2 != pc && pc2.IsActiveInGame && pc2.CharacterIndex == pc.CharacterIndex)
				{
					disableCharacter = true;
					break;
				}
			}		
	
			if (pc.WaitingForRespawn)
			{
				if (pc.RespawnTimer < pc.RespawnTotalTime)
					isDead = true;
				else
					isDead = false;
			}

			SetCharacter(index, pc.CharacterIndex, !disableCharacter, isDead);
			isDead = false; // Reset the var. Need to be nice to the other players

			SetName(index, Caps(string(GetEnum(Enum'HeroType', pc.CharacterIndex))));

			if (TAHero(pc.Pawn).barricadeCount > 0)
				SetPickup(index, 0);
			else if (TAHero(pc.Pawn).turretCount > 0)
				SetPickup(index, 1);
			else
				SetPickup(index, -1);
		}
	}

	if (game.TotalHumans == 0)
		ShowRemainingHumans(false);
	else
	{
		ShowRemainingHumans(true);
		SetRemainingHumans(game.RemainingHumans * 1.0 / game.TotalHumans);
	}

	if (game.bFightingBoss && game.BossZombie != none)
	{
		if (game.BossZombie.Health <= 0)
			ShowBossHealth(true, 0);
		else
			ShowBossHealth(true, game.BossZombie.Health * 1.0 / game.BossZombie.HealthMax);
	}
	else
		ShowBossHealth(false, 1);
}

function ShowGameOver(bool show, bool win, string n, int state, int rank)
{
	Test.SetText("ShowGameOver " $ show $ " " $ win $ " " $ n $ " " $ state $ " " $ rank);
	ActionScriptVoid("_root.ShowGameOver");
}



function ShowBossHealth(bool show, float health)
{
	Test.SetText("ShowBossHealth " $ show $ health);
	ActionScriptVoid("_root.ShowBossHealth");
}


function UpdateDynamicInteractButton(string id, float x, float y, int button)
{
	Test.SetText("UpdateDynamicInteractButton " $ id $ " " $ x $ " " $ y $ " " $ button);
	ActionScriptVoid("_root.UpdateDynamicInteractButton");
}

function RemoveDynamicInteractButton(string id)
{
	Test.SetText("RemoveDynamicInteractButton " $ id);
	ActionScriptVoid("_root.RemoveDynamicInteractButton");
}




function UpdateDynamicHumansFollowing(string id, float x, float y, int following, int total)
{
	Test.SetText("UpdateDynamicHumansFollowing " $ id $ x $ y $ following $ total);
	ActionScriptVoid("_root.UpdateDynamicHumansFollowing");
}

function RemoveDynamicHumansFollowing(string id)
{
	Test.SetText("RemoveDynamicHumansFollowing " $ id);
	ActionScriptVoid("_root.RemoveDynamicHumansFollowing");
}



function UpdateDynamicHealthBar(string id, float x, float y, float health)
{
	Test.SetText("UpdateDynamicHealthBar " $ id $ " " $ x $ " " $ y $ " " $ health);
	ActionScriptVoid("_root.UpdateDynamicHealthBar");
}

function RemoveDynamicHealthBar(string id)
{
	Test.SetText("RemoveDynamicHealthBar " $ id);
	ActionScriptVoid("_root.RemoveDynamicHealthBar");
}

function UpdateDynamicSpawnBar(string id, float x, float y, float spawn, string description)
{
	Test.SetText("UpdateDynamicSpawnBar " $ id $ " " $ x $ " " $ y $ " " $ spawn $ " " $ description);
	ActionScriptVoid("_root.UpdateDynamicSpawnBar");
}

function RemoveDynamicSpawnBar(string id)
{
	Test.SetText("RemoveDynamicSpawnBar " $ id);
	ActionScriptVoid("_root.RemoveDynamicSpawnBar");
}

// Sets the score for the given player
function SetPickup(int id, int pickup)
{
	Test.SetText("SetPickup " $ id $ " " $ pickup);
	ActionScriptVoid("_root.SetPickup");
}

// Sets the score for the given player
function SetScore(int id, int score)
{
	Test.SetText("SetScore " $ id $ " " $ score);
	ActionScriptVoid("_root.SetScore");
}

// Adds the score to the given player, triggers animations etc
function AddScore(int id, int score)
{
	Test.SetText("AddScore " $ id $ " " $ score);
	ActionScriptVoid("_root.AddScore");
}

// Sets the name of the character
function SetName(int id, string charName)
{
	Test.SetText("SetName " $ id $ " " $ charName);
	ActionScriptVoid("_root.SetName");
}

// Flashes the screen red for the given player
function TakeDamage(int id)
{
	Test.SetText("TakeDamage " $ id);
	ActionScriptVoid("_root.TakeDamage");
}

// Shows a speech bubble on the screen using the given character and speech text
function ShowSpeech(int character, string speech)
{
	Test.SetText("ShowSpeech " $ character $ " " $ speech);
	ActionScriptVoid("_root.ShowSpeech");
}

// Closes the speech bubble
function CloseSpeech()
{
	Test.SetText("CloseSpeech");
	ActionScriptVoid("_root.CloseSpeech");
}

// Temporarily changes the state of the character avatar.
// 0 = normal, 1 = hurt. Automatically returns back to normal after a period of time.
function SetCharacterState(int id, int state)
{
	Test.SetText("SetCharacterState " $ id $ " " $ state);
	ActionScriptVoid("_root.SetCharacterState");
}

// Sets the number of secs to show for the respawn timer
function SetRespawn(int id, int secs)
{
	Test.SetText("SetRespawn " $ id $ " " $ secs);
	ActionScriptVoid("_root.SetRespawn");	
}

// Sets the character for the given player
function SetCharacter(int id, int character, bool enabled, bool dead)
{
	Test.SetText("SetCharacter " $ id $ " " $ character $ " " $ enabled $ " " $ dead);
	ActionScriptVoid("_root.SetCharacter");
}

// Sets the health of the given player as a fraction, between 1 and 0
function SetHealth(int id, float health)
{
	Test.SetText("SetHealth " $ id $ " " $ health);
	ActionScriptVoid("_root.SetHealth");
}

// Sets the ammo of the given player as a fraction, between 1 and 0
function SetAmmo(int id, int ammo)
{
	Test.SetText("SetAmmo " $ id $ " " $ ammo);
	ActionScriptVoid("_root.SetAmmo");
}

// Sets the ability of the given player as a fraction, between 1 and 0
function SetAbility(int id, float ability)
{
	Test.SetText("SetAbility " $ id $ " " $ ability);
	ActionScriptVoid("_root.SetAbility");
}



// Set whether or not the player is currently playing or not
function EnablePlayer(int id, bool enable, int disabledState)
{
	Test.SetText("EnablePlayer " $ id $ " " $ enable $ " " $ disabledState);
	ActionScriptVoid("_root.EnablePlayer");
}

function ShowRemainingHumans(bool show)
{
	Test.SetText("ShowRemainingHumans " $ show);
	ActionScriptVoid("_root.ShowRemainingHumans");
}

// Sets the remaining humans as a fraction, between 1 and 0
function SetRemainingHumans(float humans)
{
	Test.SetText("SetRemainingHumans " $ humans);
	ActionScriptVoid("_root.SetRemainingHumans");
}

// Sets the current wave string
function SetWave(string wave)
{
	Test.SetText("SetWave " $ wave);
	ActionScriptVoid("_root.SetWave");
}

// Adds an objective
function AddObjective(string key, string description)
{
	Test.SetText("AddObjective " $ key);
	ActionScriptVoid("_root.AddObjective");
}

// Removes an objective
function RemoveObjective(string key)
{
	Test.SetText("RemoveObjective " $ key);
	ActionScriptVoid("_root.RemoveObjective");
}

function PushToScoreFeed(int id, string part1, string color1)
{
	Test.SetText("PushToScoreFeed " $ id $ part1 $ color1);
	ActionScriptVoid("_root.PushToScoreFeed");
}

function PushToFeed(string part1, string part2, string part3, string color1, string color2, string color3)
{
	Test.SetText("PushToFeed " $ part1 $ part2 $ part3 $ color1 $ color2 $ color3);
	ActionScriptVoid("_root.PushToFeed");
}

defaultproperties
{
	bDisplayWithHudOff = false	
	bEnableGammaCorrection = false
	bAllowInput = false;
    	bAllowFocus = false;

	MovieInfo = SwfMovie'TAHudPack.HUD'
}