class TANarratorManager extends Object;

struct SpeechSoundCue
{
	var SoundCue SoundCue;
	var int Randomness;
	var int Plays; // Maximum number of times to play sound. -1 for infinite potential
};


var TAGame Game;


var AudioComponent SpeechComponent;
var array<SpeechSoundCue> Sounds;

var SpeechSoundCue IntroSound;
var SpeechSoundCue SpawnSound;
var SpeechSoundCue WaveCompleteSound;
var SpeechSoundCue GameOverLostSound;
var SpeechSoundCue GameOverWonSound;

var SpeechSoundCue GaryAbilitySound;
var SpeechSoundCue MilesAbilitySound;
var SpeechSoundCue SaraAbilitySound;
var SpeechSoundCue SargeAbilitySound;

var SpeechSoundCue CryoObjectiveSound;
var SpeechSoundCue BookObjectiveSound;
var SpeechSoundCue KitchenObjectiveSound;
var SpeechSoundCue CryoObjectiveCompleteSound;

var SpeechSoundCue BossBeforeSound;
var SpeechSoundCue BossSpawnSound;
var SpeechSoundCue BossInjuredSound;

var SpeechSoundCue Misc1Sound;
var SpeechSoundCue Misc2Sound;

var SpeechSoundCue HeroDeadSound;

const CLOSE_SPEECH_TIME = 1.0f;
var float CurrentCloseSpeechTime;
var bool ClosingSpeech;

var SoundCue LastFinishedSound;

function Init(TAGame g)
{
	Game = g;

	SpeechComponent = new class'AudioComponent';
	SpeechComponent.OnQueueSubtitles = CueSubtitles;
	SpeechComponent.OnAudioFinished = AudioFinished;

	// Init each sound
	IntroSound = NewSpeechSoundCue(SoundCue'Speech.Necro.drnecro_intro', 1, 1);
	SpawnSound = NewSpeechSoundCue(SoundCue'Speech.Necro.drnecro_spawn', 1, 1);
	WaveCompleteSound = NewSpeechSoundCue(SoundCue'Speech.Necro.drnecro_wavecomplete', 10, 4);
	GameOverLostSound = NewSpeechSoundCue(SoundCue'Speech.Necro.drnecro_gameover_lost', 1, 1);
	GameOverWonSound = NewSpeechSoundCue(SoundCue'Speech.Necro.drnecro_gameover_won', 1, 1);
	GaryAbilitySound = NewSpeechSoundCue(SoundCue'Speech.Necro.drnecro_gary_ability', 1, 5);
	MilesAbilitySound = NewSpeechSoundCue(SoundCue'Speech.Necro.drnecro_miles_ability', 1, 5);
	SaraAbilitySound = NewSpeechSoundCue(SoundCue'Speech.Necro.drnecro_sara_ability', 1, 5);
	SargeAbilitySound = NewSpeechSoundCue(SoundCue'Speech.Necro.drnecro_sarge_ability', 1, 5);

	CryoObjectiveSound = NewSpeechSoundCue(SoundCue'Speech.Necro.drnecro_objective_cryo', -1, 1);
	CryoObjectiveCompleteSound = NewSpeechSoundCue(SoundCue'Speech.Necro.drnecro_objective_cryo_complete', -1, 1);
	BookObjectiveSound = NewSpeechSoundCue(SoundCue'Speech.Necro.drnecro_objective_book', -1, 1);
	KitchenObjectiveSound = NewSpeechSoundCue(SoundCue'Speech.Necro.drnecro_objective_kitchen', -1, 1);

	BossBeforeSound = NewSpeechSoundCue(SoundCue'Speech.Necro.drnecro_boss_before', 1, 1);
	BossSpawnSound = NewSpeechSoundCue(SoundCue'Speech.Necro.drnecro_boss_spawn', 1, 1);
	BossInjuredSound = NewSpeechSoundCue(SoundCue'Speech.Necro.drnecro_boss_injured', 1, 1);

	Misc1Sound = NewSpeechSoundCue(SoundCue'Speech.Necro.drnecro_misc1', 1, 5);
	Misc2Sound = NewSpeechSoundCue(SoundCue'Speech.Necro.drnecro_misc2', 1, 5);

	HeroDeadSound = NewSpeechSoundCue(SoundCue'Speech.Necro.drnecro_hero_dead', -1, 5);

	Sounds.length = 0;
	// Important: ADD THE SOUNDS TO THE ARRAY so they can
	// be accessed when a trigger volume is touched, etc
	Sounds.additem(IntroSound);
	Sounds.additem(SpawnSound);
	Sounds.additem(WaveCompleteSound);
	Sounds.additem(GameOverLostSound);
	Sounds.additem(GameOverWonSound);
	Sounds.additem(GaryAbilitySound);
	Sounds.additem(MilesAbilitySound);
	Sounds.additem(SaraAbilitySound);
	Sounds.additem(SargeAbilitySound);
	Sounds.additem(CryoObjectiveSound);
	Sounds.additem(CryoObjectiveCompleteSound);
	Sounds.additem(BookObjectiveSound);
	Sounds.additem(KitchenObjectiveSound);
	Sounds.additem(BossBeforeSound);
	Sounds.additem(BossSpawnSound);
	Sounds.additem(BossInjuredSound);
	Sounds.additem(Misc1Sound);
	Sounds.additem(Misc2Sound);
	Sounds.additem(HeroDeadSound);
}

