//
//  QIUtilities.m
//  QuoteIt
//
//  Created by Stephen Poletto on 12/29/11.
//  Copyright (c) 2011 QuoteIt. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#import "UIImageView+AFNetworking.h"
#import "SDImageCache.h"
#import "QIUtilities.h"
#import "QIUser.h"

#define kQICustomNavigationControllerImageTag 143

NSString * const QIBaseURL = @"https://squarequote.it/";
NSString * const QIDatabaseName = @"SquareQuote.sqlite";
NSString * const QIFacebookAppID = @"172464429503969";

#error Define your own TestFlight and Parse tokens before running the app.
NSString * const QITestFlightTeamToken = @"YOUR_TEST_FLIGHT_TEAM_TOKEN";
NSString * const QIParseApplicationID = @"YOUR_PARSE_APP_ID";
NSString * const QIParseClientKey = @"YOUR_PARSE_CLIENT_KEY";

NSString * const QIHasSwipedThroughQuoteBrowser = @"QIHasSwipedThroughQuoteBrowser";
NSString * const QIHasTappedShareQuote = @"QIHasTappedShareQuote";
NSString * const QIHasSharedQuote = @"QIHasSharedQuote";
NSString * const QIHasMadeTextChanges = @"QIHasMadeTextChanges";
NSString * const QIHasSeenPhotoSelectorOptions = @"QIHasSeenPhotoSelectorOptions";
NSString * const QIHasSeenGenericIntroOverlay = @"QIHasSeenGenericIntroOverlay";
NSString * const QIHasBrowsedQuotes = @"QIHasBrowsedQuotes";
NSString * const QIHasCustomizedQuoteBackground = @"QIHasCustomizedQuoteBackground";

@implementation QIUtilities

+ (UIImage *)topQuotesImage {
    return [UIImage imageNamed:@"Browse_static"];
}
+ (UIImage *)myQuotesImage {
    return [UIImage imageNamed:@"MyQuotes_guy_static"];
}
+ (UIImage *)topQuotesSelectedImage {
    return [UIImage imageNamed:@"Browse_active"];
}
+ (UIImage *)myQuotesSelectedImage {
    return [UIImage imageNamed:@"MyQuotes_guy_active"];
}
+ (UIImage *)logQuoteImage {
    return [UIImage imageNamed:@"ShareQuote_static"];
}
+ (UIImage *)logQuoteSelectedImage {
    return [UIImage imageNamed:@"ShareQuote_static"];    
}
+ (UIImage *)centerTabBarImage {
    return [UIImage imageNamed:@"Tab"];
}
+ (UIImage *)tabBarImage {
    return [UIImage imageNamed: @"Tab_bar"];
}
+ (UIImage *)navigationBarImage {
    return [UIImage imageNamed: @"Topbar"];
}
+ (UIImage *)fontEditorNavBarImage {
    return [UIImage imageNamed: @"sheet_header"];
}
+ (UIImage *)checkmarkImage {
    return [UIImage imageNamed:@"37x-Checkmark"];
}
+ (UIImage *)bookImage {
    return [UIImage imageNamed:@"Background"];
}
+ (UIImage *)userPlaceholderImage {
    return [UIImage imageNamed:@"Source_Placeholder.png"];
}
+ (UIImage *)tableViewPlaceholderImage {
    return [UIImage imageNamed:@"source_table_view.png"];
}
+ (UIImage *)sourceSelectionInstructionsImage {
    return [UIImage imageNamed:@"tutorial_bubble"];
}
+ (UIImage *)nextButtonEnabledImage {
    return [UIImage imageNamed:@"enabled"];
}
+ (UIImage *)nextButtonDisabledImage {
    return [UIImage imageNamed:@"disabled"];
}
+ (UIImage *)cancelButtonImage {
    return [UIImage imageNamed:@"btn_static"];
}
+ (UIImage *)settingsButtonImage {
    return [UIImage imageNamed:@"btn_settings_static"];
}
+ (UIImage *)cancelButtonPressed {
    return [UIImage imageNamed:@"btn_press"];
}
+ (UIImage *)backButtonImage {
    return [UIImage imageNamed:@"back_btn_static"];
}
+ (UIImage *)settingsButtonPressed {
    return [UIImage imageNamed:@"btn_settings_press"];
}
+ (UIImage *)dividerImage {
    return [UIImage imageNamed:@"Divider"];
}
+ (UIImage *)backButtonPressed {
    return [UIImage imageNamed:@"back_btn_press"];
}

