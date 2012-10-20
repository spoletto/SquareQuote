/*
 *  TwitterLoginPopupDelegate.h
 *  Special People
 *
 *  Created by Jaanus Kase on 19.04.10.
 *  Copyright 2010. All rights reserved.
 *
 */

@class TwitterLoginPopup;

@protocol TwitterLoginPopupDelegate <NSObject>
- (void)twitterLoginPopupDidCancel:(TwitterLoginPopup *)popup;
- (void)twitterLoginPopupDidAuthorize:(TwitterLoginPopup *)popup;
@end