// This gets called automatically when subtitles are cued. They need to be set in the
// content manager, for each of the SoundNodeWaves in each SoundCue.
function CueSubtitles(array<EngineTypes.SubtitleCue> Subtitles, float CueDuration)
{
	Game.GameHud.ScaleformHUD.ShowSpeech(4, Subtitles[0].Text);
}

function AudioFinished(AudioComponent ac)
{
	LastFinishedSound = ac.SoundCue;

	CurrentCloseSpeechTime = 0;
	ClosingSpeech = true;
}

function TriggerTouched(SoundCue sc)
{
	local int i;

	//Game.Broadcast(Game, "LOOKING FOR SC: " $ sc);

	// Find the soundcue in the sound list
	for (i = 0; i < Sounds.length; i++)
	{
		if (Sounds[i].SoundCue == sc)
		{
			SaySpeech(Sounds[i]);
			break;
		}
	}
}

function Tick(float deltaTime)
{
	if (ClosingSpeech)
	{
		CurrentCloseSpeechTime += deltaTime;
	
		if (CurrentCloseSpeechTime > CLOSE_SPEECH_TIME)
		{
			if (!SpeechComponent.IsPlaying())
				Game.GameHud.ScaleformHUD.CloseSpeech();

			LastFinishedSound = none;
			CurrentCloseSpeechTime = 0;
			ClosingSpeech = false;
		}
	}
}

function SpeechSoundCue NewSpeechSoundCue(SoundCue sc, int plays, int randomness)
{
	local SpeechSoundCue ssc;
	
	ssc.SoundCue = sc;
	ssc.Plays = plays;
	ssc.Randomness = randomness;

	return ssc;
} 

function SaySpeech(SpeechSoundCue sc, bool override = false)
{
	local int chance;
	local int i;

	// Loop through the array until we found the cue that we need
	for (i = 0; i < Sounds.length; i++)
	{
		if (Sounds[i].SoundCue == sc.SoundCue)
		{
			//Game.Broadcast(Game, "Plays Left: " $ Sounds[i].Plays);

			if (override)
			{
				if (SpeechComponent.IsPlaying())
					SpeechComponent.Stop();
	
				SpeechComponent.SoundCue = Sounds[i].SoundCue;
				SpeechComponent.Play();
			}
			else if (Sounds[i].Plays != 0)
			{
				if (!SpeechComponent.IsPlaying())
				{
					chance = RandRange(1, Sounds[i].Randomness);

					//Game.Broadcast(Game, "Chance: " $ chance);

					if (chance == 1)
					{
						//Game.Broadcast(Game, "PLAYING");

						SpeechComponent.SoundCue = Sounds[i].SoundCue;
						SpeechComponent.Play();
						Sounds[i].Plays--;
					}
				}
			}

			break;
		}
	}
}

DefaultProperties
{
	begin object class=SpriteComponent name=NarratorSprite
		Sprite=Texture2D'Sprites.narrator_manager'
		HiddenGame=true
		HiddenEditor=false
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
	end object
}
