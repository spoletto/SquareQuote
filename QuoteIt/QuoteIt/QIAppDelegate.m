//
//  QIAppDelegate.m
//  QuoteIt
//
//  Created by Stephen Poletto on 12/29/11.
//  Copyright (c) 2011 QuoteIt. All rights reserved.
//

#import <Parse/Parse.h>

#import "AFNetworkActivityIndicatorManager.h"
#import "CoreData.h"
#import "RestKit.h"
#import "iRate.h"

#import "QITemplatePhotosCache.h"
#import "QIKeychainItemWrapper.h"
#import "QIMainViewController.h"
#import "QIBucketPhotosCache.h"
#import "QIFacebookConnect.h"
#import "QICoreDataManager.h"
#import "QISplashScreen.h"
#import "QIAppDelegate.h"
#import "QIUtilities.h"
#import "QIMyQuotes.h"
#import "QIAFClient.h"
#import "QIQuote.h"
#import "QIUser.h"

@interface QIAppDelegate()
- (void)navigateToMyQuotes;
@end

@implementation QIAppDelegate

@synthesize window = _window;

+ (void)initialize {
    [iRate sharedInstance].appStoreID = 527511832;
    [iRate sharedInstance].eventsUntilPrompt = 4;
    [iRate sharedInstance].daysUntilPrompt = 0;
}

- (void)dealloc {
    [_window release];
    [super dealloc];
}

- (void)configureRestKit {
    RKObjectManager *objectManager = [RKObjectManager objectManagerWithBaseURL:QIBaseURL];
    [objectManager requestQueue].showsNetworkActivityIndicatorWhenBusy = YES;
    objectManager.objectStore = [RKManagedObjectStore objectStoreWithStoreFilename:QIDatabaseName];
    
    // Set up our object mappings.
    RKManagedObjectMapping *quoteMapping = [RKManagedObjectMapping mappingForClass:[QIQuote class]];
    quoteMapping.primaryKeyAttribute = @"quoteID";
    [quoteMapping mapAttributes:@"photoURL", @"quoteID", @"text", @"created", @"viewCount", nil];
    
    RKManagedObjectMapping *userMapping = [RKManagedObjectMapping mappingForClass:[QIUser class]];
    userMapping.primaryKeyAttribute = @"userID";
    [userMapping mapAttributes:@"type", @"name", @"firstName", @"lastName", @"photoURL", @"userID", @"fbID", nil];
    
    [userMapping mapRelationship:@"quotesSourced" withMapping:quoteMapping];
    [userMapping mapRelationship:@"quotesSubmitted" withMapping:quoteMapping];
    [userMapping mapRelationship:@"friends" withMapping:userMapping];
    [quoteMapping mapRelationship:@"submittedUser" withMapping:userMapping];
    [quoteMapping mapRelationship:@"source" withMapping:userMapping];
    
    // Register our mapping with the provider.
    [objectManager.mappingProvider setMapping:userMapping forKeyPath:@"me"];
    [objectManager.mappingProvider setMapping:quoteMapping forKeyPath:@"quote"];
}

- (void)loadSavedCredentials {
    NSString *username = [[QIKeychainItemWrapper sharedKeychainItemWrapper] objectForKey:(id)kSecAttrAccount];
    NSString *password = [[QIKeychainItemWrapper sharedKeychainItemWrapper] objectForKey:(id)kSecValueData];
    [[QIAFClient sharedClient] setAuthorizationHeaderWithUsername:username password:password];
    [[QICoreDataManager sharedDataManger] setupBasicAuthWithUsername:username password:password];
    [[NSNotificationCenter defaultCenter] postNotificationName:QIUserDidLogInNotification object:username];
}

- (void)prefetchImportantData {
    [[QITemplatePhotosCache sharedTemplatePhotosCache] cachedTemplatePhotos]; // Prefetch template images.
    [[QIBucketPhotosCache sharedBucketPhotosCache] cachedBucketPhotos]; // Prefetch the buckets.
}

- (void)userDidLogIn:(NSNotification *)notification {
    NSString *username = [notification object];
    
    // Channels must start with a letter. Usernames may not start with a letter.
    NSString *channelName = [@"a" stringByAppendingString:username];
    [PFPush subscribeToChannelInBackground:channelName block:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"Successfully subscribed to the broadcast channel.");
        } else {
            NSLog(@"Failed to subscribe to the broadcast channel.");
        }
    }];
}

- (void)userDidLogOut:(NSNotification *)notification {
    // Unsubscribe from push channel.
    NSString *username = [[QIKeychainItemWrapper sharedKeychainItemWrapper] objectForKey:(id)kSecAttrAccount];
    NSString *channelName = [@"a" stringByAppendingString:username];
    [PFPush unsubscribeFromChannel:channelName withError:NULL];
    [[QIKeychainItemWrapper sharedKeychainItemWrapper] setObject:@"" forKey:(id)kSecAttrAccount];
    [[QIKeychainItemWrapper sharedKeychainItemWrapper] setObject:@"" forKey:(id)kSecValueData];
    
    // Can't write to the sharedTumblrItemWrapper because of the strange errSecDuplicateItem bug.
    // Let's instead record that the Tumblr credentials are invalid.
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"QITumblrActive"];
    
    QISplashScreen *loginViewController = [[[QISplashScreen alloc] initWithNibName:@"QISplashScreen" bundle:nil] autorelease];
    self.window.rootViewController = loginViewController;
}

