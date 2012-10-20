//
//  QIBackgroundColorSelector.h
//  QuoteIt
//
//  Created by Stephen Poletto on 4/7/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

@protocol QIBackgroundColorSelectorDelegate;

@interface QIBackgroundColorSelector : UIViewController

@property (nonatomic, assign) id <QIBackgroundColorSelectorDelegate> delegate;

@property (retain, nonatomic) IBOutlet UIImageView *editorBackgroundView;
@property (retain, nonatomic) IBOutlet UIScrollView *colorsScrollView;

@property (retain, nonatomic) IBOutlet UIView *titleView;
@property (retain, nonatomic) IBOutlet UILabel *titleBarLabel;

@end

@protocol QIBackgroundColorSelectorDelegate <NSObject>
@optional
- (void)backgroundColorSelctor:(QIBackgroundColorSelector *)selector userSelectedTextColor:(UIColor *)textColor;
- (void)backgroundColorSelectorIsDone:(QIBackgroundColorSelector *)selector;
@end