//
//  QITemplatePhotos.m
//  QuoteIt
//
//  Created by Stephen Poletto on 2/19/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

#import "KTThumbView+SDWebImage.h"
#import "QITemplatePhotosCache.h"
#import "QITemplatePhotos.h"
#import "QIUtilities.h"
#import "QIAFClient.h"

@implementation QITemplatePhotos
@synthesize delegate;

- (void)requestTemplatePhotos {
    [images release];
    images = [[[QITemplatePhotosCache sharedTemplatePhotosCache] cachedTemplatePhotos] retain];
    if (!images) {
        [[QIAFClient sharedClient] getPath:@"/api/image-templates" parameters:nil success:^(AFHTTPRequestOperation *operation, id jsonObject) {
            if ([[jsonObject objectForKey:@"status"] isEqualToString:@"ok"]) {
                images = [[jsonObject objectForKey:@"results"] retain];
                [self reloadThumbs];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (![error code] == NSURLErrorNotConnectedToInternet) {
                TFLog(@"Failed to Fetch Template Images: %@", error);
            }
        }];
    }
    [self reloadThumbs];
}

- (id)init {
    self = [super init];
    if (self) {
        [self requestTemplatePhotos];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self requestTemplatePhotos];
    }
    return self;
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

@end
