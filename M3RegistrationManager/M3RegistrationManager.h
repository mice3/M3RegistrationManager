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

typedef enum{
    M3RegistrationTypeFacebook,
    M3RegistrationTypeTwitter,
    M3RegistrationTypeEmail
} M3RegistrationType;

@protocol M3RegistartionManagerDelegate <NSObject>
-(void)onRegistrationSuccess:(NSDictionary *)responseData;
@optional
-(void)showTransparentView:(BOOL)showView;
-(void)onRegistrationFailure:(NSString *)errorString;
@end

@interface M3RegistrationManager : NSObject <UIActionSheetDelegate>

@property (nonatomic, strong) id<M3RegistartionManagerDelegate> delegate;

/*
 viewController is the view where registration happens (we need it so that the touches can be disabled while the
 procedure takes place
*/
-(id)initWithViewController:(UIViewController *)viewController;
/*
 register with either FB, TW or email
*/
-(void) registerDeviceWithRegistrationType:(M3RegistrationType)type;
-(void) registerDeviceWithEmail:(NSString *)email
                    andPassword:(NSString *)password;
-(void) registerDeviceWithEmail:(NSString *)email;
-(void) loginWithEmail:(NSString *)email
           andPassword:(NSString *)password;
-(void)forgotPassword;
-(void) setUserDeviceId:(int) userDeviceId
          andSecureCode:(NSString *) secureCode
         andIsActivated:(BOOL) isActivated;
-(void)activateUserDevice;
// connects the current account with facebook
-(void)connectWithFacebook;

- (void)obtainAccessToAccountsWithBlock:(void (^)(BOOL))block;

// Class metohds
+(NSDictionary *) getUserDevicePostParamsDictionary;

@end
