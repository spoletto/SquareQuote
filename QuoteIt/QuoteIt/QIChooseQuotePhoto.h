//
//  QIChooseQuotePhoto.h
//  QuoteIt
//
//  Created by Stephen Poletto on 2/1/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

#import "CustomTabBar.h"

@protocol QIChoosePhotoDelegate;

@interface QIChooseQuotePhoto : UIViewController <CustomTabBarDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    UIViewController *selectedViewController;
    CustomTabBar *customTabBar;
    NSArray *tabBarControllerContent;
    UIButton *selectedButton;
    
    UIImageView *overlayView;
}

@property (retain, nonatomic) NSDictionary *quoteSource;
@property (retain, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (assign, nonatomic) id <QIChoosePhotoDelegate> delegate;

@end

@protocol QIChoosePhotoDelegate <NSObject>
@optional
- (void)userDidSelectPhotoURL:(NSString *)photoURL;
- (void)userDidSelectPhotoImage:(UIImage *)image;
@end
