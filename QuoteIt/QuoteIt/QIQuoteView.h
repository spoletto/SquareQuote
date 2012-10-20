//
//  QIQuoteView.h
//  QuoteIt
//
//  Created by Stephen Poletto on 12/30/11.
//  Copyright (c) 2011 QuoteIt. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QIQuoteViewer;

@interface QIQuoteView : UIView {
    UIImageView *loadingQuoteView;
    UIImageView *secondaryView; // Back of the quote.
    UIView *backOfQuoteMask;
    BOOL loading;
    BOOL quoteFlipped; // YES if back of quote is showing.
    
    UIButton *deleteQuoteButton;
    UIButton *flagQuoteButton;
    
    UITapGestureRecognizer *doubleTapQuoteRecognizer;
    UILongPressGestureRecognizer *longPress;
}

@property (nonatomic, assign) QIQuoteViewer *quoteViewerBackpointer;
@property (nonatomic, retain, readonly) UIImageView *imageView;
@property (nonatomic, retain) NSDictionary *quote;
@property (nonatomic) BOOL showsDeleteButton;
@property (nonatomic) BOOL showsFlagButton;
@property (nonatomic) BOOL hasGestureRecognizers;

- (void)startLoading;
- (void)stopLoading;
- (void)showFrontOfQuote; // Stop showing the back, if we were.

extern CGSize const QIQuoteViewInset;

@end
