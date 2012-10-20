//
//  QIQuoteView.m
//  QuoteIt
//
//  Created by Stephen Poletto on 12/30/11.
//  Copyright (c) 2011 QuoteIt. All rights reserved.
//

#import "QICoreDataManager.h"
#import "QIQuoteViewer.h"
#import "QIQuoteView.h"
#import "QIUtilities.h"
#import "QIAFClient.h"

@interface QIQuoteView()
- (void)removeBackOfQuoteControls;
@end

CGSize const QIQuoteViewInset = { 16.0, 0.0 };

@implementation QIQuoteView
@synthesize quoteViewerBackpointer;
@synthesize imageView;
@synthesize showsDeleteButton;
@synthesize showsFlagButton;
@synthesize quote;
@synthesize hasGestureRecognizers;

- (id)init {
    self = [super init];
    if (self) {
        imageView = [[UIImageView alloc] init];
        [self addSubview:imageView];
        self.backgroundColor = [UIColor clearColor];
        
        loadingQuoteView = [[UIImageView alloc] initWithFrame:self.frame];
        loadingQuoteView.animationImages = [NSArray arrayWithObjects:    
                                            [UIImage imageNamed:@"frame1"],
                                            [UIImage imageNamed:@"frame2"],
                                            [UIImage imageNamed:@"frame3"],
                                            [UIImage imageNamed:@"frame4"], nil];
        loadingQuoteView.animationDuration = 1.0f;
        loadingQuoteView.animationRepeatCount = 0;
        
        backOfQuoteMask = [[UIView alloc] init];
        backOfQuoteMask.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
        
        deleteQuoteButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        [deleteQuoteButton setTitle:@"Delete" forState:UIControlStateNormal];
        [deleteQuoteButton setBackgroundImage:[UIImage imageNamed:@"btn_red_static"] forState:UIControlStateNormal];
        [deleteQuoteButton setImage:[UIImage imageNamed:@"Delete_disabled"] forState:UIControlStateDisabled];
        [deleteQuoteButton setBackgroundImage:[UIImage imageNamed:@"btn_red_press"] forState:UIControlStateHighlighted];
        deleteQuoteButton.frame = CGRectMake(0, 0, 210, 38);
        deleteQuoteButton.titleLabel.font = [QIUtilities buttonTitleFont];
        [deleteQuoteButton setTitleColor:[QIUtilities buttonTitleColor] forState:UIControlStateNormal];
        [deleteQuoteButton setTitleColor:[QIUtilities buttonTitleColor] forState:UIControlStateHighlighted];
        deleteQuoteButton.titleLabel.shadowColor = [QIUtilities buttonTitleDropShadowColor];
        deleteQuoteButton.titleLabel.shadowOffset = CGSizeMake(0, -1);
        [deleteQuoteButton addTarget:self action:@selector(deleteQuote:) forControlEvents:UIControlEventTouchUpInside];
        
        flagQuoteButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        [flagQuoteButton setTitle:@"Flag For Review" forState:UIControlStateNormal];
        [flagQuoteButton setBackgroundImage:[UIImage imageNamed:@"btn_red_static"] forState:UIControlStateNormal];
        [flagQuoteButton setImage:[UIImage imageNamed:@"Flag_disabled"] forState:UIControlStateDisabled];
        [flagQuoteButton setBackgroundImage:[UIImage imageNamed:@"btn_red_press"] forState:UIControlStateHighlighted];
        flagQuoteButton.frame = CGRectMake(0, 0, 210, 38);
        flagQuoteButton.titleLabel.font = [QIUtilities buttonTitleFont];
        [flagQuoteButton setTitleColor:[QIUtilities buttonTitleColor] forState:UIControlStateNormal];
        [flagQuoteButton setTitleColor:[QIUtilities buttonTitleColor] forState:UIControlStateHighlighted];
        flagQuoteButton.titleLabel.shadowColor = [QIUtilities buttonTitleDropShadowColor];
        flagQuoteButton.titleLabel.shadowOffset = CGSizeMake(0, -1);
        [flagQuoteButton addTarget:self action:@selector(flagQuote:) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)addGestureRecognizers {
    if (!doubleTapQuoteRecognizer) {
        doubleTapQuoteRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(quoteDoubleTapped)];
        doubleTapQuoteRecognizer.numberOfTapsRequired = 2;
    }
    [self addGestureRecognizer:doubleTapQuoteRecognizer];
    
    if (!longPress) {
        longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        longPress.minimumPressDuration = 1.0;
    }
    [self addGestureRecognizer:longPress];
}

- (void)removeGestureRecognizers {
    [self removeGestureRecognizer:longPress];
    [self removeGestureRecognizer:doubleTapQuoteRecognizer];
}

- (void)setHasGestureRecognizers:(BOOL)hasGestureRecognizersIn {
    hasGestureRecognizers = hasGestureRecognizersIn;
    if (hasGestureRecognizers) {
        [self addGestureRecognizers];
    } else {
        [self removeGestureRecognizers];
    }
}

- (void)deleteQuote:(id)sender {
    deleteQuoteButton.enabled = NO;
    flagQuoteButton.enabled = NO;
    NSDictionary *postParams = [NSDictionary dictionaryWithObject:[quote valueForKey:@"quoteID"] forKey:@"quote_id"];
    [[QIAFClient sharedClient] postPath:@"/api/delete" parameters:postParams success:^(AFHTTPRequestOperation *operation, id jsonObject) {
        if ([[jsonObject valueForKey:@"status"] isEqualToString:@"ok"]) {
            self.imageView.image = [UIImage imageNamed:@"delete_banner"];
            // Update the list of my quotes. My quotes are the only ones that can be deleted.
            [[QICoreDataManager sharedDataManger] loadMyQuotes]; 
            [self animateToFrontOfQuote];
            [quoteViewerBackpointer userDidDeleteQuote:quote];
            [self removeGestureRecognizers];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[QIErrorHandler sharedErrorHandler] presentFailureViewWithTitle:@"Failed to delete quote." error:error completionHandler:nil];
        deleteQuoteButton.enabled = YES;
        flagQuoteButton.enabled = YES;
    }];
}

- (void)flagQuote:(id)sender {
    deleteQuoteButton.enabled = NO;
    flagQuoteButton.enabled = NO;
    NSDictionary *postParams = [NSDictionary dictionaryWithObject:[quote valueForKey:@"quoteID"] forKey:@"quote_id"];
    [[QIAFClient sharedClient] postPath:@"/api/flag" parameters:postParams success:^(AFHTTPRequestOperation *operation, id jsonObject) {
        if ([[jsonObject valueForKey:@"status"] isEqualToString:@"ok"]) {
            self.imageView.image = [UIImage imageNamed:@"review_banner"];
            // Reload all quotes that could have been flagged.
            [[QICoreDataManager sharedDataManger] loadMyQuotes]; 
            [self animateToFrontOfQuote];
            [quoteViewerBackpointer userDidFlagQuote:quote];
            [self removeGestureRecognizers];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[QIErrorHandler sharedErrorHandler] presentFailureViewWithTitle:@"Failed to flag quote." error:error completionHandler:nil];
        deleteQuoteButton.enabled = YES;
        flagQuoteButton.enabled = YES;
    }];
}

- (void)showFrontOfQuote {
    [self removeBackOfQuoteControls];
    [backOfQuoteMask removeFromSuperview];
    [secondaryView removeFromSuperview];
    quoteFlipped = NO;
}

- (void)startLoading {
    // Restore to front of quote (if needed).
    [self showFrontOfQuote];
    
    [self addSubview:loadingQuoteView];
    [loadingQuoteView startAnimating];
    loading = YES;
}

- (void)stopLoading {
    [loadingQuoteView removeFromSuperview];
    [loadingQuoteView stopAnimating];
    loading = NO;
    
    [secondaryView release];
    UIImage *image = [self.imageView image];
    UIImage *flippedImage = [UIImage imageWithCGImage:image.CGImage scale:1.0 orientation:UIImageOrientationUpMirrored];
    secondaryView = [[UIImageView alloc] initWithImage:flippedImage];
    CGRect imageViewFrame = CGRectZero;
    imageViewFrame.size = self.frame.size;
    [secondaryView setFrame:CGRectInset(imageViewFrame, QIQuoteViewInset.width, QIQuoteViewInset.height)];
}

- (void)animateToFrontOfQuote {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:1.0];
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft
						   forView:self
							 cache:YES];
    [self removeBackOfQuoteControls];
    [backOfQuoteMask removeFromSuperview];
	[secondaryView removeFromSuperview];
	[UIView commitAnimations];
}

