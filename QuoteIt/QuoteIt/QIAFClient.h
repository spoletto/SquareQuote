//
//  QIAFClient.h
//  QuoteIt
//
//  Created by Stephen Poletto on 12/29/11.
//  Copyright (c) 2011 QuoteIt. All rights reserved.
//

#import "AFHTTPClient.h"

@interface QIAFClient : AFHTTPClient

+ (QIAFClient *)sharedClient;
+ (AFHTTPClient *)sharedTumblrClient;
+ (AFHTTPClient *)sharedFacebookClient;

@end
