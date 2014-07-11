//
//  TTMHomeViewController.m
//  TextTimeMachine
//
//  Created by Dinesh Mehta on 28/02/14.
//  Copyright (c) 2014 Dinesh Mehta. All rights reserved.
//

#import "TTMNative.h"
#import "Macro.h"
#import "DDIndicator.h"
#import "TTMUnderLineLabel.h"
#import "UITextField+TTMShake.h"
#import "UIColor-Expanded.h"
#import "TTMSplashViewController.h"
#import "TTMForgotPasswordViewController.h"
#import "TTMHomeViewController.h"
#import "TTMConfirmationCodeViewController.h"

#define kXpadding 70
@interface TTMHomeViewController ()

@property (nonatomic, strong)TTMTextField *email_textField;
@property (nonatomic, strong)TTMTextField *password_textField;
@end

@implementation TTMHomeViewController
@synthesize locationManager;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)loadView
{
    CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
    UIView *customView = [[UIView alloc] initWithFrame:applicationFrame];
    customView.backgroundColor = [UIColor redColor];
    customView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.view = customView;
}
-(void)addLoginButton {
    
    UIImage *buttonImage = [UIImage imageNamed:@"verifyme"];
    UIButton *loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [loginButton setFrame:CGRectMake(self.view.frame.size.width/2 - buttonImage.size.width/2, [TTMCommon getWidth]/2 + kXpadding + 90, buttonImage.size.width , buttonImage.size.height - 10)];
    [loginButton addTarget:self action:@selector(loginButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [loginButton setBackgroundImage:[UIImage imageNamed:@"verifyme"] forState:UIControlStateNormal];
    [loginButton setTitle:NSLocalizedString(@"Verify Me", @"Verify Me") forState:UIControlStateNormal];
    [loginButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [loginButton setBackgroundColor:[UIColor clearColor]];
    [loginButton.titleLabel setFont:[UIFont fontWithName:LotoLight size:16.0f]];
    [self.view addSubview:loginButton];
    
}
-(void)addImageView:(CGRect)frame {
    UIImage *tempImageView = [UIImage imageNamed:@"email"];
    
    UIImageView *updateImage = [[UIImageView alloc] initWithFrame:frame];
    [updateImage setTag:12345];
    [updateImage setBackgroundColor:[UIColor clearColor]];
    [updateImage setImage:tempImageView];
    [self.view addSubview:updateImage];
}
-(void)addImageViewEmail:(CGRect)frame {
    UIImage *tempImageView = [UIImage imageNamed:@"mobileicon"];

    UIImageView *updateImage = [[UIImageView alloc] initWithFrame:frame];
    [updateImage setTag:12345];
    [updateImage setBackgroundColor:[UIColor clearColor]];
    [updateImage setImage:tempImageView];
    [self.view addSubview:updateImage];
}
-(void)addSuggestionLabel {
    
    NSString *suggestionString = NSLocalizedString(@"We will send you varification code on your email address and phone number", @"We will send you varification code on your email address and phone number");
    
    CGSize maximumLabelSize = CGSizeMake(353,9999);
    
    CGSize expectedLabelSize = [suggestionString sizeWithFont:[UIFont fontWithName:LotoLight size:12.0f]
                                  constrainedToSize:maximumLabelSize
                                      lineBreakMode:NSLineBreakByCharWrapping];
    UILabel  * label = [[UILabel alloc] initWithFrame:CGRectMake(40,  [TTMCommon getWidth]/2 + kXpadding + 150,[TTMCommon getWidth] - 80 , expectedLabelSize.height)];
    [label setTextAlignment:NSTextAlignmentCenter];
    label.backgroundColor = [UIColor clearColor];
    label.textColor=[UIColor whiteColor];
    [label setFont:[UIFont fontWithName:LotoLight size:12.0f]];
    label.numberOfLines=0;
    label.text = suggestionString;
    [self.view addSubview:label];
}

-(void)forgotPasswordTapped:(UIGestureRecognizer *)gesture {
    TTMForgotPasswordViewController *fpvc = [[TTMForgotPasswordViewController alloc]init];
    [self.navigationController pushViewController:fpvc animated:YES];
}

-(void)addPasswordLabeleInfo:(CGRect)frame {
    
    UILabel  * label = [[UILabel alloc] initWithFrame:frame];
    [label setFont:[UIFont fontWithName:LotoLight size:17.0f]];
    label.backgroundColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentLeft;
    label.textColor=[UIColor whiteColor];
    label.numberOfLines=0;
    [label.layer setBorderColor:[UIColor lightGrayColor].CGColor];
    [label.layer setBorderWidth:1.0f];
    [label setTextAlignment:NSTextAlignmentCenter];
    label.text = NSLocalizedString(@"+91", @"+91");
    [self.view addSubview:label];
}


-(void)addEmailField {
    
    self.email_textField = [[TTMTextField alloc] init];
    [self.email_textField setFrame:CGRectMake([TTMCommon getWidth]/2 - 90, [TTMCommon getWidth]/2 + kXpadding, [TTMCommon getWidth]/2 + 65, 30)];
    [self.view addSubview:self.email_textField];
    [self.email_textField setDelegate:(id)self];
    [self.email_textField setTextAlignment:NSTextAlignmentLeft];
    [self.email_textField setKeyboardType:UIKeyboardTypeEmailAddress];
    [self.email_textField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self.email_textField setFont:[UIFont fontWithName:LotoLight size:12.0f]];
    [self.email_textField setPlaceholder:NSLocalizedString(@"Enter Email", @"Enter Email")];
}

-(void)addPasswordField {
    
    self.password_textField = [[TTMTextField alloc] init];
    [self.password_textField setFrame:CGRectMake([TTMCommon getWidth]/2 - 55, [TTMCommon getWidth]/2 + kXpadding + 40, [TTMCommon getWidth]/2 + 29, 30)];
    [self.password_textField setFont:[UIFont fontWithName:LotoLight size:12.0f]];

    [self.view addSubview:self.password_textField];
    [self.password_textField setDelegate:(id)self];
    [self.password_textField setTextAlignment:NSTextAlignmentLeft];
    [self.password_textField setSecureTextEntry:NO];
    [self.password_textField setKeyboardType:UIKeyboardTypeNumberPad];
    [self.password_textField setPlaceholder:NSLocalizedString(@"  Mobile Number", @"  Mobile Numer")];
    UIImage *mobile = [UIImage imageNamed:@"txtbg"];
    [self.password_textField setBackground:mobile];
    
}
// return NO to disallow editing.

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    
    return YES;
}

- (void)shakeTextField:(TTMTextField *)textfield
{
	[textfield shake:10
				withDelta:5
				 andSpeed:0.04
           shakeDirection:ShakeDirectionHorizontal];
}

-(IBAction)loginButtonPressed:(id)sender {

    if([self.email_textField.text length] == 0) {
        [self shakeTextField:self.email_textField];
    }else if([self.password_textField.text length] == 0) {
        [self shakeTextField:self.password_textField];
    }else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.2];
            [UIView setAnimationCurve:UIViewAnimationCurveLinear];
            self.view.frame = CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height);
            [UIView commitAnimations];
        });
        
        [[TTMActivityIndicator sharedMySingleton] addIndicator:self.navigationController.view];
        [[NSUserDefaults standardUserDefaults] setObject:self.password_textField.text forKey:@"userName"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.email_textField resignFirstResponder];
        [self.password_textField resignFirstResponder];
       [self callLoginservice];
    }
}

