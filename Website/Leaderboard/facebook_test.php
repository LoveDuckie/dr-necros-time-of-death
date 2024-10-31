<?php

include('fb/src/facebook.php');
include('fb/fanpage.php');
$facebook = new Facebook(array('appId' => APP_ID, 
                               'secret' => APP_SECRET,
                               'cookie' => true));


// Get User ID
$user = $facebook->getUser();
 

if ($user) {
    
    echo 'user is valid';
  try {
    $page_id = PAGE_ID;
    $page_info = $facebook->api("/$page_id?fields=access_token");
    if( !empty($page_info['access_token']) ) {
        $args = array(
            'access_token'  => $page_info['access_token'],
            'message'       => "Something"
        );
        $post_id = $facebook->api("/$page_id/feed","post",$args);
        
        // Determine whether or not the page posted.
        echo 'posted!';
    } else {
        $permissions = $facebook->api("/me/permissions");
        if( !array_key_exists('publish_stream', $permissions['data'][0]) || 
            !array_key_exists('manage_pages', $permissions['data'][0])) {
            // We don't have one of the permissions
            // Alert the admin or ask for the permission!
            header( "Location: " . $facebook->getLoginUrl(array("scope" => "publish_stream, manage_pages")) );
        }
 
    }
  } catch (FacebookApiException $e) {
    error_log($e);
    $user = null;
  }
}
 
// Login or logout url will be needed depending on current user state.
if ($user) {
  $logoutUrl = $facebook->getLogoutUrl();
} else {
  $loginUrl = $facebook->getLoginUrl(array('scope'=>'manage_pages,publish_stream'));
}
//echo $app_token;
//$facebook->api(,)
?>
