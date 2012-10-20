//
//  QIQuote.h
//  QuoteIt
//
//  Created by Stephen Poletto on 12/29/11.
//  Copyright (c) 2011 QuoteIt. All rights reserved.
//

#import <CoreData/CoreData.h>

@class QIUser;

@interface QIQuote : NSManagedObject

@property (nonatomic, retain) NSString *photoURL;
@property (nonatomic, retain) NSString *quoteID;
@property (nonatomic, retain) NSDate *created;
@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) QIUser *source;
@property (nonatomic, retain) QIUser *submittedUser;
@property (nonatomic, retain) NSNumber *viewCount;

@end