static UIFont *titleBarFont;
+ (UIFont *)titleBarFont {
    if (!titleBarFont) {
        titleBarFont = [UIFont fontWithName:@"Georgia" size:19];
    }
    return titleBarFont;
}

static UIColor *titleBarTitleColor;
+ (UIColor *)titleBarTitleColor {
    if (!titleBarTitleColor) {
        titleBarTitleColor = [UIColorFromRGB(0x8d8b87) retain];
    }
    return titleBarTitleColor;
}

static UIColor *navButtonTitleColor;
+ (UIColor *)navButtonTitleColor {
    if (!navButtonTitleColor) {
        navButtonTitleColor = [UIColorFromRGB(0xb2aea6) retain];
    }
    return navButtonTitleColor;
}

static UIFont *navButtonTitleFont;
+ (UIFont *)navButtonTitleFont {
    if (!navButtonTitleFont) {
        navButtonTitleFont = [UIFont fontWithName:@"Georgia" size:12];
    }
    return navButtonTitleFont;
}

static UIFont *submitterFont;
+ (UIFont *)submitterLabelFont {
    if (!submitterFont) {
        submitterFont = [UIFont fontWithName:@"Georgia" size:13];
    }
    return submitterFont;
}

static UIColor *avatarBorderColor;
+ (UIColor *)avatarBorderColor {
    if (!avatarBorderColor) {
        avatarBorderColor = [UIColorFromRGB(0xb8b7b3) retain];
    }
    return avatarBorderColor;
}

static UIColor *brickInfoLabelColor;
+ (UIColor *)brickInfoLabelColor {
    if (!brickInfoLabelColor) {
        brickInfoLabelColor = [UIColorFromRGB(0x91826f) retain];
    }
    return brickInfoLabelColor;
}

static UIColor *brickSourceLabelColor;
+ (UIColor *)brickSourceLabelColor {
    if (!brickSourceLabelColor) {
        brickSourceLabelColor = [UIColorFromRGB(0xad9c86) retain];
    }
    return brickSourceLabelColor;
}

static UIColor *buttonTitleColor;
+ (UIColor *)buttonTitleColor {
    if (!buttonTitleColor) {
        buttonTitleColor = [UIColorFromRGB(0xFFFFFF) retain];
    }
    return buttonTitleColor;
}

static UIColor *formFieldColor;
+ (UIColor *)formFieldColor {
    if (!formFieldColor) {
        formFieldColor = [UIColorFromRGB(0x46484a) retain];
    }
    return formFieldColor;
}

static UIFont *formFieldFont;
+ (UIFont *)formFieldFont {
    if (!formFieldFont) {
        formFieldFont = [UIFont fontWithName:@"HelveticaNeue" size:16];
    }
    return formFieldFont;
}

static UIColor *buttonTitleDropShadowColor;
+ (UIColor *)buttonTitleDropShadowColor {
    if (!buttonTitleDropShadowColor) {
        buttonTitleDropShadowColor = [[UIColorFromRGB(0x2b8cc3) colorWithAlphaComponent:0.65] retain];
    }
    return buttonTitleDropShadowColor;
}

static UIColor *myQuotesSourceLabelColor;
+ (UIColor *)myQuotesSourceLabelColor {
    if (!myQuotesSourceLabelColor) {
        myQuotesSourceLabelColor = [UIColorFromRGB(0x5f5a50) retain];
    }
    return myQuotesSourceLabelColor;
}

static UIColor *myQuotesViewsLabelColor;
+ (UIColor *)myQuotesViewsLabelColor {
    if (!myQuotesViewsLabelColor) {
        myQuotesViewsLabelColor = [UIColorFromRGB(0xb0a796) retain];
    }
    return myQuotesViewsLabelColor;
}

static UIColor *textEditorLabelColor;
+ (UIColor *)textEditorLabelColor {
    if (!textEditorLabelColor) {
        textEditorLabelColor = [UIColorFromRGB(0x5f5a50) retain];
    }
    return textEditorLabelColor;
}

static UIColor *textEditorFontSelectorBackgroundColor;
+ (UIColor *)textEditorFontSelectorBackgroundColor {
    if (!textEditorFontSelectorBackgroundColor) {
        textEditorFontSelectorBackgroundColor = [UIColorFromRGB(0xf1efe6) retain];
    }
    return textEditorFontSelectorBackgroundColor;
}

