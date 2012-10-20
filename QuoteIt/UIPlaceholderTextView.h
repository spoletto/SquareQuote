//
//  UIPlaceholderTextView.h
//  Billrme
//
//  Created by Stephen Poletto on 11/18/11.
//  Copyright (c) 2011 Brown University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIPlaceholderTextView : UITextView {
    NSString *placeholder;
    UIColor *placeholderColor;
    
@private
    UILabel *placeHolderLabel;
}

@property (nonatomic, retain) UILabel *placeholderLabel;
@property (nonatomic, retain) NSString *placeholder;
@property (nonatomic, retain) UIColor *placeholderColor;

-(void)textChanged:(NSNotification*)notification;

@end