//
//  QIKeychainItemWrapper.h
//  QuoteIt
//
//  Created by Stephen Poletto on 11/12/11.
//  Copyright (c) 2011 QuoteIt. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QIKeychainItemWrapper : NSObject

+ (id)sharedKeychainItemWrapper;
+ (id)sharedTumblrItemWrapper;

@end