static UIColor *textEditorHeaderLabelColor;
+ (UIColor *)textEditorHeaderLabelColor {
    if (!textEditorHeaderLabelColor) {
        textEditorHeaderLabelColor = [UIColorFromRGB(0x453f3b) retain];
    }
    return textEditorHeaderLabelColor;
}

static UIFont *buttonTitleFont;
+ (UIFont *)buttonTitleFont {
    if (!buttonTitleFont) {
        buttonTitleFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14];
    }
    return buttonTitleFont;
}

+ (void)setBackgroundImage:(UIImage *)backgroundImage forNavigationController:(UINavigationController *)navigationController {
    if ([navigationController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]) {
        [navigationController.navigationBar setBackgroundImage:backgroundImage forBarMetrics:UIBarMetricsDefault];
    }
}

+ (void)navigationControllerPopViewControllerWithPageCurlTransition:(UINavigationController *)navigationController {
    /*[UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:navigationController.view cache:NO];
    [UIView commitAnimations];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:0.25];
    [navigationController popViewControllerAnimated:NO];
    [UIView commitAnimations];*/
    [navigationController popViewControllerAnimated:NO];
}

+ (void)navigationController:(UINavigationController *)navigationController animteWithPageCurlToViewController:(UIViewController *)viewController {
    /*[UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:0.5];
    [navigationController pushViewController:viewController animated:NO];
    [UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:navigationController.view cache:NO];
    [UIView commitAnimations];*/
    [navigationController pushViewController:viewController animated:NO];
}

+ (void)cacheImageAtURL:(NSURL *)url {
    UIImage *cachedImage = [[SDImageCache sharedImageCache] imageFromKey:[url absoluteString]];
    if (!cachedImage) {
        // Force the image to be downloaded and cached.
        UIImageView *temporaryView = [[UIImageView alloc] init];
        [temporaryView setImageWithURL:url];
        [temporaryView release];
    }
}

@end

@implementation QIErrorHandler

+ (QIErrorHandler *)sharedErrorHandler {
    static QIErrorHandler *sharedErrorHandler = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        sharedErrorHandler = [[self alloc] init];
    });
    return sharedErrorHandler;
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    switch (result) {
		case MFMailComposeResultCancelled:
			break;
		case MFMailComposeResultFailed:
            [[[[UIAlertView alloc] initWithTitle:@"Email Failed" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
			break;
		case MFMailComposeResultSent:
			break;
        case MFMailComposeResultSaved:
            break;
		default:
			break;
	}
    [controller dismissModalViewControllerAnimated:YES];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
    
    if (completionHandler) {
        completionHandler();
        [completionHandler release];
        completionHandler = nil;
    }
}

- (void)emailErrorToSupport {
    MFMailComposeViewController *composer = [[MFMailComposeViewController alloc] init];
    composer.navigationBar.tag = 700;
    composer.mailComposeDelegate = self;
    
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString *model = [[UIDevice currentDevice] model];
    NSString *system = [NSString stringWithFormat:@"%@ %@", [[UIDevice currentDevice] systemName], [[UIDevice currentDevice] systemVersion]];
    
    NSString *messageBody = [NSString stringWithFormat:@"Hi SquareQuote,\n\nI encountered the following error while playing with version %@ of SqaureQuote. I'm running %@ - %@\n\n%@", appVersion, model, system, [mostRecentError description]];
    [composer setMessageBody:messageBody isHTML:NO];
    [composer setSubject:@"SquareQuote iOS Bug Report"];
    [composer setToRecipients:[NSArray arrayWithObject:@"support@squarequote.it"]];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    [[[[[UIApplication sharedApplication] delegate] window] rootViewController] presentModalViewController:composer animated:YES];
    [composer release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self emailErrorToSupport];
    } else if (completionHandler) {
        completionHandler();
        [completionHandler release];
        completionHandler = nil;
    }
    [mostRecentError release];
    mostRecentError = nil;
}

- (void)presentAlertViewWithTitle:(NSString *)title message:(NSString *)message completionHandler:(QIErrorHandlerCompletionBlock)block; {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
    [alert show];
    [alert release];
    completionHandler = [block copy];
}

- (void)presentFailureViewWithTitle:(NSString *)title error:(NSError *)error completionHandler:(QIErrorHandlerCompletionBlock)block {
    if ([error code] == NSURLErrorNotConnectedToInternet) {
        // Don't email the error to us.
        [self presentAlertViewWithTitle:title message:[error localizedDescription] completionHandler:block];
    } else {
        mostRecentError = [error retain];
        completionHandler = [block copy];
        NSString *message = [NSString stringWithFormat:@"Uh oh, something went wrong! Please email this error to support@squarequote.it."];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:@"Email Error", nil];
        [alert show];
        [alert release];
    }
}

