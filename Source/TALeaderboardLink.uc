/* 
 * Class made for interacting with the global leaderboard on my website. 
 */
class TALeaderboardLink extends TcpLink config(Game);

/** Members **/
var string Path;
var int TargetPort;
var string TargetHost;
var string RequestText;
var string _receivedtext;

// Prove to the server that we're not just some random hacker that is trying to spam the server with
// post requests.
const API_KEY = "c8198a47150cb6d85ac5add81fd54b5949ddf40e"; 


var () int LeaderboardID;

var array<string> Results;

event PostBeginPlay()
{
	super.PostBeginPlay();

	// Define specifications for it all
	TargetHost = "drnecro.com";
	TargetPort = 80;
	Path = "/leaderboard.php";
	LeaderboardID = 20; // So we know where toe post to
}

function ResolveMe() //removes having to send a host
{
    Resolve(TargetHost);
}

event Resolved( IpAddr Addr )
{
    // The hostname was resolved succefully
    `Log("[TcpLinkClient] "$TargetHost$" resolved to "$ IpAddrToString(Addr));
 
    // Make sure the correct remote port is set, resolving doesn't set
    // the port value of the IpAddr structure
    Addr.Port = TargetPort;
 
    //dont comment out this log because it rungs the function bindport
    `Log("[TcpLinkClient] Bound to port: "$ BindPort() );
    if (!Open(Addr))
    {
        `Log("[TcpLinkClient] Open failed");
    }
}

/** 
 *  Compile the data that we are going to send to the internet as a JSON string and then
 *  do something with them.
 *  
 *  **/
function PostScore(int GameScore, 
					int ZombiesKilled, 
					int DeathCount,
					int Gary_Score, 
					int Sara_Score,
					int Sarge_Score,
					int Miles_Score,
					bool EndGame_Complete,
					int Gary_Kills,
					int Sara_Kills,
					int Sarge_Kills,
					int Miles_Kills,
					int Humans_Saved,
					int Objectives_Completed,
					string TeamName)
{
		local string RequestData;
		local JsonObject RequestObject;

		// First part of the text
		RequestText = "task=post_score";

		// Make a new version of the json object.
		RequestObject = new () class'JsonObject';
		RequestObject.SetIntValue("GameScore",GameScore);
		RequestObject.SetIntValue("ZombiesKilled",ZombiesKilled);
		RequestObject.SetIntValue("DeathCount",DeathCount);
		RequestObject.SetIntValue("Gary_Score",Gary_Score);
		RequestObject.SetIntValue("Sara_Score",Sara_Score);
		RequestObject.SetIntValue("Sarge_Score",Sarge_Score);
		RequestObject.SetIntValue("Miles_Score",Miles_Score);
		RequestObject.SetIntValue("EndGame_Complete",int(EndGame_Complete));
		RequestObject.SetIntValue("Gary_Kills",Gary_Kills);
		RequestObject.SetIntValue("Sara_Kills",Sara_Kills);
		RequestObject.SetIntValue("Sarge_Kills",Sarge_Kills);
		RequestObject.SetIntValue("Miles_Kills",Miles_Kills);
		RequestObject.SetIntValue("Humans_Saved",Humans_Saved);
		RequestObject.SetIntValue("Objectives_Completed",Objectives_Completed);
		RequestObject.SetIntValue("LeaderboardID",LeaderboardID);
		RequestObject.SetStringValue("TeamName",TeamName);

		// Encode the data that we are going to send to the server.
		RequestData = class'JsonObject'.static.EncodeJson(RequestObject);
		
		RequestText $= "&data=" $ RequestData;
		RequestText $= "&key=" $ API_KEY;
		
		`log("COCKBAG @@@@@@@@@@@@@@@@@@@@@ " $ RequestData); // Output what has just been encoded.

		Results.length = 0;



		if (LinkState == STATE_Listening || LinkState == STATE_Connecting)
		Close();

		Resolve(TargetHost);
}

// Get all the scores from an index in the database by an amount past that point.
function GetScores(int _index, int _amount)
{
	
}

event ReceivedText(string Text)
{
	Results.AddItem(text);
	`log(text);
}

event Opened()
{
	_receivedtext = "";
    SendText("POST /"$path$" HTTP/1.0"$chr(13)$chr(10));
    SendText("Host: "$TargetHost$chr(13)$chr(10));
    SendText("User-Agent: HTTPTool/1.0"$Chr(13)$Chr(10));
    SendText("Content-Type: application/x-www-form-urlencoded"$chr(13)$chr(10));
    //we use the length of our requesttext to tell the server
    //how long our content is
    SendText("Content-Length: "$len(RequestText)$Chr(13)$Chr(10));
    SendText(chr(13)$chr(10));
    SendText(requesttext);
    SendText(chr(13)$chr(10));
    SendText("Connection: Close");
    SendText(chr(13)$chr(10)$chr(13)$chr(10));
 
 
    `Log("[TcpLinkClient] end HTTP query");
}

event Closed()
{
	local string t;
	local int i;

	for (i = 0; i < Results.length; i++)
	{
		t $= Results[i];
	}

	t = Mid(t, InStr(t, "|"), Len(t) - InStr(t, "|") + 1);
	t = Mid(t, 1, Len(t) - 1);

	TAGame(WorldInfo.Game).GameOverRank = int(t);
	TAGame(WorldInfo.Game).GameOverState = TAGame(WorldInfo.Game).EGameOverState.Succeeded;
	TAGame(WorldInfo.Game).GameOver();


    `Log("[TcpLinkClient] event closed");
}

event ResolveFailed()
{
    `Log("[TcpLinkClient] Unable to resolve "$TargetHost);
    // You could retry resolving here if you have an alternative
    // remote host.
        //_receivedText = "Unable to resolve server\nPlease check your internet connection";

	TAGame(WorldInfo.Game).GameOverState = TAGame(WorldInfo.Game).EGameOverState.Failed;
	TAGame(WorldInfo.Game).GameOver();
}