-(void)callLoginservice {
    
    TTMBaseParser *parser =  [[TTMBaseParser alloc] init];
    NSMutableDictionary *argumentDict = [NSMutableDictionary dictionary];
    setValueWithKey(EmailDefaultKey, self.email_textField.text);
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    NSString *tzName = [timeZone name];
    [argumentDict setValue:[NSString stringWithFormat:@"%@", self.email_textField.text] forKey:@"email"];
    [argumentDict setValue:[NSString stringWithFormat:@"%@", self.password_textField.text] forKey:@"Phone"];
    [argumentDict setValue:[NSString stringWithFormat:@"%@", tzName] forKey:@"timeZone"];

    [parser serviceWithArgument:argumentDict serviceType:TTMEmailSendService callBackResponse:^(id response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{

        [[TTMActivityIndicator sharedMySingleton] removeIndicator:self.navigationController.view];
        });
        NSLog(@"Response is %@", response);
        if([response isKindOfClass:[NSDictionary class]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *userId = [response objectForKey:@"userId"];
                [[TTMSingleTon sharedMySingleton] setUser_id:userId];
                [[NSUserDefaults standardUserDefaults] setObject:userId forKey:@"UserId"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                TTMConfirmationCodeViewController *confirmationVC = [[TTMConfirmationCodeViewController alloc] init];
                [self.navigationController pushViewController:confirmationVC animated:YES];
            });
            
        }else {
            dispatch_async(dispatch_get_main_queue(), ^{

            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"There are some problem in server" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
            });
        }
    }];
}

