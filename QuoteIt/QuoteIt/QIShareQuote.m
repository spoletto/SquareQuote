//
//  QIShareQuote.m
//  QuoteIt
//
//  Created by Stephen Poletto on 12/29/11.
//  Copyright (c) 2011 QuoteIt. All rights reserved.
//

#import "UIImageView+AFNetworking.h"
#import "QITemplatePhotosCache.h"
#import "UIPlaceholderTextView.h"
#import "RKRequestQueue.h"
#import "QIQuoteEditor.h"
#import "QIShareQuote.h"
#import "QIUtilities.h"

@interface QIShareQuote()
- (void)updateNextButtonEnabledState;
@end

@implementation QIShareQuote
@synthesize backgroundImage;
@synthesize nextButton;
@synthesize quoteTextView;
@synthesize chooseSourceButton;
@synthesize chooseTopicButton;
@synthesize sourcePhoto;
@synthesize sourceName;
@synthesize whatWasSaidLabel;
@synthesize whoSaidItLabel;
@synthesize regardingLabel;
@synthesize whoContainingView;
@synthesize regardingContainingView;
@synthesize regardingFormFieldLabel;
@synthesize textViewBackground;
@synthesize whoSaidItImage;
@synthesize whatWasItRegardingImage;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Share Quote";
        
        UIBarButtonItem *cancelItem = [UIBarButtonItem barItemWithImage:[QIUtilities cancelButtonImage] highlightedImage:[QIUtilities cancelButtonPressed] title:@"Cancel" target:self action:@selector(cancel:)];
        self.navigationItem.leftBarButtonItem = cancelItem;
        [TestFlight passCheckpoint:@"Quote Creation Started"];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideKeyboard) name:QIUserDidNotLogInNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    QIRenderNavigationBarTitle();
    
    // Dismiss the keyboard whenever the background view is tapped.
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [gestureRecognizer setDelegate:self];
    [self.view addGestureRecognizer:gestureRecognizer];
    [gestureRecognizer release];
    
    quoteTextView.placeholder = @"Tap here to enter quote.";
    [backgroundImage setImage:[QIUtilities bookImage]];
    [sourcePhoto setImage:[QIUtilities userPlaceholderImage]];
    [sourceName setText:@"Choose Source"];
    sourceName.textColor = [UIColor lightGrayColor];
    [regardingFormFieldLabel setText:@"Choose Topic"];
    regardingFormFieldLabel.textColor = [UIColor lightGrayColor];
    
    QIConfigureImageWell(sourcePhoto);
    
    nextButton.enabled = NO;
    [nextButton setBackgroundImage:[UIImage imageNamed:@"next_btn_active"] forState:UIControlStateHighlighted];
    nextButton.titleLabel.font = [QIUtilities buttonTitleFont];
    [nextButton setTitleColor:[QIUtilities buttonTitleColor] forState:UIControlStateNormal];
    nextButton.titleLabel.shadowColor = [QIUtilities buttonTitleDropShadowColor];
    nextButton.titleLabel.shadowOffset = CGSizeMake(0, -1);
    
    quoteTextView.backgroundColor = [UIColor clearColor];
    whoContainingView.backgroundColor = [UIColor clearColor];
    regardingContainingView.backgroundColor = [UIColor clearColor];
    
    [textViewBackground setImage:[[UIImage imageNamed:@"Form_Field"] stretchableImageWithLeftCapWidth:5.0 topCapHeight:10.0]];
    [whoSaidItImage setImage:[[UIImage imageNamed:@"Form_Field"] stretchableImageWithLeftCapWidth:5.0 topCapHeight:10.0]];
    [whatWasItRegardingImage setImage:[[UIImage imageNamed:@"Form_Field"] stretchableImageWithLeftCapWidth:5.0 topCapHeight:10.0]];
    
    whoSaidItLabel.textColor = [QIUtilities titleBarTitleColor];
    whatWasSaidLabel.textColor = [QIUtilities titleBarTitleColor];
    regardingLabel.textColor = [QIUtilities titleBarTitleColor];
    
    quoteTextView.textColor = [QIUtilities formFieldColor];
    quoteTextView.font = [QIUtilities formFieldFont];
    regardingFormFieldLabel.font = [QIUtilities formFieldFont];
    sourceName.font = [QIUtilities formFieldFont];
    
    quoteTextView.text = memoryWarningCachedQuoteText;
    [self updateSourceUI];
    [self updateNextButtonEnabledState];
}

- (void)cancel:(id)sender {
    [TestFlight passCheckpoint:@"Quote Creation Cancelled"];
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)chooseSource:(id)sender {
    [TestFlight passCheckpoint:@"Quote Creation -- Choose Source"];
    [self.view endEditing:YES];
    QISourceSelection *sourceSelection = [[[QISourceSelection alloc] initWithNibName:@"QISourceSelection" bundle:nil] autorelease];
    sourceSelection.delegate = self;
    [QIUtilities navigationController:self.navigationController animteWithPageCurlToViewController:sourceSelection];
}

- (IBAction)chooseTopic:(id)sender {
    [TestFlight passCheckpoint:@"Quote Creation -- Choose Topic"];
    [self.view endEditing:YES];
    QIChooseTopic *chooseTopic = [[[QIChooseTopic alloc] initWithNibName:@"QIChooseTopic" bundle:nil] autorelease];
    chooseTopic.delegate = self;
    [QIUtilities navigationController:self.navigationController animteWithPageCurlToViewController:chooseTopic];
}

