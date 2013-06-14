//
//  M3RegistrationManager.m
//  flykly
//
//  Created by Rok Cresnik on 5/6/13.
//  Copyright (c) 2013 Rok Cresnik. All rights reserved.
//

#import "M3RegistrationManager.h"
#import "AFHTTPClient.h"
#import <Twitter/Twitter.h>
#import "TWAPIManager.h"
#import "Accounts/Accounts.h"


#define kUserId @"userId"
#define kUserDeviceId @"userDeviceId"


@interface M3RegistrationManager ()
@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, strong) TWAPIManager *apiManager;
@property (nonatomic, strong) NSArray *accounts;
@property (nonatomic, strong) UIViewController *viewController;
@property (nonatomic, strong) UIView *transparentView;
@end

NSString *const FBSessionStateChangedNotification = @"it.mice3.flykly:FBSessionStateChangedNotification";

@implementation M3RegistrationManager

-(id)initWithViewController:(UIViewController *)viewController
{
    if (self = [super init]) {
        self.accountStore = [[ACAccountStore alloc] init];
        self.apiManager = [[TWAPIManager alloc] init];
        self.viewController = viewController;
        
        CGFloat height = [UIScreen mainScreen].bounds.size.height;
        self.transparentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, height)];
        self.transparentView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        UILabel *logingInLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, height / 2, 320, 50)];
        logingInLabel.backgroundColor = [UIColor clearColor];
        logingInLabel.textAlignment = NSTextAlignmentCenter;
        logingInLabel.text = @"Logging in...";
//        logingInLabel.font = [UIFont fontWithName:kFontHouschaBold size:30];
        logingInLabel.textColor = [UIColor whiteColor];
        [self.transparentView addSubview:logingInLabel];
    }
    return self;
}

-(void) registerDeviceWithRegistrationType:(M3RegistrationType)type
{
    NSDictionary *deviceDict = [M3RegistrationManager getUserDevicePostParamsDictionary];
    
    if(!deviceDict) {
        switch (type) {
            case M3RegistrationTypeEmail:
                [self registerDeviceWithEmail];
                break;
            case M3RegistrationTypeFacebook:
                if ([self.delegate respondsToSelector:@selector(showTransparentView:)]) {
                    [self.delegate showTransparentView:YES];
                }
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionStateChanged:) name:FBSessionStateChangedNotification object:nil];
                [self registerDeviceWithFacebook];
                break;
            case M3RegistrationTypeTwitter:
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTwitterAccounts) name:ACAccountStoreDidChangeNotification object:nil];
                [self registerDeviceWithTwitter];
                break;
            default:
                break;
        }
    }
}

-(void) loginWithParameters:(NSDictionary *)parameters
{
    AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:
                            [NSURL URLWithString:kServerURL]];
    
    [client postPath:kServerLogin parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([self.delegate respondsToSelector:@selector(showTransparentView:)]) {
            [self.delegate showTransparentView:NO];
        }
        
        NSString *text = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        
        NSError *error;
        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData: [text dataUsingEncoding:NSUTF8StringEncoding]
                                                             options: NSJSONReadingMutableContainers
                                                               error: &error];
        if (error) {
            if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
                [self.delegate onRegistrationFailure:text];
            }
        } else if( [[JSON valueForKey:@"hasError"] intValue] == 0) {
            if ([self.delegate respondsToSelector:@selector(onRegistrationSuccess:)]) {
                [self.delegate onRegistrationSuccess:JSON];
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
                [self.delegate onRegistrationFailure:[JSON valueForKey:@"errorMessage"]];
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if ([self.delegate respondsToSelector:@selector(showTransparentView:)]) {
            [self.delegate showTransparentView:NO];
        }
        
        if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
            [self.delegate onRegistrationFailure:[error description]];
        }
        
    }];
}

-(void) registerDeviceWithParameters:(NSDictionary *)parameters
{
    AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:
                            [NSURL URLWithString:kServerURL]];
    
    [client postPath:kServerCreateDevice parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([self.delegate respondsToSelector:@selector(showTransparentView:)]) {
            [self.delegate showTransparentView:NO];
        }
        
        NSString *text = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];

        NSError *error;
        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData: [text dataUsingEncoding:NSUTF8StringEncoding]
                                                             options: NSJSONReadingMutableContainers
                                                               error: &error];
        if (error) {
            if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
                [self.delegate onRegistrationFailure:text];
            }
        } else if( [[JSON valueForKey:@"hasError"] intValue] == 0) {
            if ([self.delegate respondsToSelector:@selector(onRegistrationSuccess:)]) {
                [self.delegate onRegistrationSuccess:JSON];
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
                [self.delegate onRegistrationFailure:[JSON valueForKey:@"errorMessage"]];
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if ([self.delegate respondsToSelector:@selector(showTransparentView:)]) {
            [self.delegate showTransparentView:NO];
        }
        
        if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
            [self.delegate onRegistrationFailure:[error description]];
        }
        
    }];
}