-(void)addWelcomeLabel {
    UIFont * customFont = [UIFont fontWithName:LotoLight size:12.0f]; //custom font
    NSString * text = NSLocalizedString(@"We need your Mobile Number and Email Address to uniquly identify you!", @"We need your Mobile Number and Email Address to uniquly identify you!");
    CGSize labelSize = [text sizeWithFont:customFont constrainedToSize:CGSizeMake(380, 20) lineBreakMode:NSLineBreakByTruncatingTail];
    
    UILabel *fromLabel = [[UILabel alloc]initWithFrame:CGRectMake(20, 170, [TTMCommon getWidth] - 40, labelSize.height + 40)];
    fromLabel.text = text;
    fromLabel.font = customFont;
    fromLabel.numberOfLines = 0;
    fromLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines; // or UIBaselineAdjustmentAlignCenters, or UIBaselineAdjustmentNone
    fromLabel.adjustsFontSizeToFitWidth = YES;
    //fromLabel.adjustsLetterSpacingToFitWidth = YES;
    //fromLabel.minimumScaleFactor = 10.0f/12.0f;
    fromLabel.clipsToBounds = YES;
    fromLabel.backgroundColor = [UIColor clearColor];
    fromLabel.textColor = [UIColor whiteColor];
    fromLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:fromLabel];
}

-(void)addResisterLabel {
    UIFont * customFont = [UIFont fontWithName:LotoLight size:18]; //custom font
    NSString * text = NSLocalizedString(@"Register your mobile", @"Register your mobile");
    CGSize labelSize = [text sizeWithFont:customFont constrainedToSize:CGSizeMake(380, 20) lineBreakMode:NSLineBreakByTruncatingTail];
    
    UILabel *fromLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 150, self.view.frame.size.width, labelSize.height)];
    fromLabel.text = text;
    fromLabel.font = customFont;
    fromLabel.numberOfLines = 1;
    fromLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines; // or UIBaselineAdjustmentAlignCenters, or UIBaselineAdjustmentNone
    fromLabel.adjustsFontSizeToFitWidth = YES;
    //fromLabel.adjustsLetterSpacingToFitWidth = YES;
    //fromLabel.minimumScaleFactor = 10.0f/12.0f;
    fromLabel.clipsToBounds = YES;
    fromLabel.backgroundColor = [UIColor clearColor];
    fromLabel.textColor = [UIColor whiteColor];
    fromLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:fromLabel];
}

