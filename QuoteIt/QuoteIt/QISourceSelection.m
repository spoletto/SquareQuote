//
//  QISourceSelection.m
//  QuoteIt
//
//  Created by Stephen Poletto on 12/30/11.
//  Copyright (c) 2011 QuoteIt. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "UIImageView+AFNetworking.h"
#import "AFJSONRequestOperation.h"
#import "QIFacebookConnect.h"
#import "QICoreDataManager.h"
#import "QISourceSelection.h"
#import "QIUtilities.h"
#import "QIAFClient.h"
#import "QIUser.h"

NSString * const QISourceEntityTypeFriend = @"friend";
NSString * const QISourceEntityTypePage = @"page";
NSString * const QISourceEntityTypeKey = @"QISourceEntityTypeKey";
NSString * const QISourceFacebookIDKey = @"QISourceFacebookIDKey";
NSString * const QISourceEntityIDKey = @"QISourceEntityIDKey";
NSString * const QISourceEntityNameKey = @"QISourceEntityNameKey";
NSString * const QISourceEntityPhotoURLKey = @"QISourceEntityPhotoURLKey";

static NSString *QIFacebookPageSearchURLForQuery(NSString *query) {
    NSString *escapedQuery = [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [NSString stringWithFormat:@"%@%@%@", @"https://graph.facebook.com/search?q=", escapedQuery, @"&type=page&fields=name,id,picture"];
}

@interface QISourceSelection()
- (void)cancelPriorFacebookRequests;
@end

@implementation QISourceSelection
@synthesize backgroundImage;
@synthesize delegate;
@synthesize instructionsImage;
@synthesize instructionsLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Choose Source";
        UIBarButtonItem *backItem = [UIBarButtonItem barItemWithImage:[QIUtilities backButtonImage] highlightedImage:[QIUtilities backButtonPressed] title:@"  Back" target:self action:@selector(back:)];
        self.navigationItem.leftBarButtonItem = backItem;
        NSSet *friends = [[[QICoreDataManager sharedDataManger] loggedInUser] friends];
        NSSet *friendsAndMe = [friends setByAddingObject:[[QICoreDataManager sharedDataManger] loggedInUser]];
        NSSortDescriptor *alphabetical = [[[NSSortDescriptor alloc] initWithKey:@"firstName" ascending:YES] autorelease];        
        cachedFriends = [[[friendsAndMe allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:alphabetical]] retain];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideKeyboard) name:QIUserDidNotLogInNotification object:nil];
    }
    return self;
}

- (void)hideKeyboard {
    [self.view endEditing:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    QIRenderNavigationBarTitle();
    [[self.searchDisplayController.searchBar.subviews objectAtIndex:0] removeFromSuperview];
    self.searchDisplayController.searchBar.placeholder = @"Search Sources";
    [instructionsImage setImage:[QIUtilities sourceSelectionInstructionsImage]];
    [backgroundImage setImage:[QIUtilities bookImage]];
    instructionsLabel.textColor = [QIUtilities titleBarTitleColor];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.searchDisplayController.searchBar becomeFirstResponder];
}

- (void)back:(id)sender {
    [QIUtilities navigationControllerPopViewControllerWithPageCurlTransition:super.navigationController];
}

