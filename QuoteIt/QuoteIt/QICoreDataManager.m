//
//  QICoreDataManager.m
//  QuoteIt
//
//  Created by Stephen Poletto on 12/31/11.
//  Copyright (c) 2011 QuoteIt. All rights reserved.
//

#import "CoreData.h"
#import "RestKit.h"

#import "QIKeychainItemWrapper.h"
#import "QIFacebookConnect.h"
#import "QICoreDataManager.h"
#import "QIUtilities.h"
#import "QIUser.h"

NSString * const QICoreDataManagerDidUpdateLocalCache = @"QICoreDataManagerDidUpdateLocalCache";
NSString * const QICoreDataManagerDidUpdateMyQuotes = @"QICoreDataManagerDidUpdateMyQuotes";

@implementation QICoreDataManager
@synthesize loggedInUser;

- (void)restoreCacheFromDisk {
    NSString *username = [[QIKeychainItemWrapper sharedKeychainItemWrapper] objectForKey:(id)kSecAttrAccount];
    if (username) {
        NSFetchRequest *request = [QIUser fetchRequest];
        NSPredicate *filter = [NSPredicate predicateWithFormat:@"userID like %@", username];
        [request setPredicate:filter];
        loggedInUser = [[[QIUser objectsWithFetchRequest:request] onlyObject] retain];
    }
}

- (id)init {
    self = [super init];
    if (self) {
        [self restoreCacheFromDisk];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLogIn:) name:QIUserDidLogInNotification object:nil];
    }
    return self;
}

+ (QICoreDataManager *)sharedDataManger {
    static QICoreDataManager *sharedDataManger = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        sharedDataManger = [[self alloc] init];
    });
    return sharedDataManger;
}

- (void)userDidLogIn:(NSNotification *)notification {
    [self loadFriendData];
    [self loadMyQuotes];
}

- (void)loadFriendData {
    friendLoader = [[RKObjectManager sharedManager] loadObjectsAtResourcePath:@"/api/me" delegate:self];
}

- (void)loadMyQuotes {
    myQuotesLoader = [[RKObjectManager sharedManager] loadObjectsAtResourcePath:@"/api/my_quotes" delegate:self];
}

- (void)setupBasicAuthWithUsername:(NSString *)username password:(NSString *)password {
    [RKObjectManager sharedManager].client.authenticationType = RKRequestAuthenticationTypeHTTPBasic;
    [RKObjectManager sharedManager].client.username = username;
    [RKObjectManager sharedManager].client.password = password;
}

- (void)prefetchProfileImages {
    NSSet *friends = [[[QICoreDataManager sharedDataManger] loggedInUser] friends];
    NSSet *friendsAndMe = [friends setByAddingObject:[[QICoreDataManager sharedDataManger] loggedInUser]];
    for (QIUser *friend in friendsAndMe) {
        [QIUtilities cacheImageAtURL:[NSURL URLWithString:[friend photoURL]]];
    }
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects {
    if (objectLoader == friendLoader) {
        loggedInUser = [objects onlyObject];
        friendLoader = nil;
        
        [self prefetchProfileImages];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:QICoreDataManagerDidUpdateLocalCache object:nil];
    } else if (objectLoader == myQuotesLoader) {
        loggedInUser = [objects onlyObject];
        myQuotesLoader = nil;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:QICoreDataManagerDidUpdateMyQuotes object:nil];
    }
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    @synchronized(self) {
    if (objectLoader == myQuotesLoader || objectLoader == friendLoader) {
        if ([error code] == NSURLErrorUserCancelledAuthentication) {
            [[QIErrorHandler sharedErrorHandler] presentAlertViewWithTitle:@"Failed to authenticate Facebook." message:@"Please retry logging into Facebook." completionHandler:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:QIUserDidNotLogInNotification object:nil];
            [[[QIFacebookConnect sharedFacebookConnect] facebook] logout];
            [[QIKeychainItemWrapper sharedKeychainItemWrapper] setObject:@"" forKey:(id)kSecAttrAccount];
            [[QIKeychainItemWrapper sharedKeychainItemWrapper] setObject:@"" forKey:(id)kSecValueData];
        
            [friendLoader cancel];
            [myQuotesLoader cancel];
            friendLoader = nil;
            myQuotesLoader = nil;
        }
    }}
}

@end
