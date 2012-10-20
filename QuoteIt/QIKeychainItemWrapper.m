//
//  QIKeychainItemWrapper.m
//  QuoteIt
//
//  Created by Stephen Poletto on 11/12/11.
//  Copyright (c) 2011 QuoteIt. All rights reserved.
//

#import "QIKeychainItemWrapper.h"
#import "KeychainItemWrapper.h"

@implementation QIKeychainItemWrapper

static KeychainItemWrapper *sharedItemWrapper;

+ (id)sharedKeychainItemWrapper {
    if (!sharedItemWrapper) {
        sharedItemWrapper = [[KeychainItemWrapper alloc] initWithIdentifier:@"QuoteItLoginData" accessGroup:nil];
    }
    return sharedItemWrapper;
}

static KeychainItemWrapper *sharedTumblrItemWrapper;

+ (id)sharedTumblrItemWrapper {
    if (!sharedTumblrItemWrapper) {
        sharedTumblrItemWrapper = [[KeychainItemWrapper alloc] initWithIdentifier:@"QuoteItTumblrLoginData" accessGroup:nil];
    }
    return sharedTumblrItemWrapper;
}

@end
