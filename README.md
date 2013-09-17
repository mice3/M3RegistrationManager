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
- create a M3RegistrationConstants.h file which needs to containt the following constants:  
            a) #define kServerURL // url of your backend server  
            b) #define kServerCreateDevice // createDevice script (check the M3RegistrationServer for tips or a basic implementation)  
            c) #define kTWConsumerKey // your Twitter Consumer key (only if Twitter login is required)  
            d) #define kTWConsumerSecret // your Twitter Consumer Secret (only if Twitter login is required)  
            e) #define kFBSessionStateChangedNotification // Facebook state change notification (generaly it looks like com.acme.appName:FBSessionStateChangedNotification    
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
