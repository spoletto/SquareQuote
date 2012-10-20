//
//  QIQuoteViewer.m
//  QuoteIt
//
//  Created by Stephen Poletto on 12/30/11.
//  Copyright (c) 2011 QuoteIt. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <Twitter/Twitter.h>

#import "DETweetComposeViewController.h"
#import "UIImageView+AFNetworking.h"
#import "QIKeychainItemWrapper.h"
#import "QIMainViewController.h"
#import "QIFacebookConnect.h"
#import "QIQuoteViewer.h"
#import "SDImageCache.h"
#import "QIQuoteView.h"
#import "QIUtilities.h"
#import "QIAFClient.h"

@interface QIQuoteViewer()
- (void)fetchQuotesWithKeyword:(NSString *)keyword pageNumber:(NSInteger)pageNumber;
- (void)initializeLoadingView;
- (QIQuoteView *)selectedQuoteView;
- (QIQuoteView *)previouslyShownQuoteView;
- (UIImage *)selectedQuoteImage;
- (void)updateSubmitterInfo;
- (QIQuoteView *)selectedQuoteView;
@end

@implementation QIQuoteViewer
@synthesize pagingView;
@synthesize submitterImage;
@synthesize submitterLabel;
@synthesize shareView;
@synthesize shareButton;
@synthesize backgroundImage;
@synthesize emailButton;
@synthesize fbButton;
@synthesize tumblrButton;
@synthesize twitterButton;
@synthesize pinterestButton;
@synthesize urlButton;
@synthesize shareViewBackground;
@synthesize tumblrLoginView;
@synthesize tumblrLoginSubmitButton;
@synthesize tumblrLoginUsernameField;
@synthesize tumblrLoginPasswordField;

- (void)commonInit {
    deletedQuoteIndex = NSNotFound;
    flaggedQuoteIndex = NSNotFound;
    [[NSBundle mainBundle] loadNibNamed:@"QIShareView" owner:self options:nil];
    [[NSBundle mainBundle] loadNibNamed:@"QITumblrLoginView" owner:self options:nil];
    
    tumblrDismissKeyboardRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tumblrDismiss)];
    tumblrDismissKeyboardRecognizer.delegate = self;
    [self.tumblrLoginView addGestureRecognizer:tumblrDismissKeyboardRecognizer];
    
    self.shareView.alpha = 0.0;
    self.tumblrLoginView.alpha = 0.0;
    [self.view addSubview:self.shareView];
    [self.view addSubview:self.tumblrLoginView];
    
    UIBarButtonItem *backItem = [UIBarButtonItem barItemWithImage:[QIUtilities backButtonImage] highlightedImage:[QIUtilities backButtonPressed] title:@"  Back" target:self action:@selector(back:)];
    self.navigationItem.leftBarButtonItem = backItem;
    seenQuotes = [[NSMutableSet alloc] init];
    incrementedViewCountQuotes = [[NSMutableSet alloc] init];
}

- (id)initWithKeyword:(NSString *)keyword {
    if ((self = [super initWithNibName:@"QIQuoteViewer" bundle:nil])) {
        [TestFlight passCheckpoint:[NSString stringWithFormat:@"View Bucket -- %@", keyword]];
        bucketKeyword = [keyword copy];
        if ([bucketKeyword isEqualToString:@"Friends"]) {
            canFlagQuotes = YES;
        }
        usesNetwork = YES;
        apiPaginationNumber = 0;
        apiPaginationHasNextPage = YES;
        apiPaginationNextPageIndex = 0;
        hasLoadedAtLeastOneQuoteImage = NO;
        previouslyShownPageIndex = 0;
        
        self.title = [keyword stringByAppendingString:@" Quotes"];
        quotes = [[NSMutableArray alloc] init];
        [self fetchQuotesWithKeyword:keyword pageNumber:apiPaginationNumber++];
        [self commonInit];
    }
    return self;
}

- (id)initWithQuotes:(NSArray *)quotesIn selectedIndex:(NSInteger)index title:(NSString *)title  canDeleteQuotes:(BOOL)canDelete {
    if ((self = [super initWithNibName:@"QIQuoteViewer" bundle:nil])) {
        [TestFlight passCheckpoint:[NSString stringWithFormat:@"View Bucket -- %@", title]];
        self.title = title;
        canFlagQuotes = YES;
        canDeleteQuotes = canDelete;
        usesNetwork = NO;
        quotes = [quotesIn mutableCopy];
        initialIndex = index;
        previouslyShownPageIndex = initialIndex;
        [self.pagingView reloadData];
        self.pagingView.currentPageIndex = initialIndex;
        [self updateSubmitterInfo];
        [self commonInit];
    }
    return self;
}

