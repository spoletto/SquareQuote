//
//  QIChooseTopic.m
//  QuoteIt
//
//  Created by Stephen Poletto on 2/11/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "UIImageView+AFNetworking.h"
#import "AFJSONRequestOperation.h"
#import "QICoreDataManager.h"
#import "QIFacebookConnect.h"
#import "QIChooseTopic.h"
#import "QIUtilities.h"
#import "QIAFClient.h"
#import "QIUser.h"

#define kQIChooseTopicCategoryResultCount 8

NSString * const QITopicTypePage = @"QITopicTypePage"; 
NSString * const QITopicTypeGroup = @"QITopicTypeGroup";
NSString * const QITopicTypeEvent = @"QITopicTypeEvent";
NSString * const QITopicPhotoURLKey = @"QITopicPhotoURLKey";
NSString * const QITopicTypeKey = @"QITopicTypeKey";
NSString * const QITopicNameKey = @"QITopicNameKey";
NSString * const QITopicIDKey = @"QITopicIDKey";
NSString * const QITopicFacebookIDKey = @"QITopicFacebookIDKey";

static NSString *QIFacebookPageSearchURLForQuery(NSString *query) {
    NSString *escapedQuery = [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *accessToken = [[[QIFacebookConnect sharedFacebookConnect] facebook] accessToken];
    return [NSString stringWithFormat:@"%@%@%@%@", @"https://graph.facebook.com/search?q=", escapedQuery, @"&type=page&fields=name,id,picture&access_token=", accessToken];
}

static NSString *QIFacebookMyEventsURL(void) {
    NSString *accessToken = [[[QIFacebookConnect sharedFacebookConnect] facebook] accessToken];
    return [NSString stringWithFormat:@"%@%@", @"https://graph.facebook.com/me/events?fields=name,id,picture&access_token=", accessToken];
}

static NSString *QIFacebookMyGroupsURL(void) {
    NSString *accessToken = [[[QIFacebookConnect sharedFacebookConnect] facebook] accessToken];
    return [NSString stringWithFormat:@"%@%@", @"https://graph.facebook.com/me/groups?fields=name,id,picture&access_token=", accessToken];
}

@interface QIChooseTopic()
- (void)cancelPriorFacebookRequests;
@end

@implementation QIChooseTopic
@synthesize backgroundImage;
@synthesize instructionsImage;
@synthesize instructionsLabel;
@synthesize delegate;

- (void)filterEventsWithSearchTerm:(NSString *)searchTerm {
    if (!matchedEvents) {
        matchedEvents = [[NSMutableArray alloc] init];
	}
	[matchedEvents removeAllObjects];
	
	if ([searchTerm length] != 0) {
        for (NSDictionary *event in allMyEvents) {
            if ([[event objectForKey:@"name"] rangeOfString:searchTerm options:NSCaseInsensitiveSearch].location != NSNotFound) {
                if ([event objectForKey:@"picture"]) {
                    [matchedEvents addObject:event];
                }
            } 
        }
    }
    
    // May be called from prefetching facebook data. So force a refresh.
    [self.searchDisplayController.searchResultsTableView reloadData];
}

- (void)filterGroupsWithSearchTerm:(NSString *)searchTerm {
    if (!matchedGroups) {
        matchedGroups = [[NSMutableArray alloc] init];
	}
	[matchedGroups removeAllObjects];
	
	if ([searchTerm length] != 0) {
        for (NSDictionary *group in allMyGroups) {
            if ([[group objectForKey:@"name"] rangeOfString:searchTerm options:NSCaseInsensitiveSearch].location != NSNotFound) {
                if ([group objectForKey:@"picture"]) {
                    [matchedGroups addObject:group];
                }
            } 
        }
    }
    
    // May be called from prefetching facebook data. So force a refresh.
    [self.searchDisplayController.searchResultsTableView reloadData];
}

- (void)prefetchFacebookData {
    // Should this be cached in core data?
    eventsURL = [[NSURL alloc] initWithString:QIFacebookMyEventsURL()];
    pagesURL = [[NSURL alloc] initWithString:QIFacebookMyGroupsURL()];
    
    [[QIAFClient sharedFacebookClient] getPath:[eventsURL absoluteString] parameters:nil success:^(AFHTTPRequestOperation *operation, id jsonObject) {
        allMyEvents = [[jsonObject objectForKey:@"data"] retain];
        [self filterEventsWithSearchTerm:self.searchDisplayController.searchBar.text];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // TODO: Handle.
        NSLog(@"Error :%@", error);
    }];
    [[QIAFClient sharedFacebookClient] getPath:[pagesURL absoluteString] parameters:nil success:^(AFHTTPRequestOperation *operation, id jsonObject) {
        allMyGroups = [[jsonObject objectForKey:@"data"] retain];
        [self filterGroupsWithSearchTerm:self.searchDisplayController.searchBar.text];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // TODO: Handle.
        NSLog(@"Error :%@", error);
    }];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Choose Topic";
        UIBarButtonItem *backItem = [UIBarButtonItem barItemWithImage:[QIUtilities backButtonImage] highlightedImage:[QIUtilities backButtonPressed] title:@"  Back" target:self action:@selector(back:)];
        self.navigationItem.leftBarButtonItem = backItem;
        
        [self prefetchFacebookData];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow) name:UIKeyboardWillShowNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    QIRenderNavigationBarTitle();
    [[self.searchDisplayController.searchBar.subviews objectAtIndex:0] removeFromSuperview];
    self.searchDisplayController.searchBar.placeholder = @"Search Topics";
    [instructionsImage setImage:[QIUtilities sourceSelectionInstructionsImage]];
    [backgroundImage setImage:[QIUtilities bookImage]];
    instructionsLabel.textColor = [QIUtilities titleBarTitleColor];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.searchDisplayController.searchBar becomeFirstResponder];
}

