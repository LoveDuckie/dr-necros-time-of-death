/* 
 * Class made for interacting with the global leaderboard on my website. 
 */
class TALeaderboardGet extends TcpLink config(Game);

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

var int Index;
var int Count;
var string SortField;
var string SortDirection;
var int MaxPages;
var array<string> Results;


event PostBeginPlay()
{
	super.PostBeginPlay();

	// Define specifications for it all
	TargetHost = "drnecro.com";
	TargetPort = 80;
	Path = "/getLeaderboard.php";
}

function ResolveMe()
{
    Resolve(TargetHost);
}

event Resolved( IpAddr Addr )
{
    // The hostname was resolved succefully
    `Log("[TcpLinkClient] "$TargetHost$" resolved to "$ IpAddrToString(Addr));
 
    Addr.Port = TargetPort;
 
    `Log("[TcpLinkClient] Bound to port: "$ BindPort() );
    if (!Open(Addr))
    {
        `Log("[TcpLinkClient] Open failed");
    }
}

function RequestData()
{
	RequestText = "index=" $ index $ "&count=" $ count $ "&sortField=" $ sortField $ "&sortDirection=" $ sortDirection;

	Results.length = 0;

	TAGame(WorldInfo.Game).GameHUD.ScaleformMainMenu.UpdatePaging((count / count) * (index / count) + 1, MaxPages);

	if (LinkState == STATE_Listening || LinkState == STATE_Connecting)
	Close();

	Resolve(TargetHost);
}



event ReceivedText(string text)
{
	Results.AddItem(text);
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
	local int i;
	local string t;
	local JSONObject j;

	`Log("[TcpLinkClient] event closed");

	for (i = 0; i < Results.length; i++)
	{
		t $= Results[i];
	}

	t = Mid(t, InStr(t, "{"), Len(t) - InStr(t, "{") + 1);
	j = class'JSonObject'.static.DecodeJson(t);

	HandleResult(j);
}

function HandleResult(JSONObject j)
{
	local JSONObject data;
	local int i;
	local JSONObject row;	

	MaxPages = FCeil(int(j.GetStringValue("Total")) * 1.0 / Count);

	data = j.GetObject("Data");

	TAGame(WorldInfo.Game).GameHUD.ScaleformMainMenu.ShowLeaderboard(true);
	TAGame(WorldInfo.Game).GameHUD.ScaleformMainMenu.ClearTable();
	TAGame(WorldInfo.Game).GameHUD.ScaleformMainMenu.UpdatePaging((count / count) * (index / count) + 1, MaxPages);
	for (i = 0; i < data.ObjectArray.length; i++)
	{
		row = data.ObjectArray[i];
		TAGame(WorldInfo.Game).GameHUD.ScaleformMainMenu.AddRow(row.GetStringValue("Rank"), row.GetStringValue("TeamName"), row.GetStringValue("Created"), row.GetStringValue("ZombiesKilled"), row.GetStringValue("DeathCount"), row.GetStringValue("ObjectivesCompleted"), row.GetStringValue("GameScore"));
	}
}

event ResolveFailed()
{
    `Log("[TcpLinkClient] Unable to resolve "$TargetHost);
TAGame(WorldInfo.Game).GameHUD.ScaleformMainMenu.ShowLeaderboard(false);
}