#pragma mark -
#pragma mark UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [matchedPages count] ? 2 : 1;
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
    NSString *headerLabelText = nil;
    if (section == 0) {
        headerLabelText = [NSString stringWithFormat:@"Friends (%d)", [filteredFriends count]];
    } else {
        headerLabelText = [NSString stringWithFormat:@"Pages (%d)", [matchedPages count]];
    }
    label.text = headerLabelText;
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor clearColor];
    label.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.4];
    label.shadowOffset = CGSizeMake(0.0, 1.0);
    [headerView addSubview:label];
    
    return headerView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (section == 0) ? [filteredFriends count] : [matchedPages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"QISourceSelectionCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    }
    
    if (indexPath.section == 0) {
        QIUser *friend = [filteredFriends objectAtIndex:indexPath.row];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[friend photoURL]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
        [request setHTTPShouldHandleCookies:NO];
        [request setHTTPShouldUsePipelining:YES];
        
        [[cell imageView] setImageWithURLRequest:request placeholderImage:[QIUtilities tableViewPlaceholderImage] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            // Scale the image to fit nicely in the table view cell.
            [[cell imageView] setImage:[UIImage scale:image toFillSize:CGSizeMake(50.0, 50.0)]];
        } failure:nil];
        [[cell textLabel] setText:QIFullNameForUser(friend)];
    } else {
        NSDictionary *page = [matchedPages objectAtIndex:indexPath.row];
        if ([page valueForKey:@"picture"]) {
            NSString *pagePictureURLString = [[[page valueForKey:@"picture"] valueForKey:@"data"]valueForKey:@"url"];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:pagePictureURLString] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
            [request setHTTPShouldHandleCookies:NO];
            [request setHTTPShouldUsePipelining:YES];
            
            [[cell imageView] setImageWithURLRequest:request placeholderImage:[QIUtilities tableViewPlaceholderImage] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                // Scale the image to fit nicely in the table view cell.
                [[cell imageView] setImage:[UIImage scale:image toFillSize:CGSizeMake(50.0, 50.0)]];
            } failure:nil];
        } else {
            [[cell imageView] setImage:[QIUtilities tableViewPlaceholderImage]];
        }
        [[cell textLabel] setText:[page valueForKey:@"name"]];
    }
    
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self cancelPriorFacebookRequests];
    NSMutableDictionary *selectedSource = [NSMutableDictionary dictionary];
    
    if (indexPath.section == 0) {
        QIUser *selectedUser = [filteredFriends objectAtIndex:indexPath.row];
        [selectedSource setObject:QISourceEntityTypeFriend forKey:QISourceEntityTypeKey];
        [selectedSource setObject:[selectedUser userID] forKey:QISourceEntityIDKey];
        [selectedSource setObject:QIFullNameForUser(selectedUser) forKey:QISourceEntityNameKey];
        [selectedSource setObject:[selectedUser photoURL] forKey:QISourceEntityPhotoURLKey];
        [selectedSource setObject:[selectedUser fbID] forKey:QISourceFacebookIDKey];
    } else {
        NSDictionary *selectedPage = [matchedPages objectAtIndex:indexPath.row];
        [selectedSource setObject:QISourceEntityTypePage forKey:QISourceEntityTypeKey];
        
        // Entity ID and Facebook ID are the same because we don't store pages in our backend.
        [selectedSource setObject:[selectedPage objectForKey:@"id"] forKey:QISourceEntityIDKey];
        [selectedSource setObject:[selectedPage objectForKey:@"id"] forKey:QISourceFacebookIDKey];
        
        [selectedSource setObject:[selectedPage objectForKey:@"name"] forKey:QISourceEntityNameKey];
        [selectedSource setObject:[selectedPage objectForKey:@"picture"] forKey:QISourceEntityPhotoURLKey];
    }
    
    [self.delegate sourceSelection:self didSelectSource:selectedSource];
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

- (void)cancelPriorFacebookRequests {
    [[QIAFClient sharedFacebookClient] cancelHTTPOperationsWithMethod:@"GET" andURL:mostRecentFacebookQueryURL];
    [mostRecentFacebookQueryURL release];
    mostRecentFacebookQueryURL = nil;
}

- (void)searchFacebookPagesWithQuery:(NSString *)query {
    [self cancelPriorFacebookRequests];
    
    if (![query length]) {
        [matchedPages release];
        matchedPages = nil;
        [self.searchDisplayController.searchResultsTableView reloadData];
    } else {
        NSString *facebookURL = QIFacebookPageSearchURLForQuery(query);
        mostRecentFacebookQueryURL = [[NSURL alloc] initWithString:facebookURL];
        
        // Issue a new Facebook request.
        [[QIAFClient sharedFacebookClient] getPath:facebookURL parameters:nil success:^(AFHTTPRequestOperation *operation, id jsonObject) {
            // Not all search results have a "picture" field. Filter out the ones that don't.
            NSArray *data = [jsonObject objectForKey:@"data"];
            NSMutableArray *dataWithPictures = [NSMutableArray array];
            for (NSDictionary *element in data) {
                if ([element objectForKey:@"picture"]) {
                    [dataWithPictures addObject:element];
                }
            }
            
            [matchedPages release];
            matchedPages = [[NSArray alloc] initWithArray:dataWithPictures];
            [self.searchDisplayController.searchResultsTableView reloadData];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (![error code] == NSURLErrorNotConnectedToInternet) {
                TFLog(@"Failed to Fetch Facebook Results: %@", error);
            }
        }];
    }
}

- (void)handleSearchForTerm:(NSString *)searchTerm {
	if (!filteredFriends) {
        filteredFriends = [[NSMutableArray alloc] init];
	}
	[filteredFriends removeAllObjects];
	
	if ([searchTerm length] != 0) {
        instructionsImage.hidden = YES;
        instructionsLabel.hidden = YES;
        for (QIUser *friend in cachedFriends) {
            if ([QIFullNameForUser(friend) rangeOfString:searchTerm options:NSCaseInsensitiveSearch].location != NSNotFound) {
                [filteredFriends addObject:friend];
            } 
        }
    } else {
        instructionsImage.hidden = NO;
        instructionsLabel.hidden = NO;
    }
    [self searchFacebookPagesWithQuery:searchTerm];
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
    [self cancelPriorFacebookRequests];
}

- (void)dealloc {
    [mostRecentFacebookQueryURL release];
    [filteredFriends release];
    [matchedPages release];
    [cachedFriends release];
    [backgroundImage release];
    [instructionsImage release];
    [instructionsLabel release];
    [super dealloc];
}

- (void)viewDidUnload {
    [self setBackgroundImage:nil];
    [self setInstructionsImage:nil];
    [self setInstructionsLabel:nil];
    [super viewDidUnload];
}

@end
