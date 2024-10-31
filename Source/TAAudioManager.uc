class TAAudioManager extends Object;

var AudioComponent MainMusic;
var AudioComponent AmbienceMusic;
var AudioComponent BattleMusic;
var AudioComponent DiscoMusic;
var AudioComponent BossMusic;

function InitAudio()
{
	MainMusic = new class'AudioComponent';
	AmbienceMusic = new class'AudioComponent';
	BattleMusic = new class'AudioComponent';
	DiscoMusic = new class'AudioComponent';
	BossMusic = new class'AudioComponent';

	MainMusic.SoundCue = SoundCue'Sounds.MainTheme_Cue';
	AMbienceMusic.SoundCue = SoundCue'Sounds.Ambience_Cue';
	BattleMusic.SoundCue = SoundCue'Sounds.Battle_Cue';
	DiscoMusic.SoundCue = SoundCue'Sounds.80s.80sWave';
	BossMusic.SoundCue = SoundCue'Sounds.Boss.BossMusic';

	StartAmbienceMusic();
}

function StartMainMusic()
{ 
	if (!MainMusic.IsPlaying())
	{
		AmbienceMusic.Stop();
		BattleMusic.Stop();
		BossMusic.Stop();
		DiscoMusic.Stop();

		MainMusic.fadeIn(0, 1.0f);
	}
}

function StartAmbienceMusic()
{
	if (!AmbienceMusic.IsPlaying())
	{
		MainMusic.Stop();
		BattleMusic.Stop();
		BossMusic.Stop();
		DiscoMusic.Stop();

		AmbienceMusic.fadeIn(0, 0.5f);
	}
}

function StartBattleMusic(bool bDisco)
{
	MainMusic.Stop();
	AmbienceMusic.Stop();
	BossMusic.Stop();

	if (bDisco)
	{
		if (!DiscoMusic.isPlaying())
		{
			BattleMusic.Stop();
			DiscoMusic.FadeIn(0, 0.5f);
		}
	}
	else
	{
		if (!BattleMusic.isPlaying())
		{
			DiscoMusic.Stop();
			BattleMusic.FadeIn(0, 0.5f);
		}
	}
}

function StartBossMusic()
{
	if (!BossMusic.isPlaying())
	{
		MainMusic.Stop();
		AmbienceMusic.Stop();
		BattleMusic.Stop();
		DiscoMusic.Stop();

		BossMusic.FadeIn(0, 0.5f);
	}
}

function StopAllMusic()
{
	BattleMusic.Stop();
	AmbienceMusic.Stop();
	MainMusic.Stop();
	BossMusic.Stop();
}

defaultproperties
{
	
}