- (void)back:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    QIRenderNavigationBarTitle();
    
    [emailButton setBackgroundImage:[[UIImage imageNamed:@"silver_btn_static"] stretchableImageWithLeftCapWidth:2.0 topCapHeight:10.0] forState:UIControlStateNormal];
    [emailButton setBackgroundImage:[[UIImage imageNamed:@"silver_btn_active"] stretchableImageWithLeftCapWidth:2.0 topCapHeight:10.0] forState:UIControlStateHighlighted];
    [emailButton setImage:[UIImage imageNamed:@"email_icon"] forState:UIControlStateNormal];
    [fbButton setBackgroundImage:[[UIImage imageNamed:@"silver_btn_active"] stretchableImageWithLeftCapWidth:2.0 topCapHeight:10.0] forState:UIControlStateHighlighted];
    [fbButton setBackgroundImage:[[UIImage imageNamed:@"silver_btn_static"] stretchableImageWithLeftCapWidth:2.0 topCapHeight:10.0] forState:UIControlStateNormal];
    [fbButton setImage:[UIImage imageNamed:@"fb_icon"] forState:UIControlStateNormal];
    [twitterButton setBackgroundImage:[[UIImage imageNamed:@"silver_btn_active"] stretchableImageWithLeftCapWidth:2.0 topCapHeight:10.0] forState:UIControlStateHighlighted];
    [twitterButton setBackgroundImage:[[UIImage imageNamed:@"silver_btn_static"] stretchableImageWithLeftCapWidth:2.0 topCapHeight:10.0] forState:UIControlStateNormal];
    [twitterButton setImage:[UIImage imageNamed:@"twitter_icon"] forState:UIControlStateNormal];
    [pinterestButton setBackgroundImage:[[UIImage imageNamed:@"silver_btn_active"] stretchableImageWithLeftCapWidth:2.0 topCapHeight:10.0] forState:UIControlStateHighlighted];
    [pinterestButton setBackgroundImage:[[UIImage imageNamed:@"silver_btn_static"] stretchableImageWithLeftCapWidth:2.0 topCapHeight:10.0] forState:UIControlStateNormal];
    [pinterestButton setImage:[UIImage imageNamed:@"sms_icon"] forState:UIControlStateNormal];
    [urlButton setBackgroundImage:[[UIImage imageNamed:@"silver_btn_active"] stretchableImageWithLeftCapWidth:2.0 topCapHeight:10.0] forState:UIControlStateHighlighted];
    [urlButton setBackgroundImage:[[UIImage imageNamed:@"silver_btn_static"] stretchableImageWithLeftCapWidth:2.0 topCapHeight:10.0] forState:UIControlStateNormal];
    [urlButton setImage:[UIImage imageNamed:@"link_icon"] forState:UIControlStateNormal];
    [tumblrButton setBackgroundImage:[[UIImage imageNamed:@"silver_btn_active"] stretchableImageWithLeftCapWidth:2.0 topCapHeight:10.0] forState:UIControlStateHighlighted];
    [tumblrButton setBackgroundImage:[[UIImage imageNamed:@"silver_btn_static"] stretchableImageWithLeftCapWidth:2.0 topCapHeight:10.0] forState:UIControlStateNormal];
    [tumblrButton setImage:[UIImage imageNamed:@"tumblr_icon"] forState:UIControlStateNormal];
    
    [shareButton setBackgroundImage:[UIImage imageNamed:@"share_btn_active"] forState:UIControlStateHighlighted];
    [tumblrLoginSubmitButton setImage:[UIImage imageNamed:@"tumblr_btn_submit_press"] forState:UIControlStateHighlighted];
    
    shareButton.titleLabel.font = [QIUtilities buttonTitleFont];
    [shareButton setTitleColor:[QIUtilities buttonTitleColor] forState:UIControlStateNormal];
    shareButton.titleLabel.shadowColor = [QIUtilities buttonTitleDropShadowColor];
    shareButton.titleLabel.shadowOffset = CGSizeMake(0, -1);
    
    submitterLabel.textColor = [QIUtilities titleBarTitleColor];
    submitterLabel.font = [QIUtilities submitterLabelFont];
    submitterLabel.shadowColor = [UIColor whiteColor];
    
    QIConfigureImageWell(submitterImage);
    
    submitterImage.image = [QIUtilities userPlaceholderImage];
    submitterLabel.text = @"Loading...";
    
    self.tumblrLoginView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    [self.tumblrLoginUsernameField addTarget:self action:@selector(textFieldContentsChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.tumblrLoginPasswordField addTarget:self action:@selector(textFieldContentsChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.tumblrLoginSubmitButton setEnabled:NO];
    
    [backgroundImage setImage:[QIUtilities bookImage]];
    self.pagingView.backgroundColor = [UIColor clearColor];
    shareButton.enabled = NO;
    [super viewDidLoad];
    if (![quotes count]) {
        [self initializeLoadingView];
    } else {
        [self.pagingView reloadData];
        self.pagingView.currentPageIndex = initialIndex;
        [self updateSubmitterInfo];
    }
    
    // Twitter bug. Ask Stephen.
    self.view.autoresizesSubviews = NO;
}

- (void)showOverlayViewWithImageNamed:(NSString *)imageName {
    [self hideOverlayView:NO]; // Ensure no existing overlay view.
    overlayView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
    CGRect hack = overlayView.frame;
    hack.origin.y += 20; // Accomodate the status bar.
    overlayView.frame = hack;
    [[[UIApplication sharedApplication] keyWindow] addSubview:overlayView];
    [QIMainViewController mainViewController].overlayType = QIMainViewOverlayTypeBrowse;
    self.navigationItem.leftBarButtonItem.enabled = NO;
    [self selectedQuoteView].hasGestureRecognizers = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:QIHasSwipedThroughQuoteBrowser]) {
        showSwipeOverlayASAP = YES;
    } else if (![[NSUserDefaults standardUserDefaults] boolForKey:QIHasSharedQuote]) {
        showShareOverlayASAP = YES;
    }
}

