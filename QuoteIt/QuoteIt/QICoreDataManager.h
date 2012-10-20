//
//  QICoreDataManager.h
//  QuoteIt
//
//  Created by Stephen Poletto on 12/31/11.
//  Copyright (c) 2011 QuoteIt. All rights reserved.
//

#import "CoreData.h"
#import "RestKit.h"

extern NSString * const QICoreDataManagerDidUpdateLocalCache;
extern NSString * const QICoreDataManagerDidUpdateMyQuotes;

@class QIUser;

@interface QICoreDataManager : NSObject <RKObjectLoaderDelegate> {
    RKObjectLoader *friendLoader;
    RKObjectLoader *myQuotesLoader;
}

@property (nonatomic, retain) QIUser *loggedInUser;

+ (QICoreDataManager *)sharedDataManger;
- (void)loadFriendData;
- (void)loadMyQuotes;
- (void)setupBasicAuthWithUsername:(NSString *)username password:(NSString *)password;

@end
