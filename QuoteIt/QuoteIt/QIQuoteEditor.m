//
//  QIQuoteEditor.m
//  QuoteIt
//
//  Created by Stephen Poletto on 1/2/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <Parse/Parse.h>

#import "UIImageView+AFNetworking.h"
#import "QIFailedQuoteUploads.h"
#import "QIMainViewController.h"
#import "QICoreDataManager.h"
#import "QISourceSelection.h"
#import "QIChooseTopic.h"
#import "QIQuoteEditor.h"
#import "QIUtilities.h"
#import "QIMyQuotes.h"
#import "QIAFClient.h"
#import "QIUser.h"
#import "iRate.h"

CGFloat const QIQuoteEditorSize = 288.0;

@implementation QIQuoteEditor
@synthesize backgroundImage;
@synthesize quoteEditor;
@synthesize choosePhotoButton;
@synthesize postQuoteButton;
@synthesize editTextButton;
@synthesize privacyButton;
@synthesize privacyPopup;
@synthesize popupBackground;
@synthesize quoteSource;
@synthesize quoteText;
@synthesize editorImageURL;
@synthesize quoteTopic;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        UIBarButtonItem *backItem = [UIBarButtonItem barItemWithImage:[QIUtilities backButtonImage] highlightedImage:[QIUtilities backButtonPressed] title:@"  Back" target:self action:@selector(back:)];
        self.navigationItem.leftBarButtonItem = backItem;
        
        self.title = @"Share Quote";
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissFontController) name:QIUserDidNotLogInNotification object:nil];
    }
    return self;
}

- (void)setupEditorWithImage:(UIImage *)image {
    loading = NO;
    [quoteEditor stopLoading];
    postQuoteButton.enabled = YES;
    editTextButton.enabled = editTextButtonShouldBeEnabled;
    [[quoteEditor quoteImageView] setImage:image];
    
    // Cache the image in case we get a memory warning.
    [memoryWarningCachedImage release];
    memoryWarningCachedImage = [image retain];
    
    // Scale the image so that the smaller of width/height occupies
    // the entire window. Then, the user will be able to pan around
    // to select the region of the longer dimension they'd like to use.
    CGFloat scaleFactor = QIQuoteEditorSize / image.size.height;
    if (image.size.width < image.size.height) {
        scaleFactor = QIQuoteEditorSize / image.size.width;
    }
    UIImage *resizedImage = [UIImage scale:image toSize:CGSizeMake(image.size.width * scaleFactor, image.size.height * scaleFactor)];
    
    CGRect quoteFrame = [quoteEditor quoteImageView].frame;
    quoteFrame.size = resizedImage.size;
    [quoteEditor quoteImageView].frame = quoteFrame;
    [quoteEditor backingScrollView].contentSize = resizedImage.size;
}

- (void)updateEditorWithImageURL:(NSString *)imageURL {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:imageURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
    [request setHTTPShouldHandleCookies:NO];
    [request setHTTPShouldUsePipelining:YES];
    
    [quoteEditor startLoading];
    loading = YES;
    postQuoteButton.enabled = NO;
    editTextButton.enabled = NO;
    [[quoteEditor quoteImageView] setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        [self setupEditorWithImage:image];
    } failure:nil];
}

- (void)setEditorImageURL:(NSString *)editorImageURLIn onlyIfNil:(BOOL)onlyIfNil {
    if (!onlyIfNil || !userHasSetPhoto) {
        [editorImageURL release];
        editorImageURL = [editorImageURLIn retain];
        [self updateEditorWithImageURL:editorImageURL];
    }
}

- (void)hideOverlayView:(BOOL)animated {
    if (!animated) {
        [overlayView removeFromSuperview];
        [overlayView release];
        overlayView = nil;
        editTextButton.enabled = editTextButtonShouldBeEnabled;
        privacyButton.enabled = YES;
        choosePhotoButton.enabled = YES;
        postQuoteButton.enabled = YES;
        self.quoteEditor.userInteractionEnabled = YES;
        self.navigationItem.leftBarButtonItem.enabled = YES;
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            overlayView.alpha = 0.0;  
        } completion:^(BOOL completed) {
            [overlayView removeFromSuperview];
            [overlayView release];
            overlayView = nil;
            editTextButton.enabled = editTextButtonShouldBeEnabled;
            privacyButton.enabled = YES;
            choosePhotoButton.enabled = YES;
            postQuoteButton.enabled = YES;
            self.quoteEditor.userInteractionEnabled = YES;
            self.navigationItem.leftBarButtonItem.enabled = YES;
        }];
    }
}