- (void)hideOverlayView:(BOOL)animated {
    if (!animated) {
        [overlayView removeFromSuperview];
        [overlayView release];
        overlayView = nil;
        [QIMainViewController mainViewController].overlayType = QIMainViewOverlayTypeNone;
        self.navigationItem.leftBarButtonItem.enabled = YES;
        [self selectedQuoteView].hasGestureRecognizers = YES;
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            overlayView.alpha = 0.0;  
        } completion:^(BOOL completed) {
            [overlayView removeFromSuperview];
            [overlayView release];
            overlayView = nil;
            [QIMainViewController mainViewController].overlayType = QIMainViewOverlayTypeNone;
            self.navigationItem.leftBarButtonItem.enabled = YES;
            [self selectedQuoteView].hasGestureRecognizers = YES;
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(incrementViewCount) object:nil];
    if (usesNetwork) {
        [TestFlight passCheckpoint:[NSString stringWithFormat:@"Bucket %@ -- Viewed %d Quotes", bucketKeyword, [seenQuotes count]]];
    } else {
        [TestFlight passCheckpoint:[NSString stringWithFormat:@"%@ -- Viewed %d Quotes", self.title, [seenQuotes count]]];
    }
    [fetchOperation cancel];
    [fetchOperation release];
    fetchOperation = nil;
    [progressHUD removeFromSuperview];
    [progressHUD release];
	progressHUD = nil;
    [tumblrUploadHUD removeFromSuperview];
    [tumblrUploadHUD release];
    tumblrUploadHUD = nil;
    showSwipeOverlayASAP = NO;
    showShareOverlayASAP = NO;
}

- (void)incrementViewCount {
    NSString *quoteID = [[self selectedQuote] valueForKey:@"quoteID"];
    
    if (![incrementedViewCountQuotes containsObject:quoteID]) {
        [incrementedViewCountQuotes addObject:quoteID];
        NSDictionary *postParams = [NSDictionary dictionaryWithObject:quoteID forKey:@"quote_id"];
        [[QIAFClient sharedClient] postPath:@"/api/increment_view_count" parameters:postParams success:^(AFHTTPRequestOperation *operation, id jsonObject) {
            if ([[jsonObject valueForKey:@"status"] isEqualToString:@"ok"]) {
                // Do nothing.
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            // Do nothing.
        }];
    }
}

- (void)initializeLoadingView {
    CGRect frame = self.pagingView.frame;
    loadingQuoteView = [[UIImageView alloc] initWithFrame:CGRectInset(frame, QIQuoteViewInset.width, QIQuoteViewInset.height)];
    loadingQuoteView.animationImages = [NSArray arrayWithObjects:    
                                        [UIImage imageNamed:@"frame1"],
                                        [UIImage imageNamed:@"frame2"],
                                        [UIImage imageNamed:@"frame3"],
                                        [UIImage imageNamed:@"frame4"], nil];
    loadingQuoteView.animationDuration = 1.0f;
    loadingQuoteView.animationRepeatCount = 0;
    [self.view addSubview:loadingQuoteView];
    [loadingQuoteView startAnimating];
    self.pagingView.scrollView.scrollEnabled = NO;
}

- (void)dismissLoadingView {
    [loadingQuoteView removeFromSuperview];
    [loadingQuoteView stopAnimating];
    self.pagingView.scrollView.scrollEnabled = YES;
}

- (void)hudWasHidden:(MBProgressHUD *)hud {
    // Remove HUD from screen when the HUD was hidden.
    [hud removeFromSuperview];
    [hud release];
    if (hud == progressHUD) {
        progressHUD = nil;
    } else if (hud == tumblrUploadHUD) {
        tumblrUploadHUD = nil;
    }
}

- (void)emailInviteToFriends {
    showingEmailInvite = YES;
    MFMailComposeViewController *composer = [[MFMailComposeViewController alloc] init];
    composer.navigationBar.tag = 700;
    composer.mailComposeDelegate = self;
    [composer setMessageBody:@"Hey,\n\nI'm playing with SquareQuote, an iPhone app for creating beautiful quotes. Give it a try at http://squarequote.it." isHTML:NO];
    [composer setSubject:@"Check out SquareQuote"];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    [[QIMainViewController mainViewController] presentModalViewController:composer animated:YES];
    [composer release];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // If there was an error and we just dimissed the alert view, pop this view controller.
    if (buttonIndex == 1) {
        [self emailInviteToFriends];
    } else {
        [self.navigationController popViewControllerAnimated:NO];
    }
}

- (void)fetchQuotesWithKeyword:(NSString *)keyword pageNumber:(NSInteger)pageNumber {
    NSString *fetchEndpoint = [@"/api/bucket/" stringByAppendingPathComponent:keyword];
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:pageNumber] forKey:@"page"];
    NSURLRequest *request = [[QIAFClient sharedClient] requestWithMethod:@"GET" path:fetchEndpoint parameters:parameters];
    AFHTTPRequestOperation *operation = [[QIAFClient sharedClient] HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id jsonObject) {
        [fetchOperation release];
        fetchOperation = nil;
        if ([[jsonObject valueForKey:@"status"] isEqualToString:@"ok"]) {
            NSArray *responseQuotes = [jsonObject valueForKey:@"quotes"];
            apiPaginationNextPageIndex += [responseQuotes count];
            apiPaginationHasNextPage = !![responseQuotes count];
            [quotes addObjectsFromArray:responseQuotes];
            if ([quotes count]) {
                [self.pagingView reloadData];
                [self updateSubmitterInfo];
            } else {
                [fetchOperation release];
                fetchOperation = nil;
                [loadingQuoteView stopAnimating];
                if ([keyword isEqualToString:@"Friends"]) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Quotes" message:@"Your friends have not yet shared any quotes. Would you like to invite your friends to start using SquareQuote?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
                    [alert show];
                    [alert release];
                } else {
                    [[QIErrorHandler sharedErrorHandler] presentAlertViewWithTitle:@"Could not find any quotes." message:nil completionHandler:^(void) {
                        [self.navigationController popViewControllerAnimated:NO];
                    }];
                }
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [fetchOperation release];
        fetchOperation = nil;
        [loadingQuoteView stopAnimating];
        [[QIErrorHandler sharedErrorHandler] presentFailureViewWithTitle:@"Failed to fetch quotes." error:error completionHandler:^(void) {
            [self.navigationController popViewControllerAnimated:NO];
        }];
    }];
    [[QIAFClient sharedClient] enqueueHTTPRequestOperation:operation];
    fetchOperation = [operation retain];
}

