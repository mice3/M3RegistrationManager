//
//  M3RegistrationManager.m
//  flykly
//
//  Created by Rok Cresnik on 5/6/13.
//  Copyright (c) 2013 Rok Cresnik. All rights reserved.
//

#import "M3RegistrationManager.h"
#import "AFHTTPRequestOperationManager.h"
#import <Twitter/Twitter.h>
#import "TWAPIManager.h"
#import "Accounts/Accounts.h"


#define kUserId @"userId"
#define kUserDeviceId @"userDeviceId"
#define kSecureCode @"secureCode"
#define kDeviceActivated @"deviceActivated"


@interface M3RegistrationManager ()
@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, strong) TWAPIManager *apiManager;
@property (nonatomic, strong) NSArray *accounts;
@property (nonatomic, strong) UIViewController *viewController;
@property (nonatomic, strong) UIView *transparentView;
@end

//NSString *const FBSessionStateChangedNotification = @"it.mice3.flykly:FBSessionStateChangedNotification";

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

-(void) loginWithParameters:(NSDictionary *)parameters
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    [manager POST:kLogin parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *JSON;
        
        NSError *error;
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            JSON = responseObject;
        } else {
            NSString *text = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
            
            JSON = [NSJSONSerialization JSONObjectWithData: [text dataUsingEncoding:NSUTF8StringEncoding]
                                                   options: NSJSONReadingMutableContainers
                                                     error: &error];
        }
        
        if (error) {
            if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
                [self.delegate onRegistrationFailure:error];
            }
        } else if( [[JSON valueForKey:@"hasError"] intValue] == 0
                  && [[JSON valueForKey:@"error"] length] == 0) {
            if ([self.delegate respondsToSelector:@selector(onRegistrationSuccess:)]) {
                [self.delegate onRegistrationSuccess:JSON];
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
                [self.delegate onRegistrationFailure:JSON];
            }
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
            [self.delegate onRegistrationFailure:error];
        }
    }];
}

-(void) registerDeviceWithParameters:(NSDictionary *)parameters
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    [manager POST:kRegister parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *JSON;
        
        NSError *error;
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            JSON = responseObject;
        } else {
            NSString *text = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
            
            JSON = [NSJSONSerialization JSONObjectWithData: [text dataUsingEncoding:NSUTF8StringEncoding]
                                                   options: NSJSONReadingMutableContainers
                                                     error: &error];
        }
        
        if (error) {
            if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
                [self.delegate onRegistrationFailure:error];
            }
        } else if( [[JSON valueForKey:@"hasError"] intValue] == 0
                  && [[JSON valueForKey:@"error"] length] == 0) {
            if ([self.delegate respondsToSelector:@selector(onRegistrationSuccess:)]) {
                [self.delegate onRegistrationSuccess:JSON];
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
                [self.delegate onRegistrationFailure:JSON];
            }
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
            [self.delegate onRegistrationFailure:error];
        }
    }];
}
//
//#pragma mark - Email registration
//
//-(void) registerDeviceWithEmail:(NSString *)email
//{
//    NSMutableDictionary *params = [[M3RegistrationManager getUserDevicePostParamsDictionary] mutableCopy];
//    if (!params) {
//        params = [[NSMutableDictionary alloc] initWithCapacity:3];
//    }
//    
//    [params setValue:email forKey:@"email"];
//    
//    [params setValue:[[UIDevice currentDevice] model] forKey:@"deviceName"];
//    
//    [self registerDeviceWithParameters:params];
//}
//
-(void) registerDeviceWithEmail:(NSString *)email
                    andPassword:(NSString *)password
{
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            email, @"email",
                            password,  @"password",
                            password,  @"password_reentered",
                            [NSNumber numberWithBool:YES],  @"register_agree", nil];
    
    [self registerDeviceWithParameters:params];
}

