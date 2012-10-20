//
//  QIQuoteEditorView.m
//  QuoteIt
//
//  Created by Stephen Poletto on 1/2/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

#import "UIImageView+AFNetworking.h"
#import "QIQuoteEditorView.h"
#import "QISourceSelection.h"
#import "QIUtilities.h"

@interface SPStrokedLabel : UILabel
@end

@implementation SPStrokedLabel

- (void)drawTextInRect:(CGRect)rect {    
    CGSize shadowOffset = self.shadowOffset;
    UIColor *textColor = self.textColor;
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(c, 1);
    CGContextSetLineJoin(c, kCGLineJoinRound);
    
    CGContextSetTextDrawingMode(c, kCGTextStroke);
    self.textColor = [UIColor blackColor];
    self.shadowOffset = CGSizeMake(0, 0);
    [super drawTextInRect:rect];
    
    CGContextSetTextDrawingMode(c, kCGTextFill);
    self.textColor = textColor;
    self.shadowOffset = CGSizeMake(0, 0);
    [super drawTextInRect:rect];
    
    self.shadowOffset = shadowOffset;
}

@end

@implementation QIQuoteEditorBrickView
@synthesize eventForwardingView;

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView) {
        return eventForwardingView;
    }
    return nil;
}
@end

@implementation QIQuoteEditorView
@synthesize backingScrollView;
@synthesize quoteImageView;
@synthesize editorContainerView;
@synthesize quoteSource;
@synthesize quoteText;
@synthesize delegate;

- (void)initializeSubviews {
    CGRect subviewRect = CGRectZero;
    subviewRect.size = self.frame.size;
    backingScrollView = [[UIScrollView alloc] initWithFrame:subviewRect];
    quoteImageView = [[UIImageView alloc] initWithFrame:subviewRect];
    resizableArea = [[UIView alloc] initWithFrame:subviewRect];
    resizableArea.backgroundColor = [UIColor clearColor];
    
    [backingScrollView addSubview:quoteImageView];
    [self addSubview:backingScrollView];
    [self addSubview:resizableArea];
    
    
    CGRect gripFrame = CGRectMake(10, 10, 228, 150);
    SPUserResizableView *userResizableView = [[SPUserResizableView alloc] initWithFrame:gripFrame];
    UILabel *label = [[UILabel alloc] initWithFrame:gripFrame];
    label.textAlignment = UITextAlignmentCenter;
    label.text = @"This is a test quote.";
    label.numberOfLines = 0;
    label.font = [UIFont fontWithName:@"Georgia" size:17.0];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    userResizableView.contentView = label;
    userResizableView.delegate = self;
    [resizableArea addSubview:userResizableView];
    quoteTextLabel = label;
    quoteTextView = userResizableView;
    
    gripFrame = CGRectMake(40, 220, 200, 20);
    userResizableView = [[SPUserResizableView alloc] initWithFrame:gripFrame];
    label = [[UILabel alloc] initWithFrame:gripFrame];
    label.textAlignment = UITextAlignmentCenter;
    label.text = @"Source label.";
    label.numberOfLines = 0;
    label.font = [UIFont fontWithName:@"Georgia" size:17.0];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    userResizableView.contentView = label;
    userResizableView.delegate = self;
    [self addSubview:userResizableView];
    quoteSourceLabel = label;
    quoteSourceView = userResizableView;
    
    self.clipsToBounds = YES;
    
    loadingImageView = [[UIImageView alloc] initWithFrame:subviewRect];
    loadingImageView.animationImages = [NSArray arrayWithObjects:    
                                        [UIImage imageNamed:@"photo1"],
                                        [UIImage imageNamed:@"photo2"],
                                        [UIImage imageNamed:@"photo3"],
                                        [UIImage imageNamed:@"photo4"], nil];
    loadingImageView.animationDuration = 1.0f;
    loadingImageView.animationRepeatCount = 0;
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissEditingHandles)];
    [gestureRecognizer setDelegate:self];
    [self addGestureRecognizer:gestureRecognizer];
    [gestureRecognizer release];
    
    [quoteTextView showEditingHandles]; // Initilaze with editing ON.
    currentlyEditingView = quoteTextView;
    lastEditedView = quoteTextView;
}

