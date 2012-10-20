//
//  QISplashScreen.m
//  QuoteIt
//
//  Created by Stephen Poletto on 12/29/11.
//  Copyright (c) 2011 QuoteIt. All rights reserved.
//

#import "QIMainViewController.h"
#import "QIFacebookConnect.h"
#import "QISplashScreen.h"

@implementation QISplashScreen
@synthesize connectWithFBButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLogIn:) name:QIUserDidLogInNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidNotLogIn:) name:QIUserDidNotLogInNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShipFBToken:) name:QIWillShipFBTokenToServerNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [connectWithFBButton setImage:[UIImage imageNamed:@"fb_btn_press"] forState:UIControlStateHighlighted];
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
        ([UIScreen mainScreen].scale == 2.0)) {
        // Retina display
    } else {
        [connectWithFBButton setEnabled:NO];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Retina Display Required" message:@"SquareQuote requires an iOS device with a retina display. Please try SquareQuote using an iPhone 4 or newer." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}

- (void)initializeProgressHUD {
    progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:progressHUD];
    progressHUD.dimBackground = YES;
    progressHUD.delegate = self;
    progressHUD.labelText = @"Signing In";
    [progressHUD show:YES];
}

- (void)changeHUDText {
    [progressHUD setLabelText:@"Waiting for Facebook"];
}

- (IBAction)signInWithFacebook:(id)sender {
    [[[QIFacebookConnect sharedFacebookConnect] facebook] authorize:[NSArray arrayWithObjects:@"offline_access", @"user_photos", @"friends_photos", @"user_events", @"user_groups", @"photo_upload", nil]];
}

- (void)userDidLogIn:(NSNotification *)notification {
    loginSuccessful = YES;
    [progressHUD hide:YES];
}

- (void)userDidNotLogIn:(NSNotification *)notification {
    [progressHUD hide:YES];
}

- (void)willShipFBToken:(NSNotification *)notification {
    // Only start showing the spinner when we've authenticated FB.
    if (!progressHUD) {
        [self initializeProgressHUD];
        [self performSelector:@selector(changeHUDText) withObject:nil afterDelay:1.0];
    }
}

- (void)hudWasHidden:(MBProgressHUD *)hud {
    // Remove HUD from screen when the HUD was hidden.
    [progressHUD removeFromSuperview];
    [progressHUD release];
	progressHUD = nil;
    
    if (loginSuccessful) {
        [TestFlight passCheckpoint:@"Handshake Finished -- Showing Home Screen"];
        QIMainViewController *mainViewController = [[[QIMainViewController alloc] initWithNibName:@"QIMainViewController" bundle:nil] autorelease];
        self.view.window.rootViewController = mainViewController;
    }
}

- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(changeHUDText) object:nil];
    [connectWithFBButton release];
    [super dealloc];
}

- (void)viewDidUnload {
    [self setConnectWithFBButton:nil];
    [super viewDidUnload];
}

@end
