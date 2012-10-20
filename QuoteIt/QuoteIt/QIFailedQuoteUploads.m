//
//  QIFailedQuoteUploads.m
//  QuoteIt
//
//  Created by Stephen Poletto on 3/17/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

#import <Parse/Parse.h>

#import "UIImageView+AFNetworking.h"
#import "QIFailedQuoteUploads.h"
#import "QICoreDataManager.h"
#import "QIUtilities.h"
#import "QIAFClient.h"
#import "QIUser.h"

NSString * const QIFailedQuoteUploadsWillUpdateFailedQuotes = @"QIFailedQuoteUploadsWillUpdateFailedQuotes";
NSString * const QIFailedQuoteUploadsDidUpdateFailedQuotes = @"QIFailedQuoteUploadsDidUpdateFailedQuotes";

@implementation QIFailedQuoteUploads
@synthesize currentlyRetrying;

- (NSString *)persistedQuotesPath {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return [path stringByAppendingPathComponent:@"QIQuoteFailed_Quotes.dat"];
}

- (void)persistQuotesToDisk:(NSMutableArray *)quotes {
    [NSKeyedArchiver archiveRootObject:quotes toFile:[self persistedQuotesPath]];
}

- (NSMutableArray *)loadPersistedQuotes {
    return [NSKeyedUnarchiver unarchiveObjectWithFile:[self persistedQuotesPath]];
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

- (void)retryUploads {
    if (self.currentlyRetrying || ![failedQuotes count]) {
        return;
    }
    
    NSInteger failedQuoteCount = [failedQuotes count];
    __block NSInteger attemptedAgainCount = 0;
    
    self.currentlyRetrying = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:QIFailedQuoteUploadsWillUpdateFailedQuotes object:nil];
    for (NSDictionary *quote in failedQuotes) {
        
        NSMutableURLRequest *request = [[QIAFClient sharedClient] multipartFormRequestWithMethod:@"POST" path:@"/api/submit_quote" parameters:[quote objectForKey:@"quote"] constructingBodyWithBlock: ^(id <AFMultipartFormData> formData) {
            [formData appendPartWithFileData:[quote objectForKey:@"imageData"] name:@"quote_photo" fileName:@"quote.jpg" mimeType:@"image/jpeg"];
        }];
        
        AFHTTPRequestOperation *operation = [[QIAFClient sharedClient] HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id jsonObject) {
            attemptedAgainCount++;
            if ([[jsonObject valueForKey:@"status"] isEqualToString:@"ok"]) {
                // Update the core data cache of my quotes
                // Don't do this until the upload is complete so the new quote is in there!
                [[QICoreDataManager sharedDataManger] loadMyQuotes];
                
                [self sendPushNotification:[quote objectForKey:quote]];
                
                [failedQuotes removeObject:quote];
                [self persistQuotesToDisk:failedQuotes];
            }
            if (attemptedAgainCount == failedQuoteCount) {
                self.currentlyRetrying = NO;
                [[NSNotificationCenter defaultCenter] postNotificationName:QIFailedQuoteUploadsDidUpdateFailedQuotes object:nil];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            // Already in the queue.
            attemptedAgainCount++;
            if (attemptedAgainCount == failedQuoteCount) {
                self.currentlyRetrying = NO;
                [[NSNotificationCenter defaultCenter] postNotificationName:QIFailedQuoteUploadsDidUpdateFailedQuotes object:nil];
            }
        }];
        [operation setUploadProgressBlock:^(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite) {}];
        [operation start];
    }
}

- (void)didBecomeActive:(NSNotification *)notification {
    // Retry uploading quotes whenever application becomes active.
    [self retryUploads];
}

- (void)enqueueFailedQuote:(NSDictionary *)quote withImageData:(NSData *)imageData {
    NSDictionary *quoteWithImageData = [NSDictionary dictionaryWithObjectsAndKeys:quote, @"quote", imageData, @"imageData", nil];
    
    [failedQuotes addObject:quoteWithImageData];
    [self persistQuotesToDisk:failedQuotes];
    [[NSNotificationCenter defaultCenter] postNotificationName:QIFailedQuoteUploadsDidUpdateFailedQuotes object:nil];
}

- (NSArray *)failedQuotes {
    return failedQuotes;
}

- (id)init {
    self = [super init];
    if (self) {
        failedQuotes = [[self loadPersistedQuotes] retain];
        if (!failedQuotes) {
            failedQuotes = [[NSMutableArray alloc] init];
        }
        [self retryUploads];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

+ (QIFailedQuoteUploads *)sharedFailedQuotes {
    static QIFailedQuoteUploads *sharedFailedQuotes = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        sharedFailedQuotes = [[self alloc] init];
    });
    return sharedFailedQuotes;
}

@end