- (void)back:(id)sender {
    [self cancelPriorFacebookRequests]; // Ensure we don't have any outstanding requests.
    [QIUtilities navigationControllerPopViewControllerWithPageCurlTransition:super.navigationController];
}

- (NSArray *)sectionEntriesForSectionIndex:(NSUInteger)section {
    NSArray *entries = nil;
    if (section == 0) {
        if ([matchedPages count]) {
            entries = matchedPages;
        } else if ([matchedGroups count]) {
            entries = matchedGroups;
        } else {
            entries = matchedEvents;
        }
    }
    if (section == 1) {
        if ([matchedPages count]) {
            entries = matchedGroups;
        } else {
            entries = matchedEvents;
        }
    }
    if (section == 2) {
        entries = matchedEvents;
    }
    return entries;
}

- (NSString *)sectionHeaderForSectionIndex:(NSUInteger)section {    
    NSString *header = nil;
    if (section == 0) {
        if ([matchedPages count]) {
            header = [@"Pages" stringByAppendingFormat:@" (%d)", [matchedPages count]];
        } else if ([matchedGroups count]) {
            header = [@"Groups" stringByAppendingFormat:@" (%d)", [matchedGroups count]];
        } else {
            header = [@"Events" stringByAppendingFormat:@" (%d)", [matchedEvents count]];
        }
    }
    if (section == 1) {
        if ([matchedPages count]) {
            header = [@"Groups" stringByAppendingFormat:@" (%d)", [matchedGroups count]];
        } else {
            header = [@"Events" stringByAppendingFormat:@" (%d)", [matchedEvents count]];
        }
    }
    if (section == 2) {
        header = [@"Events" stringByAppendingFormat:@" (%d)", [matchedEvents count]];
    }
    return header;
}

