//
//  QIMainViewController.m
//  QuoteIt
//
//  Created by Stephen Poletto on 12/29/11.
//  Copyright (c) 2011 QuoteIt. All rights reserved.
//

#import "QIMainViewController.h"
#import "QIShareQuote.h"
#import "QIUtilities.h"
#import "QITopQuotes.h"
#import "QIMyQuotes.h"

#define kQITopQuotesIndex 0
#define kQILogQuoteIndex 1
#define kQIMyQuotesIndex 2

@interface QIMainViewController ()
- (NSArray *)tabBarControllerContent;
- (void)addCenterButtonImage:(UIImage *)image;
@end

@implementation QIMainViewController
@synthesize overlayType;

static QIMainViewController *currentMainViewController;

+ (QIMainViewController *)mainViewController {
    return currentMainViewController;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        currentMainViewController = self;
    }
    return self;
}

- (void)showBrowseOverlayView {
    [self hideOverlayView:NO]; // Ensure other overlay view not showing.
    overlayView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ol_Browse"]];
    [self.view addSubview:overlayView];
    self.overlayType = QIMainViewOverlayTypeBrowse;
}

- (void)showShareOverlayView {
    [self hideOverlayView:NO]; // Ensure other overlay view not showing.
    overlayView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ol_ShareQuote"]];
    [self.view addSubview:overlayView];
    self.overlayType = QIMainViewOverlayTypeShare;
}

- (void)showIntroOverlayView {
    [self hideOverlayView:NO]; // Ensure other overlay view not showing.
    overlayView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ol_BrowseShare"]];
    [self.view addSubview:overlayView];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:QIHasSeenGenericIntroOverlay];
    self.overlayType = QIMainViewOverlayTypeBrowseShare;
}

- (void)hideOverlayView:(BOOL)animated {
    if (!animated) {
        [overlayView removeFromSuperview];
        [overlayView release];
        overlayView = nil;
        self.overlayType = QIMainViewOverlayTypeNone;
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            overlayView.alpha = 0.0;  
        } completion:^(BOOL completed) {
            [overlayView removeFromSuperview];
            [overlayView release];
            overlayView = nil;
            self.overlayType = QIMainViewOverlayTypeNone;
        }];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:QIHasSeenGenericIntroOverlay]) {
        [self showIntroOverlayView];
    } else if (![[NSUserDefaults standardUserDefaults] boolForKey:QIHasTappedShareQuote]) {
        [self showShareOverlayView];
    } else if (![[NSUserDefaults standardUserDefaults] boolForKey:QIHasBrowsedQuotes]) {
        [self showBrowseOverlayView];
    }
}

- (void)viewDidLoad {
    customTabBar = [[CustomTabBar alloc] initWithItemCount:[[self tabBarControllerContent] count] itemSize:CGSizeMake(self.view.frame.size.width/[self tabBarControllerContent].count, 50) tag:0 delegate:self];
    
    // Place the tab bar at the bottom of our view
    customTabBar.frame = CGRectMake(0, self.view.frame.size.height-50, self.view.frame.size.width, 50);
    [self.view addSubview:customTabBar];
    [self addCenterButtonImage:[QIUtilities centerTabBarImage]];
    [self selectTopQuotesController];
}

- (UIImage *)selectedItemBackgroundImage {
    return nil;
}

- (UIImage *)tabBarArrowImage {
    return nil;
}

- (UIImage *)selectedItemImage {
    return nil;
}

- (UIImage *)backgroundImage {
    return [QIUtilities tabBarImage];
}

- (UIImage *)glowImage {
    return nil;
}

- (UIImage *)imageForButtonAtIndex:(NSUInteger)itemIndex {
    UIImage *image = nil;
    switch (itemIndex) {
        case kQITopQuotesIndex:
            image = [QIUtilities topQuotesImage];
            break;
        case kQILogQuoteIndex:
            image = [QIUtilities logQuoteImage];
            break;
        case kQIMyQuotesIndex:
            image = [QIUtilities myQuotesImage];
            break;
        default:
            break;
    }
    return image;
}

- (UIImage *)imageFor:(CustomTabBar *)tabBar atIndex:(NSUInteger)itemIndex {
    return [self imageForButtonAtIndex:itemIndex];
}

- (UIImage *)selectedImageForButtonAtIndex:(NSUInteger)itemIndex {
    UIImage *image = nil;
    switch (itemIndex) {
        case kQITopQuotesIndex:
            image = [QIUtilities topQuotesSelectedImage];
            break;
        case kQILogQuoteIndex:
            image = [QIUtilities logQuoteSelectedImage];
            break;
        case kQIMyQuotesIndex:
            image = [QIUtilities myQuotesSelectedImage];
            break;
        default:
            break;
    }
    return image;
}

