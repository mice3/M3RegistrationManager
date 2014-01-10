//
//  M3RegistrationManager.h
//  flykly
//
//  Created by Rok Cresnik on 5/6/13.
//  Copyright (c) 2013 Rok Cresnik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>
#import "M3RegistrationConstants.h"

#define kAuthenticationTokenKey @"authenticationToken"

@protocol M3RegistartionManagerDelegate <NSObject>
- (void)onRegistrationSuccess:(NSDictionary *)responseData;
@optional
- (void)onRegistrationCancel;
- (void)onRegistrationFailure:(id)errorResponse;
@end

@interface M3RegistrationManager : NSObject <UIActionSheetDelegate>

@property (nonatomic, strong) id<M3RegistartionManagerDelegate> delegate;

/*
 viewController is the view where registration happens (we need it so that the touches can be disabled while the
 procedure takes place
*/
- (id)initWithDelegate:(id<M3RegistartionManagerDelegate>)delegate;
-(id)initWithViewController:(UIViewController *)viewController;

// register new user
-(void) registerDeviceWithEmail:(NSString *)email
                    andPassword:(NSString *)password
                reenterPassword:(NSString *)password2
                   aggreToTerms:(BOOL)doesAgree;
-(void) registerDeviceWithEmail:(NSString *)email
                    andPassword:(NSString *)password;
-(void) registerDeviceWithEmail:(NSString *)email;
-(void) registerDeviceWithFacebook;
-(void) registerDeviceWithTwitter;

// login an existing user
-(void) loginWithEmail:(NSString *)email
           andPassword:(NSString *)password;
// TODO: separate login and register methods for Twitter & Facebook
-(void) loginWithFacebook;
-(void) loginWithTwitter;

// other methods
- (void)changePassword:(NSString *)oldPassword
           newPassword:(NSString *)password
        repeatPassword:(NSString *)password2;
- (void)resetPasswordForEmail:(NSString *)email;
- (void)changeEmailTo:(NSString *)email;
- (void)forgotPassword;


+ (NSDictionary *) getAuthenticationDictionary;
+ (void) setAuthenticationDictionary: (NSDictionary *) dic;
+ (void) removeAuthenticationDictionary;

- (void)setUserId:(int) userDeviceId
    andSecureCode:(NSString *) secureCode;

- (void)setUserDeviceId:(int) userDeviceId
          andSecureCode:(NSString *) secureCode
         andIsActivated:(BOOL) isActivated;

- (void)activateUserDevice;

// connects the current account with facebook
- (void)connectWithFacebook;

// twitter reverse auth method
- (void)obtainAccessToAccountsWithBlock:(void (^)(BOOL))block;

@end