- (void)setQuoteSource:(NSDictionary *)quoteSourceIn {
    if (quoteSourceIn != quoteSource) {
        if (!!brickView) {
            [self commonBrickRemoval]; // Get rid of the brick if it was showing.
        }
        
        [quoteSource release];
        quoteSource = [quoteSourceIn retain];
        quoteSourceLabel.text = [quoteSource objectForKey:QISourceEntityNameKey];
        
        [quoteSourceLabel sizeToFit];
        CGRect sizedFrame = [quoteSourceLabel frame];
        
        CGRect boundingBoxFrame = quoteSourceView.frame;
        boundingBoxFrame.size = CGSizeMake(sizedFrame.size.width + 40, sizedFrame.size.height + 40);
        quoteSourceView.frame = boundingBoxFrame;
    }
}

- (void)setQuoteText:(NSString *)quoteTextIn {
    if (quoteText != quoteTextIn) {
        [quoteText release];
        quoteText = [quoteTextIn retain];
        quoteTextLabel.text = quoteText;
        [quoteTextLabel sizeToFit];
        CGRect sizedFrame = [quoteTextLabel frame];

        CGRect boundingBoxFrame = quoteTextView.frame;
        boundingBoxFrame.size = CGSizeMake(sizedFrame.size.width + 40, sizedFrame.size.height + 40);
        quoteTextView.frame = boundingBoxFrame;
    }
}

- (void)startLoading {
    [self addSubview:loadingImageView];
    [loadingImageView startAnimating];
}

- (void)stopLoading {
    [loadingImageView removeFromSuperview];
    [loadingImageView stopAnimating];
}

- (void)hideEditingHandles {
    [quoteTextView hideEditingHandles];
    [quoteSourceView hideEditingHandles];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self initializeSubviews];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self initializeSubviews];
    }
    return self;
}

- (void)setDelegate:(id<QIQuoteEditorViewDelegate>)delegateIn {
    delegate = delegateIn;
    if ([delegate respondsToSelector:@selector(quoteEditorDidSelectResizableView:)]) {
        [delegate quoteEditorDidSelectResizableView:currentlyEditingView];
    }
}

- (void)removeBrickFromPhoto {
    [brickView removeFromSuperview];
    [brickView release];
    brickView = nil;
    
    CGRect subviewRect = CGRectZero;
    subviewRect.size = self.frame.size;
    resizableArea.frame = subviewRect;
}

- (void)commonBrickRemoval {
    [currentlyEditingView hideEditingHandles];
    [self removeBrickFromPhoto];
    
    //quoteSourceView.center = finalLocation;
    
    /*if ([quoteSourceView frame].origin.y + [quoteSourceView frame].size.height >= (self.frame.size.height)) {
     CGPoint center = quoteSourceView.center;
     // Shift up until the view isn't below the quote view boundary.
     center.y -= (([quoteSourceView frame].origin.y + [quoteSourceView frame].size.height) - self.frame.size.height);
     quoteSourceView.center = center;
     }*/
    
    [quoteSourceView showEditingHandles];
    currentlyEditingView = quoteSourceView;
    quoteSourceView.isShowingBrick = NO;
    
    // Frame change *must* come after isShowingBrick is set to NO.
    quoteSourceView.frame = preBrickSourceFrame;
    quoteSourceView.contentView.hidden = NO;
}

- (void)brickViewWasDraggedUpwards:(SPUserResizableView *)brickView finalLocation:(CGPoint)finalLocation {
    [self commonBrickRemoval];
    if ([delegate respondsToSelector:@selector(quoteEditorDidSelectResizableView:)]) {
        [delegate quoteEditorDidSelectResizableView:quoteSourceView];
    }
}