- (void)removeBackOfQuoteControls {
    [deleteQuoteButton removeFromSuperview];
    [flagQuoteButton removeFromSuperview];
}

- (void)addBackOfQuoteControls {
    flagQuoteButton.enabled = self.showsFlagButton;
    deleteQuoteButton.enabled = self.showsDeleteButton;
    [self addSubview:flagQuoteButton];
    [self addSubview:deleteQuoteButton];
}

- (void)configureFramesForBackOfQuoteControls:(CGRect)referenceFrame {
    CGFloat buttonX = referenceFrame.origin.x + 40;
    CGRect deleteFrame = deleteQuoteButton.frame;
    CGRect flagFrame = flagQuoteButton.frame;
    deleteFrame.origin.y = referenceFrame.origin.y + 107;
    deleteFrame.origin.x = buttonX;
    flagFrame.origin.y = referenceFrame.origin.y + 158;
    flagFrame.origin.x = buttonX;
    
    deleteQuoteButton.frame = deleteFrame;
    flagQuoteButton.frame = flagFrame;
}

- (void)animateToBackOfQuote {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:1.0];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight
                           forView:self
                             cache:YES];
    [self addSubview:secondaryView];
    [self addSubview:backOfQuoteMask];
    [self addBackOfQuoteControls];
    [UIView commitAnimations];
}