- (void)presentViewControllerForItemAtIndex:(NSUInteger)itemIndex {
    // Remove the current view controller's view
    [selectedViewController viewWillDisappear:NO];
    [selectedViewController.view removeFromSuperview];
    [selectedViewController viewDidDisappear:NO];
    
    // Get the right view controller
    UINavigationController *viewController = [[self tabBarControllerContent] objectAtIndex:itemIndex];
    
    // Set the view controller's frame to account for the tab bar
    viewController.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height-50);
    
    if (selectedViewController == viewController) {
        // Pop back to the first screen if we've tapped the tab bar
        // item representing the currently shown view controller.
        [selectedViewController popToRootViewControllerAnimated:NO];
    }
    selectedViewController = viewController;
    
    // Add the new view controller's view
    [viewController viewWillAppear:NO];
    [self.view insertSubview:viewController.view belowSubview:customTabBar];
    [viewController viewDidAppear:NO];
    
    if (selectedButton) {
        UIImage *unselectedImage = [self imageForButtonAtIndex:[[customTabBar buttons] indexOfObject:selectedButton]];
        [selectedButton setImage:unselectedImage forState:UIControlStateNormal];
        [selectedButton setImage:unselectedImage forState:UIControlStateHighlighted];
        [selectedButton setImage:unselectedImage forState:UIControlStateSelected];
    }
    
    UIImage *selectedImage = [self selectedImageForButtonAtIndex:itemIndex];
    selectedButton = [[customTabBar buttons] objectAtIndex:itemIndex];
    [selectedButton setImage:selectedImage forState:UIControlStateNormal];
    [selectedButton setImage:selectedImage forState:UIControlStateHighlighted];
    [selectedButton setImage:selectedImage forState:UIControlStateSelected];
}

- (void)touchDownAtItemAtIndex:(NSUInteger)itemIndex {
    if ((itemIndex == kQILogQuoteIndex && self.overlayType == QIMainViewOverlayTypeBrowse) || (itemIndex != kQILogQuoteIndex && [self overlayShowing])) {
        return; // Prevent action.
    }
    
    if (itemIndex == kQILogQuoteIndex) {
        [self hideOverlayView:YES];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:QIHasTappedShareQuote];
        
        // Logging a quote takes over the screen.
        QIShareQuote *shareQuote = [[[QIShareQuote alloc] init] autorelease];
        UINavigationController *shareQuoteNavigation = [[[UINavigationController alloc] initWithRootViewController:shareQuote] autorelease];
        shareQuoteNavigation.navigationBar.clipsToBounds = YES;
        [QIUtilities setBackgroundImage:[QIUtilities navigationBarImage] forNavigationController:shareQuoteNavigation];
        [self presentModalViewController:shareQuoteNavigation animated:YES];
    } else {
        [self presentViewControllerForItemAtIndex:itemIndex];
    }
}

- (BOOL)overlayShowing {
    return self.overlayType != QIMainViewOverlayTypeNone;
}

- (void)selectLogQuoteController {
    if (self.overlayType == QIMainViewOverlayTypeBrowse) {
        return; // Prevent action.
    }
    [customTabBar selectItemAtIndex:kQILogQuoteIndex];
    [self touchDownAtItemAtIndex:kQILogQuoteIndex];
}

- (void)selectTopQuotesController {
    if ([self overlayShowing]) {
        return; // Prevent action.
    }
    [customTabBar selectItemAtIndex:kQITopQuotesIndex];
    [self touchDownAtItemAtIndex:kQITopQuotesIndex];
}

- (void)selectMyQuotesController {
    if ([self overlayShowing]) {
        return; // Prevent action.
    }
    [customTabBar selectItemAtIndex:kQIMyQuotesIndex];
    [self touchDownAtItemAtIndex:kQIMyQuotesIndex];
}

- (QIMyQuotes *)myQuotesController {
    return [[[[self tabBarControllerContent] objectAtIndex:kQIMyQuotesIndex] viewControllers] firstObject];
}

- (NSArray *)tabBarControllerContent {
    if (!tabBarControllerContent) {
        QITopQuotes *topQuotes = [[[QITopQuotes alloc] init] autorelease];
        UINavigationController *topQuotesNavigation = [[[UINavigationController alloc] initWithRootViewController:topQuotes] autorelease];
        topQuotesNavigation.navigationBar.clipsToBounds = YES;
        [QIUtilities setBackgroundImage:[QIUtilities navigationBarImage] forNavigationController:topQuotesNavigation];
        
        QIShareQuote *shareQuote = [[[QIShareQuote alloc] init] autorelease];
        UINavigationController *shareQuoteNavigation = [[[UINavigationController alloc] initWithRootViewController:shareQuote] autorelease];
        shareQuoteNavigation.navigationBar.clipsToBounds = YES;
        [QIUtilities setBackgroundImage:[QIUtilities navigationBarImage] forNavigationController:shareQuoteNavigation];
        
        QIMyQuotes *myQuotes = [[[QIMyQuotes alloc] init] autorelease];
        UINavigationController *myQuotesNavigation = [[[UINavigationController alloc] initWithRootViewController:myQuotes] autorelease];
        myQuotesNavigation.navigationBar.clipsToBounds = YES;
        [QIUtilities setBackgroundImage:[QIUtilities navigationBarImage] forNavigationController:myQuotesNavigation];
        
        NSArray *controllers = [[NSArray alloc] initWithObjects:topQuotesNavigation, shareQuoteNavigation, myQuotesNavigation, nil];
        tabBarControllerContent = controllers;
    }
    return tabBarControllerContent;
}

- (void)addCenterButtonImage:(UIImage *)image {
    CGPoint center = customTabBar.center;
    center.y = center.y - 25.0 - image.size.height/2;
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.center = center;
    [self.view addSubview:imageView];
    [imageView release];
}

- (void)dealloc {
    currentMainViewController = nil;
    [overlayView release];
    [super dealloc];
}

@end
