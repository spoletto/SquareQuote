//
//  QITextEditor.h
//  QuoteIt
//
//  Created by Stephen Poletto on 3/14/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

#import "QIBackgroundColorSelector.h"
#import "QIColorSelector.h"
#import "QIFontSelector.h"

@protocol QITextEditorDelegate;
@class CMUpDownControl;

@interface QITextEditor : UIViewController <QIColorSelectorDelegate, QIFontSelectorDelegate, QIBackgroundColorSelectorDelegate>

@property (nonatomic, assign) id <QITextEditorDelegate> delegate;

@property (nonatomic, retain) UIColor *selectedTextColor;
@property (nonatomic, retain) UIColor *selectedBackgroundColor;
@property (nonatomic, retain) UIFont *selectedFont;
@property (nonatomic) UITextAlignment selectedAlignment;

@property (retain, nonatomic) IBOutlet UIImageView *editorBackgroundView;
@property (retain, nonatomic) IBOutlet CMUpDownControl *fontSizeControl;
@property (retain, nonatomic) IBOutlet UILabel *fontLabel;
@property (retain, nonatomic) IBOutlet UILabel *sizeLabel;
@property (retain, nonatomic) IBOutlet UILabel *colorLabel;
@property (retain, nonatomic) IBOutlet UIView *fontView;
@property (retain, nonatomic) IBOutlet UIView *colorView;
@property (retain, nonatomic) IBOutlet UILabel *fontSelectionDisplayLabel;

@property (retain, nonatomic) IBOutlet UIView *navBarTitleView;
@property (retain, nonatomic) IBOutlet UIButton *leftAlignmentButton;
@property (retain, nonatomic) IBOutlet UIButton *centerAlignmentButton;
@property (retain, nonatomic) IBOutlet UIButton *rightAlignmentButton;

@property (retain, nonatomic) IBOutlet UIButton *fontActionButton;
@property (retain, nonatomic) IBOutlet UIButton *colorActionButton;
@property (retain, nonatomic) IBOutlet UIButton *backgroundColorButton;
@property (retain, nonatomic) IBOutlet UILabel *noBackgroundLabel;

@property (retain, nonatomic) IBOutlet UIView *colorButtonDepressedView;
@property (retain, nonatomic) IBOutlet UIView *backgroundButtonDepressedView;


@end

@protocol QITextEditorDelegate <NSObject>
@optional
- (void)textEditor:(QITextEditor *)editor userSelectedFont:(UIFont *)font;
- (void)textEditor:(QITextEditor *)editor userSelectedTextColor:(UIColor *)textColor;
- (void)textEditor:(QITextEditor *)editor userSelectedBackgroundColor:(UIColor *)backgroundColor;
- (void)textEditor:(QITextEditor *)editor userSelectedAlignment:(UITextAlignment)alignment;
- (void)textEditorIsDone:(QITextEditor *)editor;
@end

