//
//  OAuth.m
//
//  Created by Jaanus Kase on 12.01.10.
//  Copyright 2010. All rights reserved.
//

#import "OAuth.h"
#include <CommonCrypto/CommonDigest.h>
#import "OAHMAC_SHA1SignatureProvider.h"
#import "NSString+URLEncoding.h"
#import "OAuthTwitterCallbacks.h"
#import "DEHTTPRequest.h"

@implementation OAuth

@synthesize oauth_token;
@synthesize oauth_token_secret;
@synthesize oauth_token_authorized;
@synthesize delegate;
@synthesize user_id;
@synthesize screen_name;

#pragma mark -
#pragma mark Init and dealloc

/**
 * Initialize an OAuth context object with a given consumer key and secret. These are immutable as you
 * always work in the context of one app.
 */
- (id) initWithConsumerKey:(NSString *)aConsumerKey andConsumerSecret:(NSString *)aConsumerSecret {
	if ((self = [super init])) {
		oauth_consumer_key = [aConsumerKey copy];
		oauth_consumer_secret = [aConsumerSecret copy];
		oauth_signature_method = @"HMAC-SHA1";
		oauth_version = @"1.0";
		self.oauth_token = @"";
		self.oauth_token_secret = @"";
		srandom(time(NULL)); // seed the random number generator, used for generating nonces
		self.oauth_token_authorized = NO;
		self.delegate = nil;
		self.user_id = @"";
		self.screen_name = @"";
	}
	
	return self;
}

- (void) dealloc {
	[oauth_consumer_key release];
	[oauth_consumer_secret release];
	[oauth_token release];
	[oauth_token_secret release];
	[user_id release];
	[screen_name release];
	[super dealloc];
}

#pragma mark -
#pragma mark KVC

/**
 * We specify a set of keys that are known to be returned from OAuth responses, but that we are not interested in.
 * In case of any other keys, we log them since they may indicate changes in API that we are not prepared
 * to deal with, but we continue nevertheless.
 * This is only relevant for the Twitter request/authorize convenience methods that do HTTP calls and parse responses.
 */
- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
	// KVC: define a set of keys that are known but that we are not interested in. Just ignore them.
	if ([[NSSet setWithObjects:
		  @"oauth_callback_confirmed",
		  nil] containsObject:key]) {
		
	// ... but if we got a new key that is not known, log it.
	} else {
		NSLog(@"Got unknown key from provider response. Key: \"%@\", value: \"%@\"", key, value);
	}
}

#pragma mark -
#pragma mark Public methods

/**
 * You will be calling this most of the time in your app, after the bootstrapping (authorization) is complete. You pass it
 * a set of information about your HTTP request (HTTP method, URL and any extra parameters), and you get back a header value
 * that you can put in the "Authorization" header. The header will also include a signature.
 *
 * "params" should be NSDictionary with any extra material to add in the signature. If you are doing a POST request,
 * this needs to exactly match what you will be POSTing. If you are GETting, this should include the parameters in your
 * QUERY_STRING; if there are none, this is nil.
 */
- (NSString *) oAuthHeaderForMethod:(NSString *)method andUrl:(NSString *)url andParams:(NSDictionary *)params {
	return [self oAuthHeaderForMethod:method 
							   andUrl:url
							andParams:params
					   andTokenSecret:self.oauth_token_authorized ? oauth_token_secret : @""];
}

/**
 * An extra method that lets the caller override the token secret used to sign the header. This is determined automatically
 * most of the time based on if our token has been authorized or not and you can use the method without the extra parameter,
 * but we need to override it for our /authorize request because our token has not been authorized by this point,
 * yet we still need to sign our /authorize request with both consumer and token secrets.
 */
