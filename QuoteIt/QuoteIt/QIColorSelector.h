//
//  QIColorSelector.h
//  QuoteIt
//
//  Created by Stephen Poletto on 3/15/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

@protocol QIColorSelectorDelegate;

@interface QIColorSelector : UIViewController

@property (nonatomic, assign) id <QIColorSelectorDelegate> delegate;

@property (retain, nonatomic) IBOutlet UIImageView *editorBackgroundView;
@property (retain, nonatomic) IBOutlet UIScrollView *colorsScrollView;

@property (retain, nonatomic) IBOutlet UIView *titleView;
@property (retain, nonatomic) IBOutlet UILabel *titleBarLabel;

@end

@protocol QIColorSelectorDelegate <NSObject>
@optional
- (void)colorSelctor:(QIColorSelector *)selector userSelectedTextColor:(UIColor *)textColor;
- (void)colorSelectorIsDone:(QIColorSelector *)selector;
@end