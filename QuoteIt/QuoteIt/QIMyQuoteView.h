//
//  QIMyQuoteView.h
//  QuoteIt
//
//  Created by Stephen Poletto on 3/6/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QIQuote, QIMyQuoteView;

@interface QIMyQuoteViewUIView : UIView
@property (retain, nonatomic) QIMyQuoteView *backpointedMyQuote;
@end

@interface QIMyQuoteView : NSObject

@property (retain, nonatomic) IBOutlet QIMyQuoteViewUIView *view;
@property (retain, nonatomic) IBOutlet UIImageView *quoteView;
@property (retain, nonatomic) IBOutlet UILabel *sourceLabel;
@property (retain, nonatomic) IBOutlet UILabel *sourceNameLabel;
@property (retain, nonatomic) IBOutlet UILabel *viewCountLabel;
@property (retain, nonatomic) IBOutlet UIImageView *eyeIcon;
@property (retain, nonatomic) IBOutlet UIImageView *arrowIcon;
@property (retain, nonatomic) IBOutlet UILabel *failedToUploadQuoteLabel;
@property (retain, nonatomic) IBOutlet UIButton *retryUploadButton;

// Set one or the other.
@property (retain, nonatomic) QIQuote *quote;
@property (retain, nonatomic) NSDictionary *failedQuote;

@end
