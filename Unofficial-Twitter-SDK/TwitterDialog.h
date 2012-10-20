//
//  TwitterDialog.h
//  YatterBox
//
//  Created by Lloyd Sparkes on 10/06/2011.
//  Copyright 2011 Lloyd Sparkes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAuthConsumerCredentials.h"
#import "OAuth.h"

@protocol  TwitterDialogDelegate;
@protocol TwitterLoginDialogDelegate;


@interface TwitterDialog : UIView<UIWebViewDelegate> {
    id<TwitterDialogDelegate> _delegate;
    id<TwitterLoginDialogDelegate> _logindelegate;
    NSString * _serverURL;
    NSURL* _loadingURL;
    UIWebView* _webView;
    UIActivityIndicatorView* _spinner;
    UIImageView* _iconView;
    UILabel* _titleLabel;
    UIButton* _closeButton;
    UIDeviceOrientation _orientation;
    UIView* _modalBackgroundView;
    BOOL _showingKeyboard;
    OAuth *_twitterOAuth;
    
}

@property(nonatomic, retain) OAuth *twitterOAuth;
@property(nonatomic,assign) id<TwitterDialogDelegate> delegate;
@property(nonatomic,assign) id<TwitterLoginDialogDelegate> logindelegate;

/**
 * Displays the view with an animation.
 *
 * The view will be added to the top of the current key window.
 */
- (void)show;

/**
 * Displays the first page of the dialog.
 *
 * Do not ever call this directly.  It is intended to be overriden by subclasses.
 */
- (void)load;

/**
 * Displays a URL in the dialog.
 */
- (void)loadURL:(NSString*)url
            get:(NSDictionary*)getParams;

/**
 * Hides the view and notifies delegates of success or cancellation.
 */
- (void)dismissWithSuccess:(BOOL)success animated:(BOOL)animated;

/**
 * Hides the view and notifies delegates of an error.
 */
- (void)dismissWithError:(NSError*)error animated:(BOOL)animated;

/**
 * Subclasses may override to perform actions just prior to showing the dialog.
 */
- (void)dialogWillAppear;

/**
 * Subclasses may override to perform actions just after the dialog is hidden.
 */
- (void)dialogWillDisappear;

/**
 * Subclasses should override to process data returned from the server in a 'fbconnect' url.
 *
 * Implementations must call dismissWithSuccess:YES at some point to hide the dialog.
 */
- (void)dialogDidSucceed:(NSURL *)url;

/**
 * Subclasses should override to process data returned from the server in a 'fbconnect' url.
 *
 * Implementations must call dismissWithSuccess:YES at some point to hide the dialog.
 */
- (void)dialogDidCancel:(NSURL *)url;
@end

/*
 *Your application should implement this delegate
 */
@protocol TwitterDialogDelegate <NSObject>

@optional

/**
 * Called when the dialog succeeds and is about to be dismissed.
 */
- (void)dialogDidComplete:(TwitterDialog *)dialog;

/**
 * Called when the dialog succeeds with a returning url.
 */
- (void)dialogCompleteWithUrl:(NSURL *)url;

/**
 * Called when the dialog get canceled by the user.
 */
- (void)dialogDidNotCompleteWithUrl:(NSURL *)url;

/**
 * Called when the dialog is cancelled and is about to be dismissed.
 */
- (void)dialogDidNotComplete:(TwitterDialog *)dialog;

/**
 * Called when dialog failed to load due to an error.
 */
- (void)dialog:(TwitterDialog*)dialog didFailWithError:(NSError *)error;

/**
 * Asks if a link touched by a user should be opened in an external browser.
 *
 * If a user touches a link, the default behavior is to open the link in the Safari browser,
 * which will cause your app to quit.  You may want to prevent this from happening, open the link
 * in your own internal browser, or perhaps warn the user that they are about to leave your app.
 * If so, implement this method on your delegate and return NO.  If you warn the user, you
 * should hold onto the URL and once you have received their acknowledgement open the URL yourself
 * using [[UIApplication sharedApplication] openURL:].
 */
- (BOOL)dialog:(TwitterDialog*)dialog shouldOpenURLInExternalBrowser:(NSURL *)url;

@end

@protocol TwitterLoginDialogDelegate <NSObject>

- (void)twitterDidLogin;

- (void)twitterDidNotLogin:(BOOL)cancelled;

@end