-(void) registerDeviceWithEmail:(NSString *)email
                    andPassword:(NSString *)password
                reenterPassword:(NSString *)password2
                   aggreToTerms:(BOOL)doesAgree
{
    NSString *doesAgreeString = @"N";
    if (doesAgree) {
        doesAgreeString = @"Y";
    }
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            email, @"email",
                            password,  @"password",
                            password2,  @"password_reentered",
                            doesAgreeString,  @"register_agree", nil];
    
    [self registerDeviceWithParameters:params];
}

//-(void) changeEmailTo:(NSString *)email
//{
//    NSMutableDictionary *params = [[M3RegistrationManager getUserDevicePostParamsDictionary] mutableCopy];
//    if (!params) {
//        params = [[NSMutableDictionary alloc] initWithCapacity:3];
//    }
//    
//    [params setValue:email forKey:@"email"];
//    
//    AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:
//                            [NSURL URLWithString:kServerURL]];
//    
//    [client postPath:kServerChangeEmail parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSString *text = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
//        
//        NSError *error;
//        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData: [text dataUsingEncoding:NSUTF8StringEncoding]
//                                                             options: NSJSONReadingMutableContainers
//                                                               error: &error];
//        if (error) {
//            if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
//                [self.delegate onRegistrationFailure:text];
//            }
//        } else if( [[JSON valueForKey:@"hasError"] intValue] == 0) {
//            if ([self.delegate respondsToSelector:@selector(onRegistrationSuccess:)]) {
//                [self.delegate onRegistrationSuccess:JSON];
//            }
//        } else {
//            if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
//                [self.delegate onRegistrationFailure:[JSON valueForKey:@"errorMessage"]];
//            }
//        }
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
//            [self.delegate onRegistrationFailure:[error description]];
//        }
//        
//    }];
//    
//}
//
-(void) loginWithEmail:(NSString *)email
           andPassword:(NSString *)password
{
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            email, @"email",
                            password,  @"password", nil];
    
    [self loginWithParameters:params];
}

