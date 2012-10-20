//
//  QISourceSelection.h
//  QuoteIt
//
//  Created by Stephen Poletto on 12/30/11.
//  Copyright (c) 2011 QuoteIt. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol QISourceSelectionDelegate;

@interface QISourceSelection : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchDisplayDelegate, UISearchBarDelegate> {
    NSURL *mostRecentFacebookQueryURL;
    CGRect originalTableViewFrame;
    NSMutableArray *filteredFriends;
    NSArray *cachedFriends;
    NSArray *matchedPages;
}

@property (retain, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (assign, nonatomic) id <QISourceSelectionDelegate> delegate;
@property (retain, nonatomic) IBOutlet UIImageView *instructionsImage;
@property (retain, nonatomic) IBOutlet UILabel *instructionsLabel;

@end

extern NSString * const QISourceEntityTypeFriend;
extern NSString * const QISourceEntityTypePage;

// Keys used to index into the dictionary returned by sourceSelection:didSelectSource:
extern NSString * const QISourceEntityPhotoURLKey;
extern NSString * const QISourceEntityTypeKey;
extern NSString * const QISourceEntityNameKey;
extern NSString * const QISourceEntityIDKey; // For our servers.
extern NSString * const QISourceFacebookIDKey; // For Facebook's servers.

@protocol QISourceSelectionDelegate <NSObject>
@required
- (void)sourceSelection:(QISourceSelection *)sourceSelection didSelectSource:(NSDictionary *)source;
@end