- (void)flipQuote {
    if (!loading) {
        if (quoteFlipped) {
            [self animateToFrontOfQuote];
        } else {
            [self animateToBackOfQuote];
        }
        quoteFlipped = !quoteFlipped;
    }
}

- (void)quoteDoubleTapped {
    [self flipQuote];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (UIGestureRecognizerStateBegan == gesture.state) {
        [self flipQuote];
    }
    
    if (UIGestureRecognizerStateChanged == gesture.state) {
        // Do repeated work here (repeats continuously) while finger is down
    }
    
    if (UIGestureRecognizerStateEnded == gesture.state) {
        // Do end work here when finger is lifted
    }
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    CGRect imageViewFrame = CGRectZero;
    imageViewFrame.size = frame.size;
    [imageView setFrame:CGRectInset(imageViewFrame, QIQuoteViewInset.width, QIQuoteViewInset.height)];
    [loadingQuoteView setFrame:CGRectInset(imageViewFrame, QIQuoteViewInset.width, QIQuoteViewInset.height)];
    [secondaryView setFrame:CGRectInset(imageViewFrame, QIQuoteViewInset.width, QIQuoteViewInset.height)];
    [self configureFramesForBackOfQuoteControls:CGRectInset(imageViewFrame, QIQuoteViewInset.width, QIQuoteViewInset.height)];
    [backOfQuoteMask setFrame:CGRectInset(imageViewFrame, QIQuoteViewInset.width, QIQuoteViewInset.height)];
}

- (void)dealloc {
    [doubleTapQuoteRecognizer release];
    [longPress release];
    [backOfQuoteMask release];
    [loadingQuoteView release];
    [secondaryView release];
    [imageView release];
    [super dealloc];
}

@end