- (void)showOverlayViewWithImageNamed:(NSString *)imageName {
    [self hideOverlayView:NO]; // Ensure no existing overlay view.
    overlayView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
    CGRect hack = overlayView.frame;
    hack.origin.y += 20; // Accomodate the status bar.
    overlayView.frame = hack;
    [[[UIApplication sharedApplication] keyWindow] addSubview:overlayView];
    editTextButton.enabled = NO;
    privacyButton.enabled = NO;
    choosePhotoButton.enabled = NO;
    postQuoteButton.enabled = NO;
    self.quoteEditor.userInteractionEnabled = NO;
    self.navigationItem.leftBarButtonItem.enabled = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:QIHasCustomizedQuoteBackground]) {
        [self showOverlayViewWithImageNamed:@"ol_Background"];
        self.choosePhotoButton.enabled = YES;
    } else if (![[NSUserDefaults standardUserDefaults] boolForKey:QIHasMadeTextChanges]) {
        [self showOverlayViewWithImageNamed:@"ol_EditText"];
        self.editTextButton.enabled = YES;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    QIRenderNavigationBarTitle();
    [backgroundImage setImage:[QIUtilities bookImage]];
    
    if (memoryWarningCachedImage) {
        [self setupEditorWithImage:memoryWarningCachedImage];
    } else {
        [self updateEditorWithImageURL:editorImageURL];
    }
    
    [editTextButton setImage:[UIImage imageNamed:@"btn_text_press"] forState:UIControlStateHighlighted];
    [choosePhotoButton setImage:[UIImage imageNamed:@"btn_background_press"] forState:UIControlStateHighlighted];
    [postQuoteButton setImage:[UIImage imageNamed:@"btn_post_press"] forState:UIControlStateHighlighted];
    [privacyButton setImage:[UIImage imageNamed:@"privacy_public_press"] forState:UIControlStateHighlighted];
    privacyString = @"public";
    
    // These shouldn't look any different when disabled, so that they don't change
    // in appearance when the privacy selector popup is shown.
    [postQuoteButton setImage:[UIImage imageNamed:@"btn_post_static"] forState:UIControlStateDisabled];
    [choosePhotoButton setImage:[UIImage imageNamed:@"btn_background_static"] forState:UIControlStateDisabled];
    
    privacyPopup.hidden = YES;
    privacyPopup.backgroundColor = [UIColor clearColor];
    
    quoteEditor.quoteText = self.quoteText;
    quoteEditor.quoteSource = self.quoteSource;
    quoteEditor.delegate = self;
}

- (UILabel *)selectedLabel {
    return (UILabel *)[selectedResizableView contentView];
}

- (void)quoteEditorDidSelectResizableView:(SPUserResizableView *)view {
    if (fontEditorNavigationController && selectedResizableView != view) {
        selectedResizableView = view;
        [fontEditorNavigationController popToRootViewControllerAnimated:NO];
        QITextEditor *fontEditor = [fontEditorNavigationController.viewControllers firstObject];
        fontEditor.selectedFont = [self selectedLabel].font;
        fontEditor.selectedTextColor = [self selectedLabel].textColor;
        fontEditor.selectedBackgroundColor = [self selectedLabel].backgroundColor;
        fontEditor.selectedAlignment = [self selectedLabel].textAlignment;
    }
    selectedResizableView = view;
    editTextButtonShouldBeEnabled = YES;
    [editTextButton setEnabled:!loading];
}

- (void)dismissFontController {
    if (fontEditorNavigationController) {
        
        [fontEditorNavigationController.view removeFromSuperview];
        [fontEditorNavigationController release];
        fontEditorNavigationController = nil;
        
        CGRect editorFrame = quoteEditor.frame;
        editorFrame.origin.y += 15;
        
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        
        [UIView animateWithDuration:0.25 delay:0.0 options:0 animations:^{
            quoteEditor.frame = editorFrame;
        } completion:^(BOOL finished){
            
        }];
    }
}

- (void)quoteEditorDidDismissResizableView:(SPUserResizableView *)view {
    if (!selectedResizableView || view == selectedResizableView) {
        editTextButtonShouldBeEnabled = NO;
        [editTextButton setEnabled:NO];
        [self dismissFontController];
    }
}

- (void)installDismissGestureRecognizer {
    privacyPopupDismissRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hidePrivacyPopup)];
    [privacyPopupDismissRecognizer setDelegate:self];
    [self.view addGestureRecognizer:privacyPopupDismissRecognizer];
}