- (void)updateSubmitterInfo {
    if (self.pagingView.currentPageIndex == deletedQuoteIndex || self.pagingView.currentPageIndex == flaggedQuoteIndex) {
        // Don't update the submitter info for a quote we're about to delete anyway.
        // It could be deleted from SQL when we contact the server, and then we'll be displaying (null) (null) for the submitter info.
        return;
    }
    
    NSDictionary *currentQuote = [quotes objectAtIndex:pagingView.currentPageIndex];
    NSDictionary *submitter = [currentQuote valueForKey:@"submittedUser"];
    [submitterLabel setText:QIFullNameForUserDictionary(submitter)];
    NSURL *submitterImageURL = [NSURL URLWithString:[submitter valueForKey:@"photoURL"]];
    [submitterImage setImageWithURL:submitterImageURL placeholderImage:[QIUtilities userPlaceholderImage]];
}

- (BOOL)haveIFlaggedQuoteAtIndex:(NSInteger)index {
    // [quotes objectAtIndex:index]
    return NO;
}

- (void)updateShareButtonEnabledState {
    // If the currently selected quote has an image, we can share it!
    if ([self selectedQuoteImage] && self.pagingView.currentPageIndex != deletedQuoteIndex && self.pagingView.currentPageIndex != flaggedQuoteIndex && ![self haveIFlaggedQuoteAtIndex:self.pagingView.currentPageIndex] && !disableSharing) {
        shareButton.enabled = YES;
        
        NSInteger currentIndex = self.pagingView.currentPageIndex;
        if (showShareOverlayASAP || currentIndex > 2) {
            [self showShareOverlay];
        }
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(incrementViewCount) object:nil];
        [self performSelector:@selector(incrementViewCount) withObject:nil afterDelay:2.0];
        
    } else {
        shareButton.enabled = NO;
    }
}

#pragma mark -
#pragma mark Image caching

- (NSURL *)urlForImageInPagingViewAtIndex:(NSInteger)index {
    NSString *urlString = [[quotes objectAtIndex:index] valueForKey:@"photoURL"];
    return [NSURL URLWithString:urlString];
}

- (NSURL *)urlForSubmitterImageForPageAtIndex:(NSInteger)index {
    NSDictionary *quote = [quotes objectAtIndex:index];
    NSDictionary *submitter = [quote valueForKey:@"submittedUser"];
    return [NSURL URLWithString:[submitter valueForKey:@"photoURL"]];
}

- (void)loadImageForPageView:(QIQuoteView *)view atIndex:(NSInteger)index {
    if ([self haveIFlaggedQuoteAtIndex:index]) {
        // If the quote has been flagged, show the under review banner.
        [[view imageView] setImage:[UIImage imageNamed:@"review_banner"]];
        return;
    }
    
    NSURL *url = [self urlForImageInPagingViewAtIndex:index];
    
    // UIImageView+AFNetworking maintains the cache for us.
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
    [request setHTTPShouldHandleCookies:NO];
    [request setHTTPShouldUsePipelining:YES];
    
    [view startLoading];
    [[view imageView] setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        [view stopLoading];
        [self updateShareButtonEnabledState];
        if (!hasLoadedAtLeastOneQuoteImage) {
            [self dismissLoadingView];
            if (showSwipeOverlayASAP) {
                [self showOverlayViewWithImageNamed:@"ol_SwipeQuote"];
                shareButton.enabled = NO;
                disableSharing = YES;
                showSwipeOverlayASAP = NO;
            }
            hasLoadedAtLeastOneQuoteImage = YES;
        }
    } failure:nil];
}

- (void)prefetchImageAtIndex:(NSInteger)index {
    NSURL *quoteURL = [self urlForImageInPagingViewAtIndex:index];
    NSURL *submitterURL = [self urlForSubmitterImageForPageAtIndex:index];
    
    for (NSURL *url in [NSSet setWithObjects:quoteURL, submitterURL, nil]) {
        [QIUtilities cacheImageAtURL:url];
    }
}

#pragma mark -
#pragma mark ATPagingViewDelegate methods

- (NSInteger)numberOfPagesInPagingView:(ATPagingView *)pagingView {
    return quotes.count;
}

- (void)pagesDidChangeInPagingView:(ATPagingView *)pagingView {
    [self updateShareButtonEnabledState];
}

