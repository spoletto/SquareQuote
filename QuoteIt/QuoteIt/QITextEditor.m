//
//  QITextEditor.m
//  QuoteIt
//
//  Created by Stephen Poletto on 3/14/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "UIDevice+DETweetComposeViewController.h"
#import "CMUpDownControl.h"
#import "QITextEditor.h"
#import "QIUtilities.h"

@interface QITextEditor()
- (void)updateUIWithSelectedParameters;
@end

@implementation QITextEditor
@synthesize editorBackgroundView;
@synthesize fontSizeControl;
@synthesize fontLabel;
@synthesize sizeLabel;
@synthesize colorLabel;
@synthesize fontView;
@synthesize colorView;
@synthesize fontSelectionDisplayLabel;
@synthesize navBarTitleView;
@synthesize leftAlignmentButton;
@synthesize centerAlignmentButton;
@synthesize rightAlignmentButton;
@synthesize fontActionButton;
@synthesize colorActionButton;
@synthesize backgroundColorButton;
@synthesize noBackgroundLabel;
@synthesize colorButtonDepressedView;
@synthesize backgroundButtonDepressedView;
@synthesize selectedFont, selectedAlignment, selectedTextColor, selectedBackgroundColor;
@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        CGFloat shiftDownByHeight = ([UIDevice de_isIOS5]) ? 15.0 : 0.0;
        UIBarButtonItem *doneItem = [UIBarButtonItem barItemWithImage:[UIImage imageNamed:@"sheet_btn_done_static"] highlightedImage:[UIImage imageNamed:@"sheet_btn_done_press"] title:nil target:self action:@selector(done:) shiftedDownByHeight:shiftDownByHeight];
        self.navigationItem.rightBarButtonItem = doneItem;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navBarTitleView.backgroundColor = [UIColor clearColor];
    
    if (![UIDevice de_isIOS5]) {
        CGRect leftFrame = self.leftAlignmentButton.frame;
        CGRect rightFrame = self.rightAlignmentButton.frame;
        CGRect centerFrame = self.centerAlignmentButton.frame;
        leftFrame.origin.y -= 9;
        rightFrame.origin.y -= 9;
        centerFrame.origin.y -= 9;
        self.leftAlignmentButton.frame = leftFrame;
        self.rightAlignmentButton.frame = rightFrame;
        self.centerAlignmentButton.frame = centerFrame;
    }
    
    self.navigationItem.titleView = self.navBarTitleView;
    self.fontSizeControl.backgroundColor = [UIColor clearColor];
    self.fontSizeControl.minimumAllowedValue = 8;
	self.fontSizeControl.maximumAllowedValue = 72;
    
    [self.leftAlignmentButton setImage:[UIImage imageNamed:@"alignment_left_press"] forState:UIControlStateHighlighted];
    [self.centerAlignmentButton setImage:[UIImage imageNamed:@"alignment_middle_press"] forState:UIControlStateHighlighted];
    [self.rightAlignmentButton setImage:[UIImage imageNamed:@"alignment_right_press"] forState:UIControlStateHighlighted];
    [self.fontActionButton setImage:[UIImage imageNamed:@"sheet_background_press"] forState:UIControlStateHighlighted];
    
    [self.backgroundColorButton setBackgroundColor:[QIUtilities textEditorFontSelectorBackgroundColor]];
    self.backgroundColorButton.layer.borderWidth = 1.0;
    self.backgroundColorButton.layer.borderColor = [QIUtilities avatarBorderColor].CGColor;
    
    self.fontLabel.textColor = [QIUtilities textEditorLabelColor];
    self.sizeLabel.textColor = [QIUtilities textEditorLabelColor];
    self.noBackgroundLabel.textColor = [QIUtilities textEditorLabelColor];
    self.colorLabel.textColor = [QIUtilities textEditorLabelColor];
    
    // Set up the bounding boxes for the font and color selectors.
    self.fontView.layer.cornerRadius = 4.0;
    self.fontView.layer.borderWidth = 1.0;
    self.fontView.layer.borderColor = [QIUtilities avatarBorderColor].CGColor;
    self.fontView.layer.masksToBounds = YES;
    [self.fontView.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.fontView.layer setShadowOffset:CGSizeMake(0, 0)];
    [self.fontView.layer setShadowOpacity:1];
    [self.fontView.layer setShadowRadius:2.0];
    self.fontView.backgroundColor = [QIUtilities textEditorFontSelectorBackgroundColor];
    
    self.colorView.layer.cornerRadius = 4.0;
    self.colorView.layer.borderWidth = 1.0;
    self.colorView.layer.borderColor = [QIUtilities avatarBorderColor].CGColor;
    self.colorView.layer.masksToBounds = YES;
    [self.colorView.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.colorView.layer setShadowOffset:CGSizeMake(0, 0)];
    [self.colorView.layer setShadowOpacity:1];
    [self.colorView.layer setShadowRadius:2.0];
    
    self.backgroundButtonDepressedView.hidden = YES;
    self.colorButtonDepressedView.hidden = YES;
    self.backgroundButtonDepressedView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.2];
    self.colorButtonDepressedView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.2];
    
    [self updateUIWithSelectedParameters];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Set the frame size
    CGRect frame = self.view.frame;
    
    // This constant must be the height of the view containing the controls + 44.
    frame.size.height = self.editorBackgroundView.frame.size.height + 44;
    self.view.frame = frame;
}