- (void)uninstallDismissGestureRecognizer {
    [self.view removeGestureRecognizer:privacyPopupDismissRecognizer];
    [privacyPopupDismissRecognizer release];
    privacyPopupDismissRecognizer = nil;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([self.privacyPopup hitTest:[touch locationInView:self.privacyPopup] withEvent:nil]) {
        return NO;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)hidePrivacyPopup {
    popupBackground.image = [UIImage imageNamed:@"popup"];
    privacyPopup.hidden = YES;
    postQuoteButton.enabled = YES;
    choosePhotoButton.enabled = YES;
    quoteEditor.userInteractionEnabled = YES;
    [self uninstallDismissGestureRecognizer];
}

- (void)showPrivacyPopup {
    [TestFlight passCheckpoint:@"Show Privacy Settings"];
    privacyPopup.hidden = NO;
    postQuoteButton.enabled = NO;
    choosePhotoButton.enabled = NO;
    quoteEditor.userInteractionEnabled = NO;
    [self installDismissGestureRecognizer];
}

- (IBAction)editText:(id)sender {
    [TestFlight passCheckpoint:@"Quote Editor -- Edit Text"];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:QIHasMadeTextChanges]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:QIHasMadeTextChanges];
        [self hideOverlayView:YES];
    }
    
    QITextEditor *fontEditor = [[QITextEditor alloc] initWithNibName:@"QITextEditor" bundle:nil];
    fontEditor.delegate = self;
    fontEditor.selectedTextColor = [self selectedLabel].textColor;
    fontEditor.selectedFont = [self selectedLabel].font;
    fontEditor.selectedAlignment = [self selectedLabel].textAlignment;
    fontEditor.selectedBackgroundColor = [self selectedLabel].backgroundColor;

    fontEditorNavigationController = [[UINavigationController alloc] initWithRootViewController:fontEditor];
    fontEditorNavigationController.navigationBar.clipsToBounds = YES;
    [QIUtilities setBackgroundImage:[QIUtilities fontEditorNavBarImage] forNavigationController:fontEditorNavigationController];
    fontEditorNavigationController.navigationBar.tag = 995;
    fontEditorNavigationController.view.frame = CGRectMake(0, 480, 320, 480);
    [self.view addSubview:fontEditorNavigationController.view];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    CGRect editorFrame = quoteEditor.frame;
    editorFrame.origin.y -= 15;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationBeginsFromCurrentState:YES];
    quoteEditor.frame = editorFrame;
    fontEditorNavigationController.view.frame = CGRectMake(0, 291, 320, 189);
    [UIView commitAnimations];
}

#pragma mark -
#pragma mark QITextEditorDelegate

- (void)textEditor:(QITextEditor *)editor userSelectedFont:(UIFont *)font {
    [self selectedLabel].font = font;
}

- (void)textEditor:(QITextEditor *)editor userSelectedTextColor:(UIColor *)textColor {
    if (textColor == [UIColor blackColor]) {
        //[self selectedLabel].shadowColor = [UIColor whiteColor];
    } else {
        //[self selectedLabel].shadowColor = [UIColor blackColor];
    }
    [self selectedLabel].textColor = textColor;
}

- (void)textEditor:(QITextEditor *)editor userSelectedBackgroundColor:(UIColor *)backgroundColor {
    [self selectedLabel].backgroundColor = backgroundColor;
    if (!backgroundColor) {
        // If it's nil, set the background color to clear.
        [self selectedLabel].backgroundColor = [UIColor clearColor];
    }
}

- (void)textEditor:(QITextEditor *)editor userSelectedAlignment:(UITextAlignment)alignment {
    [self selectedLabel].textAlignment = alignment;
}

- (void)textEditorIsDone:(QITextEditor *)editor {
    [self dismissFontController];
}

- (IBAction)changePrivacy:(id)sender {
    if (privacyPopup.hidden) {
        [self showPrivacyPopup];
    } else {
        [self hidePrivacyPopup];
    }
}

- (IBAction)publicPrivacyTouchDown:(id)sender {
    popupBackground.image = [UIImage imageNamed:@"public_press"];
}

- (IBAction)friendsPrivacyTouchDown:(id)sender {
    popupBackground.image = [UIImage imageNamed:@"Friends_Only_Press"];
}

- (IBAction)onlyMePrivacyTouchDown:(id)sender {
    popupBackground.image = [UIImage imageNamed:@"me_press"];
}

