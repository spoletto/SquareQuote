//
//  QIFailedQuoteUploads.h
//  QuoteIt
//
//  Created by Stephen Poletto on 3/17/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

extern NSString * const QIFailedQuoteUploadsWillUpdateFailedQuotes;
extern NSString * const QIFailedQuoteUploadsDidUpdateFailedQuotes;

@interface QIFailedQuoteUploads : NSObject {
    NSMutableArray *failedQuotes;
}

@property (atomic) BOOL currentlyRetrying;

+ (QIFailedQuoteUploads *)sharedFailedQuotes;
- (void)enqueueFailedQuote:(NSDictionary *)quote withImageData:(NSData *)imageData;
- (NSArray *)failedQuotes;
- (void)retryUploads;

@end
