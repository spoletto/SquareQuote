//
//  QIMainViewController.h
//  QuoteIt
//
//  Created by Stephen Poletto on 12/29/11.
//  Copyright (c) 2011 QuoteIt. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CustomTabBar.h"

@class QIMyQuotes;

typedef enum {
    QIMainViewOverlayTypeNone,
    QIMainViewOverlayTypeBrowse,
    QIMainViewOverlayTypeShare,
    QIMainViewOverlayTypeBrowseShare,
} QIMainViewOverlayType;

@interface QIMainViewController : UIViewController <CustomTabBarDelegate> {
    UINavigationController *selectedViewController;
    CustomTabBar *customTabBar;
    NSArray *tabBarControllerContent;
    UIButton *selectedButton;
    
    UIImageView *overlayView;
}

@property (nonatomic) QIMainViewOverlayType overlayType;

// Since we're using the custom tab bar, we need to be able to reference the top-level
// view controller for things like presenting modal controllers.
+ (QIMainViewController *)mainViewController;

- (void)selectLogQuoteController;
- (void)selectTopQuotesController;
- (void)selectMyQuotesController;

- (BOOL)overlayShowing;
- (void)hideOverlayView:(BOOL)animated;
- (void)showIntroOverlayView;
- (void)showShareOverlayView;
- (void)showBrowseOverlayView;

- (QIMyQuotes *)myQuotesController;

@end