- (void)done:(id)sender {
	if (delegate && [delegate respondsToSelector:@selector(textEditorIsDone:)]) {
        [delegate textEditorIsDone:self];
	}
}

- (void)notifyDelegateSelectedFontChanged {
	if (delegate && [delegate respondsToSelector:@selector(textEditor:userSelectedFont:)]) {
		[delegate textEditor:self userSelectedFont:self.selectedFont];
	}
}

- (void)notifyDelegateSelectedAlignmentChanged {
    if (delegate && [delegate respondsToSelector:@selector(textEditor:userSelectedAlignment:)]) {
        [delegate textEditor:self userSelectedAlignment:self.selectedAlignment];
    }
}

- (void)notifyDelegateSelectedTextColorChanged {
    if (delegate && [delegate respondsToSelector:@selector(textEditor:userSelectedTextColor:)]) {
        [delegate textEditor:self userSelectedTextColor:self.selectedTextColor];
    }
}

- (void)notifyDelegateSelectedBackgroundColorChanged {
    if (delegate && [delegate respondsToSelector:@selector(textEditor:userSelectedBackgroundColor:)]) {
        [delegate textEditor:self userSelectedBackgroundColor:self.selectedBackgroundColor];
    }
}

- (void)updateUIWithSelectedParameters {
    //update UI for font, color and size
    self.fontSizeControl.value = selectedFont.pointSize;
    [self.fontSizeControl setNeedsDisplay];
    self.colorView.backgroundColor = self.selectedTextColor;
    self.noBackgroundLabel.hidden = YES;
    self.backgroundColorButton.backgroundColor = self.selectedBackgroundColor;
    if (!self.selectedBackgroundColor || [self.selectedBackgroundColor isEqual:[UIColor clearColor]]) {
        // If there's no background selected, show the "No Background" label.
        self.noBackgroundLabel.hidden = NO;
        self.backgroundColorButton.backgroundColor = [QIUtilities textEditorFontSelectorBackgroundColor];
    }
    
    // Always size 17.
    self.fontSelectionDisplayLabel.font = [UIFont fontWithName:self.selectedFont.fontName size:17.0];
    self.fontSelectionDisplayLabel.text = QIPrettyFontNameFromFont(self.selectedFont);
    
    // Update pressed-state for alignment buttons. Inelegant. Lazy coding.
    if (selectedAlignment == UITextAlignmentLeft) {
        [self.leftAlignmentButton setImage:[UIImage imageNamed:@"alignment_left_press"] forState:UIControlStateNormal];
        [self.centerAlignmentButton setImage:[UIImage imageNamed:@"alignment_middle_static"] forState:UIControlStateNormal];
        [self.rightAlignmentButton setImage:[UIImage imageNamed:@"alignment_right_static"] forState:UIControlStateNormal];
    } else if (selectedAlignment == UITextAlignmentCenter) {
        [self.leftAlignmentButton setImage:[UIImage imageNamed:@"alignment_left_static"] forState:UIControlStateNormal];
        [self.centerAlignmentButton setImage:[UIImage imageNamed:@"alignment_middle_press"] forState:UIControlStateNormal];
        [self.rightAlignmentButton setImage:[UIImage imageNamed:@"alignment_right_static"] forState:UIControlStateNormal];
    } else if (selectedAlignment == UITextAlignmentRight) {
        [self.leftAlignmentButton setImage:[UIImage imageNamed:@"alignment_left_static"] forState:UIControlStateNormal];
        [self.centerAlignmentButton setImage:[UIImage imageNamed:@"alignment_middle_static"] forState:UIControlStateNormal];
        [self.rightAlignmentButton setImage:[UIImage imageNamed:@"alignment_right_press"] forState:UIControlStateNormal];
    }
}

