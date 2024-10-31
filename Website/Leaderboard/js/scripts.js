// Display the one score that we want and then hide the rest.
function DisplayScore(divToDisplay)
{
    // Loop through the item scores that have this class enabled.
    $('.ItemScoreMore').each(iterator,function(){
       $(this).hide();
    });
    
    // Determine whether the one in question is not null
    if ($(divToDisplay) != null)
    {
        $(divToDisplay).show();
    }   
}

function HideAllScores()
{
    $('.ItemScoreMore').each(iterator,function(){
       $(this).hide(); 
    });
}