//
//  QITaggedPhotos.m
//  QuoteIt
//
//  Created by Stephen Poletto on 2/19/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

#import "KTThumbView+SDWebImage.h"
#import "QISourceSelection.h"
#import "QICoreDataManager.h"
#import "QITaggedPhotos.h"
#import "RKRequestQueue.h"
#import "QIUtilities.h"
#import "QIUser.h"

@implementation QITaggedPhotos
@synthesize quoteSource;
@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)startLoading {
    [noDataImage removeFromSuperview]; // In case it's still hanging around.
    [self.view addSubview:loadingImageView];
    [loadingImageView startAnimating];
}

- (void)stopLoading {
    [loadingImageView removeFromSuperview];
    [loadingImageView stopAnimating];
}

- (BOOL)sourceIsMe {
    return [[quoteSource objectForKey:QISourceFacebookIDKey] isEqualToString:[[[QICoreDataManager sharedDataManger] loggedInUser] fbID]];
}

- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
    if (request == taggedFQLQuery) {
        [[UIApplication sharedApplication] popNetworkActivity];
        taggedFQLQuery = nil;
    }
    if (request == profilePhotosFQLQuery) {
        [[UIApplication sharedApplication] popNetworkActivity];
        profilePhotosFQLQuery = nil;
    }
    
    [self stopLoading];
    [self.view addSubview:noDataImage];
}

- (void)request:(FBRequest *)request didLoad:(id)result {
    if (request == profilePhotosFQLQuery) {
        profilePhotos = [result retain];
        [[UIApplication sharedApplication] popNetworkActivity];
        profilePhotosFQLQuery = nil;
    }
    if (request == taggedFQLQuery) {
        taggedPhotos = [result retain];
        [[UIApplication sharedApplication] popNetworkActivity];
        taggedFQLQuery = nil;
    }
    
    if (!!taggedPhotos && (![self sourceIsMe] || !!profilePhotos)) {
        NSMutableArray *noDuplicates = [NSMutableArray array];
        [noDuplicates addObjectsFromArray:profilePhotos];
        for (NSDictionary *taggedPhoto in taggedPhotos) {
            BOOL exists = NO;
            for (NSDictionary *profilePhoto in profilePhotos) {
                if ([[profilePhoto objectForKey:@"pid"] isEqualToString:[taggedPhoto objectForKey:@"pid"]]) {
                    exists = YES;
                }
            }
            if (!exists) {
                [noDuplicates addObject:taggedPhoto];
            }
        }
        images = [noDuplicates retain];
        [self reloadThumbs];
        
        [self stopLoading];
        if (![images count]) {
            [self.view addSubview:noDataImage];
        } else {
            [noDataImage removeFromSuperview];
        }
    }
}

- (void)fetchProfilePhotos {
    if (profilePhotosFQLQuery) {
        [profilePhotosFQLQuery.connection cancel];
        [[UIApplication sharedApplication] popNetworkActivity];
    }
    NSString *fqlQuery = [NSString stringWithFormat:@"select pid, src_big, src_small from photo where aid in (select aid from album where owner=%@ and type='profile') order by created desc", [quoteSource objectForKey:QISourceFacebookIDKey]];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:fqlQuery, @"query", nil];
    profilePhotosFQLQuery = [[[QIFacebookConnect sharedFacebookConnect] facebook] requestWithMethodName:@"fql.query" andParams:params andHttpMethod:@"GET" andDelegate:self];
    [[UIApplication sharedApplication] pushNetworkActivity];
}

- (void)fetchTaggedFacebookPhotos {    
    if (taggedFQLQuery) {
        [taggedFQLQuery.connection cancel];
        [[UIApplication sharedApplication] popNetworkActivity];
    }
    NSString *fqlQuery = [NSString stringWithFormat:@"select pid, src_big, src_small from photo where pid in (select pid from photo where aid in (select aid from album where owner=%@)) and pid in (select pid from photo where pid in (select pid from photo_tag where subject=%@))", [[[QICoreDataManager sharedDataManger] loggedInUser] fbID], [quoteSource objectForKey:QISourceFacebookIDKey]];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:fqlQuery, @"query", nil];
    taggedFQLQuery = [[[QIFacebookConnect sharedFacebookConnect] facebook] requestWithMethodName:@"fql.query" andParams:params andHttpMethod:@"GET" andDelegate:self];
    [[UIApplication sharedApplication] pushNetworkActivity];
}

- (void)setQuoteSource:(NSDictionary *)quoteSourceIn {
    if (quoteSourceIn != quoteSource) {
        [quoteSource release];
        quoteSource = [quoteSourceIn retain];
        
        // Reset images array.
        [images release];
        images = nil;        
        [self reloadThumbs];
        [profilePhotos release];
        [taggedPhotos release];
        taggedPhotos = nil;
        profilePhotos = nil;
        
        // Searching for tagged photos of Pages fails way too often.
        // Facebook's API is flakey.
        [self startLoading];
        if (![[quoteSourceIn objectForKey:QISourceEntityTypeKey] isEqualToString:QISourceEntityTypePage]) {
            [self fetchTaggedFacebookPhotos];
        }
        if ([self sourceIsMe]) {
            [self fetchProfilePhotos];
        }
        if ([[quoteSourceIn objectForKey:QISourceEntityTypeKey] isEqualToString:QISourceEntityTypePage]) {
            [self stopLoading];
            [self.view addSubview:noDataImage];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // The thumbs view controller sets the scrollview as the main view. We need
    // to set the background color of the view to the book image. It appears that
    // using a static conainer view in which the scrollview is contained, yields
    // better scrolling performance.
    CGRect frame = self.view.frame;
    frame.size.height -= 115; // Account for tab bar and nav bar.
    UIView *containerView = [[UIView alloc] initWithFrame:frame];
    UIView *scrollView = self.view;
    scrollView.frame = frame;
    scrollView.backgroundColor = [UIColor clearColor];
    self.view = containerView;
    [containerView addSubview:scrollView];
    [containerView release];
    
    loadingImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 143, 80)];
    loadingImageView.animationImages = [NSArray arrayWithObjects:    
                                        [UIImage imageNamed:@"fb1"],
                                        [UIImage imageNamed:@"fb2"],
                                        [UIImage imageNamed:@"fb3"],
                                        [UIImage imageNamed:@"fb4"], nil];
    loadingImageView.animationDuration = 1.0f;
    loadingImageView.animationRepeatCount = 0;
    loadingImageView.center = self.view.center;
    
    noDataImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"oh_no"]];
    CGPoint center = self.view.center;
    noDataImage.center = center;
    
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
    NSDictionary *imageUrls = [images objectAtIndex:index];
    NSString *url = [imageUrls objectForKey:@"src_small"];
    [thumbView setImageWithURL:[NSURL URLWithString:url] placeholderImage:[UIImage imageNamed:@"img_placeholder"]];
}

- (void)dealloc {
    [loadingImageView release];
    [profilePhotos release];
    [taggedPhotos release];
    if (taggedFQLQuery) {
        [taggedFQLQuery.connection cancel];
        [[UIApplication sharedApplication] popNetworkActivity];
    }
    if (profilePhotosFQLQuery) {
        [profilePhotosFQLQuery.connection cancel];
        [[UIApplication sharedApplication] popNetworkActivity];
    }
    [images release];
    [super dealloc];
}

@end