- (void)setSelectedFont:(UIFont *)selectedFontIn {
    [selectedFont release];
    selectedFont = [selectedFontIn retain];
    [self updateUIWithSelectedParameters];
    [self notifyDelegateSelectedFontChanged];
}

- (void)setSelectedTextColor:(UIColor *)selectedTextColorIn {
    [selectedTextColor release];
    selectedTextColor = [selectedTextColorIn retain];
    [self updateUIWithSelectedParameters];
    [self notifyDelegateSelectedTextColorChanged];
}

- (void)setSelectedBackgroundColor:(UIColor *)selectedBackgroundColorIn {
    [selectedBackgroundColor release];
    selectedBackgroundColor = [selectedBackgroundColorIn retain];
    [self updateUIWithSelectedParameters];
    [self notifyDelegateSelectedBackgroundColorChanged];
}

- (void)setSelectedAlignment:(UITextAlignment)selectedAlignmentIn {
    selectedAlignment = selectedAlignmentIn;
    [self updateUIWithSelectedParameters];
}

- (IBAction)fontSizeChanged:(CMUpDownControl *)control {
    CGFloat size = (CGFloat)control.value;
	UIFont *textFont = [UIFont fontWithName:self.selectedFont.fontName size:size];
	self.selectedFont = textFont;
	
	[self notifyDelegateSelectedFontChanged];
}

- (IBAction)leftAlignmentSelected:(id)sender {
    self.selectedAlignment = UITextAlignmentLeft;
    [self notifyDelegateSelectedAlignmentChanged];
}

- (IBAction)centerAlignmentSelected:(id)sender {
    self.selectedAlignment = UITextAlignmentCenter;
    [self notifyDelegateSelectedAlignmentChanged];
}

- (IBAction)rightAlignmentSelected:(id)sender {
    self.selectedAlignment = UITextAlignmentRight;
    [self notifyDelegateSelectedAlignmentChanged];
}

#pragma mark -
#pragma mark QIFontSelectorDelegate

- (void)fontSelctor:(QIFontSelector *)selector userSelectedFont:(UIFont *)font {
    self.selectedFont = [UIFont fontWithName:font.fontName size:fontSizeControl.value];
}

- (void)fontSelectorIsDone:(QIFontSelector *)selector {
    if (delegate && [delegate respondsToSelector:@selector(textEditorIsDone:)]) {
        [delegate textEditorIsDone:self];
	}
}

- (IBAction)fontButtonPressed:(id)sender {
    QIFontSelector *fontSelector = [[QIFontSelector alloc] initWithNibName:@"QIFontSelector" bundle:nil];
    fontSelector.delegate = self;
    [self.navigationController pushViewController:fontSelector animated:NO];
    [fontSelector release];
}

