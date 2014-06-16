
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

- (void)callScript:(NSString *)scriptName withParameters:(NSDictionary *)parameters;

@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, strong) TWAPIManager *apiManager;
@property (nonatomic, strong) NSArray *accounts;
@property (nonatomic, strong) UIViewController *viewController;
@property (nonatomic, strong) UIView *transparentView;
@end

//NSString *const FBSessionStateChangedNotification = @"it.mice3.flykly:FBSessionStateChangedNotification";


static M3RegistrationManager *instanceOfRegistrationManager;

@implementation M3RegistrationManager

+ (M3RegistrationManager *)sharedInstance
{
    if (instanceOfRegistrationManager) {
        return instanceOfRegistrationManager;
    } else {
        instanceOfRegistrationManager = [[M3RegistrationManager alloc] init];
        return instanceOfRegistrationManager;
    }
}

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

#pragma mark - Registration methods
- (void)registerDeviceWithEmail:(NSString *)email
{
    NSMutableDictionary *params = [[M3RegistrationManager getAuthenticationToken] mutableCopy];
    if (!params) {
        params = [[NSMutableDictionary alloc] initWithCapacity:3];
    }
    
    [params setValue:email forKey:@"email"];
    [params setValue:[[UIDevice currentDevice] model] forKey:@"deviceName"];
    
    [self callScript:kServerCreateDevice withParameters:params];
}

- (void)registerDeviceWithEmail:(NSString *)email
                    andPassword:(NSString *)password
{
    NSMutableDictionary *params = [[M3RegistrationManager getAuthenticationToken] mutableCopy];
    if (!params) {
        params = [[NSMutableDictionary alloc] initWithCapacity:3];
    }
    
    [params setValue:email forKey:@"email"];
    [params setValue:password forKey:@"password"];
    [params setValue:[[UIDevice currentDevice] model] forKey:@"deviceName"];
    
    [self callScript:kServerRegister withParameters:params];
}

- (void)registerDeviceWithFacebook
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sessionStateChanged:)
                                                 name:kFBSessionStateChangedNotification
                                               object:nil];
    [self openSessionWithAllowLoginUI:YES];
}

- (void)registerDeviceWithFacebookAccessToken:(NSString *)accessToken
{
    NSMutableDictionary *params = [[M3RegistrationManager getAuthenticationToken] mutableCopy];
    if (!params) {
        params = [[NSMutableDictionary alloc] initWithCapacity:3];
    }
    
    [params setValue:@"facebook" forKey:@"registrationType"];
    [params setValue:[[UIDevice currentDevice] model] forKey:@"deviceName"];
    [params setValue:accessToken forKey:@"accessToken"];
    
    [self callScript:kServerCreateDevice withParameters:params];
}

- (void)registerDeviceWithTwitter
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshTwitterAccounts)
                                                 name:ACAccountStoreDidChangeNotification
                                               object:nil];
    
    if ([TWAPIManager isLocalTwitterAccountAvailable]) {
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Choose an Account" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        
        for (ACAccount *acct in self.accounts) {
            [sheet addButtonWithTitle:acct.username];
        }
        
        sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Cancel"];
        [sheet showInView:self.viewController.view];
    } else {
        if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
            [self.delegate onRegistrationFailure:@"Please configure a Twitter account in Settings.app"];
        }
    }
}

- (void)registerDeviceWithTwitterAccessToken:(NSString *)accessToken
{
    NSMutableDictionary *params = [[M3RegistrationManager getAuthenticationToken] mutableCopy];
    if (!params) {
        params = [[NSMutableDictionary alloc] initWithCapacity:3];
    }
    [params setValue:@"twitter" forKey:@"registrationType"];
    [params setValue:[[UIDevice currentDevice] model] forKey:@"deviceName"];
    [params setValue:accessToken forKey:@"accessToken"];
    
    [self callScript:kServerCreateDevice withParameters:params];
}


#pragma mark - Login methods
- (void)loginWithEmail:(NSString *)email
           andPassword:(NSString *)password
{
    NSMutableDictionary *params = [[M3RegistrationManager getAuthenticationToken] mutableCopy];
    if (!params) {
        params = [[NSMutableDictionary alloc] initWithCapacity:3];
    }
    [params setValue:email forKey:@"email"];
    [params setValue:password forKey:@"password"];
    [params setValue:[[UIDevice currentDevice] model] forKey:@"deviceName"];
    
    [self callScript:kServerLogin withParameters:params];
}

- (void)loginWithFacebook
{
    
}

- (void)loginWithTwitter
{
    
}

#pragma mark - Other authentication methods
- (void)changeEmailTo:(NSString *)email
{    
    NSMutableDictionary *params = [[M3RegistrationManager getAuthenticationToken] mutableCopy];
    if (!params) {
        params = [[NSMutableDictionary alloc] initWithCapacity:3];
    }
    [params setValue:email forKey:@"email"];
    
    [self callScript:kServerChangeEmail withParameters:params];
}

- (void)resetPasswordForEmail:(NSString *)email
{
    [self callScript:kServerReserPassword withParameters:@{@"email": email}];
}