#pragma mark -
#pragma mark UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return !![matchedPages count] + !![matchedGroups count] + !![matchedEvents count];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section  {
    UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, tableView.sectionHeaderHeight)] autorelease];
    
    // Create a gradient for the header.
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = headerView.bounds;
    
    // Setup the colors for the gradient.
    UIColor *one = UIColorFromRGB(0x726e67);
    UIColor *two = UIColorFromRGB(0xb9b5ad);
    UIColor *three = UIColorFromRGB(0xaca8a1);
    UIColor *four = UIColorFromRGB(0xd8d5d0);
    UIColor *five = UIColorFromRGB(0x858077);
    gradient.colors = [NSArray arrayWithObjects:(id)[one CGColor], (id)[two CGColor], (id)[three CGColor], (id)[four CGColor], (id)[five CGColor], (id)[five CGColor], nil];
    
    // Setup the control points for the gradient.
    NSNumber *oneLoc = [NSNumber numberWithFloat:0.05];
    NSNumber *twoLoc = [NSNumber numberWithFloat:0.06];
    NSNumber *threeLoc = [NSNumber numberWithFloat:0.92];
    NSNumber *fourLoc = [NSNumber numberWithFloat:0.95];
    NSNumber *fiveLoc = [NSNumber numberWithFloat:0.98];
    NSNumber *sixLoc = [NSNumber numberWithFloat:1.0];
    gradient.locations = [NSArray arrayWithObjects:oneLoc, twoLoc, threeLoc, fourLoc, fiveLoc, sixLoc, nil];
    
    gradient.startPoint = CGPointMake(0.5, 1.0);
    gradient.endPoint = CGPointMake(0.5, 0.0);
    
    // Insert the gradient into the header view.
    gradient.opacity = 0.9;
    [headerView.layer insertSublayer:gradient atIndex:0];
    
    // Add a label for the header.
    UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(10, 0, tableView.bounds.size.width - 10, tableView.sectionHeaderHeight)] autorelease];
    label.font = [UIFont fontWithName:@"Helvetica-Bold" size:16.0];
    label.text = [self sectionHeaderForSectionIndex:section];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor clearColor];
    label.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.4];
    label.shadowOffset = CGSizeMake(0.0, 1.0);
    [headerView addSubview:label];
    
    return headerView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self sectionEntriesForSectionIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"QIChooseTopicCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    }
    
    NSDictionary *entry = [[self sectionEntriesForSectionIndex:indexPath.section] objectAtIndex:indexPath.row];
    if ([entry valueForKey:@"picture"]) {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[entry valueForKey:@"picture"]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
        [request setHTTPShouldHandleCookies:NO];
        [request setHTTPShouldUsePipelining:YES];
        
        [[cell imageView] setImageWithURLRequest:request placeholderImage:[QIUtilities tableViewPlaceholderImage] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            // Scale the image to fit nicely in the table view cell.
            [[cell imageView] setImage:[UIImage scale:image toFillSize:CGSizeMake(50.0, 50.0)]];
        } failure:nil];
    } else {
        [[cell imageView] setImage:[QIUtilities tableViewPlaceholderImage]];
    }
    [[cell textLabel] setText:[entry valueForKey:@"name"]];
    
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self cancelPriorFacebookRequests];
    NSMutableDictionary *selectedTopic = [NSMutableDictionary dictionary];
    
    NSString *type = nil;
    NSArray *entries = [self sectionEntriesForSectionIndex:indexPath.section];
    if (entries == matchedEvents) {
        type = QITopicTypeEvent;
    } else if (entries == matchedGroups) {
        type = QITopicTypeGroup;
    } else {
        type = QITopicTypePage;
    }
    [selectedTopic setObject:type forKey:QITopicTypeKey];
    
    NSDictionary *entry = [entries objectAtIndex:indexPath.row];
    // Entity ID and Facebook ID are the same because we don't store pages in our backend.
    [selectedTopic setObject:[entry objectForKey:@"id"] forKey:QITopicIDKey];
    [selectedTopic setObject:[entry objectForKey:@"id"] forKey:QITopicFacebookIDKey];
    
    [selectedTopic setObject:[entry objectForKey:@"name"] forKey:QITopicNameKey];
    [selectedTopic setObject:[entry objectForKey:@"picture"] forKey:QITopicPhotoURLKey];
    
    [self.delegate chooseTopic:self didSelectTopic:selectedTopic];
    [super.navigationController popViewControllerAnimated:NO];
}

#pragma mark -
#pragma mark UISearchDisplayControllerDelegate Methods

// http://stackoverflow.com/questions/5473579/uisearchdisplaydelegate-how-to-remove-this-opaque-view
- (void)keyboardWillShow {
    for(UIView *subview in self.view.subviews) {
        if ([subview isKindOfClass:[UIControl class]]) {
            UIControl *v = (UIControl*)subview;
            if (v.alpha < 1) {
                v.hidden = YES;
            }
        }
    }
}

