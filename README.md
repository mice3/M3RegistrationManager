M3RegistrationManager
===================

Installation:
-------------
-Add the Social.framework, AdSupport.framework, libsqlite3.dylib, Accounts.framework, Twitter.framework, Security.framework  
-In your XCode Project, drag the M3RegistrationManager folder and AFNetworking (under the main folder) into your project  
-add the -fno-objc-arc Compiler Flags for the NSData+Base64.m, OAuth+Additions.m and OAuth.m files  
-Import M3RegistrationManager.h  
-in M3RegistrationConstants fill out your info  
-Start writing code!

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


Requirements:
-------------
-iOS6.x or newer  
-ARC