- (void)dealloc {
    [completionHandler release];
    [mostRecentError release];
    [super dealloc];
}

@end

@implementation NSArray(QIArrayAdditions)
- (NSArray *)arrayByReversingArray {
    NSMutableArray *reversed = [NSMutableArray arrayWithCapacity:[self count]];
    for (id obj in [self reverseObjectEnumerator]) {
        [reversed addObject:obj];
    }
    return reversed;
}

- (id)onlyObject {
    id onlyObject = nil;
    if ([self count] == 1) {
        onlyObject = [self objectAtIndex:0];
    }
    return onlyObject;
}

- (id)firstObject {
    id firstObject = nil;
    if ([self count]) {
        firstObject = [self objectAtIndex:0];
    }
    return firstObject;
}
@end

@implementation UIBarButtonItem(QIBarButtonItemAdditions)
+ (UIBarButtonItem*)barItemWithImage:(UIImage *)image highlightedImage:(UIImage *)highlightedImage title:(NSString *)title target:(id)target action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[QIUtilities navButtonTitleColor] forState:UIControlStateNormal];
    [button titleLabel].font = [QIUtilities navButtonTitleFont];
    [button titleLabel].textAlignment = UITextAlignmentCenter;
    
    [button setBackgroundImage:[image stretchableImageWithLeftCapWidth:7.0 topCapHeight:0.0] forState:UIControlStateNormal];
    [button setBackgroundImage:[highlightedImage stretchableImageWithLeftCapWidth:7.0 topCapHeight:0.0] forState:UIControlStateHighlighted];
    button.frame = CGRectMake(2.0, 0.0, image.size.width, image.size.height);
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    
    UIView *containingView = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, image.size.width + 2.0, image.size.height)] autorelease];
    [containingView addSubview:button];
    
    return [[[UIBarButtonItem alloc] initWithCustomView:containingView] autorelease];
}

+ (UIBarButtonItem*)barItemWithImage:(UIImage *)image highlightedImage:(UIImage *)highlightedImage title:(NSString *)title target:(id)target action:(SEL)action shiftedDownByHeight:(CGFloat)heightShift {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[QIUtilities navButtonTitleColor] forState:UIControlStateNormal];
    [button titleLabel].font = [QIUtilities navButtonTitleFont];
    [button titleLabel].textAlignment = UITextAlignmentCenter;
    
    [button setBackgroundImage:[image stretchableImageWithLeftCapWidth:7.0 topCapHeight:0.0] forState:UIControlStateNormal];
    [button setBackgroundImage:[highlightedImage stretchableImageWithLeftCapWidth:7.0 topCapHeight:0.0] forState:UIControlStateHighlighted];
    button.frame = CGRectMake(2.0, heightShift, image.size.width, image.size.height);
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    
    UIView *containingView = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, image.size.width + 2.0, image.size.height + heightShift)] autorelease];
    [containingView addSubview:button];
    
    return [[[UIBarButtonItem alloc] initWithCustomView:containingView] autorelease];
}
@end

@implementation UIImage(QIImageAdditions)
+ (UIImage *)scale:(UIImage *)image toSize:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}
+ (UIImage *)scale:(UIImage *)sourceImage toFillSize:(CGSize)targetSize {
    if (CGSizeEqualToSize(sourceImage.size, targetSize)) {
        return sourceImage;
    }
    
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetSize.width;
    CGFloat scaledHeight = targetSize.height;
    CGPoint thumbnailPoint = CGPointMake(0.0, 0.0);
    
    if (!CGSizeEqualToSize(sourceImage.size, targetSize))  {
        CGFloat widthFactor = targetSize.width / sourceImage.size.width;
        CGFloat heightFactor = targetSize.height / sourceImage.size.height;
        
        if (widthFactor > heightFactor) {
            scaleFactor = widthFactor; // Scale to fit height.
        } else {
            scaleFactor = heightFactor; // Scale to fit width.
        }
        scaledWidth  = sourceImage.size.width * scaleFactor;
        scaledHeight = sourceImage.size.height * scaleFactor;
        
        // Center the image
        if (widthFactor > heightFactor) {
            thumbnailPoint.y = (targetSize.height - scaledHeight) * 0.5; 
        } else if (widthFactor < heightFactor) {
            thumbnailPoint.x = (targetSize.width - scaledWidth) * 0.5;
        }
    }       
    
    UIGraphicsBeginImageContext(targetSize); // This will crop.
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext(); 
    UIGraphicsEndImageContext();
    return newImage;
}
@end