- (UINavigationController *)navigationController {
    // http://stackoverflow.com/questions/2813118/prevent-a-uisearchdisplaycontroller-from-hiding-the-navigation-bar
    return nil;
}

- (void)cancelPagesFacebookRequest {
    [[QIAFClient sharedFacebookClient] cancelHTTPOperationsWithMethod:@"GET" andURL:pagesURL];
    [pagesURL release];
    pagesURL = nil;
}

- (void)cancelPriorFacebookRequests {
    [[QIAFClient sharedFacebookClient] cancelHTTPOperationsWithMethod:@"GET" andURL:pagesURL];
    [[QIAFClient sharedFacebookClient] cancelHTTPOperationsWithMethod:@"GET" andURL:groupsURL];
    [[QIAFClient sharedFacebookClient] cancelHTTPOperationsWithMethod:@"GET" andURL:eventsURL];
    [pagesURL release];
    pagesURL = nil;
    [groupsURL release];
    groupsURL = nil;
    [eventsURL release];
    eventsURL = nil;
}

- (void)clearAllResults {
    [matchedPages release];
    matchedPages = nil;
    [matchedEvents release];
    matchedEvents = nil;
    [matchedGroups release];
    matchedGroups = nil;
}

- (void)searchFacebookPagesWithQuery:(NSString *)query {
    [self cancelPagesFacebookRequest];
    
    if (![query length]) {
        [self clearAllResults];
        [self.searchDisplayController.searchResultsTableView reloadData];
    } else {
        pagesURL = [[NSURL alloc] initWithString:QIFacebookPageSearchURLForQuery(query)];

        // Issue Facebook request.
        [[QIAFClient sharedFacebookClient] getPath:[pagesURL absoluteString] parameters:nil success:^(AFHTTPRequestOperation *operation, id jsonObject) {            
            // Not all search results have a "picture" field. Filter out the ones that don't.
            NSArray *data = [jsonObject objectForKey:@"data"];
            NSMutableArray *dataWithPictures = [NSMutableArray array];
            for (NSDictionary *element in data) {
                if ([element objectForKey:@"picture"]) {
                    [dataWithPictures addObject:element];
                }
                if ([dataWithPictures count] >= kQIChooseTopicCategoryResultCount) {
                    break;
                }
            }
            
            [matchedPages release];
            matchedPages = [[NSArray alloc] initWithArray:dataWithPictures];
            [self.searchDisplayController.searchResultsTableView reloadData];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            // TODO: Handle.
            NSLog(@"Error :%@", error);
        }];
    }
}

- (void)handleSearchForTerm:(NSString *)searchTerm {
    [self searchFacebookPagesWithQuery:searchTerm];
    [self filterEventsWithSearchTerm:searchTerm];
    [self filterGroupsWithSearchTerm:searchTerm];
    
    if (![searchTerm length]) {
        instructionsImage.hidden = NO;
        instructionsLabel.hidden = NO;
    } else {
        instructionsImage.hidden = YES;
        instructionsLabel.hidden = YES;
    }
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
	[self handleSearchForTerm:searchString];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didShowSearchResultsTableView:(UITableView *)tableView {
    //originalTableViewFrame can be used to make the width of the table smaller.
    //originalTableViewFrame = tableView.frame;
    tableView.backgroundColor = [UIColor clearColor];
    //tableView.frame = CGRectMake(10.0, 45.0, 300.0, 360.0);
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView {
    //tableView.frame = originalTableViewFrame;
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    //instructionsImage.hidden = YES;
    //instructionsLabel.hidden = YES;
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
    instructionsImage.hidden = NO;
    instructionsLabel.hidden = NO;
    [self cancelPagesFacebookRequest];
}

- (void)viewDidUnload {
    [self setBackgroundImage:nil];
    [self setInstructionsImage:nil];
    [self setInstructionsLabel:nil];
    [super viewDidUnload];
}

- (void)dealloc {
    [headerLabels release];
    [backgroundImage release];
    [instructionsImage release];
    [instructionsLabel release];
    [super dealloc];
}

@end
