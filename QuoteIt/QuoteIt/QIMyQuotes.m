//
//  QIMyQuotes.m
//  QuoteIt
//
//  Created by Stephen Poletto on 12/29/11.
//  Copyright (c) 2011 QuoteIt. All rights reserved.
//

#import "GCDiscreetNotificationView.h"
#import "QIFailedQuoteUploads.h"
#import "QIMainViewController.h"
#import "QICoreDataManager.h"
#import "QIAccountSettings.h"
#import "QIQuoteViewer.h"
#import "QIMyQuoteView.h"
#import "QIUtilities.h"
#import "QIMyQuotes.h"
#import "QIQuote.h"
#import "QIUser.h"

#define kQIMyQuoteTableViewCellHeight 85

@interface QIMyQuotes()
- (void)updateToCreatedByYou;
- (void)updateToTaggedWithYou;
- (void)updateQuotes;
@end

@implementation QIMyQuotes
@synthesize quoteTableView;
@synthesize createdByYouButton;
@synthesize taggedWithYouButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"My Quotes";
        
        UIBarButtonItem *accountItem = [UIBarButtonItem barItemWithImage:[QIUtilities settingsButtonImage] highlightedImage:[QIUtilities settingsButtonPressed] title:@"" target:self action:@selector(showAccountSettings:)];
        self.navigationItem.rightBarButtonItem = accountItem;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateMyQuotes:) name:QICoreDataManagerDidUpdateMyQuotes object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateFailedQuotes:) name:QIFailedQuoteUploadsDidUpdateFailedQuotes object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willUpdateFailedQuotes:) name:QIFailedQuoteUploadsWillUpdateFailedQuotes object:nil];
        [self updateQuotes];
    }
    return self;
}

- (void)showAccountSettings:(id)sender {
    QIAccountSettings *accountSettings = [[QIAccountSettings alloc] initWithNibName:@"QIAccountSettings" bundle:nil];
    UINavigationController *accountSettingsNavigation = [[[UINavigationController alloc] initWithRootViewController:accountSettings] autorelease];
    accountSettingsNavigation.navigationBar.clipsToBounds = YES;
    [QIUtilities setBackgroundImage:[QIUtilities navigationBarImage] forNavigationController:accountSettingsNavigation];
    [[QIMainViewController mainViewController] presentModalViewController:accountSettingsNavigation animated:YES];
    [accountSettings release];
}

- (void)didUpdateMyQuotes:(NSNotification *)notification {
    [self updateQuotes];
    [self hideUpdatingQuotesSpinner];
}

- (void)willUpdateFailedQuotes:(NSNotification *)notification {
    if (!showingLoadingAnimation) {
        [self showUpdatingQuotesSpinnerWithMessage:@"Retrying Quote Upload"];
    }
}

- (void)didUpdateFailedQuotes:(NSNotification *)notification {
    [self updateQuotes];
    [self hideUpdatingQuotesSpinner];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:QIHasTappedShareQuote] && ![[QIMainViewController mainViewController] overlayShowing]) {
        [[QIMainViewController mainViewController] showShareOverlayView];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    QIRenderNavigationBarTitle();
    
    self.quoteTableView.rowHeight = kQIMyQuoteTableViewCellHeight;
    self.quoteTableView.backgroundColor = [UIColor clearColor];
    
    refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.quoteTableView.bounds.size.height, self.view.frame.size.width, self.quoteTableView.bounds.size.height)];
    refreshHeaderView.backgroundColor = [UIColor clearColor];
    refreshHeaderView.delegate = self;
    [self.quoteTableView addSubview:refreshHeaderView];
    
    // It's very important this be called *after* the row height is set, since it will
    // -reloadData on the tableview.
    [self updateToCreatedByYou];
    [self.taggedWithYouButton setImage:[UIImage imageNamed:@"right_active"] forState:UIControlStateHighlighted];
    [self.createdByYouButton setImage:[UIImage imageNamed:@"left_active"] forState:UIControlStateHighlighted];
    
    UIImageView *backgroundImage = [[UIImageView alloc] initWithFrame:self.view.frame];
    [backgroundImage setImage:[QIUtilities bookImage]];
    [self.view insertSubview:backgroundImage atIndex:0];
    [backgroundImage release];
    
    if (showingLoadingAnimation) {
        // We could have been told to show our loading view before viewDidLoad is called.
        [self showUpdatingQuotesSpinnerWithMessage:loadingMessage];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.quoteTableView deselectRowAtIndexPath:[self.quoteTableView indexPathForSelectedRow] animated:YES];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [refreshHeaderView release];
    [notificationView release];
    [quotesSourced release];
    [quotesSubmitted release];
    [quoteTableView release];
    [createdByYouButton release];
    [taggedWithYouButton release];
    [super dealloc];
}

