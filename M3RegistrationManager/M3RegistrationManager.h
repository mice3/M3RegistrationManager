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

@protocol M3RegistrationDelegate <NSObject>
- (void)onRegistrationSuccess:(NSDictionary *)responseData;
@optional
- (void)onRegistrationFailure:(id)error;
@end

@interface M3RegistrationManager : NSObject <UIActionSheetDelegate>

@property (nonatomic, strong) id<M3RegistrationDelegate> delegate;

/*
 viewController is the view where registration happens (we need it so that the touches can be disabled while the
 procedure takes place
 */
+ (M3RegistrationManager *)sharedInstance;
-(id)initWithViewController:(UIViewController *)viewController;

// Registration methods
-(void) registerDeviceWithEmail:(NSString *)email
                    andPassword:(NSString *)password;
-(void) registerDeviceWithEmail:(NSString *)email;
-(void) registerDeviceWithFacebook;
-(void) registerDeviceWithTwitter;

// Login methods
-(void) loginWithEmail:(NSString *)email
           andPassword:(NSString *)password;
-(void) loginWithFacebook;
-(void) loginWithTwitter;

// Other authentication methods
- (void)changeEmailTo:(NSString *)email;
- (void)resetPasswordForEmail:(NSString *)email;
- (void)forgotPassword;
- (void)connectWithFacebook;
+ (BOOL)validatePassword:(NSString *)password;
+ (BOOL)validateEmail:(NSString *)email;

// Authentication token methods
+ (void)activateDevice;
+ (void)setAuthenticationToken:(NSDictionary *)authToken;
+ (NSDictionary *)getAuthenticationToken;
+ (void)removeAuthenticationToken;


// twitter reverse auth method
- (void)obtainAccessToAccountsWithBlock:(void (^)(BOOL))block;

@end
