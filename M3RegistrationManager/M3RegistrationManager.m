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



@interface M3RegistrationManager ()
@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, strong) TWAPIManager *apiManager;
@property (nonatomic, strong) NSArray *accounts;
@property (nonatomic, strong) UIViewController *viewController;
@property (nonatomic, strong) UIView *transparentView;
@end

//NSString *const FBSessionStateChangedNotification = @"it.mice3.flykly:FBSessionStateChangedNotification";

@implementation M3RegistrationManager


- (id)initWithDelegate:(id<M3RegistartionManagerDelegate>)delegate
{
    if (self = [super init]) {
        self.delegate = delegate;
    }
    return self;
}

- (id)initWithViewController:(UIViewController *)viewController
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

- (void)onAuthenticationSuccess: (NSDictionary *) json
{
    if ([json objectForKey:kParameterAuthToken]) {
        [M3RegistrationManager setAuthenticationDictionary:[json objectForKey:kParameterAuthToken]];
    }
}

#pragma mark - Email registration
- (void)registerDeviceWithEmail:(NSString *)email
                    andPassword:(NSString *)password
                reenterPassword:(NSString *)password2
                   aggreToTerms:(BOOL)doesAgree
{
    NSMutableDictionary *params = [@{kParameterEmail : email,
                                     kParameterPassword : password,
                                     kParameterPassword2 : password2}
                                   mutableCopy];
    if (doesAgree) {
        [params setValue:@"Y" forKey:kParameterTearmsAgree];
    }

    [self callServerScript:kServerRegister withPOSTParameters:params];
}

- (void)registerDeviceWithEmail:(NSString *)email
{
    NSDictionary *params = @{kParameterEmail : email};

    [self callServerScript:kServerRegister withPOSTParameters:params];
}

- (void)registerDeviceWithEmail:(NSString *)email
                    andPassword:(NSString *)password
{
    NSDictionary *params = @{kParameterEmail : email,
                             kParameterPassword : password};
    
    [self callServerScript:kServerRegister withPOSTParameters:params];
}

- (void)changePassword:(NSString *)oldPassword
           newPassword:(NSString *)password
        repeatPassword:(NSString *)password2
{
    NSMutableDictionary *params = [[M3RegistrationManager getAuthenticationDictionary] mutableCopy];
    if (!params) {
        params = [[NSMutableDictionary alloc] initWithCapacity:3];
    }
    
    [params setValue:oldPassword forKey:kParameterOldPass];
    [params setValue:password forKey:kParameterNewPass];
    [params setValue:password2 forKey:kParameterNewPass2];
    
    [self callServerScript:kServerChangePassword withPOSTParameters:params];
}

- (void)callServerScript:(NSString *)serverScript withPOSTParameters:(NSDictionary *)parameters
{
    // Enacapsulate the parameters in a user dict (REST architecture purposes)
    NSDictionary *postParameters =  @{kParameterUser : parameters};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    [manager POST:serverScript parameters:postParameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (![[responseObject objectForKey:kParameterStatus] intValue]) {
            if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
                [self.delegate onRegistrationFailure:[responseObject objectForKey:kParameterError]];
            }
        } else {
            [self onAuthenticationSuccess:responseObject];
            if ([self.delegate respondsToSelector:@selector(onRegistrationSuccess:)]) {
                [self.delegate onRegistrationSuccess:responseObject];
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
            [self.delegate onRegistrationFailure:[error localizedDescription]];
        }
    }];
}

//-(void) changeEmailTo:(NSString *)email
//{
//    NSMutableDictionary *params = [[M3RegistrationManager getAuthenticationDictionary] mutableCopy];
//    if (!params) {
//        params = [[NSMutableDictionary alloc] initWithCapacity:3];
//    }
//    
//    [params setValue:email forKey:@"email"];
//    // call server script
//}

- (void)loginWithEmail:(NSString *)email
           andPassword:(NSString *)password
{
    NSDictionary *params = @{kParameterEmail : email,
                             kParameterPassword : password};
    
    [self callServerScript:kServerLogin withPOSTParameters:params];
}

- (void)resetPasswordForEmail:(NSString *)email
{
    NSMutableDictionary *params = [[M3RegistrationManager getAuthenticationDictionary] mutableCopy];
    if (!params) {
        params = [[NSMutableDictionary alloc] initWithCapacity:3];
    }
    [params setValue:email forKey:kParameterEmail];
    
    [self callServerScript:kServerResetPassword withPOSTParameters:params];
    
}
//-(void)forgotPassword
//{
//    AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:
//                            [NSURL URLWithString:kServerURL]];
//    
//    NSDictionary *params = [M3RegistrationManager getAuthenticationDictionary];
//    
//    if (!params) {
//        params = [[NSMutableDictionary alloc] initWithCapacity:3];
//    }
//    // call 
//}


#pragma mark - Facebook registration
/*
 * Opens a Facebook session and optionally shows the login UX.
 */

