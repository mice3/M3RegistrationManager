//
//  M3RegistrationManager.h
//  flykly
//
//  Created by Rok Cresnik on 5/6/13.
//  Copyright (c) 2013 Rok Cresnik. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum{
    M3RegistrationTypeFacebook,
    M3RegistrationTypeTwitter,
    M3RegistrationTypeEmail
} M3RegistrationType;

@interface M3RegistrationManager : NSObject <UIActionSheetDelegate>

-(id)initWithViewController:(UIViewController *)viewController;
-(void) registerDeviceWithRegistrationType:(M3RegistrationType)type;
-(void) registerDeviceWithEmail:(NSString *)email
                    andPassword:(NSString *)password;
-(void)connectWithFacebook;

- (void)obtainAccessToAccountsWithBlock:(void (^)(BOOL))block;

@end