- (void)addBrickToPhoto {
    if (!brickView) {
        brickView = [[QIQuoteEditorBrickView alloc] initWithFrame:CGRectMake(0, 248, 288, 47)];
        
        UIImageView *brickBackground = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 288, 47)];
        brickBackground.image = [UIImage imageNamed:@"source_container"];
        [brickView addSubview:brickBackground];
        [brickBackground release];
        
        UIImageView *sourceImage = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 27, 27)];
        QIConfigureImageWell(sourceImage);
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[quoteSource objectForKey:QISourceEntityPhotoURLKey]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
        [request setHTTPShouldHandleCookies:NO];
        [request setHTTPShouldUsePipelining:YES];
        
        [sourceImage setImageWithURLRequest:request placeholderImage:[QIUtilities userPlaceholderImage] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            if ([[quoteSource objectForKey:QISourceEntityTypeKey] isEqualToString:QISourceEntityTypePage]) {
                [sourceImage setImage:[UIImage scale:image toFillSize:sourceImage.frame.size]];
            }
        } failure:nil];
        
        [brickView addSubview:sourceImage];
        [sourceImage release];
        
        UILabel *sourceLabel = [[UILabel alloc] initWithFrame:CGRectMake(47, 10, 200, 27)];
        sourceLabel.backgroundColor = [UIColor clearColor];
        sourceLabel.text = [quoteSource objectForKey:QISourceEntityNameKey];
        sourceLabel.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        sourceLabel.textColor = [QIUtilities brickSourceLabelColor];
        sourceLabel.font = [UIFont fontWithName:@"Georgia-Italic" size:16.0];
        [brickView addSubview:sourceLabel];
        [sourceLabel release];
        
        /*UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(47, 4, 200, 27)];
        infoLabel.backgroundColor = [UIColor clearColor];
        infoLabel.text = @"Source:";
        infoLabel.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        infoLabel.textColor = [QIUtilities brickInfoLabelColor];
        infoLabel.font = [UIFont fontWithName:@"Georgia" size:10.0];
        [brickView addSubview:infoLabel];
        [infoLabel release];*/

        brickView.eventForwardingView = quoteSourceView;
        [self addSubview:brickView];
        
        preBrickSourceFrame = quoteSourceView.frame;
        resizableArea.frame = CGRectMake(0, 0, 288, 248);
        
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents]; // Cancel the drag operation on the resizable view.
        //[UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationCurveEaseOut animations:^{
            quoteSourceView.frame = CGRectMake(quoteSourceView.frame.origin.x, 288, quoteSourceView.frame.size.width, quoteSourceView.frame.size.height);
        //} completion:^(BOOL completion) {}];
        
        didJustAddBrick = YES;
        quoteSourceView.isShowingBrick = YES;
        
        if ([delegate respondsToSelector:@selector(quoteEditorDidDismissResizableView:)]) {
            [delegate quoteEditorDidDismissResizableView:quoteSourceView];
        }
    }
}

#pragma mark -
#pragma mark SPUserResizableViewDelegate methods

- (void)userResizableViewDidBeginEditing:(SPUserResizableView *)userResizableView {
    [currentlyEditingView hideEditingHandles];
    currentlyEditingView = userResizableView;
    
    if ([delegate respondsToSelector:@selector(quoteEditorDidSelectResizableView:)]) {
        [delegate quoteEditorDidSelectResizableView:userResizableView];
    }
}

- (void)userResizableViewDidEndEditing:(SPUserResizableView *)userResizableView {
    if (didJustAddBrick) {
        [[UIApplication sharedApplication] endIgnoringInteractionEvents]; // Resume perception of touch events.
        quoteSourceView.contentView.hidden = YES;
        quoteSourceView.frame = CGRectMake(0, 248, 288, 47);
        didJustAddBrick = NO;
    }
    lastEditedView = userResizableView;
}

- (void)userResizableViewDidTranslate:(SPUserResizableView *)userResizableView {
    if (userResizableView != quoteSourceView) {
        return;
    }
    if ([userResizableView frame].origin.y + [userResizableView frame].size.height >= (self.frame.size.height)) {
        if (++brickGestureCount > 15) {
            [self addBrickToPhoto];
        }
    } else {
        brickGestureCount = 0;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (!self.userInteractionEnabled) {
        return NO;
    }
    if ([currentlyEditingView hitTest:[touch locationInView:currentlyEditingView] withEvent:nil]) {
        return NO;
    }
    return YES;
}

- (void)dismissEditingHandles {
    // We only want the gesture recognizer to end the editing session on the last
    // edited view. We wouldn't want to dismiss an editing session in progress.
    [lastEditedView hideEditingHandles];
    if ([delegate respondsToSelector:@selector(quoteEditorDidDismissResizableView:)]) {
        [delegate quoteEditorDidDismissResizableView:lastEditedView];
    }
}

- (void)dealloc {
    [quoteSourceLabel release];
    [quoteTextLabel release];
    [quoteTextView release];
    [quoteSourceView release];
    [super dealloc];
}


- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *result = [super hitTest:point withEvent:event];
    BOOL foundInteractiveView = NO;
    if (!quoteTextView.hidden && [quoteTextView pointInside:[quoteTextView convertPoint:point fromView:self] withEvent:event]) {
        foundInteractiveView = YES;
    }
    if (!quoteSourceView.hidden && [quoteSourceView pointInside:[quoteSourceView convertPoint:point fromView:self] withEvent:event]) {
        foundInteractiveView = YES;
    }
    if (!brickView.hidden && [brickView pointInside:[brickView convertPoint:point fromView:self] withEvent:event]) {
        foundInteractiveView = YES;
    }
    if (!foundInteractiveView) {
        result = backingScrollView;
    }
    return result;
}

@end
