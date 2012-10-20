//
//  QIPhotoSearch.m
//  QuoteIt
//
//  Created by Stephen Poletto on 2/19/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

#import "KTThumbView+SDWebImage.h"
#import "QIPhotoSearch.h"
#import "QISearchBar.h"
#import "QIUtilities.h"
#import "QIAFClient.h"

@implementation QIPhotoSearch
@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)displayInstructions {
    instructionsLabel.hidden = NO;
    instructionsBackground.hidden = NO;
}

- (void)hideInstructions {
    instructionsLabel.hidden = YES;
    instructionsBackground.hidden = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // The thumbs view controller sets the scrollview as the main view. We need to add
    // a search bar to the top of the view, so we need to create a container view that
    // wraps around the scrollview.
    CGRect frame = self.view.frame;
    frame.origin.y += 44; // Make room for the search bar.
    frame.size.height -= 159; // Account for tab bar, nav bar and search bar.
    UIView *containerView = [[UIView alloc] initWithFrame:frame];
    UIView *scrollView = self.view;
    scrollView.frame = frame;
    scrollView.backgroundColor = [UIColor clearColor];
    self.view = containerView;
    [containerView addSubview:scrollView];
    [containerView release];
    
    QISearchBar *searchBar = [[QISearchBar alloc] initWithFrame:CGRectMake(10, 0, 300, 44)];
    [[[searchBar subviews] objectAtIndex:0] removeFromSuperview];
    searchBar.delegate = self;
    searchBar.placeholder = @"Search Photos";
    [self.view addSubview:searchBar];
    [searchBar release];
    
    instructionsBackground = [[UIImageView alloc] initWithFrame:CGRectMake(15, 44, 290, 44)];
    instructionsBackground.image = [QIUtilities sourceSelectionInstructionsImage];
    instructionsLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 57, 260, 21)];
    instructionsLabel.text = @"Search for images using the search field above.";
    instructionsLabel.textColor = [QIUtilities titleBarTitleColor];
    instructionsLabel.font = [UIFont fontWithName:@"Georgia" size:13.5];
    instructionsLabel.backgroundColor = [UIColor clearColor];
    instructionsLabel.textAlignment = UITextAlignmentCenter;
    instructionsLabel.adjustsFontSizeToFitWidth = YES;
    instructionsLabel.minimumFontSize = 10.0;
    
    [self.view addSubview:instructionsBackground];
    [self.view addSubview:instructionsLabel];
    
    self.dataSource = self;
    self.view.backgroundColor = [UIColor colorWithPatternImage:[QIUtilities bookImage]];
}

// Superclass override.
- (void)didSelectThumbAtIndex:(NSUInteger)index {
    if ([self.delegate respondsToSelector:@selector(userDidSelectPhotoURL:)]) {
        [self.delegate userDidSelectPhotoURL:[[images objectAtIndex:index] objectForKey:@"src_big"]];
    }
}

#pragma mark -
#pragma mark KTPhotoBrowserDataSource

- (NSInteger)numberOfPhotos {
    return [images count];
}

- (void)thumbImageAtIndex:(NSInteger)index thumbView:(KTThumbView *)thumbView {
    NSDictionary *imageInfo = [images objectAtIndex:index];
    [thumbView setImageWithURL:[NSURL URLWithString:[imageInfo objectForKey:@"src_small"]] placeholderImage:[UIImage imageNamed:@"img_placeholder"]];
}

#pragma mark -
#pragma mark UISearchBarDelegate

- (NSURL *)photoSearchAPIEndpointURLForQuery:(NSString *)query {
    NSString *baseString = [[[QIAFClient sharedClient] baseURL] absoluteString];
    NSString *searchString = [@"api/search-images?query=" stringByAppendingString:query];
    return [NSURL URLWithString:[baseString stringByAppendingString:searchString]];
}

- (void)cancelPriorRequest {
    [[QIAFClient sharedClient] cancelHTTPOperationsWithMethod:@"GET" andURL:mostRecentPhotoSearchURL];
    [mostRecentPhotoSearchURL release];
    mostRecentPhotoSearchURL = nil;
}

- (void)filterContent:(NSString *)searchText {
	if (inSearchMode && [searchText length]) {
        if (![priorSearchText isEqualToString:searchText]) {
            [self cancelPriorRequest];
            [priorSearchText release];
            priorSearchText = [searchText retain];
            [self hideInstructions];
            
            mostRecentPhotoSearchURL = [[self photoSearchAPIEndpointURLForQuery:searchText] retain];
            
            NSDictionary *params = [NSDictionary dictionaryWithObject:searchText forKey:@"query"];
            [[QIAFClient sharedClient] getPath:@"/api/search-images" parameters:params success:^(AFHTTPRequestOperation *operation, id jsonObject) {
                if ([[jsonObject objectForKey:@"status"] isEqualToString:@"ok"]) {
                    [images release];
                    images = [[jsonObject objectForKey:@"results"] retain];
                    [self reloadThumbs];
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                // TODO: Handle.
                NSLog(@"Error :%@", error);
            }]; 
        }
	} else {
        [self cancelPriorRequest];
        [images release];
        images = nil;
        [self reloadThumbs];
        [self displayInstructions];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {	
	[searchBar resignFirstResponder];
    [searchBar setShowsCancelButton:NO animated:YES];
	[self filterContent:searchBar.text];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {	
	searchBar.text = nil;	
	[searchBar resignFirstResponder];
	
	[self filterContent:searchBar.text];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {	
	[self filterContent:searchText];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
	inSearchMode = YES;
	[searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {	
	NSString *searchText = searchBar.text;
	
	// We're still 'in edit mode', if the user left a keyword in the searchBar
	inSearchMode = (searchText != nil && [searchText length] > 0);
	[searchBar setShowsCancelButton:inSearchMode animated:YES];
	
	[self filterContent:searchText];
}

@end
