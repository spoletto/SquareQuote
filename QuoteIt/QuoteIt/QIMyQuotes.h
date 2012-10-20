//
//  QIMyQuotes.h
//  QuoteIt
//
//  Created by Stephen Poletto on 12/29/11.
//  Copyright (c) 2011 QuoteIt. All rights reserved.
//

#import "EGORefreshTableHeaderView.h"

@class GCDiscreetNotificationView;

typedef enum {
    QIMyQuotesCreatedByMe,
    QIMyQuotesTaggedWithMe,
} QIMyQuotesSelector;

@interface QIMyQuotes : UIViewController <EGORefreshTableHeaderDelegate> {
    QIMyQuotesSelector displayedQuotesSelector;
    
    NSArray *quotesSourced;
    NSArray *quotesSubmitted;
    NSArray *quotesFailedUpload;
    
    GCDiscreetNotificationView *notificationView;
    NSString *loadingMessage;
    BOOL showingLoadingAnimation;
    
    EGORefreshTableHeaderView *refreshHeaderView;
    NSDate *lastUpdatedDate;
    BOOL reloading;
}

@property (retain, nonatomic) IBOutlet UITableView *quoteTableView;
@property (retain, nonatomic) IBOutlet UIButton *createdByYouButton;
@property (retain, nonatomic) IBOutlet UIButton *taggedWithYouButton;

- (void)showUpdatingQuotesSpinnerWithMessage:(NSString *)message;
- (void)hideUpdatingQuotesSpinner;

- (void)selectCreatedByYouTab;
- (void)selectTaggedWithYouTab;

@end
