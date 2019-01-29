<?php
 
$message = array();
$message_css = "";
 
function changePassword($user,$oldPassword,$newPassword,$newPasswordCnf){
  global $message;
  global $message_css;
 
  $server = "idp.inflibnet.ac.in";
  //$server = "infonet.inflibnet.ac.in";
  $dn = "ou=People,dc=inflibnet,dc=ac,dc=in";
    
  error_reporting(0);
  ldap_connect($server);
  $con = ldap_connect($server);
  ldap_set_option($con, LDAP_OPT_PROTOCOL_VERSION, 3);
  $rootdn = "cn=Manager,dc=inflibnet,dc=ac,dc=in";
  $rootpwd = ""; 
  // bind anon and find user by uid
  $user_search = ldap_search($con,$dn,"(|(uid=$user)(mail=$user))");
  $user_get = ldap_get_entries($con, $user_search);
  $user_entry = ldap_first_entry($con, $user_search);
  $user_dn = ldap_get_dn($con, $user_entry);
  $user_id = $user_get[0]["uid"][0];
  $user_givenName = $user_get[0]["givenName"][0];
  $user_search_arry = array( "*", "ou", "uid", "mail", "passwordRetryCount", "passwordhistory" );
  $user_search_filter = "(|(uid=$user_id)(mail=$user))";
  $user_search_opt = ldap_search($con,$user_dn,$user_search_filter,$user_search_arry);
  $user_get_opt = ldap_get_entries($con, $user_search_opt);
  $passwordRetryCount = $user_get_opt[0]["passwordRetryCount"][0];
  $passwordhistory = $user_get_opt[0]["passwordhistory"][0];
   
 
  /* Start the testing */
  if ( $passwordRetryCount == 3 ) {
    $message[] = "Error E101 - Your Account is Locked Out!!!";
    return false;
  }
/*echo $con;
echo  $user_dn;
echo  $oldPassword;
exit;*/
  if (ldap_bind($con, $user_dn, $oldPassword) === false) {
    $message[] = "Error E101 - Current Username or Password is wrong.";
    return false;
  }
  if ($newPassword != $newPasswordCnf ) {
    $message[] = "Error E102 - Your New passwords do not match!";
    return false;
  }
  $encoded_newPassword = "{SHA}" . base64_encode( pack( "H*", sha1( $newPassword ) ) );
  $history_arr = ldap_get_values($con,$user_dn,"passwordhistory");
  if ( $history_arr ) {
    $message[] = "Error E102 - Your new password matches one of the last 10 passwords that you used, you MUST come up with a new password.";
    return false;
  }
  if (strlen($newPassword) < 8 ) {
    $message[] = "Error E103 - Your new password is too short.<br/>Your password must be at least 8 characters long.";
    return false;
  }
  if (!preg_match("/[0-9]/",$newPassword)) {
    $message[] = "Error E104 - Your new password must contain at least one number.";
    return false;
  }
  if (!preg_match("/[a-zA-Z]/",$newPassword)) {
    $message[] = "Error E105 - Your new password must contain at least one letter.";
    return false;
  }
  if (!preg_match("/[A-Z]/",$newPassword)) {
    $message[] = "Error E106 - Your new password must contain at least one uppercase letter.";
    return false;
  }
  if (!preg_match("/[a-z]/",$newPassword)) {
    $message[] = "Error E107 - Your new password must contain at least one lowercase letter.";
    return false;
  }

  if (!$user_get) {
    $message[] = "Error E200 - Unable to connect to server, you may not change your password at this time, sorry.";
    return false;
  }
  
  $auth_entry = ldap_first_entry($con, $user_search);
  $mail_addresses = ldap_get_values($con, $auth_entry, "mail");
  $given_names = ldap_get_values($con, $auth_entry, "givenName");
  $last_names = ldap_get_values($con, $auth_entry, "sn");
  $password_history = ldap_get_values($con, $auth_entry, "passwordhistory");
  $mail_address = $mail_addresses[0];
  $first_name = $given_names[0];
  $last_name = $last_names[0];
   
  /* And Finally, Change the password */
  $entry = array();
  $entry["userPassword"] = "$encoded_newPassword";
  $r = ldap_bind($con,$rootdn,$rootpwd); 
  if ($r = ldap_modify($con,$user_dn,$entry) === false){
    $error = ldap_error($con);
    $errno = ldap_errno($con);
    $message[] = "E201 - Your password cannot be change, please contact the administrator.";
    $message[] = "$errno - $error";
  } else {
    $message_css = "yes";
	$mail_body="";
    mail($mail_address,"Password change notice for LDAP: INFLIBNET Centre","Dear $first_name $last_name ,
Your password for account '$user_id' was just changed in LDAP server. If you did not make this change, please contact gaurav@inflibnet.ac.in.
If you are the legitimate user please ignore this message.
 
Thanks
Team INFLIBNET", "From: INFLIBNET<noreply@inflibnet.ac.in>\r\n");
    $message[] = "The password for $user_id has been changed.<br/>An informational email as been sent to $mail_address.<br/>Your new password is now fully Active.";
  }
}
 
?>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>LDAP</title>
<link href="bootstrap/css/bootstrap.min.css" rel="stylesheet" media="screen">
<link href="bootstrap/css/bootstrap-theme.min.css" rel="stylesheet" media="screen"> 
<link rel="stylesheet" href="includes/style.css" type="text/css" />
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
</head>
<body>

<div class="signin-form">
<div class="container">
<form action="<?php print $_SERVER['PHP_SELF']; ?>" name="passwordChange" method="post" id="login-form" class="form-signin">
<p class="imagecentre"><a href="http://www.inflibnet.ac.in/" target="_blank"><img src="images/logo.png" border="0" height="150px" width="100px"/></a></p>
<p class="imagecentre"><b>CHANGE PASSWORD</b></p>
<p>Your new password must be 8 characters long and must contains:<br/></p>
<ul>
<li>one capital letter</li>
<li>one lowercase letter</li>
<li>one number</li>
<li>You must use a new password, your current password can not be the same as your new password.</li>
 
</ul>     <?php
      if (isset($_POST["submitted"])) {
        changePassword($_POST['username'],$_POST['oldPassword'],$_POST['newPassword1'],$_POST['newPassword2']);
        global $message_css;
        if ($message_css == "yes") {
          ?><div class="alert alert-success"><?php
         } else {
          ?><div class="alert alert-danger"><?php
          $message[] = "Your password was not changed.";
        }
        foreach ( $message as $one ) { echo "<p>$one</p>"; }
      ?></div><?php
      } ?>
		
		 <div class="form-group">
        <input type="text" class="form-control" placeholder="Username " name="username" required />
        <span id="check-e"></span>
        </div>
		<div class="form-group">
        <input name="oldPassword" class="form-control" placeholder="Old Password" type="password" required />
        </div> 
		<div class="form-group">
        <input name="newPassword1" class="form-control" placeholder="New Password" type="password" required />
        </div> 
		<div class="form-group">
        <input name="newPassword2" class="form-control" placeholder="Confirm Password" type="password" required />
        </div> 
		  <div class="form-group">
			<input name="submitted" type="submit" class="btn btn-default" value="Change Password" onClick="return validate_form()" autocomplete="off" >
			<input name="reset" type="reset" class="btn btn-default" id="submit2"  value="Reset"></td>
          
        </div>  
        
<!--table style="width: 400px; margin: 0 auto;">
<tr><th>Username or Email Address:</th><td><input name="username" type="text" size="20px" autocomplete="off" /></td></tr>
<tr><th>Current password:</th><td><input name="oldPassword" size="20px" type="password" /></td></tr>
<tr><th>New password:</th><td><input name="newPassword1" size="20px" type="password" /></td></tr>
<tr><th>New password (again):</th><td><input name="newPassword2" size="20px" type="password" /></td></tr>
<tr><td colspan="2" style="text-align: center;" >
<input name="submitted" type="submit" value="Change Password"/>
<button onclick="$('frm').action='changepassword.php';$('frm').submit();">Cancel</button>
</td></tr>
</table-->
</form>
</div>
</div>
</body>
</html>