- (void)forgotPassword // withEmail!!
{
    NSDictionary *params = [M3RegistrationManager getAuthenticationToken];
    
    if (!params) {
        params = [[NSMutableDictionary alloc] initWithCapacity:3];
    }
    
    [self callScript:kServerForgotPassword withParameters:params];
}

+ (BOOL)validatePassword:(NSString *)password
{
    BOOL isValid = YES;
    if (password.length < 6) {
        isValid = NO;
    }
    
    return isValid;
}

+ (BOOL)validateEmail:(NSString *)email
{
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    
    return [emailTest evaluateWithObject:email];
}

- (void)connectWithFacebook
{
    // links the user with his FB profile
    [self registerDeviceWithFacebook];
}

- (void)checkUserStatus
{
    [self callScript:kConstantsCheckIfDeviceIsActivatedUrl withParameters:[M3RegistrationManager getAuthenticationToken]];
}


#pragma mark - Facebook auxilary methods
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

- (void)sessionStateChanged:(NSNotification*)notification
{
    if (FBSession.activeSession.isOpen) {
        [FBRequestConnection
         startForMeWithCompletionHandler:^(FBRequestConnection *connection,
                                           id<FBGraphUser> user,
                                           NSError *error) {
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            if (!error) {
                [self registerDeviceWithFacebookAccessToken:[FBSession.activeSession accessToken]];
            }
         }];
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
     postNotificationName:kFBSessionStateChangedNotification
     object:session];
    
    if (error) {
        if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
            [self.delegate onRegistrationFailure:[error localizedDescription]];
        }
    }
}

#pragma mark - Twitter auxilary methods
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
        if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
            [self.delegate onRegistrationFailure:@"Please configure a Twitter account in Settings.app"];
        }
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        [self.apiManager performReverseAuthForAccount:self.accounts[buttonIndex]
                                          withHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            if (responseData) {
                NSString *accessToken = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];

                NSLog(@"Reverse Auth process returned: %@", accessToken);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self registerDeviceWithTwitterAccessToken:accessToken];
                });
            }
            else {
                if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
                    [self.delegate onRegistrationFailure:[error localizedDescription]];
                }
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

#pragma mark - Authentication methods
- (void)callScript:(NSString *)scriptName withParameters:(NSDictionary *)parameters
{
    AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:
                            [NSURL URLWithString:kServerURL]];
    
    [client postPath:scriptName
          parameters:parameters
             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSString *responsString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                
                NSError *error;
                NSDictionary *responsDict = [NSJSONSerialization JSONObjectWithData:[responsString dataUsingEncoding:NSUTF8StringEncoding]
                                                                            options:NSJSONReadingMutableContainers
                                                                              error:&error];

                if (error
                    || [[responsDict valueForKey:@"hasError"] intValue] != 0) {
                    if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
                        [self.delegate onRegistrationFailure:error?[error localizedDescription]:[responsDict valueForKey:@"errorMessage"]];
                    }
                } else {
                    [self onAuthenticationSuccess:responsDict];
                    if ([self.delegate respondsToSelector:@selector(onRegistrationSuccess:)]) {
                        [self.delegate onRegistrationSuccess:responsDict];
                    }
                }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
            [self.delegate onRegistrationFailure:[error localizedDescription]];
        }
    }];
}

- (void)onAuthenticationSuccess:(NSDictionary *)parameters
{
    [M3RegistrationManager setAuthenticationToken:parameters];
}

#pragma mark get / set post parameters
+ (NSDictionary *)getAuthenticationToken
{
    NSDictionary *authToken = [[NSUserDefaults standardUserDefaults] objectForKey:kAuthToken];
    
    return authToken;
}

+ (void)setAuthenticationToken:(NSDictionary *)params
{
    NSDictionary *authToken = [params valueForKey:kAuthToken];
    authToken = authToken ? authToken : [params valueForKey:@"authenticationToken"];
    if (!authToken) {
        NSString * deviceId = [params valueForKey:kUserDeviceId];
        NSString * secureCode = [params valueForKey:kSecureCode];
        
        if (deviceId
            && secureCode) {
            authToken = @{kUserDeviceId: deviceId,
                          kSecureCode: secureCode};
        }
    }
    [M3RegistrationManager removeAuthenticationToken];
    [[NSUserDefaults standardUserDefaults] setObject:authToken forKey:kAuthToken];
}

+ (void)removeAuthenticationToken
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kAuthToken];
}

+ (void)activateDevice
{
    NSMutableDictionary *authToken = [[M3RegistrationManager getAuthenticationToken] mutableCopy];
    [authToken setObject:[NSNumber numberWithBool:YES] forKey:kDeviceActivated];
    
    [M3RegistrationManager setAuthenticationToken:@{kAuthToken: authToken}];
}

+ (BOOL)isUserActivated
{
    NSDictionary *authDict = [[NSUserDefaults standardUserDefaults] objectForKey:kAuthToken];
    
    if ([[authDict objectForKey:@"status"] rangeOfString:@"Activated"].location != NSNotFound) {
        return YES;
    }
    
    return [[authDict objectForKey:kDeviceActivated] boolValue];
}

@end
