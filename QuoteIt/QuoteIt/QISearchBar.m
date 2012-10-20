//
//  QISearchBar.m
//  QuoteIt
//
//  Created by Stephen Poletto on 12/31/11.
//  Copyright (c) 2011 QuoteIt. All rights reserved.
//

#import "QIUtilities.h"
#import "QISearchBar.h"

@implementation QISearchBar

// Customize the appearance of the cancel button.
- (void)addSubview:(UIView *)view {
    [super addSubview:view];
    
    if ([view isKindOfClass:[UIButton class]]) {
        UIButton *cancelButton = (UIButton *)view;
        [cancelButton setBackgroundImage:[UIImage imageNamed:@"cancel_static"] forState:UIControlStateNormal];
        [cancelButton setBackgroundImage:[UIImage imageNamed:@"cancel_press"] forState:UIControlStateHighlighted];
        
        // The width of the button is determined by the title. There are differences
        // in width between OSes.
        [cancelButton setTitle:@"          " forState:UIControlStateNormal];
        CGFloat systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
        if (systemVersion < 5.0) {
            [cancelButton setTitle:@"           " forState:UIControlStateNormal];
        }
    }
}

@end