- (IBAction)publicPrivacyTouchUpOutside:(id)sender {
    popupBackground.image = [UIImage imageNamed:@"popup"];
}

- (IBAction)onlyMePrivacyTouchUpOutside:(id)sender {
    popupBackground.image = [UIImage imageNamed:@"popup"];
}

- (IBAction)onlyMePrivacyTouchUpInside:(id)sender {
    [self hidePrivacyPopup];
    [privacyButton setImage:[UIImage imageNamed:@"privacy_me_static"] forState:UIControlStateNormal];
    [privacyButton setImage:[UIImage imageNamed:@"privacy_me_press"] forState:UIControlStateHighlighted];
    privacyString = @"me";
}

- (IBAction)publicPrivacyTouchUpInside:(id)sender {
    [self hidePrivacyPopup];
    [privacyButton setImage:[UIImage imageNamed:@"privacy_public_static"] forState:UIControlStateNormal];
    [privacyButton setImage:[UIImage imageNamed:@"privacy_public_press"] forState:UIControlStateHighlighted];
    privacyString = @"public";
}

- (IBAction)friendsPrivacyTouchUpOutside:(id)sender {
    popupBackground.image = [UIImage imageNamed:@"popup"];
}

- (IBAction)friendsPrivacyTouchUpInside:(id)sender {
    [self hidePrivacyPopup];
    [privacyButton setImage:[UIImage imageNamed:@"privacy_friends_static"] forState:UIControlStateNormal];
    [privacyButton setImage:[UIImage imageNamed:@"privacy_friends_press"] forState:UIControlStateHighlighted];
    privacyString = @"friends";
}

- (void)setQuoteText:(NSString *)quoteTextIn {
    if (quoteText != quoteTextIn) {
        [quoteText release];
        quoteText = [quoteTextIn retain];
        quoteEditor.quoteText = self.quoteText;
    }
}

- (void)setQuoteSource:(NSDictionary *)quoteSourceIn {
    if (quoteSourceIn != quoteSource) {
        userHasSetPhoto = NO;
        [quoteSource release];
        quoteSource = [quoteSourceIn retain];
        quoteEditor.quoteSource = self.quoteSource;
    }
}

- (void)back:(id)sender {
    [TestFlight passCheckpoint:@"Quote Editor -- Back"];
    [QIUtilities navigationControllerPopViewControllerWithPageCurlTransition:super.navigationController];
}

- (void)userDidSelectPhotoURL:(NSString *)photoURL {
    userHasSetPhoto = YES;
    [QIUtilities navigationControllerPopViewControllerWithPageCurlTransition:super.navigationController];
    [self setEditorImageURL:photoURL onlyIfNil:NO];
}

- (void)userDidSelectPhotoImage:(UIImage *)image {
    userHasSetPhoto = YES;
    [QIUtilities navigationControllerPopViewControllerWithPageCurlTransition:super.navigationController];
    [self setupEditorWithImage:image];
}

- (IBAction)choosePhoto:(id)sender {
    [TestFlight passCheckpoint:@"Quote Editor -- Choose Photo"];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:QIHasCustomizedQuoteBackground]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:QIHasCustomizedQuoteBackground];
        [self hideOverlayView:YES];
    }
    
    if (!choosePhoto) {
        choosePhoto = [[QIChooseQuotePhoto alloc] initWithNibName:@"QIChooseQuotePhoto" bundle:nil];
        choosePhoto.delegate = self;
    }
    choosePhoto.quoteSource = quoteSource;
    [QIUtilities navigationController:super.navigationController animteWithPageCurlToViewController:choosePhoto];
}

- (void)transitionToPostQuoteSubmissionScreen {
    QIMyQuotes *myQuotes = [[QIMainViewController mainViewController] myQuotesController];
    [myQuotes.navigationController popToRootViewControllerAnimated:NO];
    [myQuotes showUpdatingQuotesSpinnerWithMessage:@"Uploading Quote"];
    [myQuotes selectCreatedByYouTab];
    [[QIMainViewController mainViewController] dismissModalViewControllerAnimated:NO];
    [[QIMainViewController mainViewController] selectMyQuotesController];
}

- (UIImage *)imageFromView:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0.0);
    view.hidden = NO;
	[view.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
    return viewImage;
}

