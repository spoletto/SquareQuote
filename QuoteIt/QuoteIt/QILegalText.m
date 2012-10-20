//
//  QILegalText.m
//  QuoteIt
//
//  Created by Stephen Poletto on 4/7/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

#import "QIUtilities.h"
#import "QILegalText.h"

@implementation QILegalText
@synthesize urlToDisplay;
@synthesize textDisplayRegion;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {        
        UIBarButtonItem *backItem = [UIBarButtonItem barItemWithImage:[QIUtilities backButtonImage] highlightedImage:[QIUtilities backButtonPressed] title:@"  Back" target:self action:@selector(back:)];
        self.navigationItem.leftBarButtonItem = backItem;
    }
    return self;
}

- (void)back:(id)sender {
    [QIUtilities navigationControllerPopViewControllerWithPageCurlTransition:super.navigationController];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    QIRenderNavigationBarTitle();
    
    UIImageView *backgroundImage = [[UIImageView alloc] initWithFrame:self.view.frame];
    [backgroundImage setImage:[QIUtilities bookImage]];
    [self.view insertSubview:backgroundImage atIndex:0];
    [backgroundImage release];
    
    firstLoad = YES;
    self.textDisplayRegion.alpha = 0.0;
    if (urlToDisplay) {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlToDisplay]];
        [self.textDisplayRegion loadRequest:request];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if (firstLoad) {
        firstLoad = NO;
        [UIView beginAnimations:@"QILegalTextWebViewAnimation" context:nil];
        self.textDisplayRegion.alpha = 1.0;
        [UIView commitAnimations];
    }
}

- (void)setUrlToDisplay:(NSString *)urlToDisplayIn {
    [urlToDisplay release];
    urlToDisplay = [urlToDisplayIn copy];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlToDisplay]];
    [self.textDisplayRegion loadRequest:request];
}

- (void)dealloc {
    [textDisplayRegion release];
    [super dealloc];
}

- (void)viewDidUnload {
    [self setTextDisplayRegion:nil];
    [super viewDidUnload];
}

@end