#pragma mark -
#pragma mark QIColorSelectorDelegate

- (void)colorSelctor:(QIColorSelector *)selector userSelectedTextColor:(UIColor *)textColor {
    self.selectedTextColor = textColor;
}

- (void)colorSelectorIsDone:(QIColorSelector *)selector {
    if (delegate && [delegate respondsToSelector:@selector(textEditorIsDone:)]) {
        [delegate textEditorIsDone:self];
	}
}

- (IBAction)colorButtonPressed:(id)sender {
    QIColorSelector *colorSelectior = [[QIColorSelector alloc] initWithNibName:@"QIColorSelector" bundle:nil];
    colorSelectior.delegate = self;
    [self.navigationController pushViewController:colorSelectior animated:NO];
    [colorSelectior release];
    self.colorButtonDepressedView.hidden = YES;
}

- (IBAction)colorButtonTouchDown:(id)sender {
    self.colorButtonDepressedView.hidden = NO;
}

- (IBAction)colorButtonTouchUpOutside:(id)sender {
    self.colorButtonDepressedView.hidden = YES;
}

#pragma mark -
#pragma mark QIBackgroundColorSelectorDelegate

- (void)backgroundColorSelctor:(QIBackgroundColorSelector *)selector userSelectedTextColor:(UIColor *)textColor {
    self.selectedBackgroundColor = textColor;
}

- (void)backgroundColorSelectorIsDone:(QIBackgroundColorSelector *)selector {
    if (delegate && [delegate respondsToSelector:@selector(textEditorIsDone:)]) {
        [delegate textEditorIsDone:self];
	}
}

- (IBAction)backgroundColorButtonTouchDown:(id)sender {
    self.backgroundButtonDepressedView.hidden = NO;
}

- (IBAction)backgroundColorButtonTouchUpOutside:(id)sender {
    self.backgroundButtonDepressedView.hidden = YES;
}

- (IBAction)backgroundColorButtonPressed:(id)sender {
    QIBackgroundColorSelector *colorSelectior = [[QIBackgroundColorSelector alloc] initWithNibName:@"QIBackgroundColorSelector" bundle:nil];
    colorSelectior.delegate = self;
    [self.navigationController pushViewController:colorSelectior animated:NO];
    [colorSelectior release];
    self.backgroundButtonDepressedView.hidden = YES;
}

- (void)dealloc {
    [editorBackgroundView release];
    [fontSizeControl release];
    [navBarTitleView release];
    [fontLabel release];
    [sizeLabel release];
    [colorLabel release];
    [fontView release];
    [colorView release];
    [fontSelectionDisplayLabel release];
    [leftAlignmentButton release];
    [centerAlignmentButton release];
    [rightAlignmentButton release];
    [fontActionButton release];
    [colorActionButton release];
    [backgroundColorButton release];
    [noBackgroundLabel release];
    [colorButtonDepressedView release];
    [backgroundButtonDepressedView release];
    [super dealloc];
}

- (void)viewDidUnload {
    [self setEditorBackgroundView:nil];
    [self setFontSizeControl:nil];
    [self setNavBarTitleView:nil];
    [self setFontLabel:nil];
    [self setSizeLabel:nil];
    [self setColorLabel:nil];
    [self setFontView:nil];
    [self setColorView:nil];
    [self setFontSelectionDisplayLabel:nil];
    [self setLeftAlignmentButton:nil];
    [self setCenterAlignmentButton:nil];
    [self setRightAlignmentButton:nil];
    [self setFontActionButton:nil];
    [self setColorActionButton:nil];
    [self setBackgroundColorButton:nil];
    [self setNoBackgroundLabel:nil];
    [self setColorButtonDepressedView:nil];
    [self setBackgroundButtonDepressedView:nil];
    [super viewDidUnload];
}

@end