- (NSString *) oAuthHeaderForMethod:(NSString *)method
							 andUrl:(NSString *)url
						  andParams:(NSDictionary *)params
					 andTokenSecret:(NSString *)token_secret {

	OAHMAC_SHA1SignatureProvider *sigProvider = [[OAHMAC_SHA1SignatureProvider alloc] init];
	
	// If there were any params, URLencode them.
	NSMutableDictionary *_params = [NSMutableDictionary dictionaryWithCapacity:[params count]];
	if (params) {
		for (NSString *key in [params allKeys]) {
			[_params setObject:[[params objectForKey:key] encodedURLParameterString] forKey:key];
		}
	}
    
	// Given a signature base and secret key, calculate the signature.
	NSString *oauth_signature = [sigProvider
								 signClearText:[self oauth_signature_base:method
																  withUrl:url
																andParams:_params]
								 withSecret:[NSString stringWithFormat:@"%@&%@", oauth_consumer_secret, token_secret]];
	[sigProvider release];
	
	// Return the authorization header using the signature and parameters (if any).
	return [self oauth_authorization_header:oauth_signature withParams:_params];
}

/**
 * When the user invokes the "sign out" function in the app, forget the current OAuth context.
 * We still remember consumer key and secret
 * since those are for an app and don't change, but we forget everything else.
 */
- (void) forget {
	self.oauth_token_authorized = NO;
	self.oauth_token = @"";
	self.oauth_token_secret = @"";
	self.user_id = @"";
	self.screen_name = @"";
}

- (NSString *) description {
	return [NSString stringWithFormat:@"OAuth context object with consumer key \"%@\", token \"%@\". Authorized: %@",
			oauth_consumer_key, self.oauth_token, self.oauth_token_authorized ? @"YES" : @"NO"]; 
}

#pragma mark -
#pragma mark Twitter convenience methods

/**
 * Given a request URL, request an unauthorized OAuth token from that URL. This starts
 * the process of getting permission from user. This is done synchronously. If you want
 * threading, do your own.
 *
 * This is the request/response specified in OAuth Core 1.0A section 6.1.
 */
- (void) synchronousRequestTwitterTokenWithCallbackUrl:(NSString *)callbackUrl {
   	NSString *url = @"https://api.twitter.com/oauth/request_token";
	
	// Invalidate the previous request token, whether it was authorized or not.
	self.oauth_token_authorized = NO; // We are invalidating whatever token we had before.
	self.oauth_token = @"";
	self.oauth_token_secret = @"";
	
	// Calculate the header.
    
    // Guard against someone forgetting to set the callback. Pretend that we have out-of-band request
    // in that case.
    NSString *_callbackUrl = callbackUrl;
    if (!callbackUrl) {
        _callbackUrl = @"oob";
    }
    NSDictionary *params = [NSDictionary dictionaryWithObject:_callbackUrl forKey:@"oauth_callback"];
	NSString *oauth_header = [self oAuthHeaderForMethod:@"POST" andUrl:url andParams:params];
	
	// Synchronously perform the HTTP request.
	DEHTTPRequest *request = [DEHTTPRequest requestWithURL:[NSURL URLWithString:url]];
	request.requestMethod = @"POST";
	[request addRequestHeader:@"Authorization" value:oauth_header];
	[request startSynchronous];
	
	if ([request error]) {
		if ([self.delegate respondsToSelector:@selector(requestTwitterTokenDidFail:)]) {
			[delegate requestTwitterTokenDidFail:self];
		}
	} else {
		NSArray *responseBodyComponents = [[request responseString] componentsSeparatedByString:@"&"];
		// For a successful response, break the response down into pieces and set the properties
		// with KVC. If there's a response for which there is no local property or ivar, this
		// may end up with setValue:forUndefinedKey:.
		for (NSString *component in responseBodyComponents) {
			NSArray *subComponents = [component componentsSeparatedByString:@"="];
			[self setValue:[subComponents objectAtIndex:1] forKey:[subComponents objectAtIndex:0]];			
		}
		if ([self.delegate respondsToSelector:@selector(requestTwitterTokenDidSucceed:)]) {
			[delegate requestTwitterTokenDidSucceed:self];
		}
	} 
}


