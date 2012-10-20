/*
 *  TwitterLoginUiFeedback.h
 *  Special People
 *
 *  Created by Jaanus Kase on 19.04.10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

@class TwitterLoginPopup;

@protocol TwitterLoginUiFeedback <NSObject>

- (void) tokenRequestDidStart:(TwitterLoginPopup *)twitterLogin;
- (void) tokenRequestDidSucceed:(TwitterLoginPopup *)twitterLogin;
- (void) tokenRequestDidFail:(TwitterLoginPopup *)twitterLogin;

- (void) authorizationRequestDidStart:(TwitterLoginPopup *)twitterLogin;
- (void) authorizationRequestDidSucceed:(TwitterLoginPopup *)twitterLogin;
- (void) authorizationRequestDidFail:(TwitterLoginPopup *)twitterLogin;

@end