- (void)resetPasswordForEmail:(NSString *)email
{
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                            email, @"email", nil];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    [manager POST:kResetPassword parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *JSON;
        
        NSError *error;
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            JSON = responseObject;
        } else {
            NSString *text = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
            
            JSON = [NSJSONSerialization JSONObjectWithData: [text dataUsingEncoding:NSUTF8StringEncoding]
                                                   options: NSJSONReadingMutableContainers
                                                     error: &error];
        }
        
        if (error) {
            if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
                [self.delegate onRegistrationFailure:error];
            }
        } else if( [[JSON valueForKey:@"hasError"] intValue] == 0
                  && [[JSON valueForKey:@"error"] length] == 0) {
            if ([self.delegate respondsToSelector:@selector(onRegistrationSuccess:)]) {
                [self.delegate onRegistrationSuccess:JSON];
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
                [self.delegate onRegistrationFailure:JSON];
            }
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
            [self.delegate onRegistrationFailure:error];
        }
    }];
}
//
//-(void)forgotPassword
//{
//    AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:
//                            [NSURL URLWithString:kServerURL]];
//    
//    NSDictionary *params = [M3RegistrationManager getUserDevicePostParamsDictionary];
//    
//    if (!params) {
//        params = [[NSMutableDictionary alloc] initWithCapacity:3];
//    }
//    
//    [client postPath:kServerForgotPassword parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSString *text = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
//        NSError *error;
//        
//        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData: [text dataUsingEncoding:NSUTF8StringEncoding]
//                                                             options: NSJSONReadingMutableContainers
//                                                               error: &error];
//        
//        if (error) {
//            if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
//                [self.delegate onRegistrationFailure:text];
//            }
//        } else if( [[JSON valueForKey:@"hasError"] intValue] == 0) {
//            if ([self.delegate respondsToSelector:@selector(onRegistrationSuccess:)]) {
//                [self.delegate onRegistrationSuccess:JSON];
//            }
//        } else {
//            if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
//                [self.delegate onRegistrationFailure:[JSON valueForKey:@"errorMessage"]];
//            }
//        }
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
//            [self.delegate onRegistrationFailure:[error description]];
//        }
//        
//    }];
//}
//
//
//#pragma mark - Facebook registration
///*
// * Opens a Facebook session and optionally shows the login UX.
// */
//- (BOOL)openSessionWithAllowLoginUI:(BOOL)allowLoginUI {
//    NSArray *permissions = [[NSArray alloc] initWithObjects:
//                            @"email",
//                            nil];
//    
//    return [FBSession openActiveSessionWithReadPermissions:permissions
//                                              allowLoginUI:allowLoginUI
//                                         completionHandler:^(FBSession *session,
//                                                             FBSessionState state,
//                                                             NSError *error) {
//                                             [self sessionStateChanged:session
//                                                                 state:state
//                                                                 error:error];
//                                         }];
//}
//
//
//-(void) registerDeviceWithFacebook
//{
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(sessionStateChanged:)
//                                                 name:kFBSessionStateChangedNotification
//                                               object:nil];
//    [self openSessionWithAllowLoginUI:YES];
//}
//
//- (void)sessionStateChanged:(NSNotification*)notification
//{
//    if (FBSession.activeSession.isOpen) {
//        [FBRequestConnection
//         startForMeWithCompletionHandler:^(FBRequestConnection *connection,
//                                           id<FBGraphUser> user,
//                                           NSError *error) {
//             [[NSNotificationCenter defaultCenter] removeObserver:self];
//             if (!error) {
//                 [self registerDeviceWithFacebookAccessToken:[FBSession.activeSession accessToken]];
//             }
//         }];
//    }
//}
//
///*
// * Callback for session changes.
// */
//- (void)sessionStateChanged:(FBSession *)session
//                      state:(FBSessionState) state
//                      error:(NSError *)error
//{
//    switch (state) {
//        case FBSessionStateOpen:
//            if (!error) {
//                // We have a valid session
//                NSLog(@"User session found");
//            }
//            break;
//        case FBSessionStateClosed:
//        case FBSessionStateClosedLoginFailed:
//            [FBSession.activeSession closeAndClearTokenInformation];
//            break;
//        default:
//            break;
//    }
//    
//    [[NSNotificationCenter defaultCenter]
//     postNotificationName:kFBSessionStateChangedNotification
//     object:session];
//    
//    if (error) {
//        if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
//            [self.delegate onRegistrationFailure:[error description]];
//        }
//    }
//}
//
//-(void) registerDeviceWithFacebookAccessToken:(NSString *)accessToken
//{
//    NSMutableDictionary *params = [[M3RegistrationManager getUserDevicePostParamsDictionary] mutableCopy];
//    if (!params) {
//        params = [[NSMutableDictionary alloc] initWithCapacity:3];
//    }
//    
//    [params setValue:@"facebook" forKey:@"registrationType"];
//    [params setValue:[[UIDevice currentDevice] model] forKey:@"deviceName"];
//    [params setValue:accessToken forKey:@"accessToken"];
//    
//    [self registerDeviceWithParameters:params];
//}
//
//-(void) loginWithFacebook
//{
//    
//}
//
//-(void) connectWithFacebook
//{
//    // links the user with his FB profile
//    [self registerDeviceWithFacebook];
//}
//
//#pragma mark - Twitter registration
//-(void) registerDeviceWithTwitter
//{
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(refreshTwitterAccounts)
//                                                 name:ACAccountStoreDidChangeNotification
//                                               object:nil];
//    
//    if ([TWAPIManager isLocalTwitterAccountAvailable]) {
//        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Choose an Account" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
//        
//        for (ACAccount *acct in self.accounts) {
//            [sheet addButtonWithTitle:acct.username];
//        }
//        
//        sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Cancel"];
//        [sheet showInView:self.viewController.view];
//    } else {
//        if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
//            [self.delegate onRegistrationFailure:@"Please configure a Twitter account in Settings.app"];
//        }
//    }
//}
//
//-(void) registerDeviceWithTwitterAccessToken:(NSString *)accessToken
//{
//    NSMutableDictionary *params = [[M3RegistrationManager getUserDevicePostParamsDictionary] mutableCopy];
//    if (!params) {
//        params = [[NSMutableDictionary alloc] initWithCapacity:3];
//    }
//    [params setValue:@"twitter" forKey:@"registrationType"];
//    [params setValue:[[UIDevice currentDevice] model] forKey:@"deviceName"];
//    [params setValue:accessToken forKey:@"accessToken"];
//    
//    [self registerDeviceWithParameters:params];
//}
//
//- (void)performReverseAuth:(id)sender
//{
//    if ([TWAPIManager isLocalTwitterAccountAvailable]) {
//        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Choose an Account" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
//        
//        for (ACAccount *acct in self.accounts) {
//            [sheet addButtonWithTitle:acct.username];
//        }
//        
//        sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Cancel"];
//        [sheet showInView:self.viewController.view];
//    }
//    else {
//        if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
//            [self.delegate onRegistrationFailure:@"Please configure a Twitter account in Settings.app"];
//        }
//    }
//}
//
//- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//    if (buttonIndex != actionSheet.cancelButtonIndex) {
//        [self.apiManager performReverseAuthForAccount:self.accounts[buttonIndex]
//                                          withHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
//                                              [[NSNotificationCenter defaultCenter] removeObserver:self];
//                                              if (responseData) {
//                                                  NSString *accessToken = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
//                                                  
//                                                  NSLog(@"Reverse Auth process returned: %@", accessToken);
//                                                  dispatch_async(dispatch_get_main_queue(), ^{
//                                                      [self registerDeviceWithTwitterAccessToken:accessToken];
//                                                  });
//                                              }
//                                              else {
//                                                  if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
//                                                      [self.delegate onRegistrationFailure:[error localizedDescription]];
//                                                  }
//                                                  NSLog(@"Reverse Auth process failed. Error returned was: %@\n", [error localizedDescription]);
//                                              }
//                                          }];
//    } else {
//        if ([self.delegate respondsToSelector:@selector(onRegistrationCancel)]) {
//            [self.delegate onRegistrationCancel];
//        }
//    }
//}
//
//- (void)obtainAccessToAccountsWithBlock:(void (^)(BOOL))block
//{
//    ACAccountType *twitterType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
//    
//    ACAccountStoreRequestAccessCompletionHandler handler = ^(BOOL granted, NSError *error) {
//        if (granted) {
//            self.accounts = [self.accountStore accountsWithAccountType:twitterType];
//        }
//        
//        block(granted);
//    };
//    
//    //  This method changed in iOS6. If the new version isn't available, fall back to the original (which means that we're running on iOS5+).
//    if ([self.accountStore respondsToSelector:@selector(requestAccessToAccountsWithType:options:completion:)]) {
//        [self.accountStore requestAccessToAccountsWithType:twitterType options:nil completion:handler];
//    }
//    else {
//        [self.accountStore requestAccessToAccountsWithType:twitterType options:nil completion:handler];
//    }
//}
//
//-(void) loginWithTwitter
//{
//    
//}


#pragma mark get / set post parameters
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

-(void) setUserDeviceId:(int) userDeviceId
          andSecureCode:(NSString *) secureCode
         andIsActivated:(BOOL) isActivated
{
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:userDeviceId] forKey:kUserDeviceId];
    [[NSUserDefaults standardUserDefaults] setValue:secureCode forKey:kSecureCode];
    
    if(isActivated) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kDeviceActivated];
    }
    
    NSLog(@"%@", [M3RegistrationManager getUserDevicePostParamsDictionary]);
}

-(void) activateUserDevice
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isActivated"];
}

#pragma mark - Registration helper methods
+ (BOOL)isEmailAddressValid:(NSString *)emailAddress
{
    BOOL stricterFilter = YES; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    NSString *stricterFilterString = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
    NSString *laxString = @".+@([A-Za-z0-9]+\\.)+[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    
    return [emailTest evaluateWithObject:emailAddress];
}

+ (BOOL)doPasswordsMatch:(NSString *)password and:(NSString *)password2
{
    if ([password isEqualToString:password2]) {
        return YES;
    }
    return NO;
}

@end
