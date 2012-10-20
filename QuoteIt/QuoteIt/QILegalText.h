//
//  QILegalText.h
//  QuoteIt
//
//  Created by Stephen Poletto on 4/7/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QILegalText : UIViewController <UIWebViewDelegate> {
    BOOL firstLoad;
}

@property (nonatomic, copy) NSString *urlToDisplay;
@property (retain, nonatomic) IBOutlet UIWebView *textDisplayRegion;

@end
