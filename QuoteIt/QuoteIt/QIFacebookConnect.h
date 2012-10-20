//
//  QIFacebookConnect.h
//  QuoteIt
//
//  Created by Stephen Poletto on 12/29/11.
//  Copyright (c) 2011 QuoteIt. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FBConnect.h"

extern NSString * const QIUserDidLogInNotification;
extern NSString * const QIUserDidLogOutNotification;
extern NSString * const QIFBSessionInvalidatedNotification;
extern NSString * const QIUserDidNotLogInNotification;
extern NSString * const QIWillShipFBTokenToServerNotification;

@interface QIFacebookConnect : NSObject <FBSessionDelegate>

@property (nonatomic, retain) Facebook *facebook;

- (void)shipFacebookAuthTokenToServer; // Phone home.
+ (id)sharedFacebookConnect;

@end
