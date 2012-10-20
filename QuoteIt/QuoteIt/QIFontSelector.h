//
//  QIFontSelector.h
//  QuoteIt
//
//  Created by Stephen Poletto on 3/15/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol QIFontSelectorDelegate;

@interface QIFontSelector : UIViewController

@property (nonatomic, assign) id <QIFontSelectorDelegate> delegate;

@property (retain, nonatomic) IBOutlet UIImageView *editorBackgroundView;
@property (retain, nonatomic) IBOutlet UIScrollView *fontsScrollView;

@property (retain, nonatomic) IBOutlet UIView *titleView;
@property (retain, nonatomic) IBOutlet UILabel *titleViewLabel;

@end

@protocol QIFontSelectorDelegate <NSObject>
@optional
- (void)fontSelctor:(QIFontSelector *)selector userSelectedFont:(UIFont *)font;
- (void)fontSelectorIsDone:(QIFontSelector *)selector;
@end