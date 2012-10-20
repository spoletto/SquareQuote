//
//  QIUtilities.h
//  QuoteIt
//
//  Created by Stephen Poletto on 12/29/11.
//  Copyright (c) 2011 QuoteIt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>

#define UIColorFromRGB(rgbValue) [UIColor \
    colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
    green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
    blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define QIRenderNavigationBarTitle() \
    CGRect frame = CGRectMake(0, 0, 180, 44); \
    UILabel *label = [[UILabel alloc] initWithFrame:frame]; \
    label.backgroundColor = [UIColor clearColor]; \
    label.font = [QIUtilities titleBarFont]; \
    label.shadowColor = [UIColor whiteColor]; \
    label.textAlignment = UITextAlignmentCenter; \
    label.textColor = [QIUtilities titleBarTitleColor]; \
    self.navigationItem.titleView = label; \
    label.text = self.title; \
    [label release];

extern NSString * const QIBaseURL;
extern NSString * const QIDatabaseName;
extern NSString * const QIFacebookAppID;
extern NSString * const QITestFlightTeamToken;
extern NSString * const QIParseApplicationID;
extern NSString * const QIParseClientKey;

extern NSString * const QIHasSwipedThroughQuoteBrowser;
extern NSString * const QIHasTappedShareQuote;
extern NSString * const QIHasSharedQuote;
extern NSString * const QIHasMadeTextChanges;
extern NSString * const QIHasSeenPhotoSelectorOptions;
extern NSString * const QIHasSeenGenericIntroOverlay;
extern NSString * const QIHasBrowsedQuotes;
extern NSString * const QIHasCustomizedQuoteBackground;

@class QIUser;

@interface QIUtilities : NSObject

+ (UIImage *)tableViewPlaceholderImage;
+ (UIImage *)topQuotesImage;
+ (UIImage *)myQuotesImage;
+ (UIImage *)topQuotesSelectedImage;
+ (UIImage *)myQuotesSelectedImage;
+ (UIImage *)logQuoteImage;
+ (UIImage *)logQuoteSelectedImage;
+ (UIImage *)centerTabBarImage;
+ (UIImage *)tabBarImage;
+ (UIImage *)navigationBarImage;
+ (UIImage *)checkmarkImage;
+ (UIImage *)bookImage;
+ (UIImage *)userPlaceholderImage;
+ (UIImage *)sourceSelectionInstructionsImage;
+ (UIImage *)nextButtonEnabledImage;
+ (UIImage *)nextButtonDisabledImage;
+ (UIImage *)cancelButtonImage;
+ (UIImage *)backButtonImage;
+ (UIImage *)backButtonPressed;
+ (UIImage *)cancelButtonPressed;
+ (UIColor *)titleBarTitleColor;
+ (UIFont *)titleBarFont;
+ (UIImage *)dividerImage;
+ (UIColor *)avatarBorderColor;
+ (UIColor *)buttonTitleColor;
+ (UIColor *)buttonTitleDropShadowColor;
+ (UIFont *)buttonTitleFont;
+ (UIFont *)submitterLabelFont;
+ (UIColor *)formFieldColor;
+ (UIFont *)formFieldFont;
+ (UIFont *)navButtonTitleFont;
+ (UIImage *)settingsButtonPressed;
+ (UIImage *)settingsButtonImage;
+ (UIColor *)brickSourceLabelColor;
+ (UIColor *)brickInfoLabelColor;
+ (UIColor *)myQuotesSourceLabelColor;
+ (UIColor *)myQuotesViewsLabelColor;
+ (UIImage *)fontEditorNavBarImage;
+ (UIColor *)textEditorLabelColor;
+ (UIColor *)textEditorFontSelectorBackgroundColor;
+ (UIColor *)textEditorHeaderLabelColor;

+ (void)setBackgroundImage:(UIImage *)backgroundImage forNavigationController:(UINavigationController *)navigationController;
+ (void)navigationControllerPopViewControllerWithPageCurlTransition:(UINavigationController *)navigationController;
+ (void)navigationController:(UINavigationController *)navigationController animteWithPageCurlToViewController:(UIViewController *)viewController;
+ (void)cacheImageAtURL:(NSURL *)url;

@end

typedef void(^QIErrorHandlerCompletionBlock)(void);

@interface QIErrorHandler : NSObject <UIAlertViewDelegate, MFMailComposeViewControllerDelegate> {
    QIErrorHandlerCompletionBlock completionHandler;
    NSError *mostRecentError;
}

+ (QIErrorHandler *)sharedErrorHandler;
- (void)presentAlertViewWithTitle:(NSString *)title message:(NSString *)message completionHandler:(QIErrorHandlerCompletionBlock)block;
- (void)presentFailureViewWithTitle:(NSString *)title error:(NSError *)error completionHandler:(QIErrorHandlerCompletionBlock)block;

@end

// Utility category methods.
@interface NSArray(QIArrayAdditions)
- (NSArray *)arrayByReversingArray;
- (id)onlyObject;
- (id)firstObject;
@end

@interface UIBarButtonItem(QIBarButtonItemAdditions)
+ (UIBarButtonItem*)barItemWithImage:(UIImage *)image highlightedImage:(UIImage *)highlightedImage title:(NSString *)title target:(id)target action:(SEL)action;
+ (UIBarButtonItem*)barItemWithImage:(UIImage *)image highlightedImage:(UIImage *)highlightedImage title:(NSString *)title target:(id)target action:(SEL)action shiftedDownByHeight:(CGFloat)heightShift;
@end

@interface UIImage(QIImageAdditions)
+ (UIImage *)scale:(UIImage *)image toSize:(CGSize)size;
+ (UIImage *)scale:(UIImage *)image toFillSize:(CGSize)targetSize;
@end

extern NSString *QIPrettyFontNameFromFont(UIFont *font);
extern NSString *QIFullNameForUser(QIUser *user);
extern NSString *QIFullNameForUserDictionary(NSDictionary *user);
extern NSString *QIURLForQuote(NSDictionary *quote);
extern NSString *QISourceNameForQuote(NSDictionary *quote);
extern void QIConfigureImageWell(UIImageView *sourcePhoto);