- (void)registerDeviceWithFacebook
{
    if (FBSession.activeSession.state == FBSessionStateOpen
        || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
        [self registerDeviceWithFacebookAccessToken:[FBSession.activeSession.accessTokenData accessToken]];
    } else {
        // Open a session showing the user the login UI
        // You must ALWAYS ask for basic_info permissions when opening a session
        NSArray *permissions = [[NSArray alloc] initWithObjects:
                                @"basic_info",
                                @"email",
                                nil];
        
        [FBSession openActiveSessionWithReadPermissions:permissions
                                           allowLoginUI:YES
                                      completionHandler:
         ^(FBSession *session, FBSessionState state, NSError *error) {
             
             // Retrieve the app delegate
             // Call the app delegate's sessionStateChanged:state:error method to handle session state changes
             [self sessionStateChanged:session state:state error:error];
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
    // If the session was opened successfully
    if (!error && state == FBSessionStateOpen){
        NSLog(@"Session opened");
        [self registerDeviceWithFacebookAccessToken:[FBSession.activeSession.accessTokenData accessToken]];
        return;
    }
    if (state == FBSessionStateClosed || state == FBSessionStateClosedLoginFailed){
        // If the session is closed
        NSLog(@"Session closed");
    }
    
    // Handle errors
    if (error){
        NSLog(@"Error");
        NSString *alertText;
        NSString *alertTitle;
        // If the error requires people using an app to make an action outside of the app in order to recover
        if ([FBErrorUtility shouldNotifyUserForError:error] == YES){
            alertTitle = @"Something went wrong";
            alertText = [FBErrorUtility userMessageForError:error];
            //            [self showMessage:alertText withTitle:alertTitle];
        } else {
            
            // If the user cancelled login, do nothing
            if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
                NSLog(@"User cancelled login");
                
                // Handle session closures that happen outside of the app
            } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession){
                alertTitle = @"Session Error";
                alertText = @"Your current session is no longer valid. Please log in again.";
                //                [self showMessage:alertText withTitle:alertTitle];
                
                // Here we will handle all other errors with a generic error message.
                // We recommend you check our Handling Errors guide for more information
                // https://developers.facebook.com/docs/ios/errors/
            } else {
                //Get more error information from the error
                NSDictionary *errorInformation = [[[error.userInfo objectForKey:@"com.facebook.sdk:ParsedJSONResponseKey"] objectForKey:@"body"] objectForKey:@"error"];
                
                // Show the user an error message
                alertTitle = @"Something went wrong";
                alertText = [NSString stringWithFormat:@"Please retry. \n\n If the problem persists contact us and mention this error code: %@", [errorInformation objectForKey:@"message"]];
                //                [self showMessage:alertText withTitle:alertTitle];
            }
        }
        // Clear this token
        [FBSession.activeSession closeAndClearTokenInformation];
        // Show the user the logged-out UI
        //        [self userLoggedOut];
        
        if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
            [self.delegate onRegistrationFailure:alertText];
        }
    }
    
    switch (state) {
        case FBSessionStateOpen:
            if (!error) {
                [self registerDeviceWithFacebookAccessToken:[FBSession.activeSession.accessTokenData accessToken]];
            }
            break;
        case FBSessionStateClosed:
        case FBSessionStateClosedLoginFailed:
            [FBSession.activeSession closeAndClearTokenInformation];
            break;
        default:
            break;
    }
}

- (void)registerDeviceWithFacebookAccessToken:(NSString *)accessToken
{
    NSMutableDictionary *params = [[M3RegistrationManager getAuthenticationDictionary] mutableCopy];
    if (!params) {
        params = [[NSMutableDictionary alloc] initWithCapacity:3];
    }
    [params setObject:@"facebook" forKey:kParameterProvider];
    [params setObject:accessToken forKey:kParameterAccessToken];
    
    [self callServerScript:kServerFBLogin withPOSTParameters:params];
}

- (void)loginWithFacebook
{
    
}

- (void)connectWithFacebook
{
    // links the user with his FB profile
    [self registerDeviceWithFacebook];
}

#pragma mark - Twitter registration
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
    NSMutableDictionary *params = [[M3RegistrationManager getAuthenticationDictionary] mutableCopy];
    if (!params) {
        params = [[NSMutableDictionary alloc] initWithCapacity:3];
    }
    [params setValue:@"twitter" forKey:kParameterProvider];
    [params setValue:accessToken forKey:kParameterAccessToken];
    
    [self callServerScript:kServerRegister withPOSTParameters:params];
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
                                              if (error) {
                                                  if ([self.delegate respondsToSelector:@selector(onRegistrationFailure:)]) {
                                                      [self.delegate onRegistrationFailure:[error localizedDescription]];
                                                  }
                                              } else {
                                                  NSString *accessToken = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      [self registerDeviceWithTwitterAccessToken:accessToken];
                                                  });
                                              }
                                          }];
    } else {
        if ([self.delegate respondsToSelector:@selector(onRegistrationCancel)]) {
            [self.delegate onRegistrationCancel];
        }
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

- (void)loginWithTwitter
{
    
}

#pragma mark get / set post parameters
+ (NSDictionary *)getAuthenticationDictionary
{
    NSDictionary *authDict = [[NSUserDefaults standardUserDefaults] objectForKey:kParameterAuthToken];
    if (authDict) {
        return @{kParameterAuthToken : authDict};
    }
    
    return nil;
}

+ (void)setAuthenticationDictionary:(NSDictionary *)dic
{
    [[NSUserDefaults standardUserDefaults] setObject:dic forKey:kParameterAuthToken];
}

+ (void)removeAuthenticationDictionary
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kParameterAuthToken];
}

@end