-(IBAction)backButtonAction:(id)sender {
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:YES];
    self.locationManager = [[RCLocationManager alloc] initWithUserDistanceFilter:kCLLocationAccuracyHundredMeters userDesiredAccuracy:kCLLocationAccuracyBest purpose:@"My custom purpose message" delegate:(id)self];
    
    // Start updating location changes.
    [self.locationManager startUpdatingLocation];
    NSString *userId = [NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults] objectForKey:@"UserId"] ];
    NSLog(@"User is value is %lu", (unsigned long)userId.length
          );
    if(![userId isEqualToString:@"(null)"]) {
        TTMMenuViewController *confirmationVC = [[TTMMenuViewController alloc] init];
        [self.navigationController pushViewController:confirmationVC animated:NO];
    }else {
        [self addResisterLabel];
        UIImage *logoImage = [UIImage imageNamed:@"logo"];
        
        [self addWelcomeLabel];
        
        [self addSuggestionLabel];
        [self addLoginButton];
        //[self addEmailLabeleInfo];
        UIImage *tempImageView = [UIImage imageNamed:@"email"];
        UIImage *mobileicon = [UIImage imageNamed:@"mobileicon"];
        [self addImageView:CGRectMake(30,  [TTMCommon getWidth]/2 + kXpadding , tempImageView.size.width+ 12, tempImageView.size.height)];
        [self addImageViewEmail:CGRectMake(30,  [TTMCommon getWidth]/2 + kXpadding + 40, mobileicon.size.width - 10, mobileicon.size.height -4)];
        [self addEmailField];
        [self addPasswordField];
        TTMLogo *logo = [[TTMLogo alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - logoImage.size.width/2 + 12, 50, logoImage.size.width- 25, logoImage.size.height - 25)];
        [self.view addSubview:logo];
    }
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardDidShowNotification object:nil];
}
#pragma mark - RCLocationManagerDelegate

- (void)locationManager:(RCLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    NSLog(@"*dLatitude : %f", newLocation.coordinate.latitude);
    NSLog(@"*dLongitude : %f",newLocation.coordinate.longitude);
    __block NSString *place_name = nil;
    CLGeocoder * geoCoder = [[CLGeocoder alloc] init];
    [geoCoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        for (CLPlacemark * placemark in placemarks) {
            NSLog(@"Place mark dictionary %@", [placemark addressDictionary]);
            place_name = [NSString stringWithFormat:@"%@, %@, %@",[[placemark addressDictionary] objectForKey:@"Name"],[[placemark addressDictionary] objectForKey:@"City"],[[placemark addressDictionary] objectForKey:@"Country"]];
        }
    }];
}

-(void)didFailRequestWithError:(NSError*)_error
{
    NSLog(@"Error: %@", _error);
}
- (void)keyboardWillShow:(NSNotification *)note {
    
    if([self.password_textField isFirstResponder]) {
    UIButton *doneButton  = [[UIButton alloc] initWithFrame:CGRectMake(0, 163, 106, 53)];
    doneButton.adjustsImageWhenHighlighted = NO;
    // [doneButton setImage:[UIImage imageNamed:@"Done.png"] forState:UIControlStateNormal];
    [doneButton setTitle:@"Done" forState:UIControlStateNormal];
    [doneButton addTarget:self action:@selector(doneButton:) forControlEvents:UIControlEventTouchUpInside];
    UIWindow* tempWindow = [[[UIApplication sharedApplication] windows] objectAtIndex:1];
    UIView* keyboard;
    for(int i=0; i<[tempWindow.subviews count]; i++) {
        keyboard = [tempWindow.subviews objectAtIndex:i];
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 3.2) {
            if([[keyboard description] hasPrefix:@"<UIPeripheralHost"] == YES)
                [keyboard addSubview:doneButton];
        }
        else {
            if([[keyboard description] hasPrefix:@"<UIKeyboard"] == YES)
                [keyboard addSubview:doneButton];
        }
    }
    }
}

-(IBAction)doneButton:(id)sender {
    [self.password_textField resignFirstResponder];
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.2];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        self.view.frame = CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height);
        [UIView commitAnimations];
    });
}
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.25];
    self.view.frame = CGRectMake(0,-90,self.view.frame.size.width,self.view.frame.size.height);
    [UIView commitAnimations];
    
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.2];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        self.view.frame = CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height);
        [UIView commitAnimations];
    });
	return YES;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
