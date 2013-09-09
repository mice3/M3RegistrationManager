//
//  ViewController.m
//  M3RegistrationExample
//
//  Created by Rok Cresnik on 09/09/13.
//  Copyright (c) 2013 Rok Cresnik. All rights reserved.
//

#import "RegistrationViewController.h"

@interface RegistrationViewController ()

@property (nonatomic, retain) M3RegistrationManager *registrationManager;
@property (weak, nonatomic) IBOutlet UIButton *twitterButtton;

@end

@implementation RegistrationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.registrationManager = [[M3RegistrationManager alloc] initWithViewController:self];
    self.registrationManager.delegate = self;
    self.twitterButtton.enabled = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    
    [self refreshTwitterAccounts];
}

- (IBAction)facebookButtonClickHandler:(id)sender
{
    [self.registrationManager registerDeviceWithRegistrationType:M3RegistrationTypeFacebook];
}

- (IBAction)twitterButtonClickHandler:(id)sender
{
    [self.registrationManager registerDeviceWithRegistrationType:M3RegistrationTypeTwitter];
}

- (IBAction)emailButtonClickHandler:(id)sender {
}

- (void)refreshTwitterAccounts
{
    NSLog(@"Refreshing Twitter Accounts \n");
    
    [self.registrationManager obtainAccessToAccountsWithBlock:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                self.twitterButtton.enabled = YES;
            }
            else {
                NSLog(@"You were not granted access to the Twitter accounts.");
            }
        });
    }];
}

- (void)onRegistrationSuccess:(NSDictionary *)responseData
{
    NSLog(@"Registration succeded! %@", responseData);
}

- (void)onRegistrationFailure:(NSString *)errorString
{
    NSLog(@"Registration failed! %@", errorString);
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