- (void)updateTopicUI {
    [regardingFormFieldLabel setText:[selectedTopic objectForKey:QITopicNameKey]];
    regardingFormFieldLabel.textColor = [QIUtilities formFieldColor];
}

- (void)updateSourceUI {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[selectedSource objectForKey:QISourceEntityPhotoURLKey]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
    [request setHTTPShouldHandleCookies:NO];
    [request setHTTPShouldUsePipelining:YES];
    
    [sourcePhoto setImageWithURLRequest:request placeholderImage:[QIUtilities userPlaceholderImage] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        if ([[selectedSource objectForKey:QISourceEntityTypeKey] isEqualToString:QISourceEntityTypePage]) {
            [sourcePhoto setImage:[UIImage scale:image toFillSize:sourcePhoto.frame.size]];
        }
    } failure:nil];
    
    
    if ([[selectedSource objectForKey:QISourceEntityNameKey] length]) {
        [sourceName setText:[selectedSource objectForKey:QISourceEntityNameKey]];
        sourceName.textColor = [QIUtilities formFieldColor];
    } else {
        [sourceName setText:@"Choose Source"];
        sourceName.textColor = [UIColor lightGrayColor];
    }
}

- (void)sourceSelection:(QISourceSelection *)sourceSelection didSelectSource:(NSDictionary *)source {
    [TestFlight passCheckpoint:@"Quote Creation -- Did Choose Source"];
    [selectedSource release];
    selectedSource = [source retain];
    [self updateNextButtonEnabledState];
    [self updateSourceUI];
}

- (void)chooseTopic:(QIChooseTopic *)chooseTopic didSelectTopic:(NSDictionary *)topic {
    [TestFlight passCheckpoint:@"Quote Creation -- Did Choose Topic"];
    [selectedTopic release];
    selectedTopic = [topic retain];
    [self updateTopicUI];
}

- (void)updateNextButtonEnabledState {
    if (selectedSource && [[quoteTextView text] length]) {
        nextButton.enabled = YES;
    } else {
        nextButton.enabled = NO;
    }
}

- (IBAction)nextScreen:(id)sender {
    // We're setting this up as an ivar instead of a local variable so that QIShareQuote can attempt to prefetch
    // the profile picture as soon as the source is selected. However, the user may tap "next" before the facebook
    // request completes, and we therefore want to have a reference to the editor to update its image.
    [TestFlight passCheckpoint:@"Quote Creation -- Showing Editor"];
    [memoryWarningCachedQuoteText release];
    memoryWarningCachedQuoteText = [[self.quoteTextView text] retain];
    if (!editor) {
        editor = [[QIQuoteEditor alloc] initWithNibName:@"QIQuoteEditor" bundle:nil];
    }
    editor.quoteSource = selectedSource;
    editor.quoteTopic = selectedTopic;
    editor.quoteText = [quoteTextView text];

    NSDictionary *templatePhoto = [[[QITemplatePhotosCache sharedTemplatePhotosCache] cachedTemplatePhotos] firstObject];
    [editor setEditorImageURL:[templatePhoto objectForKey:@"src_big"] onlyIfNil:YES];
    
    [QIUtilities navigationController:self.navigationController animteWithPageCurlToViewController:editor];
}

#pragma mark -
#pragma mark UITextViewDelegate methods

- (void)hideKeyboard {
    [self.view endEditing:YES];
    [self updateNextButtonEnabledState];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)string {
    if ([string isEqualToString:@"\n"]) {
        [self hideKeyboard];
        return NO;
    }
    return YES;
}

#pragma mark -
#pragma mark UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([chooseSourceButton hitTest:[touch locationInView:chooseSourceButton] withEvent:nil]) {
        return NO;
    } else if ([chooseTopicButton hitTest:[touch locationInView:chooseTopicButton] withEvent:nil]) {
        return NO;
    } else if ([nextButton hitTest:[touch locationInView:nextButton] withEvent:nil]) {
        return NO;
    } else if ([quoteTextView hitTest:[touch locationInView:quoteTextView] withEvent:nil]) {
        return NO;
    }
    return YES;
}

- (void)dealloc {
    [memoryWarningCachedQuoteText release];
    [editor release];
    [selectedSource release];
    [backgroundImage release];
    [nextButton release];
    [quoteTextView release];
    [chooseSourceButton release];
    [sourcePhoto release];
    [sourceName release];
    [whatWasSaidLabel release];
    [whoSaidItLabel release];
    [regardingLabel release];
    [whoContainingView release];
    [regardingContainingView release];
    [regardingFormFieldLabel release];
    [textViewBackground release];
    [whoSaidItImage release];
    [whatWasItRegardingImage release];
    [chooseTopicButton release];
    [super dealloc];
}

- (void)viewDidUnload {
    [self setBackgroundImage:nil];
    [self setNextButton:nil];
    [self setQuoteTextView:nil];
    [self setChooseSourceButton:nil];
    [self setSourcePhoto:nil];
    [self setSourceName:nil];
    [self setWhatWasSaidLabel:nil];
    [self setWhoSaidItLabel:nil];
    [self setRegardingLabel:nil];
    [self setWhoContainingView:nil];
    [self setRegardingContainingView:nil];
    [self setRegardingFormFieldLabel:nil];
    [self setTextViewBackground:nil];
    [self setWhoSaidItImage:nil];
    [self setWhatWasItRegardingImage:nil];
    [self setChooseTopicButton:nil];
    [super viewDidUnload];
}

@end
