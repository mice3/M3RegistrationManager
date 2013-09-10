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
    [self.registrationManager registerDeviceWithFacebook];
}

- (IBAction)twitterButtonClickHandler:(id)sender
{
    [self.registrationManager registerDeviceWithTwitter];
}

- (IBAction)emailButtonClickHandler:(id)sender
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Email login"
                                                        message:@"Enter email and password"
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                              otherButtonTitles:nil];
    
    alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    alertView.tag = 1;
    [alertView show];
}

- (IBAction)resetButtonClickHandler:(id)sender
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"M3Registration"
                                                        message:@"User data reset"
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                              otherButtonTitles:nil];
    [alertView show];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSecureCode];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kDeviceActivated];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUserDeviceId];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(alertView.tag == 1) {
		NSString *email = [alertView textFieldAtIndex:0].text;
		NSString *password = [alertView textFieldAtIndex:1].text;
        
        [self.registrationManager registerDeviceWithEmail:email andPassword:password];
		NSLog(@"Username: %@\nPassword: %@", email, password);
	}
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
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Registration succeded"
                                                        message:[responseData objectForKey:@"status"]
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void)onRegistrationFailure:(NSString *)errorString
{
    NSLog(@"%@", errorString);
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Registration failed"
                                                        message:errorString
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                              otherButtonTitles:nil];
    [alertView show];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