/**
 * By this point, we have a token, and we have a verifier such as PIN from the user. We combine
 * these together and exchange the unauthorized token for a new, authorized one.
 *
 * This is the request/response specified in OAuth Core 1.0A section 6.3.
 */
- (void) synchronousAuthorizeTwitterTokenWithVerifier:(NSString *)oauth_verifier {
	
	NSString *url = @"https://api.twitter.com/oauth/access_token";
	
	// We manually specify the token as a param, because it has not yet been authorized
	// and the automatic state checking wouldn't include it in signature construction or header,
	// since oauth_token_authorized is still NO by this point.
	NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
							oauth_token, @"oauth_token",
							oauth_verifier, @"oauth_verifier",
							nil];
	
	NSString *oauth_header = [self oAuthHeaderForMethod:@"POST" andUrl:url andParams:params andTokenSecret:oauth_token_secret];

	DEHTTPRequest *request = [DEHTTPRequest requestWithURL:[NSURL URLWithString:url]];
	request.requestMethod = @"POST";
	[request addRequestHeader:@"Authorization" value:oauth_header];
	[request startSynchronous];
	
	if ([request error]) {
        
        NSLog(@"HTTP return code for token authorization error: %d, message: %@, string: %@", request.responseStatusCode, request.responseStatusMessage, request.responseString);
        NSLog(@"OAuth header was: %@", oauth_header);
        
		if ([self.delegate respondsToSelector:@selector(authorizeTwitterTokenDidFail:)]) {
			[delegate authorizeTwitterTokenDidFail:self];
		}
	} else {
		NSArray *responseBodyComponents = [[request responseString] componentsSeparatedByString:@"&"];
		for (NSString *component in responseBodyComponents) {
			// Twitter as of January 2010 returns oauth_token, oauth_token_secret, user_id and screen_name.
			// We support all these.
			NSArray *subComponents = [component componentsSeparatedByString:@"="];
			[self setValue:[subComponents objectAtIndex:1] forKey:[subComponents objectAtIndex:0]];			
		}
		
		self.oauth_token_authorized = YES;
		if ([self.delegate respondsToSelector:@selector(authorizeTwitterTokenDidSucceed:)]) {
			[delegate authorizeTwitterTokenDidSucceed:self];
		}
	}
}


/**
 * Verify with the provider whether the credentials are currently valid. YES if yes.
 */
- (BOOL) synchronousVerifyTwitterCredentials {
	
	NSString *url = @"https://api.twitter.com/1/account/verify_credentials.json";
	
	NSString *oauth_header = [self oAuthHeaderForMethod:@"GET" andUrl:url andParams:nil];
	
	DEHTTPRequest *request = [DEHTTPRequest requestWithURL:[NSURL URLWithString:url]];
	request.requestMethod = @"GET";
	[request addRequestHeader:@"Authorization" value:oauth_header];
	[request startSynchronous];
	if ([request error]) {
		return NO;
	} else {
		return YES;
	}
}

#pragma mark -
#pragma mark Internal utilities for crypto, signing.

/**
 * Given a HTTP method, URL and a set of parameters, calculate the signature base string according to the spec.
 * Some ideas for the implementation come from OAMutableUrlRequest
 * (http://oauth.googlecode.com/svn/code/obj-c/OAuthConsumer/OAMutableURLRequest.m).
 */
