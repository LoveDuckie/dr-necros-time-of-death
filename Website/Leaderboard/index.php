<?php

// The leaderboard will be displayed here.
include('leaderboard.php');
  
// Instantiate the leaderboard object.
$_leaderboard = new Leaderboard();

// Grab 15 of the top scores at the moment.
$_scores = $_leaderboard->GetScores(15);

// Get the template file that we so desperately require
$_template = file_get_contents('templates/index.html');
$_itemtemplate = file_get_contents('templates/item_score.html');
$_output = '';

// If post data has been sent to the leaderboard
if (isset($_POST['request_type']))
{
    switch($_POST['request_type'])
    {
        case "scores_get":
            
        break;
        
        case "scores_post":
            
        break;
    }
}

// If a specific score entry has been determined, then do something
if (isset($_GET['id']) && is_numeric($_GET['id']))
{
    
    // Determine if the score exists.
    if ($_leaderboard->ScoreExists($_GET['id']))
    {
        // Get a copy of the item template for the website.
        $_templateCopy = $_itemtemplate;
        $_scoreData = $_leaderboard->GetScore($_GET['id']);
    
    }
    

}
else
{ 
    // Loop through the sores that have been obtained.
    for($i = 0; $i < count($_scores); $i++)
    {
        $_copy = $_itemtemplate;
        $_copy = str_replace('%SCOREID%',$i + 1,$_copy);
        $_copy = str_replace('%_END_SCORE_%',$_scores[$i]['END_SCORE'],$_copy);
        $_copy = str_replace('%KILLCOUNT%',number_format(intval($_scores[$i]['ZOMBIES_KILLED'])),$_copy);
        
        switch($i + 1)
        {
            case 1:
                $_copy = str_replace('%POSITION%','FirstPlace',$_copy);
                $_copy = str_replace('%_POSITION_%',$i + 1,$_copy);
            break;
            
            case 2:
                 $_copy = str_replace('%POSITION%','SecondPlace',$_copy);
                $_copy = str_replace('%_POSITION_%',$i + 1,$_copy);
            break;
            
            case 3:
                 $_copy = str_replace('%POSITION%','ThirdPlace',$_copy);
                $_copy = str_replace('%_POSITION_%',$i + 1,$_copy);
            break;
            
            default:
                 $_copy = str_replace('%POSITION%',$i + 1,$_copy);
                $_copy = str_replace('%_POSITION_%',$i + 1,$_copy);
            break;
        }
        
        $_output .= $_copy;
    }
    
    $_template = str_replace('%SCORES%',$_output,$_template);

}

echo $_template;

?>
