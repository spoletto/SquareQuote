//
//  QIUser.h
//  QuoteIt
//
//  Created by Stephen Poletto on 12/29/11.
//  Copyright (c) 2011 QuoteIt. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface QIUser : NSManagedObject

@property (nonatomic, retain) NSString *name; // This is only used for fb-graph types!
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *firstName;
@property (nonatomic, retain) NSString *lastName;
@property (nonatomic, retain) NSString *photoURL;
@property (nonatomic, retain) NSString *userID;
@property (nonatomic, retain) NSString *fbID;
@property (nonatomic, retain) NSSet *friends;
@property (nonatomic, retain) NSSet *quotesSourced;
@property (nonatomic, retain) NSSet *quotesSubmitted;

@end
