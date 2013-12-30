//
//  M3RegistrationExampleTests.m
//  M3RegistrationExampleTests
//
//  Created by Rok Cresnik on 30/12/13.
//  Copyright (c) 2013 Rok Cresnik. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "M3RegistrationManager.h"

@interface M3RegistrationExampleTests : XCTestCase <M3RegistartionManagerDelegate>

@property (nonatomic, strong) M3RegistrationManager *registrationManager;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *password;
@property (nonatomic) BOOL isRegistrationInProgress;
@property (nonatomic) BOOL didRegistrationSucced;

@property (nonatomic) BOOL isRegisteringBeforeLogin;

@end

@implementation M3RegistrationExampleTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.registrationManager = [[M3RegistrationManager alloc] init];
    self.registrationManager.delegate = self;
    int randomNumber = [[NSDate date] timeIntervalSince1970];
    self.email = [NSString stringWithFormat:@"%i@unittest.mice3.it", randomNumber];
    self.password = [self generatePassword];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    self.registrationManager.delegate = nil;
    [super tearDown];
}

- (void)testRegistrationWithNoData
{
    [self registerWithEmail:@"" andPassword:@""];
    XCTAssertEqual(NO, self.didRegistrationSucced, @"Registration should fail!!");
}

- (void)testRegistrationWithEmail
{
    [self registerWithEmail:@"rok@cresnik.com" andPassword:@""];
    XCTAssertEqual(NO, self.didRegistrationSucced, @"Registration should fail!!");
}

- (void)testRegistrationWithAllData
{
    [self registerWithEmail:self.email andPassword:self.password];
    XCTAssertEqual(YES, self.didRegistrationSucced, @"Registration should succed!!");
}

- (void)testLoginWithNoData
{
    [self loginWithEmail:@"" andPassword:@""];
    XCTAssertEqual(NO, self.didRegistrationSucced, @"Login should fail!!");
}

- (void)testLoginWithWrongEmailNoPassword
{
    [self loginWithEmail:@"rok" andPassword:@""];
    XCTAssertEqual(NO, self.didRegistrationSucced, @"Login should fail!!");
}

- (void)testLoginWithEmailNoPassword
{
    [self loginWithEmail:self.email andPassword:@""];
    XCTAssertEqual(NO, self.didRegistrationSucced, @"Login should fail!!");
}

- (void)testLoginWithEmailWrongPassword
{
    [self loginWithEmail:self.email andPassword:@"_____"];
    XCTAssertEqual(NO, self.didRegistrationSucced, @"Login should fail!!");
}

- (void)testLoginWithEmailAndPasswordUserDoesNotExist
{
    [self loginWithEmail:self.email andPassword:@"krompirjevzos"];
    XCTAssertEqual(NO, self.didRegistrationSucced, @"Login should fail!!");
}

- (void)testLoginWithEmailAndPasswordUserDoesExist
{
    self.isRegisteringBeforeLogin = YES;
    
    [self testRegistrationWithAllData];
    
    XCTAssertEqual(YES, self.didRegistrationSucced, @"Login should succed!!");
}

- (void)loginWithEmail:(NSString *)email
           andPassword:(NSString *)password
{
    [self.registrationManager loginWithEmail:email andPassword:password];
    
    [self waitTillDone];
}

- (void)registerWithEmail:(NSString *)email
              andPassword:(NSString *)password
{
    [self.registrationManager registerDeviceWithEmail:email andPassword:password];
    
    [self waitTillDone];
}


- (void)waitTillDone
{
    self.isRegistrationInProgress = YES;
    
    while (self.isRegistrationInProgress) {
        NSDate *oneSecond = [NSDate dateWithTimeIntervalSinceNow:1];
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:oneSecond];
    }
}

#pragma mark - M3RegistrationManager methods
- (void)onRegistrationSuccess:(id)responseData
{
    [self.registrationManager setAuthenticationDictionary:responseData];
    if (self.isRegisteringBeforeLogin) {
        self.isRegisteringBeforeLogin = NO;
        [self.registrationManager loginWithEmail:self.email andPassword:self.password];
    } else {
        self.didRegistrationSucced = YES;
        self.isRegistrationInProgress = NO;
    }
}

- (void)onRegistrationFailure:(id)error
{
    self.didRegistrationSucced = NO;
    self.isRegistrationInProgress = NO;
}

- (NSString *)generatePassword
{
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

    int len = 12;
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random() % [letters length]]];
    }
    
    return randomString;
}

@end