- (UIView *)viewForPageInPagingView:(ATPagingView *)pagingView atIndex:(NSInteger)index {
    QIQuoteView *view = (QIQuoteView *)[self.pagingView dequeueReusablePage];
    if (view == nil) {
        view = [[[QIQuoteView alloc] init] autorelease];
        view.quoteViewerBackpointer = self;
    }
    view.showsDeleteButton = canDeleteQuotes;
    view.showsFlagButton = canFlagQuotes;
    NSDictionary *quote = [quotes objectAtIndex:index];
    view.quote = quote;
    [self loadImageForPageView:view atIndex:index];
    view.hasGestureRecognizers = ![self haveIFlaggedQuoteAtIndex:index];
    return view;
}

- (void)hideShareOverlay {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:QIHasSharedQuote]) {
        [self.view removeGestureRecognizer:dismissShareOverlayRecognizer];
        [dismissShareOverlayRecognizer release];
        dismissShareOverlayRecognizer = nil;
        
        [self hideOverlayView:YES];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:QIHasSharedQuote];
        showShareOverlayASAP = NO;
    }
}

- (void)dismissShareOverlayTapped {
    [self hideShareOverlay];
}

- (void)showShareOverlay {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:QIHasSharedQuote]) {
        [self showOverlayViewWithImageNamed:@"ol_Share"];
        if (!dismissShareOverlayRecognizer) {
            dismissShareOverlayRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissShareOverlayTapped)];
            dismissShareOverlayRecognizer.delegate = self;
            [self.view addGestureRecognizer:dismissShareOverlayRecognizer];
        }
    }
}

- (void)pagingViewWillBeginMoving:(ATPagingView *)pagingView {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:QIHasSwipedThroughQuoteBrowser]) {
        disableSharing = NO;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:QIHasSwipedThroughQuoteBrowser];
        [self hideOverlayView:YES];
        [self updateShareButtonEnabledState];
    }
}

- (void)pagingViewDidEndMoving:(ATPagingView *)pagingView {
    if (previouslyShownPageIndex != self.pagingView.currentPageIndex) {
        [[self previouslyShownQuoteView] showFrontOfQuote];
        if (previouslyShownPageIndex == deletedQuoteIndex) {
            [quotes removeObjectAtIndex:deletedQuoteIndex];
            
            NSInteger currentPageIndex = self.pagingView.currentPageIndex;
            [self.pagingView reloadData];
            
            if (currentPageIndex > deletedQuoteIndex) {
                self.pagingView.currentPageIndex = currentPageIndex - 1;
            }
            
            deletedQuoteIndex = NSNotFound;
        }
        if (previouslyShownPageIndex == flaggedQuoteIndex) {
            [quotes removeObjectAtIndex:flaggedQuoteIndex];
            
            NSInteger currentPageIndex = self.pagingView.currentPageIndex;
            [self.pagingView reloadData];
            
            if (currentPageIndex > flaggedQuoteIndex) {
                self.pagingView.currentPageIndex = currentPageIndex - 1;
            }
            
            flaggedQuoteIndex = NSNotFound;
        }
        previouslyShownPageIndex = self.pagingView.currentPageIndex;
    }
    [self updateShareButtonEnabledState];
}

- (void)currentPageDidChangeInPagingView:(ATPagingView *)pagingView {
    [self updateShareButtonEnabledState];
    NSInteger currentIndex = self.pagingView.currentPageIndex;
    
    // Record the quote as having been seen.
    [seenQuotes addObject:[NSNumber numberWithInteger:currentIndex]];
    
    NSInteger maxIndex = MIN(currentIndex + 5, self.pagingView.pageCount - 1);
    if (usesNetwork && (currentIndex + 6 > apiPaginationNextPageIndex) && apiPaginationHasNextPage && !fetchOperation) {
        [self fetchQuotesWithKeyword:bucketKeyword pageNumber:apiPaginationNumber++];
    }
    for (NSInteger i = currentIndex; i < maxIndex; i++) {
        [self prefetchImageAtIndex:i];
    }
    [self updateSubmitterInfo];
}

- (void)userDidDeleteQuote:(NSDictionary *)deletedQuote {
    deletedQuoteIndex = [quotes indexOfObject:deletedQuote];
    shareButton.enabled = NO;
}

- (void)userDidFlagQuote:(NSDictionary *)flaggedQuote {
    flaggedQuoteIndex = [quotes indexOfObject:flaggedQuote];
    shareButton.enabled = NO;
}

#pragma mark -
#pragma mark Sharing

- (void)installDismissGestureRecognizer {
    shareBarDismissGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleShareBarVisibility)];
    [shareBarDismissGestureRecognizer setDelegate:self];
    [self.view addGestureRecognizer:shareBarDismissGestureRecognizer];
}

- (void)uninstallDismissGestureRecognizer {
    [self.view removeGestureRecognizer:shareBarDismissGestureRecognizer];
    [shareBarDismissGestureRecognizer release];
    shareBarDismissGestureRecognizer = nil;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (gestureRecognizer == shareBarDismissGestureRecognizer) {
        if ([self.shareView hitTest:[touch locationInView:self.shareView] withEvent:nil]) {
            return NO;
        }
    }
    if (gestureRecognizer == tumblrDismissKeyboardRecognizer) {
        if ([self.tumblrLoginSubmitButton hitTest:[touch locationInView:self.tumblrLoginSubmitButton] withEvent:nil]) {
            return NO;
        }
    }
    if (gestureRecognizer == dismissShareOverlayRecognizer) {
        if ([self.shareButton hitTest:[touch locationInView:self.shareButton] withEvent:nil]) {
            return NO;
        }
    }
    
    return YES;
}

