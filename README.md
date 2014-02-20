M3RegistrationManager
===================
The M3RegistrationManager is a small class that (should) make the login/registration procedure easier.  
It was created for a couple of projects that needed different login/registartion types and after a couple iterations offers:  
- Facebook login (requires an app created on developer.facebook.com)  
- Twitter login (requires an app created on dev.twitter.com)  
- gmail login (login with the users gmail email and pass)  
- emaill + pass login  
  

It comes with a basic server side implementation (written in nodeJS) and needs the understanding of different login flows.  

Installation:
-------------
- Add the Social.framework, AdSupport.framework, libsqlite3.dylib, Accounts.framework, Twitter.framework, Security.framework  
- In your XCode Project, drag the M3RegistrationManager folder and AFNetworking (under the main folder) into your project  
- Import M3RegistrationManager.h  
- create a M3ServerConstants.h file which needs to containt the following constants:  
#define kServerURL                  @"serverUrl"  
// Authentication functions  
#define kServerLogin                kServerURL @"/mobile_scripts/login.php"  
#define kServerFBLogin              kServerURL @"/mobile_scripts/register.php"  
#define kServerRegister             kServerURL @"/mobile_scripts/register.php"  
#define kServerResetPassword        kServerURL @"/mobile_scripts/resetPassword.php"  
#define kServerChangePassword       kServerURL @"/mobile_scripts/login.php"  
// if auth sending params should be encapsulated into an user object  
#define kEncapsulateAuthParams          0  
// post parameter keys  
#define kParameterUser                  @"authentication_token"  
#define kParameterUserId                @"user_id"  
#define kParameterEmail                 @"email"  
#define kParameterPassword              @"password"  
#define kParameterPassword2             @"password_reentered"  
#define kParameterProvider              @"registrationType"  
#define kParameterAccessToken           @"accessToken"  
#define kParameterTearmsAgree           @"register_agree"  
#define kParameterAuthToken             @"authenticationToken"  
#define kParameterStatus                @"hasError"  
#define kParameterErrorDescription      @"show_message"  
#define kParameterError                 @"error"  
#define kParameterFriends               @"friends"  
#define kParameterOldPass               @"old_password"  
#define kParameterNewPass               @"new_password"  
#define kParameterNewPass2              @"new_password_repeat"  
// other constants  
#define kFacebookConnected @"facebookConnected"  
#define kUserDeviceId @"userId"  
#define kSecureCode @"secureCode"  
#define kDeviceActivated @"isActivated"  
// Twitter consumer key and secret  
#define kTWConsumerKey @""  
#define kTWConsumerSecret @""  
// Facebook state change notification  
#define kFBSessionStateChangedNotification @"com.acme.appName:FBSessionStateChangedNotification"     
- Start writing code!

The repository is in an alpha state, so if you have any questions or trouble, dont hesitate to ask :)

Optional:
---------
If you want FB login for users, that do not have native FB or the FB app add the following code to your AppDelegate.m:

```objc
// Import the FacebookSDK
#import <FacebookSDK/FacebookSDK.h>

// somewhere in the AppDelegate.m file add the following code
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    // attempt to extract a token from the url
    return [FBSession.activeSession handleOpenURL:url];
}
```
Example:  
--------
There is a working example added to the repo, which uses a nodeJS backend server and a mySQL database.  
The createDevice script is in the M3RegistrationManager.js file and features registration/log in possibilities for Facebook, Twitter, Gmail and email+pass


Requirements:
-------------
-iOS6.x or newer  
-ARC
