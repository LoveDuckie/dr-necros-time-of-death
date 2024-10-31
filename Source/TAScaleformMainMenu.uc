class TAScaleformMainMenu extends GFxMoviePlayer;

var GFxObject Test; 

function Init(optional LocalPlayer locPlay)
{
	super.Init(locPlay);

	Start();
	Advance(0.0f);

	Test = GetVariableObject("_root.test1");
}

function Update(TAGame game)
{

}

function ShowLeaderboard(bool show)
{
	Test.SetText("ShowLeaderboard " $ show);
	ActionScriptVoid("_root.ShowLeaderboard");
}

function UpdatePaging(int current, int max)
{
	Test.SetText("UpdatePaging " $ current $ max);
	ActionScriptVoid("_root.UpdatePaging");
}

function AddRow(string rank, string teamName, string date, string kills, string deaths, string objectives, string points)
{
	Test.SetText("AddRow " $ rank $ date $ kills $ deaths $ objectives $ points);
	ActionScriptVoid("_root.AddRow");
}

function ClearTable()
{
	Test.SetText("ClearTable ");
	ActionScriptVoid("_root.ClearTable");
}

defaultproperties
{
	bDisplayWithHudOff = false	
	bEnableGammaCorrection=false	 
	bIgnoreMouseInput = false
	bPauseGameWhileActive = false

	MovieInfo = SwfMovie'TAHudPack.MainMenu'
}