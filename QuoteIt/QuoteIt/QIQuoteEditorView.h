//
//  QIQuoteEditorView.h
//  QuoteIt
//
//  Created by Stephen Poletto on 1/2/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

// If you're reading this source code, I'm sorry.
// The quote editor is a shitshow, due mostly to a complex view
// heirarchy and my hacking of the responder chain to get the
// brick to work.
// spoletto:2-14-2012

#import "SPUserResizableView.h"

@class SPStrokedLabel;
@protocol QIQuoteEditorBrickViewDelegate;
@protocol QIQuoteEditorViewDelegate;

@interface QIQuoteEditorBrickView : UIView
@property (nonatomic, assign) UIView *eventForwardingView;
@end

@interface QIQuoteEditorView : UIView <SPUserResizableViewDelegate, UIGestureRecognizerDelegate> {
    SPUserResizableView *currentlyEditingView;
    SPUserResizableView *lastEditedView;
    SPUserResizableView *quoteSourceView;
    SPUserResizableView *quoteTextView;
    
    UILabel *quoteSourceLabel;
    UILabel *quoteTextLabel;
    //SPStrokedLabel *quoteSourceLabel;
    //SPStrokedLabel *quoteTextLabel;
    
    UIView *resizableArea;
    QIQuoteEditorBrickView *brickView;    
    NSInteger brickGestureCount;
    
    CGRect preBrickSourceFrame;
    BOOL didJustAddBrick;
    
    UIImageView *loadingImageView;
}

@property (retain, nonatomic) UIScrollView *backingScrollView;
@property (retain, nonatomic) UIImageView *quoteImageView;
@property (retain, nonatomic) UIView *editorContainerView;

@property (copy, nonatomic) NSString *quoteText;
@property (retain, nonatomic) NSDictionary *quoteSource;

@property (assign, nonatomic) id <QIQuoteEditorViewDelegate> delegate;

- (void)startLoading;
- (void)stopLoading;
- (void)hideEditingHandles;

@end

@protocol QIQuoteEditorViewDelegate <NSObject>

@optional
- (void)quoteEditorDidSelectResizableView:(SPUserResizableView *)view;
- (void)quoteEditorDidDismissResizableView:(SPUserResizableView *)view;

@end