- (void)viewDidUnload {
    [self setQuoteTableView:nil];
    [self setCreatedByYouButton:nil];
    [self setTaggedWithYouButton:nil];
    [super viewDidUnload];
}

#pragma mark -
#pragma mark UITableViewDataSource

- (void)showUpdatingQuotesSpinnerWithMessage:(NSString *)message {
    // setTextLabel on the notification view is broken. Just make a new one!
    [notificationView removeFromSuperview];
    [notificationView release];
    notificationView = [[GCDiscreetNotificationView alloc] initWithText:message showActivity:YES inPresentationMode:GCDiscreetNotificationViewPresentationModeTop inView:self.view];
    
    // Scroll table view to top.
    [self.quoteTableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    
    loadingMessage = message;
    showingLoadingAnimation = YES;
    [notificationView show:YES];
}

- (void)hideUpdatingQuotesSpinner {
    showingLoadingAnimation = NO; // Ignore the timer, since this is just viewDidLoad magic.
    [notificationView hideAnimatedAfter:0.5];
}

- (void)prefetchPhotosForMyQuotes {
    for (QIQuote *quote in quotesSourced) {
        [QIUtilities cacheImageAtURL:[NSURL URLWithString:[quote photoURL]]];
    }
    for (QIQuote *quote in quotesSubmitted) {
        [QIUtilities cacheImageAtURL:[NSURL URLWithString:[quote photoURL]]];
    }
}

- (void)updateQuotes {
    [quotesFailedUpload release];
    [quotesSubmitted release];
    [quotesSourced release];
    
    // Sorted in reverse chronological order.
    quotesSubmitted = [[[[QICoreDataManager sharedDataManger] loggedInUser] quotesSubmitted] allObjects];
    quotesSubmitted = [[quotesSubmitted sortedArrayUsingComparator:^(QIQuote *obj1, QIQuote *obj2) {
        return [[obj2 created] compare:[obj1 created]];
    }] retain];
    quotesSourced = [[[[QICoreDataManager sharedDataManger] loggedInUser] quotesSourced] allObjects];
    quotesSourced = [[quotesSourced sortedArrayUsingComparator:^(QIQuote *obj1, QIQuote *obj2) {
        return [[obj2 created] compare:[obj1 created]];
    }] retain];
    
    quotesFailedUpload = [[[QIFailedQuoteUploads sharedFailedQuotes] failedQuotes] retain];
    
    [self prefetchPhotosForMyQuotes];
    
    [self.quoteTableView reloadData];
    [lastUpdatedDate release];
    lastUpdatedDate = [[NSDate alloc] init];
    [refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.quoteTableView];
    reloading = NO;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = 0;
    if (displayedQuotesSelector == QIMyQuotesCreatedByMe) {
        count = [quotesSubmitted count] + [quotesFailedUpload count];
    } else if (displayedQuotesSelector == QIMyQuotesTaggedWithMe) {
        count = [quotesSourced count];
    }
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForFailedQuoteAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"QIMyQuotesCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    }

    NSDictionary *failedQuote = [quotesFailedUpload objectAtIndex:indexPath.row];    
    QIMyQuoteViewUIView *existingMyQuoteView = (QIMyQuoteViewUIView *)[cell.contentView viewWithTag:500];
    if (existingMyQuoteView) {
        // Try re-using the existing QIMyQuoteView for performance.
        existingMyQuoteView.backpointedMyQuote.failedQuote = failedQuote;
    } else {
        // No pre-existing QIMyQuoteView. Init a new one.
        QIMyQuoteView *quoteView = [[QIMyQuoteView alloc] init];
        quoteView.failedQuote = failedQuote;
        quoteView.view.tag = 500;
        [cell.contentView addSubview:[quoteView view]];
        [quoteView release];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // First check if we're displaying a failed quote.
    if (displayedQuotesSelector == QIMyQuotesCreatedByMe && indexPath.row < [quotesFailedUpload count]) {
        return [self tableView:tableView cellForFailedQuoteAtIndexPath:indexPath];
    }
    
    static NSString *cellIdentifier = @"QIMyQuotesCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    }

    QIQuote *quote = nil;
    if (displayedQuotesSelector == QIMyQuotesCreatedByMe) {
        quote = [quotesSubmitted objectAtIndex:(indexPath.row - [quotesFailedUpload count])];
    } else if (displayedQuotesSelector == QIMyQuotesTaggedWithMe) {
        quote = [quotesSourced objectAtIndex:indexPath.row];
    }
    
    QIMyQuoteViewUIView *existingMyQuoteView = (QIMyQuoteViewUIView *)[cell.contentView viewWithTag:500];
    if (existingMyQuoteView) {
        // Try re-using the existing QIMyQuoteView for performance.
        existingMyQuoteView.backpointedMyQuote.quote = quote;
    } else {
        // No pre-existing QIMyQuoteView. Init a new one.
        QIMyQuoteView *quoteView = [[QIMyQuoteView alloc] init];
        quoteView.quote = quote;
        quoteView.view.tag = 500;
        [cell.contentView addSubview:[quoteView view]];
        [quoteView release];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (displayedQuotesSelector == QIMyQuotesCreatedByMe && indexPath.row < [quotesFailedUpload  count]) {
        return nil; // Disable selection for failed quotes.
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = indexPath.row;
    NSArray *quotes = nil;
    NSString *navBarTitle = nil;
    BOOL userCanDeleteQuotes = NO;
    
    if (displayedQuotesSelector == QIMyQuotesCreatedByMe) {
        userCanDeleteQuotes = YES;
        row = indexPath.row - [quotesFailedUpload count];
        quotes = quotesSubmitted;
        navBarTitle = @"Submitted Quotes";
    } else if (displayedQuotesSelector == QIMyQuotesTaggedWithMe) {
        quotes = quotesSourced;
        navBarTitle = @"Attributed Quotes";
    }
    
    QIQuoteViewer *quoteViewer = [[QIQuoteViewer alloc] initWithQuotes:quotes selectedIndex:row title:navBarTitle canDeleteQuotes:userCanDeleteQuotes];
    [QIUtilities navigationController:self.navigationController animteWithPageCurlToViewController:quoteViewer];
    [quoteViewer release];
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{	
	[refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	[refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}


#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
	[[QICoreDataManager sharedDataManger] loadMyQuotes]; // Update the list of my quotes.
    reloading = YES;
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
	return reloading;
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	return lastUpdatedDate;
}

#pragma mark -
#pragma mark Segmented Control

- (void)updateToCreatedByYou {
    displayedQuotesSelector = QIMyQuotesCreatedByMe;
    [self.quoteTableView reloadData];
    [self.createdByYouButton setImage:[UIImage imageNamed:@"left_active"] forState:UIControlStateNormal];
    [self.taggedWithYouButton setImage:[UIImage imageNamed:@"right_static"] forState:UIControlStateNormal];
}

- (void)updateToTaggedWithYou {
    displayedQuotesSelector = QIMyQuotesTaggedWithMe;
    [self.quoteTableView reloadData];
    [self.createdByYouButton setImage:[UIImage imageNamed:@"left_static"] forState:UIControlStateNormal];
    [self.taggedWithYouButton setImage:[UIImage imageNamed:@"right_active"] forState:UIControlStateNormal];
}

- (void)selectCreatedByYouTab {
    if (displayedQuotesSelector != QIMyQuotesCreatedByMe) {
        [self updateToCreatedByYou];
    }
}

- (void)selectTaggedWithYouTab {
    if (displayedQuotesSelector != QIMyQuotesTaggedWithMe) {
        [self updateToTaggedWithYou];
    }
}

- (IBAction)createdByYouPressed:(id)sender {
    [self selectCreatedByYouTab];
}

- (IBAction)taggedWithYouPressed:(id)sender {
    [self selectTaggedWithYouTab];
}

@end
