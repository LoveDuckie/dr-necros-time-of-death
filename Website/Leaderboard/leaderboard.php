<?

include('sql.php');
include('fb/src/facebook.php');

// For posting to the facebook fan page.
$facebook = new Facebook();

// Fake enum!
class ReturnType
{
    const JSON = 0;
    const StandardArray = 0;
}
    
class Leaderboard 
{ 
    // The type of requests that can be made to the leaderboard system.
    private $action_messages = array( 
        0 => "APIRequest",
        1 => "GetLeaderboard",
        2 => "PostLeaderboard",
        3 => "APIGenerate"
    );
     
    // Boolean value that will display whether or not the key is valid.
    private $valid_key;
    
    function __construct($api_key)
    {
        // Ensure that the API key is valid first.
        if ($this->CheckAPIKey($api_key))
        {
            $valid_key = true;
        }
    }
    
    public function GetScore($score_id)
    {
        global $sql;
        
        $_get = $sql->prepare('SELECT * FROM leaderboard WHERE ID=:id');
        $_get->bindParam(':id',$score_id,PDO::PARAM_INT);
        
        // Make sure that the query executed OK
        if ($_get->execute() != FALSE)
        {
            $data = $_get->fetchAll();
            
            return $data;
        }
    }
    
    public function ScoreExists($scoreID)
    {
        global $sql;
        
        $checkStatement = $sql->prepare('SELECT * FROM leaderboard WHERE ID=:score_id');
        $checkStatement->bindParam(':score_id',$scoreID,PDO::PARAM_STR);
        
        // return whether or not the sql returns with a row count larger than 0 (none)
        if ($checkStatement->execute() != FALSE)
        {
            return $checkStatement->rowCount() > 0;
        }
        else
        {
            return 1;
        }
        
    }
    
    /* Presuming that we have some interaction with facebook */
    public function PublishScoreToFacebook($scoreID)
    {
        // ...
    }
    
    // Send the data into the database.
    public function PostScore($jsondata,$api_key)
    {
        global $sql;
        
        // Make sure that a valid API key is being used.
        if ($this->CheckAPIKey($api_key))
        {
            $_data = json_decode($jsondata,true);

            // Can't do this part until I do the unrealscript and test what data I am getting
            if (is_array($_data))
            {
                $_insert = $sql->prepare('INSERT INTO leaderboard(HERO_1_NAME,HERO_2_NAME,HERO_3_NAME,HERO_4_NAME,END_SCORE,COMPLETE_ENDGAME,HUMANS_SAVED,HERO_1_SCORE,HERO_2_SCORE,HERO_3_SCORE,HERO_4_SCORE) values(:hero1name,:hero2name,:hero3name,:hero4name,:endscore,:completeendgame)');

                // If the insert went OK then that's fine!
                if ($_insert->execute() != FALSE)
                {
                    return true;
                }
            }
        }
    }
    
    // $action - Integer value determining what the log message is concerning
    // $message - The description of the log that we want to post.
    public function PostLog($action,$message)
    {
        global $sql;
        global $action_messages; // grab the variable from outside of the function.
        
        $_logquery = $sql->prepare('INSERT INTO logs(LOG_TYPE,LOG_MESSAGE) values(:log_type,:log_message)');
        $_logquery->bindParam(':log_type',strval($action_messages[intval($action)]),PDO::PARAM_STR);
        $_logquery->bindParam(':log_message',$message,PDO::PARAM_STR);
        
        // If the query correctly executed, then don't worry.
        if ($_logquery->execute() != FALSE)
        {
            return true;
        }
        else
        {
            die ('Problem with posting log to the database :(');
        }
    }
    
    // Get the scores simply as an array
    public function GetScores($amount)
    {
        global $sql;
       
        $_get = $sql->prepare('SELECT * FROM leaderboard ORDER BY END_SCORE DESC LIMIT :limit');
        $_get->bindParam(':limit',$amount,PDO::PARAM_INT);
        
        // Make sure that the query worked OK
        if ($_get->execute() != FALSE)
        {
            $data = $_get->fetchAll();
            
            $this->PostLog(1,"GetScores(amount) has been called");
            
            return $data;
        }
        else
        {
            die('Error with query');
        }
    }
    
    public function GetScoresJSON($amount)
    {
        global $sql;
       
        $_get = $sql->prepare('SELECT * FROM leaderboards LIMIT :limit ORDER BY END_SCORE DESC');
        $_get->bindParam(':limit',$amount,PDO::PARAM_INT);
        
        // Make sure that the query worked OK
        if ($_get->execute() != FALSE)
        {
            $data = $_get->fetchAll();
            
            return json_encode($data);
        }
    }
    
    // Return whether or not the API key is valid.
    public static function CheckAPIKey($key)
    {
        global $sql;
        
        $_getquery = $sql->prepare('SELECT * FROM keys WHERE API_KEY = :key');
        $_getquery->bindParam(':key',$key,PDO::PARAM_STR);
        
        // Make sure that it ran OK
        if ($_getquery->execute() != FALSE)
        {
            return $_getquery->rowCount() == 1;
        }
    }

    
    // For generating a new form of access for the leaderboard
    // $description -
    // $data - 
    public static function GenerateAPIKey($data,$description)
    {
       // Grab the global declaration of the API key.
        global $sql;
        
        PostLog(3,"GenerateAPIKey(data,description) has been called");
        
        $_key_generated = sha1($data);
        
        // Put the SHA1 hashed key into the database.
        $_insertquery = $sql->prepare('INSERT INTO api_key(API_KEY,API_DESC) values(:key,:desc)');
        $_insertquery->bindParam(':key',$_key_generated,PDO::PARAM_STR);
        $_insertquery->bindParam(':desc',$description,PDO::PARAM_STR);
        
        // If the inser has been made successfully explain to the user that it has been done.
        if ($_insertquery->execute() != FALSE)
        {
           die('Successfully got the key generated!');
        }
        else
        {
            die(var_dump($_insertquery->errorInfo()));
        }
    }
    
}

// Create the leaderboard object.
$leaderboard = new Leaderboard();

if (isset($_POST['task']) && isset($_POST['key']) && isset($_POST['data']))
{
    if (Leaderboard::CheckAPIKey($_POST['key']))
    {
        switch($_POST['task'])
        {
            case "get_all":
                echo $leaderboard->GetScores();
            break;
        
            case "get_score":
                echo $leaderboard->GetScore($_POST['data']);
            break;

            case "post_score":
                if (isset($_POST['data']))
                {
                    $_decoded = json_decode($_POST['data'],true);
                    
                    // Ensure that the JSON string was properly decoded.
                    if (is_array($_decoded) && count($_decoded) > 0)
                    {
                        $leaderboard->PostScore($_POST['data'], $_POST['key']);
                    }
                    else
                    {
                        die('Bad request');
                    }
                }
            break;

            case "register_api":
                
            break;
        }
    }

}

?>