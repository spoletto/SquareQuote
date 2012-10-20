//
//  QIMyQuoteView.m
//  QuoteIt
//
//  Created by Stephen Poletto on 3/6/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "UIImageView+AFNetworking.h"
#import "QIFailedQuoteUploads.h"
#import "QIMyQuoteView.h"
#import "QIUtilities.h"
#import "QIQuote.h"
#import "QIUser.h"

@implementation QIMyQuoteViewUIView
@synthesize backpointedMyQuote;
@end

@implementation QIMyQuoteView
@synthesize view;
@synthesize quoteView;
@synthesize sourceLabel;
@synthesize sourceNameLabel;
@synthesize viewCountLabel;
@synthesize eyeIcon;
@synthesize arrowIcon;
@synthesize failedToUploadQuoteLabel;
@synthesize retryUploadButton;
@synthesize quote;
@synthesize failedQuote;

- (id)init {
    self = [super init];
    if (self) {
        [[NSBundle mainBundle] loadNibNamed:@"QIMyQuoteView" owner:self options:nil];
        view.backgroundColor = [UIColor clearColor];
        view.backpointedMyQuote = self;
        
        quoteView.layer.cornerRadius = 3.0;
        quoteView.layer.masksToBounds = YES;
        sourceLabel.textColor = [QIUtilities myQuotesSourceLabelColor];
        sourceNameLabel.textColor = [QIUtilities myQuotesSourceLabelColor];
        viewCountLabel.textColor = [QIUtilities myQuotesViewsLabelColor];
        
        [self.retryUploadButton setImage:[UIImage imageNamed:@"btn_retry_press"] forState:UIControlStateHighlighted];
    }
    return self;
}

- (void)loadImage {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[quote photoURL]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
    [request setHTTPShouldHandleCookies:NO];
    [request setHTTPShouldUsePipelining:YES];
    
    [self.quoteView setImageWithURLRequest:request placeholderImage:[UIImage imageNamed:@"placeholder_myquotes"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        // Scale the image to fit nicely in the table view cell.
        //[self.quoteView setImage:[UIImage scale:image toFillSize:CGSizeMake(72.0, 72.0)]];
    } failure:nil];
}

// If either of these setters do the if (quoteIn != quote) trick,
// they need to keep track of whether they're displaying a quote or 
// a failed quote, so the don't step on each other's toes.
// Easier just not to do it, I think.
- (void)setQuote:(QIQuote *)quoteIn {
    [quote release];
    quote = [quoteIn retain];
    if ([[[quote source] type] isEqualToString:@"user"]) {
        sourceNameLabel.text = QIFullNameForUser(quote.source);
    } else if ([[[quote source] type] isEqualToString:@"fb-graph"]) {
        sourceNameLabel.text = quote.source.name;
    }
    viewCountLabel.text = [NSString stringWithFormat:@"%d", [quote.viewCount integerValue]];
    
    [self loadImage];
    self.failedToUploadQuoteLabel.hidden = YES;
    self.sourceLabel.hidden = NO;
    self.sourceNameLabel.hidden = NO;
    self.viewCountLabel.hidden = NO;
    self.eyeIcon.hidden = NO;
    self.arrowIcon.hidden = NO;
    self.retryUploadButton.hidden = YES;
}

- (void)setFailedQuote:(NSDictionary *)failedQuoteIn {
    [failedQuote release];
    failedQuote = [failedQuoteIn retain];
    
    sourceNameLabel.text = [[failedQuote objectForKey:@"quote"] objectForKey:@"source_name"];
    // Cancel old image request, since we may be reusing the view.
    [self.quoteView cancelImageRequestOperation];
    self.quoteView.image = [UIImage imageWithData:[failedQuote objectForKey:@"imageData"]];
    self.failedToUploadQuoteLabel.hidden = NO;
    self.sourceLabel.hidden = YES;
    self.sourceNameLabel.hidden = YES;
    self.viewCountLabel.hidden = YES;
    self.eyeIcon.hidden = YES;
    self.arrowIcon.hidden = YES;
    self.retryUploadButton.hidden = NO;
}

- (IBAction)retryUpload:(id)sender {
    // Just try reuploading all of them.
    [[QIFailedQuoteUploads sharedFailedQuotes] retryUploads];
}

- (void)dealloc {
    [quoteView release];
    [view release];
    [sourceLabel release];
    [sourceNameLabel release];
    [viewCountLabel release];
    [eyeIcon release];
    [arrowIcon release];
    [failedToUploadQuoteLabel release];
    [retryUploadButton release];
    [super dealloc];
}

@end