// Hack the navigation bar to use a custom background image on iOS < 5.
@implementation UINavigationBar(UINavigationBarCategory)
- (void)drawRectHacked:(CGRect)rect {
    if (self.tag == 700) {
        [self drawRectHacked:rect]; // Awww yeah. Swizzle that shit.
        return;
    }
    UIImage *image = [QIUtilities navigationBarImage];
    CGRect imageRect = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    if (self.tag == 995) {
        image = [QIUtilities fontEditorNavBarImage];
        imageRect = CGRectMake(0, -9.0, self.frame.size.width, 53);
    }
    [image drawInRect:imageRect];
}

+ (void)load {
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(drawRect:)), class_getInstanceMethod(self, @selector(drawRectHacked:)));
}
@end

NSString *QIPrettyFontNameFromFont(UIFont *font) {
    if ([font.fontName isEqualToString:@"AmericanTypewriter"]) {
        return @"American \nTypewriter";
    }
    if ([font.fontName isEqualToString:@"HelveticaNeue-Bold"]) {
        return @"Helvetica \nNeue";
    }
    if ([font.fontName isEqualToString:@"ArialRoundedMTBold"]) {
        return @"Arial \nRounded";
    }
    if ([font.fontName isEqualToString:@"Baskerville-BoldItalic"]) {
        return @"Baskerville";
    }
    if ([font.fontName isEqualToString:@"BodoniSvtyTwoITCTT-Book"]) {
        return @"Bodoni Svty Two ITCTT";
    }
    if ([font.fontName isEqualToString:@"Chalkduster"]) {
        return @"Chalkduster";
    }
    if ([font.fontName isEqualToString:@"Cochin"]) {
        return @"Cochin";
    }
    if ([font.fontName isEqualToString:@"Futura-Medium"]) {
        return @"Futura";
    }
    if ([font.fontName isEqualToString:@"Futura-CondensedExtraBold"]) {
        return @"Futura Condensed";
    }
    if ([font.fontName isEqualToString:@"GeezaPro"]) {
        return @"Geeza Pro";
    }
    if ([font.fontName isEqualToString:@"Georgia"]) {
        return @"Georgia";
    }
    if ([font.fontName isEqualToString:@"Georgia-Italic"]) {
        return @"Georgia Italic";
    }
    if ([font.fontName isEqualToString:@"GillSans-Bold"]) {
        return @"Gill Sans";
    }
    if ([font.fontName isEqualToString:@"HoeflerText-Regular"]) {
        return @"Hoefler Text";
    }
    if ([font.fontName isEqualToString:@"Noteworthy-Bold"]) {
        return @"Noteworthy";
    }
    // Default fallback.
    return font.fontName;
}

NSString *QIFullNameForUser(QIUser *user) {
    return [NSString stringWithFormat:@"%@ %@", [user firstName], [user lastName]];
}

NSString *QIFullNameForUserDictionary(NSDictionary *user) {
    return [NSString stringWithFormat:@"%@ %@", [user valueForKey:@"firstName"], [user valueForKey:@"lastName"]];
}

NSString *QIURLForQuote(NSDictionary *quote) {
    NSString *endpoint = [@"/q/" stringByAppendingString:[quote valueForKey:@"quoteID"]];
    return [[NSURL URLWithString:endpoint relativeToURL:[NSURL URLWithString:QIBaseURL]] absoluteString];
}

NSString *QISourceNameForQuote(NSDictionary *quote) {
    NSDictionary *source = [quote valueForKey:@"source"];
    if ([[source valueForKey:@"type"] isEqualToString:@"fb-graph"]) {
        return [source valueForKey:@"name"];
    }
    return QIFullNameForUserDictionary(source);
}

void QIConfigureImageWell(UIImageView *sourcePhoto) {
    sourcePhoto.layer.cornerRadius = 4.0;
    sourcePhoto.layer.borderWidth = 1.0;
    sourcePhoto.layer.borderColor = [QIUtilities avatarBorderColor].CGColor;
    sourcePhoto.layer.masksToBounds = YES;
    [sourcePhoto.layer setShadowColor:[UIColor blackColor].CGColor];
    [sourcePhoto.layer setShadowOffset:CGSizeMake(0, 0)];
    [sourcePhoto.layer setShadowOpacity:1];
    [sourcePhoto.layer setShadowRadius:2.0];
}
