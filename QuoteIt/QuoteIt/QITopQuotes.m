//
//  QITopQuotes.m
//  QuoteIt
//
//  Created by Stephen Poletto on 12/29/11.
//  Copyright (c) 2011 QuoteIt. All rights reserved.
//

#import "UIImageView+AFNetworking.h"
#import "QIMainViewController.h"
#import "QIBucketPhotosCache.h"
#import "QIQuoteViewer.h"
#import "QIUtilities.h"
#import "QITopQuotes.h"
#import "QIAFClient.h"

@interface QIBucketButton : UIButton
@property (nonatomic, copy) NSString *bucketName;
@end

@implementation QIBucketButton
@synthesize bucketName;
@end

@interface QITopQuotes()
- (void)drawBuckets;
@end

@implementation QITopQuotes
@synthesize bucketsScrollView;
@synthesize backgroundImage;
@synthesize navBarShadow;

- (void)requestBucketPhotos {
    [buckets release];
    buckets = [[[QIBucketPhotosCache sharedBucketPhotosCache] cachedBucketPhotos] retain];
    if (!buckets) {
        [[QIAFClient sharedClient] getPath:@"/api/list-buckets" parameters:nil success:^(AFHTTPRequestOperation *operation, id jsonObject) {
            if ([[jsonObject objectForKey:@"status"] isEqualToString:@"ok"]) {
                buckets = [[jsonObject objectForKey:@"buckets"] retain];
                [self drawBuckets];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (![error code] == NSURLErrorNotConnectedToInternet) {
                TFLog(@"Failed to Fetch Buckets: %@", error);
            }
        }];
    }
    [self drawBuckets];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Browse Quotes";
        
        [[QIMainViewController mainViewController] addObserver:self forKeyPath:@"overlayType" options:NSKeyValueObservingOptionNew context:NULL];
        if ([QIMainViewController mainViewController].overlayType == QIMainViewOverlayTypeShare) {
            self.bucketsScrollView.userInteractionEnabled = NO;
        } else {
            self.bucketsScrollView.userInteractionEnabled = YES;
        }
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == [QIMainViewController mainViewController] && keyPath == @"overlayType") {
        if ([QIMainViewController mainViewController].overlayType == QIMainViewOverlayTypeShare) {
            self.bucketsScrollView.userInteractionEnabled = NO;
        } else {
            self.bucketsScrollView.userInteractionEnabled = YES;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self requestBucketPhotos];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:QIHasTappedShareQuote] && ![[QIMainViewController mainViewController] overlayShowing]) {
        [[QIMainViewController mainViewController] showShareOverlayView];
    }
}

- (void)revealQuoteViewer:(QIBucketButton *)sender {
    if ([[QIMainViewController mainViewController] overlayShowing]) {
        return; // Don't reveal quotes until the user has scrolled.
    }
    QIQuoteViewer *quoteViewer = [[[QIQuoteViewer alloc] initWithKeyword:[sender bucketName]] autorelease];
    [self.navigationController pushViewController:quoteViewer animated:NO];
}

#define kBucketImageHeight 51
#define kBucketImageWidth 241
- (void)drawBuckets {
    for (UIView *subview in [bucketsScrollView subviews]) {
        [subview removeFromSuperview];
    }
    
    for (NSInteger i = 0; i < [buckets count]; i++) {
        NSDictionary *bucket = [buckets objectAtIndex:i];
        NSString *bucketURL = [bucket objectForKey:@"image-iOS"];
        if ([[UIScreen mainScreen] scale] == 2.0f) {
            bucketURL = [bucket objectForKey:@"image-iOS-2x"];
        }
        NSURL *imgURL = [NSURL URLWithString:bucketURL relativeToURL:[[QIAFClient sharedClient] baseURL]];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:imgURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
        [request setHTTPShouldHandleCookies:NO];
        [request setHTTPShouldUsePipelining:YES];
        
        QIBucketButton *bucketButton = [QIBucketButton buttonWithType:UIButtonTypeCustom];
        bucketButton.bucketName = [bucket objectForKey:@"name"];
        bucketButton.frame = CGRectMake(35.0, 10.0 + (30.0 * i) + (kBucketImageHeight * i), kBucketImageWidth, kBucketImageHeight);
        [bucketsScrollView addSubview:bucketButton];
        
        [[bucketButton imageView] setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            [bucketButton setImage:image forState:UIControlStateNormal];
            [bucketButton addTarget:self action:@selector(revealQuoteViewer:) forControlEvents:UIControlEventTouchUpInside];
        } failure:nil];
        
        UIImage *dividerImage = [QIUtilities dividerImage];
        UIImageView *divider = [[UIImageView alloc] initWithImage:dividerImage];
        divider.frame = CGRectMake(0.0, 0.0, dividerImage.size.width, dividerImage.size.height);
        divider.center = CGPointMake(self.view.center.x, 10 + (30.0 * i) + (kBucketImageHeight * (i + 1)) + 15.0);
        [bucketsScrollView addSubview:divider];
        [divider release];
    }
    bucketsScrollView.contentSize = CGSizeMake(320.0, 20.0 + (30.0 + kBucketImageHeight) * [buckets count]);
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [[QIMainViewController mainViewController] hideOverlayView:YES];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:QIHasBrowsedQuotes];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    QIRenderNavigationBarTitle();
    
    [navBarShadow setImage:[UIImage imageNamed:@"top_bar_shadow"]];
    [backgroundImage setImage:[QIUtilities bookImage]];
    [self drawBuckets];
}

- (void)dealloc {
    [[QIMainViewController mainViewController] removeObserver:self forKeyPath:@"overlayType"];
    [bucketsScrollView release];
    [backgroundImage release];
    [navBarShadow release];
    [super dealloc];
}

- (void)viewDidUnload {
    [self setBucketsScrollView:nil];
    [self setBackgroundImage:nil];
    [self setNavBarShadow:nil];
    [super viewDidUnload];
}

@end
