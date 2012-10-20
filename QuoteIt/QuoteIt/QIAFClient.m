//
//  QIAFClient.m
//  QuoteIt
//
//  Created by Stephen Poletto on 12/29/11.
//  Copyright (c) 2011 QuoteIt. All rights reserved.
//

#import "AFJSONRequestOperation.h"
#import "QIUtilities.h"
#import "QIAFClient.h"

@implementation QIAFClient

+ (QIAFClient *)sharedClient {
    static QIAFClient *sharedClient = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:QIBaseURL]];
    });
    
    return sharedClient;
}

+ (AFHTTPClient *)sharedTumblrClient {
    static AFHTTPClient *sharedTumblrClient = nil;
    static dispatch_once_t onceTumblrPredicate;
    dispatch_once(&onceTumblrPredicate, ^{
        sharedTumblrClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:@"http://www.tumblr.com/"]];
    });
    
    return sharedTumblrClient;
}

+ (AFHTTPClient *)sharedFacebookClient {
    static AFHTTPClient *sharedFacebookClient = nil;
    static dispatch_once_t onceFacebookPredicate;
    dispatch_once(&onceFacebookPredicate, ^{
        sharedFacebookClient = [[AFHTTPClient alloc] initWithBaseURL:nil];
        [sharedFacebookClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [sharedFacebookClient setDefaultHeader:@"Accept" value:@"application/json"];
    });
    
    return sharedFacebookClient;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
	[self setDefaultHeader:@"Accept" value:@"application/json"];
    
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    [self setDefaultHeader:@"X-AppVersion" value:appVersion];
	
    return self;
}

@end
