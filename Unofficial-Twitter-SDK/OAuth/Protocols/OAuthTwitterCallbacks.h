/*
 *  OAuthTwitterCallbacks.h
 *  Special People
 *
 *  Created by Jaanus Kase on 19.04.10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

@class OAuth;

@protocol OAuthTwitterCallbacks <NSObject>
- (void) requestTwitterTokenDidSucceed:(OAuth *)oAuth;
- (void) requestTwitterTokenDidFail:(OAuth *)oAuth;
- (void) authorizeTwitterTokenDidSucceed:(OAuth *)oAuth;
- (void) authorizeTwitterTokenDidFail:(OAuth *)oAuth;
@end