- (void)registerDefaults {
    NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], QIHasBrowsedQuotes, [NSNumber numberWithBool:NO], QIHasCustomizedQuoteBackground, [NSNumber numberWithBool:NO], QIHasMadeTextChanges, [NSNumber numberWithBool:NO], QIHasSeenGenericIntroOverlay, [NSNumber numberWithBool:NO], QIHasSeenPhotoSelectorOptions, [NSNumber numberWithBool:NO], QIHasSharedQuote, [NSNumber numberWithBool:NO], QIHasSwipedThroughQuoteBrowser, [NSNumber numberWithBool:NO], QIHasTappedShareQuote, nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self registerDefaults];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLogIn:) name:QIUserDidLogInNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLogOut:) name:QIUserDidLogOutNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLogOut:) name:QIFBSessionInvalidatedNotification object:nil];
    
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    [[RKObjectManager sharedManager].client setValue:appVersion forHTTPHeaderField:@"X-AppVersion"];
    
    [Parse setApplicationId:QIParseApplicationID clientKey:QIParseClientKey];
    [TestFlight takeOff:QITestFlightTeamToken];
    [TestFlight passCheckpoint:@"Application Launched"];
    
    // Register for push notifications.
    [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound];
    
    // Initialize an AFNetworkActivityIndicatorManager.
    // It will funnel through to RKRequestManager.
    [AFNetworkActivityIndicatorManager sharedManager];
    
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
        
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:NO];
    
    [self configureRestKit];
        
    if (![[[QIFacebookConnect sharedFacebookConnect] facebook] isSessionValid]|| ![[[QIKeychainItemWrapper sharedKeychainItemWrapper] objectForKey:(id)kSecAttrAccount] length]) {
        QISplashScreen *loginViewController = [[[QISplashScreen alloc] initWithNibName:@"QISplashScreen" bundle:nil] autorelease];
        self.window.rootViewController = loginViewController;
    } else {
        [self loadSavedCredentials];
        QIMainViewController *mainViewController = [[[QIMainViewController alloc] initWithNibName:@"QIMainViewController" bundle:nil] autorelease];
        self.window.rootViewController = mainViewController;
    }
    
    [self prefetchImportantData];
    
    NSDictionary *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (notification) {
        // Simplistic notification handling for now.
        [[QICoreDataManager sharedDataManger] loadMyQuotes]; // Update the list of my quotes.
        [self navigateToMyQuotes];
        application.applicationIconBadgeNumber = 0;
    }
    
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    if (application.applicationIconBadgeNumber) {
        application.applicationIconBadgeNumber = 0;
        [self navigateToMyQuotes];
    }
    [[QIFacebookConnect sharedFacebookConnect] shipFacebookAuthTokenToServer];
    [[QICoreDataManager sharedDataManger] loadMyQuotes];
    [[QICoreDataManager sharedDataManger] loadFriendData];
    [self prefetchImportantData];
}

#pragma mark -
#pragma mark Facebook URL Handling

// Pre 4.2 support
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [[[QIFacebookConnect sharedFacebookConnect] facebook] handleOpenURL:url]; 
}

// For 4.2+ support
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [[[QIFacebookConnect sharedFacebookConnect] facebook] handleOpenURL:url]; 
}

#pragma mark -
#pragma mark Push Notification Support

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
    [PFPush storeDeviceToken:newDeviceToken]; // Send parse the device token
    // Subscribe this user to the broadcast channel, "" 
    [PFPush subscribeToChannelInBackground:@"" block:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"Successfully subscribed to the broadcast channel.");
        } else {
            NSLog(@"Failed to subscribe to the broadcast channel.");
        }
    }];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    TFLog(@"Failed to register for push notifications: %@", error);
#if !(TARGET_IPHONE_SIMULATOR)
    [[QIErrorHandler sharedErrorHandler] presentFailureViewWithTitle:@"Failed to register for push notifications" error:error completionHandler:nil];
#endif
}

- (void)navigateToMyQuotes {
    QIMyQuotes *myQuotes = [[QIMainViewController mainViewController] myQuotesController];
    [myQuotes.navigationController popToRootViewControllerAnimated:NO];
    [myQuotes showUpdatingQuotesSpinnerWithMessage:@"Updating Quotes"];
    [myQuotes selectTaggedWithYouTab];
    [[QIMainViewController mainViewController] dismissModalViewControllerAnimated:NO];
    [[QIMainViewController mainViewController] selectMyQuotesController];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
        [self navigateToMyQuotes];
	}
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [[QICoreDataManager sharedDataManger] loadMyQuotes]; // Update the list of my quotes.
    application.applicationIconBadgeNumber = 0;
    if (application.applicationState == UIApplicationStateActive) {
        UIAlertView *alert = [[UIAlertView alloc] init];
        [alert setTitle:[[userInfo objectForKey:@"aps"] objectForKey:@"alert"]];
        [alert setDelegate:self];
        [alert addButtonWithTitle:@"Ignore"];
        [alert addButtonWithTitle:@"View"];
        [alert show];
        [alert release];
    } else {
        // Coming from background.
        [self navigateToMyQuotes];
    }
}

@end