- (void)sendPushNotification:(NSDictionary *)postedQuote {
    // Only send the push if we didn't quote ourself.
    if (![[[[QICoreDataManager sharedDataManger] loggedInUser] userID] isEqualToString:[postedQuote objectForKey:@"quote_source_id"]] && ![[postedQuote objectForKey:@"quote_privacy"] isEqualToString:@"me"]) {
        
        // And if we're quoting a *user*.
        if ([[postedQuote objectForKey:@"entity_type"] isEqualToString:@"friend"]) {
            // Send the notification to the user who we just quoted.
            // Channels must start with a letter. Unique identifiers may not start with a letter.
            NSString *channelName = [@"a" stringByAppendingString:[postedQuote objectForKey:@"quote_source_id"]];
            NSString *message = [NSString stringWithFormat:@"You have been quoted by %@.", QIFullNameForUser([[QICoreDataManager sharedDataManger] loggedInUser])];
            
            NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                    message, @"alert",
                                    [NSNumber numberWithInt:1], @"badge", nil];
            
            [PFPush sendPushDataToChannelInBackground:channelName withData:params];
        }
    }
}

// POST parameters:
// entity_type = friend, fb-graph
// quote_privacy = public, linkonly
// quote_source_id
// quote_text
// quote_topic_id
// quote_photo = file
- (IBAction)postQuote:(id)sender {
    [TestFlight passCheckpoint:@"Post Quote"];
    NSString *entityType = @"fb-graph";
    if ([quoteSource objectForKey:QISourceEntityTypeKey] == QISourceEntityTypeFriend) {
        entityType = @"friend";
    }
    NSString *quoteSourceID = [quoteSource objectForKey:QISourceEntityIDKey];
    NSString *quoteTopicID = [quoteTopic objectForKey:QITopicIDKey];
    NSString *sourceName = [quoteSource objectForKey:QISourceEntityNameKey];
    
    NSDictionary *postParams = [NSDictionary dictionaryWithObjectsAndKeys:sourceName, @"source_name",
                                                                          privacyString, @"quote_privacy",
                                                                          quoteSourceID, @"quote_source_id",
                                                                          entityType, @"entity_type",
                                                                          self.quoteText, @"quote_text", 
                                                                          quoteTopicID, @"quote_topic_id", nil]; // quoteTopicID might be nil so it *must* come last.
    [quoteEditor hideEditingHandles]; // Make sure the editing handles aren't in the quote.
    NSData *imageData = UIImageJPEGRepresentation([self imageFromView:quoteEditor], 0.9);
    NSMutableURLRequest *request = [[QIAFClient sharedClient] multipartFormRequestWithMethod:@"POST" path:@"/api/submit_quote" parameters:postParams constructingBodyWithBlock: ^(id <AFMultipartFormData> formData) {
        [formData appendPartWithFileData:imageData name:@"quote_photo" fileName:@"quote.jpg" mimeType:@"image/jpeg"];
    }];
    
    AFHTTPRequestOperation *operation = [[QIAFClient sharedClient] HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id jsonObject) {
        if ([[jsonObject valueForKey:@"status"] isEqualToString:@"ok"]) {
            // Update the core data cache of my quotes
            // Don't do this until the upload is complete so the new quote is in there!
            [[QICoreDataManager sharedDataManger] loadMyQuotes];
            
            [self sendPushNotification:postParams];
            [[iRate sharedInstance] logEvent:NO]; // Don't defer prompt.
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[QIFailedQuoteUploads sharedFailedQuotes] enqueueFailedQuote:postParams withImageData:imageData];
    }];
    [operation setUploadProgressBlock:^(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite) {
        // TODO show a progress bar
        NSLog(@"Sent %d of %d bytes", totalBytesWritten, totalBytesExpectedToWrite);
    }];
    [operation start];
    [self transitionToPostQuoteSubmissionScreen];
}

- (void)dealloc {
    [privacyPopupDismissRecognizer release];
    [choosePhoto release];
    [backgroundImage release];
    [quoteEditor release];
    [choosePhotoButton release];
    [postQuoteButton release];
    [editTextButton release];
    [privacyButton release];
    [privacyPopup release];
    [popupBackground release];
    [super dealloc];
}

- (void)viewDidUnload {
    [self setBackgroundImage:nil];
    [self setQuoteEditor:nil];
    [self setChoosePhotoButton:nil];
    [self setPostQuoteButton:nil];
    [self setEditTextButton:nil];
    [self setPrivacyButton:nil];
    [self setPrivacyPopup:nil];
    [self setPopupBackground:nil];
    [super viewDidUnload];
}

@end