- (void)toggleShareBarVisibility {
    // Install the share view in the appropriate location.
    CGRect shareFrame = self.shareView.frame;
    
    // 11 lower and 7 to the left to accomodate padding in actual share view background asset.
    shareFrame.origin.y = self.pagingView.frame.origin.y + self.pagingView.frame.size.height - self.shareView.frame.size.height + 11;
    shareFrame.origin.x = self.pagingView.frame.origin.x + QIQuoteViewInset.width - 7;
    shareFrame.size.width = self.pagingView.frame.size.width - (2*QIQuoteViewInset.width);
    self.shareView.frame = shareFrame;
    
    // Fade the share view in/out.
    CGFloat newAlpha = (self.shareView.alpha == 0.0) ? 1.0 : 0.0;
    [UIView animateWithDuration:0.25 animations:^{
        self.shareView.alpha = newAlpha;
    }];
    
    // Install/unistall the dismiss gesture appropriately.
    if (newAlpha == 1.0) {
        self.pagingView.scrollView.scrollEnabled = NO;
        [self installDismissGestureRecognizer];
    } else {
        self.pagingView.scrollView.scrollEnabled = YES;
        [self uninstallDismissGestureRecognizer];
    }
}

- (IBAction)shareQuote:(id)sender {
    [TestFlight passCheckpoint:@"Share Popup Revealed"];
    [self hideShareOverlay];
    [self toggleShareBarVisibility];
}

- (NSDictionary *)selectedQuote {
    return [quotes objectAtIndex:self.pagingView.currentPageIndex];
}

- (QIQuoteView *)previouslyShownQuoteView {
    return (QIQuoteView *)[self.pagingView viewForPageAtIndex:previouslyShownPageIndex];
}

- (QIQuoteView *)selectedQuoteView {
    return (QIQuoteView *)[self.pagingView viewForPageAtIndex:self.pagingView.currentPageIndex];
}

- (UIImage *)selectedQuoteImage {
    return [[[self selectedQuoteView] imageView] image];
}

- (void)displayHUDMessage:(NSString *)message withImage:(UIImage *)image {
    progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
	[self.view addSubview:progressHUD];
	progressHUD.customView = [[[UIImageView alloc] initWithImage:image] autorelease];
    progressHUD.mode = MBProgressHUDModeCustomView;
    progressHUD.delegate = self;
    progressHUD.labelText = message;
    [progressHUD show:YES];
	[progressHUD hide:YES afterDelay:1.0];
}