-(void) setUserDeviceId:(int) userDeviceId
          andSecureCode:(NSString *) secureCode
         andIsActivated:(BOOL) isActivated
{
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:userDeviceId] forKey:@"userDeviceId"];
    [[NSUserDefaults standardUserDefaults] setValue:secureCode forKey:@"secureCode"];
    
    if(isActivated) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isActivated"];
    }
    
}

-(void) showAlertViewWithText:(NSString *)text
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ApplicationTitle", nil)
                                                        message:text
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                              otherButtonTitles:nil];
    [alertView show];
}

#pragma mark - Email registration
-(void) registerDeviceWithEmail
{
    
}

-(void) registerDeviceWithEmail:(NSString *)email
{
    if ([self.delegate respondsToSelector:@selector(showTransparentView:)]) {
        [self.delegate showTransparentView:YES];
    }
    
    NSMutableDictionary *params = [[M3RegistrationManager getUserDevicePostParamsDictionary] mutableCopy];
    if (!params) {
        params = [[NSMutableDictionary alloc] initWithCapacity:3];
    }
    
    [params setValue:email forKey:@"email"];
    
    [params setValue:[[UIDevice currentDevice] model] forKey:@"deviceName"];
    
    [self registerDeviceWithParameters:params];
}

-(void) loginWithEmail:(NSString *)email
           andPassword:(NSString *)password
{
    if ([self.delegate respondsToSelector:@selector(showTransparentView:)]) {
        [self.delegate showTransparentView:YES];
    }
    
    NSMutableDictionary *params = [[M3RegistrationManager getUserDevicePostParamsDictionary] mutableCopy];
    if (!params) {
        params = [[NSMutableDictionary alloc] initWithCapacity:3];
    }
    [params setValue:email forKey:@"email"];
    [params setValue:password forKey:@"password"];
    
    [params setValue:[[UIDevice currentDevice] model] forKey:@"deviceName"];
    
    [self loginWithParameters:params];
}

-(void)forgotPassword
{
    if ([self.delegate respondsToSelector:@selector(showTransparentView:)]) {
        [self.delegate showTransparentView:YES];
    }
    
    AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:
                            [NSURL URLWithString:kServerURL]];
    
    NSDictionary *params = [M3RegistrationManager getUserDevicePostParamsDictionary];
    
    if (!params) {
        params = [[NSMutableDictionary alloc] initWithCapacity:3];
    }
    
    [client postPath:kServerForgotPassword
          parameters:params
             success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         if ([self.delegate respondsToSelector:@selector(showTransparentView:)]) {
             [self.delegate showTransparentView:NO];
         }
         NSString *text = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
         NSError *error;
         
         NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData: [text dataUsingEncoding:NSUTF8StringEncoding]
                                                              options: NSJSONReadingMutableContainers
                                                                error: &error];
         
         if (error) {
             if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
                 [self.delegate onRegistrationFailure:text];
             }
         } else if( [[JSON valueForKey:@"hasError"] intValue] == 0) {
             if ([self.delegate respondsToSelector:@selector(onRegistrationSuccess:)]) {
                 [self.delegate onRegistrationSuccess:JSON];
             }
         } else {
             if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
                 [self.delegate onRegistrationFailure:[JSON valueForKey:@"errorMessage"]];
             }
         }
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         if ([self.delegate respondsToSelector:@selector(showTransparentView:)]) {
             [self.delegate showTransparentView:NO];
         }
         
         if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
             [self.delegate onRegistrationFailure:[error description]];
         }
         
     }];
}


#pragma mark - Facebook registration
/*
 * Opens a Facebook session and optionally shows the login UX.
 */
- (BOOL)openSessionWithAllowLoginUI:(BOOL)allowLoginUI {
    NSArray *permissions = [[NSArray alloc] initWithObjects:
                            @"email",
                            nil];
    
    return [FBSession openActiveSessionWithReadPermissions:permissions
                                              allowLoginUI:allowLoginUI
                                         completionHandler:^(FBSession *session,
                                                             FBSessionState state,
                                                             NSError *error) {
                                             [self sessionStateChanged:session
                                                                 state:state
                                                                 error:error];
                                         }];
}


-(void) registerDeviceWithFacebook
{
    [self openSessionWithAllowLoginUI:YES];
}

- (void)sessionStateChanged:(NSNotification*)notification
{
    if (FBSession.activeSession.isOpen) {
        [FBRequestConnection
         startForMeWithCompletionHandler:^(FBRequestConnection *connection,
                                           id<FBGraphUser> user,
                                           NSError *error) {
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            if (!error) {
                [self registerDeviceWithFacebookEmail:[user objectForKey:@"email"]
                                        andFacebookId:user.id
                                       andAccessToken:[FBSession.activeSession accessToken]];
//                [self registerDeviceWithFacebookAccessToken:[FBSession.activeSession accessToken]];
            } else {
                if ([self.delegate respondsToSelector:@selector(showTransparentView:)]) {
                    [self.delegate showTransparentView:NO];
                }
            }
         }];
    } else {
    }
}

/*
 * Callback for session changes.
 */
- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState) state
                      error:(NSError *)error
{
    switch (state) {
        case FBSessionStateOpen:
            if (!error) {
                // We have a valid session
                NSLog(@"User session found");
            }
            break;
        case FBSessionStateClosed:
        case FBSessionStateClosedLoginFailed:
            [FBSession.activeSession closeAndClearTokenInformation];
            break;
        default:
            break;
    }
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:FBSessionStateChangedNotification
     object:session];
    
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Error"
                                  message:error.localizedDescription
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

-(void) registerDeviceWithFacebookAccessToken:(NSString *)accessToken
{
    NSLog(@"%@", accessToken);
}

-(void) registerDeviceWithFacebookEmail:(NSString *) email
                          andFacebookId:(NSString *)facebookId
                         andAccessToken:(NSString *)accessToken
{
    NSMutableDictionary *params = [[M3RegistrationManager getUserDevicePostParamsDictionary] mutableCopy];
    if (!params) {
        params = [[NSMutableDictionary alloc] initWithCapacity:3];
    }
    
    [params setValue:facebookId forKey:@"facebookId"];
    [params setValue:[[UIDevice currentDevice] model] forKey:@"deviceName"];
    [params setValue:accessToken forKey:@"accessToken"];
    
//    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kFacebookConnected];
    
    [self registerDeviceWithParameters:params];
}

-(void) connectWithFacebook
{
    // links the user with his FB profile
    [self registerDeviceWithRegistrationType:M3RegistrationTypeFacebook];
}

#pragma mark - Twitter registration
-(void) registerDeviceWithTwitter
{
    if ([TWAPIManager isLocalTwitterAccountAvailable]) {
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Choose an Account" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        
        for (ACAccount *acct in self.accounts) {
            [sheet addButtonWithTitle:acct.username];
        }
        
        sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Cancel"];
        [sheet showInView:self.viewController.view];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Accounts" message:@"Please configure a Twitter account in Settings.app" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

-(void) registerDeviceWithTwitterAccessToken:(NSString *)accessToken
{
    NSMutableDictionary *params = [[M3RegistrationManager getUserDevicePostParamsDictionary] mutableCopy];
    if (!params) {
        params = [[NSMutableDictionary alloc] initWithCapacity:3];
    }
    [params setValue:[[UIDevice currentDevice] model] forKey:@"deviceName"];
    [params setValue:accessToken forKey:@"accessToken"];
    
    [self registerDeviceWithParameters:params];
}

- (void)performReverseAuth:(id)sender
{
    if ([TWAPIManager isLocalTwitterAccountAvailable]) {
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Choose an Account" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        
        for (ACAccount *acct in self.accounts) {
            [sheet addButtonWithTitle:acct.username];
        }
        
        sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Cancel"];
        [sheet showInView:self.viewController.view];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Accounts" message:@"Please configure a Twitter account in Settings.app" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        if ([self.delegate respondsToSelector:@selector(showTransparentView:)]) {
            [self.delegate showTransparentView:YES];
        }
        [self.apiManager performReverseAuthForAccount:self.accounts[buttonIndex] withHandler:^(NSData *responseData, NSError *error) {
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            if (responseData) {
                NSString *accessToken = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];

                NSLog(@"Reverse Auth process returned: %@", accessToken);

                NSArray *lines = [accessToken componentsSeparatedByString:@"&"];
                NSString *twitterId = [[[lines objectAtIndex:2] componentsSeparatedByString:@"="] objectAtIndex:1];
                NSString *screenName = [[[lines objectAtIndex:3] componentsSeparatedByString:@"="] objectAtIndex:1];

                dispatch_async(dispatch_get_main_queue(), ^{
                    [self registerDeviceWithTwitterAccessToken:accessToken];
                });
            }
            else {
                NSLog(@"Reverse Auth process failed. Error returned was: %@\n", [error localizedDescription]);
            }
        }];
    }
}

- (void)obtainAccessToAccountsWithBlock:(void (^)(BOOL))block
{
    ACAccountType *twitterType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

    ACAccountStoreRequestAccessCompletionHandler handler = ^(BOOL granted, NSError *error) {
        if (granted) {
            self.accounts = [self.accountStore accountsWithAccountType:twitterType];
        }

        block(granted);
    };

    //  This method changed in iOS6. If the new version isn't available, fall back to the original (which means that we're running on iOS5+).
    if ([self.accountStore respondsToSelector:@selector(requestAccessToAccountsWithType:options:completion:)]) {
        [self.accountStore requestAccessToAccountsWithType:twitterType options:nil completion:handler];
    }
    else {
        [self.accountStore requestAccessToAccountsWithType:twitterType options:nil completion:handler];
    }
}

+(NSDictionary *) getUserDevicePostParamsDictionary
{
    NSString * deviceId = [[NSUserDefaults standardUserDefaults] stringForKey:kUserDeviceId];
    NSString * secureCode = [[NSUserDefaults standardUserDefaults] stringForKey:kSecureCode];
    
    if (deviceId && secureCode) {
        return @{kUserDeviceId: deviceId,
                 kSecureCode: secureCode};
    } else {
        return nil;
    }
}

@end
