//
//  QIQuoteViewer.h
//  QuoteIt
//
//  Created by Stephen Poletto on 12/30/11.
//  Copyright (c) 2011 QuoteIt. All rights reserved.
//

#import <MessageUI/MessageUI.h>

#import "MBProgressHUD.h"
#import "ATPagingView.h"
#import "Facebook.h"

@class AFHTTPRequestOperation;

@interface QIQuoteViewer : UIViewController <MBProgressHUDDelegate, ATPagingViewDelegate, UIGestureRecognizerDelegate, MFMailComposeViewControllerDelegate, FBDialogDelegate, UIAlertViewDelegate, MFMessageComposeViewControllerDelegate> {
    NSString *bucketKeyword;
    NSInteger apiPaginationNumber;
    NSInteger apiPaginationNextPageIndex; // The first index that would require a new page.
    BOOL apiPaginationHasNextPage;
    
    NSMutableArray *quotes;
    MBProgressHUD *progressHUD;
    MBProgressHUD *tumblrUploadHUD;
    UIGestureRecognizer *shareBarDismissGestureRecognizer;
    AFHTTPRequestOperation *fetchOperation;
    
    UIImageView *loadingQuoteView;
    BOOL hasLoadedAtLeastOneQuoteImage;
    
    // Is the view controller contacting the server to fetch quotes?
    // If we're displaying local QIQuote objects, this should be set to NO.
    BOOL usesNetwork;
    NSInteger initialIndex;
    
    NSInteger previouslyShownPageIndex;
    NSMutableSet *seenQuotes;
    BOOL showingEmailInvite;
    
    BOOL canDeleteQuotes;
    BOOL canFlagQuotes;
    
    UIGestureRecognizer *tumblrDismissKeyboardRecognizer;
    UITapGestureRecognizer *dismissShareOverlayRecognizer;
    NSInteger deletedQuoteIndex;
    NSInteger flaggedQuoteIndex;
    
    UIImageView *overlayView;
    BOOL disableSharing;
    BOOL showShareOverlayASAP;
    BOOL showSwipeOverlayASAP;
    NSMutableSet *incrementedViewCountQuotes;
}

- (id)initWithKeyword:(NSString *)keyword; // Sets usesNetwork to YES.
- (id)initWithQuotes:(NSArray *)quotes selectedIndex:(NSInteger)index title:(NSString *)title canDeleteQuotes:(BOOL)canDeleteQuotes; // Array of local QIQuote objects. usesNetwork = NO.
- (void)userDidDeleteQuote:(NSDictionary *)deletedQuote;
- (void)userDidFlagQuote:(NSDictionary *)flaggedQuote;

@property (retain, nonatomic) IBOutlet ATPagingView *pagingView;
@property (retain, nonatomic) IBOutlet UIImageView *submitterImage;
@property (retain, nonatomic) IBOutlet UILabel *submitterLabel;
@property (retain, nonatomic) IBOutlet UIView *shareView;
@property (retain, nonatomic) IBOutlet UIButton *shareButton;
@property (retain, nonatomic) IBOutlet UIImageView *backgroundImage;

@property (retain, nonatomic) IBOutlet UIButton *emailButton;
@property (retain, nonatomic) IBOutlet UIButton *fbButton;
@property (retain, nonatomic) IBOutlet UIButton *tumblrButton;
@property (retain, nonatomic) IBOutlet UIButton *twitterButton;
@property (retain, nonatomic) IBOutlet UIButton *pinterestButton;
@property (retain, nonatomic) IBOutlet UIButton *urlButton;
@property (retain, nonatomic) IBOutlet UIImageView *shareViewBackground;

@property (retain, nonatomic) IBOutlet UIView *tumblrLoginView;
@property (retain, nonatomic) IBOutlet UIButton *tumblrLoginSubmitButton;
@property (retain, nonatomic) IBOutlet UITextField *tumblrLoginUsernameField;
@property (retain, nonatomic) IBOutlet UITextField *tumblrLoginPasswordField;

@end