- (IBAction)shareURL:(id)sender {    
    // Copy the URL to the pasteboard.
    [TestFlight passCheckpoint:@"Share -- URL"];
    [UIPasteboard generalPasteboard].string = QIURLForQuote([self selectedQuote]);
    [self toggleShareBarVisibility];
    [self displayHUDMessage:@"URL Copied to Clipboard" withImage:[QIUtilities checkmarkImage]];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
	switch (result) {
		case MessageComposeResultCancelled:
			break;
		case MessageComposeResultFailed:
            [[[[UIAlertView alloc] initWithTitle:@"SMS Failed" message:@"Unknown Error" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
			break;
		case MessageComposeResultSent:
            [self displayHUDMessage:@"Message Sent" withImage:[QIUtilities checkmarkImage]];
			break;
		default:
			break;
	}
	[controller dismissModalViewControllerAnimated:YES];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    switch (result) {
		case MFMailComposeResultCancelled:
			break;
		case MFMailComposeResultFailed:
            [[[[UIAlertView alloc] initWithTitle:@"Email Failed" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
			break;
		case MFMailComposeResultSent:
            [self displayHUDMessage:@"Email Sent" withImage:[QIUtilities checkmarkImage]];
			break;
        case MFMailComposeResultSaved:
            break;
		default:
			break;
	}
    [controller dismissModalViewControllerAnimated:YES];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
    if (showingEmailInvite) {
        [self.navigationController popViewControllerAnimated:NO];
        showingEmailInvite = NO;
    }
}

- (IBAction)emailQuote:(id)sender {
    [TestFlight passCheckpoint:@"Share -- Email"];
    [self toggleShareBarVisibility];
    
    MFMailComposeViewController *composer = [[MFMailComposeViewController alloc] init];
    composer.navigationBar.tag = 700;
    composer.mailComposeDelegate = self;
    NSString *messageBody = [NSString stringWithFormat:@"<html><head></head><body bgcolor=\"#FFFFFF\"><div></div><div><a href=\"%@\"><img src=\"%@\" width=300, height=300></a><br>(<a href=\"%@\">via %@</a>)</div>", QIURLForQuote([self selectedQuote]), [[self selectedQuote] valueForKey:@"photoURL"], QIURLForQuote([self selectedQuote]), QIURLForQuote([self selectedQuote])];
    [composer setMessageBody:messageBody isHTML:YES];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    [[QIMainViewController mainViewController] presentModalViewController:composer animated:YES];
    [composer release];
}

- (IBAction)shareViaSMS:(id)sender {
    [TestFlight passCheckpoint:@"Share -- SMS"];
    [self toggleShareBarVisibility];
    if ([MFMessageComposeViewController canSendText]) {
        NSString *urlToShare = QIURLForQuote([self selectedQuote]);
        MFMessageComposeViewController *controller = [[[MFMessageComposeViewController alloc] init] autorelease];
        controller.body = urlToShare;
        controller.messageComposeDelegate = self;
        [self presentModalViewController:controller animated:YES];
    } else {
        [[[[UIAlertView alloc] initWithTitle:@"SMS not available on this device." message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
    }
}

- (void)initializeTumblrUploadHUD {
    if (!tumblrUploadHUD) {
        tumblrUploadHUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:tumblrUploadHUD];
        tumblrUploadHUD.delegate = self;
        tumblrUploadHUD.labelText = @"Posting to Tumblr";
        [tumblrUploadHUD show:YES];
    }
}

- (void)updateTumblrHUDToReflectSuccess {
    tumblrUploadHUD.customView = [[[UIImageView alloc] initWithImage:[QIUtilities checkmarkImage]] autorelease];
    tumblrUploadHUD.mode = MBProgressHUDModeCustomView;
    tumblrUploadHUD.labelText = @"Posted to Tumblr";
    [tumblrUploadHUD show:YES];
	[tumblrUploadHUD hide:YES afterDelay:1.0];
}

- (void)tumblrDismiss {
    if ([self.tumblrLoginPasswordField isFirstResponder] || [self.tumblrLoginUsernameField isFirstResponder]) {
        [self.view endEditing:YES];
    } else {
        [self hideTumblrLoginPrompt];
    }
}

- (BOOL)hasTumblrCredentials {
    NSString *username = [[QIKeychainItemWrapper sharedTumblrItemWrapper] objectForKey:(id)kSecAttrAccount];
    NSString *password = [[QIKeychainItemWrapper sharedTumblrItemWrapper] objectForKey:(id)kSecValueData];
    return [username length] && [password length] && [[NSUserDefaults standardUserDefaults] boolForKey:@"QITumblrActive"];
}

- (void)saveTumblrUsername:(NSString *)username password:(NSString *)password {
    [[QIKeychainItemWrapper sharedTumblrItemWrapper] setObject:username forKey:(id)kSecAttrAccount];
    [[QIKeychainItemWrapper sharedTumblrItemWrapper] setObject:password forKey:(id)kSecValueData];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"QITumblrActive"];
}

- (void)postToTumblr {
    NSString *quotePhotoURL = [[self selectedQuote] valueForKey:@"photoURL"]; // S3 directly.
    NSString *clickThroughURL = QIURLForQuote([self selectedQuote]);
    NSString *username = [[QIKeychainItemWrapper sharedTumblrItemWrapper] objectForKey:(id)kSecAttrAccount];
    NSString *password = [[QIKeychainItemWrapper sharedTumblrItemWrapper] objectForKey:(id)kSecValueData];
    NSDictionary *postParams = [NSDictionary dictionaryWithObjectsAndKeys:username, @"email",
                                password, @"password",
                                @"photo", @"type",
                                quotePhotoURL, @"source",
                                [NSString stringWithFormat:@"(via %@)", QIURLForQuote([self selectedQuote])], @"caption",
                                clickThroughURL, @"click-through-url", nil];
    
    [self initializeTumblrUploadHUD];
    [[QIAFClient sharedTumblrClient] postPath:@"/api/write" parameters:postParams success:^(AFHTTPRequestOperation *operation, id jsonObject) {
        [self updateTumblrHUDToReflectSuccess];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [tumblrUploadHUD hide:NO];
        [[QIErrorHandler sharedErrorHandler] presentFailureViewWithTitle:@"Upload to Tumblr Failed" error:error completionHandler:nil];
    }];
}

- (void)authenticateTumblrCredentials {
    NSString *username = [self.tumblrLoginUsernameField text];
    NSString *password = [self.tumblrLoginPasswordField text];
    NSDictionary *postParams = [NSDictionary dictionaryWithObjectsAndKeys:username, @"email",
                                password, @"password", nil];
    
    [self initializeTumblrUploadHUD];
    [[QIAFClient sharedTumblrClient] postPath:@"/api/authenticate" parameters:postParams success:^(AFHTTPRequestOperation *operation, id object) {
        [self hideTumblrLoginPrompt];
        [self saveTumblrUsername:username password:password];
        [self postToTumblr];        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [tumblrUploadHUD hide:NO];
        [[[[UIAlertView alloc] initWithTitle:@"Upload to Tumblr Failed" message:@"Incorrect username or password." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
    }];

}

- (void)textFieldContentsChanged:(id)sender {
    BOOL enabled = [[self.tumblrLoginPasswordField text] length] && [[self.tumblrLoginUsernameField text] length];
    [self.tumblrLoginSubmitButton setEnabled:enabled];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    BOOL shouldReturn = YES;
    if (textField == self.tumblrLoginUsernameField) {
        [self.tumblrLoginPasswordField becomeFirstResponder];
    } else if (textField == self.tumblrLoginPasswordField) {
        shouldReturn = [[self.tumblrLoginPasswordField text] length] && [[self.tumblrLoginUsernameField text] length];
        if (shouldReturn) {
            [textField resignFirstResponder];
            [self authenticateTumblrCredentials];
        }
    }
    return shouldReturn;
}

- (IBAction)tumblrLoginSubmit:(id)sender {
    [self authenticateTumblrCredentials];
}

- (void)hideTumblrLoginPrompt {
    CGFloat newAlpha = 0.0;
    [UIView animateWithDuration:0.25 animations:^{
        self.tumblrLoginView.alpha = newAlpha;
    }];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)showTumblrLoginPrompt {
    CGFloat newAlpha = 1.0;
    [UIView animateWithDuration:0.25 animations:^{
        self.tumblrLoginView.alpha = newAlpha;
    }];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.tumblrLoginUsernameField becomeFirstResponder];
}

- (IBAction)shareOnTumblr:(id)sender {
    [TestFlight passCheckpoint:@"Share -- Tumblr"];
    [self toggleShareBarVisibility];
    if (![self hasTumblrCredentials]) {
        [self showTumblrLoginPrompt];
    } else {
        [self postToTumblr];
    }
}

- (IBAction)shareOnFacebook:(id)sender {
    [TestFlight passCheckpoint:@"Share -- Facebook"];
    [self toggleShareBarVisibility];
    NSString *name = [NSString stringWithFormat:@"SquareQuote from %@", QISourceNameForQuote([self selectedQuote])];
    NSString *link = QIURLForQuote([self selectedQuote]);
    NSString *description = [NSString stringWithFormat:@"\"%@\"", [[self selectedQuote] valueForKey:@"text"]];
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   QIFacebookAppID, @"app_id",
                                   @"https://developers.facebook.com/docs/reference/dialogs/", @"link",
                                   [[self selectedQuote] valueForKey:@"photoURL"], @"picture",
                                   name, @"name",
                                   link, @"link",
                                   link, @"caption",
                                   description, @"description",
                                   nil];
    
    [[[QIFacebookConnect sharedFacebookConnect] facebook] dialog:@"feed" andParams:params andDelegate:self];
}

- (IBAction)shareOnTwitter:(id)sender {
    [TestFlight passCheckpoint:@"Share -- Twitter"];
    [self toggleShareBarVisibility];
    
    // Cook up the Twitter text.
    NSString *initialTextStart = [NSString stringWithFormat:@"%@ @quote: ", QISourceNameForQuote([self selectedQuote])];
    NSInteger charsRemaining = 140 - [initialTextStart length] - [QIURLForQuote([self selectedQuote]) length] - 2; // Make room for ""
    
    NSInteger endIndex = [[[self selectedQuote] valueForKey:@"text"] length];
    NSString *quoteText = [NSString stringWithFormat:@"\"%@\"", [[[self selectedQuote] valueForKey:@"text"] substringToIndex:endIndex]];
    if (charsRemaining < [[[self selectedQuote] valueForKey:@"text"] length]) {
        endIndex = charsRemaining - 3; // Make room for "..."
        quoteText = [NSString stringWithFormat:@"\"%@...\"", [[[self selectedQuote] valueForKey:@"text"] substringToIndex:endIndex]];
    }
    NSString *initialText = [initialTextStart stringByAppendingString:quoteText];
    
    if (NSClassFromString(@"TWTweetComposeViewController")) {
        TWTweetComposeViewController *tweetSheet = [[[TWTweetComposeViewController alloc] init] autorelease];
        [tweetSheet setInitialText:initialText];
        [tweetSheet addURL:[NSURL URLWithString:QIURLForQuote([self selectedQuote])]];
        tweetSheet.completionHandler = ^(TWTweetComposeViewControllerResult result){
            [self dismissModalViewControllerAnimated:YES];
        };
        [self presentModalViewController:tweetSheet animated:YES];
    } else {    
        DETweetComposeViewController *tweetSheet = [[[DETweetComposeViewController alloc] init] autorelease];
        [tweetSheet setInitialText:initialText];
        [tweetSheet addURL:[NSURL URLWithString:QIURLForQuote([self selectedQuote])]];
        self.modalPresentationStyle = UIModalPresentationCurrentContext;
        [self presentModalViewController:tweetSheet animated:YES];
    }
}

- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(incrementViewCount) object:nil];
    [seenQuotes release];
    [incrementedViewCountQuotes release];
    [dismissShareOverlayRecognizer release];
    [tumblrDismissKeyboardRecognizer release];
    [bucketKeyword release];
    [shareBarDismissGestureRecognizer release];
    [progressHUD release];
    [tumblrUploadHUD release];
    [quotes release];
    [submitterImage release];
    [submitterLabel release];
    [shareView release];
    [shareButton release];
    [backgroundImage release];
    [emailButton release];
    [fbButton release];
    [tumblrButton release];
    [twitterButton release];
    [pinterestButton release];
    [urlButton release];
    [shareViewBackground release];
    [tumblrLoginSubmitButton release];
    [tumblrLoginUsernameField release];
    [tumblrLoginPasswordField release];
    [tumblrLoginView release];
    [super dealloc];
}

- (void)viewDidUnload {
    [self setSubmitterImage:nil];
    [self setSubmitterLabel:nil];
    [self setShareView:nil];
    [self setShareButton:nil];
    [self setBackgroundImage:nil];
    [self setEmailButton:nil];
    [self setFbButton:nil];
    [self setTumblrButton:nil];
    [self setTwitterButton:nil];
    [self setPinterestButton:nil];
    [self setUrlButton:nil];
    [self setShareViewBackground:nil];
    [self setTumblrLoginSubmitButton:nil];
    [self setTumblrLoginUsernameField:nil];
    [self setTumblrLoginPasswordField:nil];
    [self setTumblrLoginView:nil];
    [super viewDidUnload];
}

@end
