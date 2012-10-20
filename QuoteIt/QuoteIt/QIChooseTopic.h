//
//  QIChooseTopic.h
//  QuoteIt
//
//  Created by Stephen Poletto on 2/11/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol QIChooseTopicDelegate;

@interface QIChooseTopic : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchDisplayDelegate, UISearchBarDelegate> {
    CGRect originalTableViewFrame;
    NSArray *headerLabels;
    
    // Pages
    NSArray *matchedPages;
    NSURL *pagesURL;
    
    // Events
    NSArray *allMyEvents;
    NSMutableArray *matchedEvents;
    NSURL *eventsURL;
    
    // Groups
    NSArray *allMyGroups;
    NSMutableArray *matchedGroups;
    NSURL *groupsURL;
}

@property (retain, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (retain, nonatomic) IBOutlet UIImageView *instructionsImage;
@property (retain, nonatomic) IBOutlet UILabel *instructionsLabel;
@property (assign, nonatomic) id <QIChooseTopicDelegate> delegate;

@end

extern NSString * const QITopicTypePage;
extern NSString * const QITopicTypeGroup;
extern NSString * const QITopicTypeEvent;

// Keys used to index into the dictionary returned by chooseTopic:didSelectTopic:
extern NSString * const QITopicPhotoURLKey;
extern NSString * const QITopicTypeKey;
extern NSString * const QITopicNameKey;
extern NSString * const QITopicIDKey; // For our servers.
extern NSString * const QITopicFacebookIDKey; // For Facebook's servers.

@protocol QIChooseTopicDelegate <NSObject>
@required
- (void)chooseTopic:(QIChooseTopic *)chooseTopic didSelectTopic:(NSDictionary *)topic;
@end