//
//  QIFacebookConnect.m
//  QuoteIt
//
//  Created by Stephen Poletto on 12/29/11.
//  Copyright (c) 2011 QuoteIt. All rights reserved.
//

#import "QIKeychainItemWrapper.h"
#import "QICoreDataManager.h"
#import "QIFacebookConnect.h"
#import "QIUtilities.h"
#import "QIAFClient.h"

NSString * const QIUserDidLogInNotification = @"QIUserDidLogInNotification";
NSString * const QIUserDidLogOutNotification = @"QIUserDidLogOutNotification";
NSString * const QIFBSessionInvalidatedNotification = @"QIFBSessionInvalidatedNotification";
NSString * const QIUserDidNotLogInNotification = @"QIUserDidNotLogInNotification";
NSString * const QIWillShipFBTokenToServerNotification = @"QIWillShipFBTokenToServerNotification";

@implementation QIFacebookConnect
@synthesize facebook;

- (id)init {
    self = [super init];
    if (self) {
        self.facebook = [[[Facebook alloc] initWithAppId:QIFacebookAppID andDelegate:self] autorelease];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([defaults objectForKey:@"FBAccessTokenKey"] && [defaults objectForKey:@"FBExpirationDateKey"]) {
            self.facebook.accessToken = [defaults objectForKey:@"FBAccessTokenKey"];
            self.facebook.expirationDate = [defaults objectForKey:@"FBExpirationDateKey"];
        }
    }
    return self;
}

- (void)shipFacebookAuthTokenToServer {
    if (![self.facebook isSessionValid]) {
        return; // Don't bother sending the auth token if it's invalid.
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:QIWillShipFBTokenToServerNotification object:nil];
    NSDictionary *postParams = [NSDictionary dictionaryWithObject:self.facebook.accessToken  forKey:@"access_token"];
    [[QIAFClient sharedClient] postPath:@"/api/link_fb" parameters:postParams success:^(AFHTTPRequestOperation *operation, id jsonObject) {
        if ([[jsonObject valueForKey:@"status"] isEqualToString:@"ok"]) {
            NSDictionary *userDictionary = [jsonObject valueForKey:@"user"];
            NSString *password = [userDictionary valueForKey:@"secret_token"];
            NSString *username = [userDictionary valueForKey:@"user_id"];
            [[QIAFClient sharedClient] setAuthorizationHeaderWithUsername:username password:password];
            [[QICoreDataManager sharedDataManger] setupBasicAuthWithUsername:username password:password];
            
            // Store the successful credentials in the keychain for later use.
            [[QIKeychainItemWrapper sharedKeychainItemWrapper] setObject:username forKey:(id)kSecAttrAccount];
            [[QIKeychainItemWrapper sharedKeychainItemWrapper] setObject:password forKey:(id)kSecValueData];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:QIUserDidLogInNotification object:username];
        } else {
            [[QIErrorHandler sharedErrorHandler] presentAlertViewWithTitle:@"Failed to authenticate Facebook." message:@"Please retry logging into Facebook." completionHandler:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:QIUserDidNotLogInNotification object:nil];
            [[self facebook] logout];
            [[QIKeychainItemWrapper sharedKeychainItemWrapper] setObject:@"" forKey:(id)kSecAttrAccount];
            [[QIKeychainItemWrapper sharedKeychainItemWrapper] setObject:@"" forKey:(id)kSecValueData];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (![error code] == NSURLErrorNotConnectedToInternet) {
            [[QIErrorHandler sharedErrorHandler] presentAlertViewWithTitle:@"Failed to authenticate Facebook." message:@"Please retry logging into Facebook." completionHandler:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:QIUserDidNotLogInNotification object:nil];
            [[self facebook] logout];
            [[QIKeychainItemWrapper sharedKeychainItemWrapper] setObject:@"" forKey:(id)kSecAttrAccount];
            [[QIKeychainItemWrapper sharedKeychainItemWrapper] setObject:@"" forKey:(id)kSecValueData];
        }
    }];
}

- (void)fbDidLogin {
    [TestFlight passCheckpoint:@"Authenticated Facebook"];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[self.facebook accessToken] forKey:@"FBAccessTokenKey"];
    [defaults setObject:[self.facebook expirationDate] forKey:@"FBExpirationDateKey"];
    [defaults synchronize];
    [self shipFacebookAuthTokenToServer];
}

- (void)fbDidNotLogin:(BOOL)cancelled {
    [TestFlight passCheckpoint:@"Did Not Authenticate"];
    [[NSNotificationCenter defaultCenter] postNotificationName:QIUserDidNotLogInNotification object:nil];
}

- (void)fbDidLogout {
    // Remove saved authorization information if it exists
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"FBAccessTokenKey"]) {
        [defaults removeObjectForKey:@"FBAccessTokenKey"];
        [defaults removeObjectForKey:@"FBExpirationDateKey"];
        [defaults synchronize];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:QIUserDidLogOutNotification object:nil];
}

/**
 * Called when the current session has expired. This might happen when:
 *  - the access token expired 
 *  - the app has been disabled
 *  - the user revoked the app's permissions
 *  - the user changed his or her password
 */
- (void)fbSessionInvalidated {
    [[NSNotificationCenter defaultCenter] postNotificationName:QIFBSessionInvalidatedNotification object:nil];
}

static QIFacebookConnect *sharedFacebookConnect;

+ (id)sharedFacebookConnect {
    if (!sharedFacebookConnect) {
        sharedFacebookConnect = [[QIFacebookConnect alloc] init];
    }
    return sharedFacebookConnect;
}

@end