- (NSString *) oauth_signature_base:(NSString *)httpMethod withUrl:(NSString *)url andParams:(NSDictionary *)params {
	
	// Freshen the context. Get a fresh timestamp and calculate a nonce.
	// Nonce algorithm is sha1(timestamp || random), i.e
	// we concatenate timestamp with a random string, and then sha1 it.
	int timestamp = time(NULL);
	oauth_timestamp = [NSString stringWithFormat:@"%d", timestamp];
	int myRandom = random();
	oauth_nonce = [self sha1:[NSString stringWithFormat:@"%d%d", timestamp, myRandom]];
	
	NSMutableDictionary *parts = [NSMutableDictionary dictionaryWithCapacity:[[self oauth_base_components] count]];
	
	[NSMutableArray arrayWithCapacity:[[self oauth_base_components] count]];
	
	// Include all the OAuth base components into signature base string, no matter what else is going on.
	for (NSString *part in [self oauth_base_components]) {
		[parts setObject:[self valueForKey:part] forKey:part];
	}
	
	if (params) {		
		[parts addEntriesFromDictionary:params];
	}
	
	// Sort the base string components and make them into string key=value pairs.
	NSMutableArray *normalizedBase = [NSMutableArray arrayWithCapacity:[parts count]];
	for (NSString *key in [[parts allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
		[normalizedBase addObject:[NSString stringWithFormat:@"%@=%@", key, [parts objectForKey:key]]];
	}
	
	NSString *normalizedRequestParameters = [normalizedBase componentsJoinedByString:@"&"];
	
	// Return the signature base string. Note that the individual parameters must have previously
	// already URL-encoded and here we are encoding them again; thus you will see some
	// double URL-encoding for params. This is normal.
	return [NSString stringWithFormat:@"%@&%@&%@",
            httpMethod,
            [url encodedURLParameterString],
            [normalizedRequestParameters encodedURLParameterString]];
}

/**
 * Given a calculated signature (by this point it is Base64-encoded string) and a set of parameters, return
 * the header value that you will stick in the "Authorization" header.
 */
- (NSString *) oauth_authorization_header:(NSString *)oauth_signature withParams:(NSDictionary *)params {
	NSMutableArray *chunks = [[[NSMutableArray alloc] init] autorelease];
	
	// First add all the base components.
	[chunks addObject:@"OAuth realm=\"\""];
	for (NSString *part in [self oauth_base_components]) {
		[chunks addObject:[NSString stringWithFormat:@"%@=\"%@\"", part, [[self valueForKey:part] encodedURLParameterString]]];
	}
	
	// Add parameter values if any. They don't really have to be sorted, but we do it anyway
	// just to be nice and make the output somewhat more parsable.
	if (params) {
		for (NSString *key in [[params allKeys] sortedArrayUsingSelector:@selector(compare:)]) {		
			[chunks addObject:[NSString stringWithFormat:@"%@=\"%@\"", key, [params objectForKey:key]]];
		}
	}
	
	// Signature will be the last component of our header.
	[chunks addObject:[NSString stringWithFormat:@"%@=\"%@\"", @"oauth_signature", [oauth_signature encodedURLParameterString]]];
	
	return [NSString stringWithFormat:@"%@", [chunks componentsJoinedByString:@", "]];
}

/**
 * Return the set of OAuth base components to always include in signature base string and header. If we have an authorized token, we use it,
 * otherwise we don't. The token is not authorized for /request and /access_token. For the former, we don't need to include the token.
 * For the latter, we include it manually as an input parameter to the methods.
 */
- (NSArray *) oauth_base_components {
	if (self.oauth_token_authorized) {
		return [NSArray arrayWithObjects:@"oauth_timestamp", @"oauth_nonce",
				@"oauth_signature_method", @"oauth_consumer_key", @"oauth_version", @"oauth_token", nil];
	} else {
		return [NSArray arrayWithObjects:@"oauth_timestamp", @"oauth_nonce",
				@"oauth_signature_method", @"oauth_consumer_key", @"oauth_version", nil];
	}
}

// http://stackoverflow.com/questions/1353771/trying-to-write-nsstring-sha1-function-but-its-returning-null
- (NSString *)sha1:(NSString *)str {
	const char *cStr = [str UTF8String];
	unsigned char result[CC_SHA1_DIGEST_LENGTH];
	CC_SHA1(cStr, strlen(cStr), result);
	NSMutableString *out = [NSMutableString stringWithCapacity:20];
	for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
		[out appendFormat:@"%02X", result[i]];
	}
	return [out lowercaseString];
}

@end
