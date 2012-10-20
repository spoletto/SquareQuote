//
//  DEHTTPRequest.m
//  unoffical-twitter-sdk
//
//  Copyright (c) 2011 Double Encore Inc. All rights reserved.
//
//  A quick class that mimics ASIHTTPRequest
//  Warning! This is not a full ASIHTTPRequest replacement.
//  It only does what is necessary to authenticate with Twitter.
//
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//  Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer 
//  in the documentation and/or other materials provided with the distribution. Neither the name of the Double Encore Inc. nor the names of its 
//  contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
//  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS 
//  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE 
//  GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
//  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "DEHTTPRequest.h"

@interface DEHTTPRequest ()
@property (nonatomic, retain) NSMutableDictionary *requestHeaders;
@property (nonatomic) BOOL requestFinished;
@end

@implementation DEHTTPRequest

@synthesize url = _url;
@synthesize requestMethod = _requestMethod;
@synthesize requestHeaders = _requestHeaders;
@synthesize error = _error;
@synthesize responseStatusCode = _responseStatusCode;
@synthesize responseStatusMessage = _responseStatusMessage;
@synthesize responseString = _responseString;
@synthesize responseData = _responseData;
@synthesize urlConnection = _urlConnection;
@synthesize requestFinished = _requestFinished;


- (void)dealloc {
    [_url release], _url = nil;
    [_requestMethod release], _requestMethod = nil;
    [_requestHeaders release], _requestHeaders = nil;
    [_error release], _error = nil;
    [_responseStatusMessage release], _responseStatusMessage = nil;
    [_responseString release], _responseString = nil;
    [_responseData release], _responseData = nil;
    [_urlConnection cancel];
    [_urlConnection release], _urlConnection = nil;
    [super dealloc];
}


- (id)initWithURL:(NSURL *)newURL
{
    self = [super init];
    if (self) {
        _url = [newURL retain];
        _requestFinished = NO;
    }
    return self;
}


- (void)addRequestHeader:(NSString *)header value:(NSString *)value
{
    if (!self.requestHeaders) {
		self.requestHeaders = [NSMutableDictionary dictionary];
	}
    
	[self.requestHeaders setObject:value forKey:header];
}


- (void)startSynchronous
{
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:self.url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    urlRequest.HTTPMethod = self.requestMethod;
    
    [self.requestHeaders enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [urlRequest setValue:obj forHTTPHeaderField:key];
    }];
    
    if ([NSURLConnection canHandleRequest:urlRequest]) {
        self.urlConnection = [NSURLConnection connectionWithRequest:urlRequest delegate:self];
        [self.urlConnection start];
    }
    else {
        self.error = [NSError errorWithDomain:@"com.doubleencore.DEHTTPRequest" code:1 userInfo:nil];
    }
    
    while (self.requestFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

#pragma mark - Class methods

+ (id)requestWithURL:(NSURL *)newURL;
{
    return [[[self alloc] initWithURL:newURL] autorelease];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.error = error;
}


#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    self.responseStatusCode = [response statusCode];
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (!self.responseData) {
        self.responseData = [NSMutableData dataWithData:data];
    }
    else {
        [self.responseData appendData:data];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    self.responseString = [[[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding] autorelease];
    self.requestFinished = YES;
}

@end
